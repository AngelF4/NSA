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
    @Published var dataset: [GeneralDataset]? = nil
    @Published var isLoading: Bool = false
    @Published var presicion: ModelPrecision? = nil
    
    init() {
        Task {
            await fetchFiles()
            await getModelPresicion()
        }
    }
    
    func getModelPresicion() async {
        isLoading = true
        defer { isLoading = false }
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
        isLoading = true
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
        isLoading = true
        cleanData()
        guard let url = APIEndpoint.generalData.url() else {
            print("URL inválida")
            isLoading = false
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
        isLoading = false
    }
    
    func fetchFiles() async {
        guard let req = APIEndpoint.listCSVs.request() else { return }
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
}
