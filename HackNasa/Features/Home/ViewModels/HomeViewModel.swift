//
//  HomeViewModel.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import Foundation
import Combine
import SwiftUI

struct filesCSV: Decodable {
    let csvs: [String]
}

class HomeViewModel: ObservableObject {
    @Published var files: [FilesLoaded] = []
    @Published var fileSelected: FilesLoaded.ID? = nil
    @Published var dataset: [GeneralDataset]? = nil {
        didSet {
            recomputeCharts()
        }
    }
    @Published var isLoadingFiles: Bool = false
    @Published var isLoadingDataset: Bool = false
    @Published var isLoadingPrecision: Bool = false
    /// Estado de carga agregado para compatibilidad con vistas existentes
    @Published var isLoading: Bool = false
    @Published var presicion: ModelPrecision? = nil
    
    // Resultados precalculados de gráficas para no hacer trabajo pesado en el body de las vistas
    @Published var steffVsSradPoints: [SteffVsSradPoint] = []
    @Published var durationAggData: [DurationByDisposition] = []
    @Published var steffBinsData: [SteffBin] = []
    @Published var sloggBinsData: [SloggBin] = []
    @Published var snrLogBinsData: [ModelSNRBin] = []
    @Published var depthLogBinsData: [DepthLogBin] = []
    @Published var periodLogBinsData: [PeriodLogBin] = []
    
#if DEBUG
    // No need to recomputeCharts on init in debug: dataset is set directly and triggers didSet
#endif
    init() {
#if DEBUG
        // Datos falsos para debug
        self.files = FilesLoaded.mockList
        self.fileSelected = self.files.first?.id
        self.dataset = GeneralDataset.mockList
        self.presicion = .mock
#else
        Task {
            await fetchFiles()
            await getModelPresicion()
        }
#endif
    }
    
    func getModelPresicion() async {
        isLoadingPrecision = true
        updateLoadingState()
        defer {
            isLoadingPrecision = false
            updateLoadingState()
        }
        guard let req = APIEndpoint.modelPrecision.request() else { return }
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
                print("Respuesta HTTP no válida. Código: \(code)")
                return
            }
            let decoded = try JSONDecoder().decode(ModelPrecision.self, from: data)
            await MainActor.run {
                withAnimation {
                    self.presicion = decoded
                }
            }
        } catch {
            print("Error de red o decodificación, modelPrecision:", error)
        }
    }
    
    func selectCSV() async {
        guard let fileSelectedID = fileSelected,
              let fileSelected = files.first(where: { $0.id == fileSelectedID }) else { return }
        
        let fileName = csvBaseName(fileSelected.name)
        // Crea el URLRequest listo para usar
        guard let req = APIEndpoint.selectCSV(name: fileName).request()
        else { return }
        do {
            // Llama al endpoint
            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return
            }
            await fetchDataset()
        } catch {
            print("Error de red o decodificación, selectedCSV: ", error)
        }
    }
    
    /// Normaliza el nombre (por si te pasan "foo.csv")
    private func csvBaseName(_ name: String) -> String {
        name.lowercased().hasSuffix(".csv") ? String(name.dropLast(4)) : name
    }
    
    func fetchDataset() async {
        isLoadingDataset = true
        updateLoadingState()
        cleanData()
        guard let url = APIEndpoint.generalData.url() else {
            print("URL inválida")
            isLoadingDataset = false
            updateLoadingState()
            return
        }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("Respuesta HTTP no válida. Código: \(code)")
                return
            }
            
            let decoder = JSONDecoder()
            let datasets = try decoder.decode([GeneralDataset].self, from: data)
            
            await MainActor.run {
                withAnimation {
                    self.dataset = datasets
                }
            }
            print("Dataset cargado correctamente: \(datasets.count) registros")
        } catch {
            print("Error de red o decodificación:, fetchDataset", error)
        }
        isLoadingDataset = false
        updateLoadingState()
    }
    
    func fetchFiles() async {
        isLoadingFiles = true
        updateLoadingState()
        guard let req = APIEndpoint.listCSVs.request() else {
            isLoadingFiles = false
            updateLoadingState()
            return
        }
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let nombres = try JSONDecoder().decode(filesCSV.self, from: data)
            files = nombres.csvs.map { FilesLoaded(name: $0) }
        } catch {
            print("Error de red o decodificación:, fetchFiles", error)
        }
        
        isLoadingFiles = false
        updateLoadingState()
        automaticSelection()
    }
    private func automaticSelection() {
        let firstFile = files.first?.id
        fileSelected = firstFile
    }
    private func cleanData() {
        dataset = nil
    }
    
    // MARK: - Chart Inputs
    
    /// 1) Dispersión Teff vs Srad
    func datasetPointsSteffSrad() -> [SteffVsSradPoint] {
        let items = dataset ?? []
        return datasetPointsSteffSrad(from: items)
    }
    
    private func datasetPointsSteffSrad(from items: [GeneralDataset]) -> [SteffVsSradPoint] {
        return items.compactMap { d in
            guard let steff = d.koiSteff, steff.isFinite,
                  let srad  = d.koiSrad,  srad.isFinite else { return nil }
            let disp = (d.koiDisposition as String?)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "N/A"
            return SteffVsSradPoint(steff: steff, srad: srad, disposition: disp.isEmpty ? "N/A" : disp)
        }
    }
    
    /// 2) Barras por disposición: media o mediana de duración
    func durationAgg(stat: String = "media") -> [DurationByDisposition] {
        let items = dataset ?? []
        return durationAgg(from: items, stat: stat)
    }
    
    private func durationAgg(from items: [GeneralDataset], stat: String = "media") -> [DurationByDisposition] {
        let grouped = Dictionary(grouping: items.compactMap { d -> (String, Double)? in
            guard let v = d.koiDuration, v.isFinite else { return nil }
            let disp = (d.koiDisposition as String?)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "N/A"
            return (disp.isEmpty ? "N/A" : disp, v)
        }) { $0.0 }
        
        return grouped.map { (key, pairs) in
            let values = pairs.map { $0.1 }.sorted()
            if stat.lowercased() == "mediana" {
                let mid = values.count / 2
                let med: Double = values.isEmpty ? .nan :
                (values.count % 2 == 0 ? (values[mid - 1] + values[mid]) / 2 : values[mid])
                return DurationByDisposition(disposition: key, value: med, stat: "mediana")
            } else {
                let mean = values.isEmpty ? .nan : values.reduce(0, +) / Double(values.count)
                return DurationByDisposition(disposition: key, value: mean, stat: "media")
            }
        }
        .sorted { $0.disposition < $1.disposition }
    }
    
    // MARK: - Histogram helpers
    private func linearBinIndex(value: Double, step: Double) -> Int {
        Int(floor(value / step))
    }
    private func linearBinLabel(index: Int, step: Double, unit: String? = nil) -> String {
        let start = Double(index) * step
        let end   = Double(index + 1) * step
        let label = "\(trim(start))–\(trim(end))"
        return unit == nil ? label : "\(label) \(unit!)"
    }
    private func edgeBinIndex(value: Double, edges: [Double]) -> Int? {
        guard edges.count >= 2 else { return nil }
        // bins defined by consecutive pairs: [e0,e1), [e1,e2), ..., [e{n-2}, e{n-1})
        for i in 0..<(edges.count - 1) {
            if (value >= edges[i] && value < edges[i + 1]) { return i }
        }
        // include right edge on last bin
        if let last = edges.last, value == last { return edges.count - 2 }
        return nil
    }
    private func edgeBinLabel(index: Int, edges: [Double]) -> String {
        guard index >= 0, index + 1 < edges.count else { return "N/A" }
        return "\(trim(edges[index]))–\(trim(edges[index + 1]))"
    }
    private func trim(_ x: Double) -> String {
        // compact number formatting without trailing zeros
        let s = String(format: "%.4f", x)
        return s.replacingOccurrences(of: #"(\.\d*?[1-9])0+$"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\.0+$"#, with: "", options: .regularExpression)
    }
    
    /// 3) Histograma Teff por disposición. step en Kelvin.
    func steffBins(step: Double = 250) -> [SteffBin] {
        let items = dataset ?? []
        return steffBins(from: items, step: step)
    }
    
    private func steffBins(from items: [GeneralDataset], step: Double = 250) -> [SteffBin] {
        let rows = items.compactMap { d -> (String, Int)? in
            guard let v = d.koiSteff, v.isFinite else { return nil }
            let idx = linearBinIndex(value: v, step: step)
            let label = linearBinLabel(index: idx, step: step)
            let disp = (d.koiDisposition as String?)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "N/A"
            return (label + "|\(disp.isEmpty ? "N/A" : disp)", 1)
        }
        let grouped = Dictionary(grouping: rows, by: { $0.0 })
        return grouped.map { (key, vals) in
            let parts = key.split(separator: "|", maxSplits: 1).map(String.init)
            let label = parts.first ?? "N/A"
            let disp  = parts.count > 1 ? parts[1] : "N/A"
            return SteffBin(binLabel: label, count: vals.count, disposition: disp)
        }
        .sorted { ($0.binLabel, $0.disposition) < ($1.binLabel, $1.disposition) }
    }
    
    /// 4) Histograma log g por disposición. step típico 0.2
    func sloggBins(step: Double = 0.2) -> [SloggBin] {
        let items = dataset ?? []
        return sloggBins(from: items, step: step)
    }
    
    private func sloggBins(from items: [GeneralDataset], step: Double = 0.2) -> [SloggBin] {
        let rows = items.compactMap { d -> (String, Int)? in
            guard let v = d.koiSlogg, v.isFinite else { return nil }
            let idx = linearBinIndex(value: v, step: step)
            let label = linearBinLabel(index: idx, step: step)
            let disp = (d.koiDisposition as String?)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "N/A"
            return (label + "|\(disp.isEmpty ? "N/A" : disp)", 1)
        }
        let grouped = Dictionary(grouping: rows, by: { $0.0 })
        return grouped.map { (key, vals) in
            let parts = key.split(separator: "|", maxSplits: 1).map(String.init)
            let label = parts.first ?? "N/A"
            let disp  = parts.count > 1 ? parts[1] : "N/A"
            return SloggBin(binLabel: label, count: vals.count, disposition: disp)
        }
        .sorted { ($0.binLabel, $0.disposition) < ($1.binLabel, $1.disposition) }
    }
    
    /// 5) Histograma SNR con bins log a partir de bordes (edges)
    func snrLogBins(edges: [Double] = [0.1, 0.3, 1, 3, 10, 30, 100]) -> [ModelSNRBin] {
        let items = dataset ?? []
        return snrLogBins(from: items, edges: edges)
    }
    
    private func snrLogBins(from items: [GeneralDataset], edges: [Double] = [0.1, 0.3, 1, 3, 10, 30, 100]) -> [ModelSNRBin] {
        let rows = items.compactMap { d -> (String, Int)? in
            guard let raw = d.koiModelSnr, raw.isFinite, raw > 0 else { return nil }
            guard let idx = edgeBinIndex(value: raw, edges: edges) else { return nil }
            let label = edgeBinLabel(index: idx, edges: edges)
            let disp = (d.koiDisposition as String?)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "N/A"
            return (label + "|\(disp.isEmpty ? "N/A" : disp)", 1)
        }
        let grouped = Dictionary(grouping: rows, by: { $0.0 })
        return grouped.map { (key, vals) in
            let parts = key.split(separator: "|", maxSplits: 1).map(String.init)
            let label = parts.first ?? "N/A"
            let disp  = parts.count > 1 ? parts[1] : "N/A"
            return ModelSNRBin(binLabel: label, count: vals.count, disposition: disp)
        }
        .sorted { ($0.binLabel, $0.disposition) < ($1.binLabel, $1.disposition) }
    }
    
    /// 6) Histograma de profundidad con bins en log10. step en unidades de log10
    func depthLogBins(step: Double = 0.5) -> [DepthLogBin] {
        let items = dataset ?? []
        return depthLogBins(from: items, step: step)
    }
    
    private func depthLogBins(from items: [GeneralDataset], step: Double = 0.5) -> [DepthLogBin] {
        let rows = items.compactMap { d -> (String, Int)? in
            guard let raw = d.koiDepth, raw.isFinite, raw > 0 else { return nil }
            let v = log10(raw)
            let idx = linearBinIndex(value: v, step: step)
            let label = linearBinLabel(index: idx, step: step)
            let disp = (d.koiDisposition as String?)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "N/A"
            return (label + "|\(disp.isEmpty ? "N/A" : disp)", 1)
        }
        let grouped = Dictionary(grouping: rows, by: { $0.0 })
        return grouped.map { (key, vals) in
            let parts = key.split(separator: "|", maxSplits: 1).map(String.init)
            let label = parts.first ?? "N/A"
            let disp  = parts.count > 1 ? parts[1] : "N/A"
            return DepthLogBin(binLabel: label, count: vals.count, disposition: disp)
        }
        .sorted { ($0.binLabel, $0.disposition) < ($1.binLabel, $1.disposition) }
    }
    
    /// 7) Histograma de periodo con bins en log10. step en unidades de log10
    func periodLogBins(step: Double = 0.3) -> [PeriodLogBin] {
        let items = dataset ?? []
        return periodLogBins(from: items, step: step)
    }
    
    private func periodLogBins(from items: [GeneralDataset], step: Double = 0.3) -> [PeriodLogBin] {
        let rows = items.compactMap { d -> (String, Int)? in
            guard let raw = d.koiPeriod, raw.isFinite, raw > 0 else { return nil }
            let v = log10(raw)
            let idx = linearBinIndex(value: v, step: step)
            let label = linearBinLabel(index: idx, step: step)
            let disp = (d.koiDisposition as String?)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "N/A"
            return (label + "|\(disp.isEmpty ? "N/A" : disp)", 1)
        }
        let grouped = Dictionary(grouping: rows, by: { $0.0 })
        return grouped.map { (key, vals) in
            let parts = key.split(separator: "|", maxSplits: 1).map(String.init)
            let label = parts.first ?? "N/A"
            let disp  = parts.count > 1 ? parts[1] : "N/A"
            return PeriodLogBin(binLabel: label, count: vals.count, disposition: disp)
        }
        .sorted { ($0.binLabel, $0.disposition) < ($1.binLabel, $1.disposition) }
    }
    
    // MARK: - Loading state and chart recomputation
    
    // Actualiza el flag global de carga a partir de los flags específicos
    private func updateLoadingState() {
        isLoading = isLoadingFiles || isLoadingDataset || isLoadingPrecision
    }
    
    /// Recalcula en background los datos agregados para gráficas cuando cambia el dataset
    private func recomputeCharts() {
        let items = dataset ?? []
        
        Task(priority: .background) { [weak self, items] in
            guard let self else { return }
            
            // Usa las funciones puras basadas en `items` para calcular en background
            let steffPoints = self.datasetPointsSteffSrad(from: items)
            let duration    = self.durationAgg(from: items, stat: "media")
            let steff       = self.steffBins(from: items, step: 250)
            let slogg       = self.sloggBins(from: items, step: 0.2)
            let snr         = self.snrLogBins(from: items, edges: [0.1, 0.3, 1, 3, 10, 30, 100])
            let depth       = self.depthLogBins(from: items, step: 0.5)
            let period      = self.periodLogBins(from: items, step: 0.3)
            
            await MainActor.run {
                self.steffVsSradPoints = steffPoints
                self.durationAggData   = duration
                self.steffBinsData     = steff
                self.sloggBinsData     = slogg
                self.snrLogBinsData    = snr
                self.depthLogBinsData  = depth
                self.periodLogBinsData = period
            }
        }
    }
}

#if DEBUG
// MARK: - Inits de conveniencia para mocks
extension GeneralDataset {
    init(
        id: String,
        keplerName: String?,
        kepoiName: String,
        name: String,
        koiSteff: Double?,
        koiDisposition: String,
        koiDuration: Double?,
        koiSrad: Double?,
        koiSlogg: Double?,
        koiModelSnr: Double?,
        koiDepth: Double?,
        koiPeriod: Double?
    ) {
        self.id = id
        self.keplerName = keplerName
        self.kepoiName = kepoiName
        self.name = name
        self.koiSteff = koiSteff
        self.koiDisposition = koiDisposition
        self.koiDuration = koiDuration
        self.koiSrad = koiSrad
        self.koiSlogg = koiSlogg
        self.koiModelSnr = koiModelSnr
        self.koiDepth = koiDepth
        self.koiPeriod = koiPeriod
    }
}

extension FilesLoaded {
    static let mockList: [FilesLoaded] = [
        .init(name: "kepler_sample.csv"),
        .init(name: "koi_subset.csv"),
        .init(name: "training_set_v1.csv")
    ]
}

extension ModelPrecision {
    static let mock: ModelPrecision = {
        let confirmed = ClassStats(f1Score: 0.9871, precision: 1.0, recall: 0.9745, support: 549)
        let candidate = ClassStats(f1Score: 0.9812, precision: 0.9750, recall: 0.9875, support: 430)
        let falsePos  = ClassStats(f1Score: 0.9930, precision: 0.9900, recall: 0.9960, support: 510)
        let macro     = ClassStats(f1Score: 0.9871, precision: 0.9883, recall: 0.9860, support: 1489)
        let weighted  = ClassStats(f1Score: 0.9900, precision: 0.9910, recall: 0.9908, support: 1489)
        return ModelPrecision(
            accuracy: 0.9908,
            aggregates: ["accuracy": 0.9908],
            perClass: [
                "CONFIRMED": confirmed,
                "CANDIDATE": candidate,
                "FALSE POSITIVE": falsePos,
                "macro avg": macro,
                "weighted avg": weighted
            ]
        )
    }()
}

extension GeneralDataset {
    static let mockList: [GeneralDataset] = [
        .init(
            id: "1234567",
            keplerName: "Kepler-22 b",
            kepoiName: "K02200.01",
            name: "Kepler-22 b",
            koiSteff: 5600,
            koiDisposition: "CONFIRMED",
            koiDuration: 7.5,
            koiSrad: 0.98,
            koiSlogg: 4.35,
            koiModelSnr: 18.2,
            koiDepth: 0.00012,
            koiPeriod: 289.9
        ),
        .init(
            id: "7654321",
            keplerName: nil,
            kepoiName: "K04450.02",
            name: "K04450.02",
            koiSteff: 6100,
            koiDisposition: "CANDIDATE",
            koiDuration: 3.2,
            koiSrad: 1.15,
            koiSlogg: 4.20,
            koiModelSnr: 9.7,
            koiDepth: 0.00045,
            koiPeriod: 12.6
        ),
        .init(
            id: "2468101",
            keplerName: "Kepler-452 b",
            kepoiName: "K09000.01",
            name: "Kepler-452 b",
            koiSteff: 5750,
            koiDisposition: "CONFIRMED",
            koiDuration: 10.5,
            koiSrad: 1.00,
            koiSlogg: 4.40,
            koiModelSnr: 35.0,
            koiDepth: 0.00008,
            koiPeriod: 384.8
        ),
        .init(
            id: "1122334",
            keplerName: nil,
            kepoiName: "K01234.01",
            name: "K01234.01",
            koiSteff: 4900,
            koiDisposition: "FALSE POSITIVE",
            koiDuration: 2.1,
            koiSrad: 0.75,
            koiSlogg: 4.60,
            koiModelSnr: 2.8,
            koiDepth: 0.0035,
            koiPeriod: 3.9
        ),
        .init(
            id: "9988776",
            keplerName: nil,
            kepoiName: "K05555.03",
            name: "K05555.03",
            koiSteff: 5200,
            koiDisposition: "CANDIDATE",
            koiDuration: 5.0,
            koiSrad: 0.90,
            koiSlogg: 4.50,
            koiModelSnr: 14.0,
            koiDepth: 0.0009,
            koiPeriod: 27.2
        ),
        .init(
            id: "3344556",
            keplerName: nil,
            kepoiName: "K07777.01",
            name: "K07777.01",
            koiSteff: 6300,
            koiDisposition: "FALSE POSITIVE",
            koiDuration: 1.7,
            koiSrad: 1.30,
            koiSlogg: 4.15,
            koiModelSnr: 1.1,
            koiDepth: 0.0060,
            koiPeriod: 1.8
        )
    ]
}
#endif
