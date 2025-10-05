//
//  ChartsData.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import Foundation

// MARK: - Etiqueta de clase
public typealias Disposition = String  // ej. "CONFIRMED" | "CANDIDATE" | "FALSE POSITIVE"

// MARK: - Dispersión (x,y)
public struct ScatterPoint: Identifiable, Hashable {
    public let id = UUID()
    public let x: Double   // eje X
    public let y: Double   // eje Y
    public let disposition: Disposition
    public init(x: Double, y: Double, disposition: Disposition) {
        self.x = x; self.y = y; self.disposition = disposition
    }
}

// MARK: - Barras categóricas (p. ej. duración promedio por disposición)
public struct BarDatum: Identifiable, Hashable {
    public let id = UUID()
    public let x: String   // categoría, ej. koi_disposition
    public let y: Double   // valor agregado, ej. media de koi_duration
    public init(x: String, y: Double) {
        self.x = x; self.y = y
    }
}

// MARK: - Histograma por bins
public struct HistogramBin: Identifiable, Hashable {
    public let id = UUID()
    public let binStart: Double
    public let binEnd: Double
    public let count: Int
    public let disposition: Disposition
    public var xCenter: Double { (binStart + binEnd) / 2.0 } // útil para Charts
    public init(binStart: Double, binEnd: Double, count: Int, disposition: Disposition) {
        self.binStart = binStart; self.binEnd = binEnd
        self.count = count; self.disposition = disposition
    }
}

// MARK: - Estructuras específicas de tus gráficas

// 1) Histograma: Stellar Effective Temperature (koi_steff) por disposición
public typealias SteffBin = HistogramBin

// 2) Barras: koi_disposition vs koi_duration (usa agregado: media/mediana)
public typealias DurationByDisposition = BarDatum  // x = disposition, y = duración agregada

// 3) Dispersión: koi_steff vs koi_srad por disposición
public struct SteffVsSradPoint: Identifiable, Hashable {
    public let id = UUID()
    public let koi_steff: Double   // X
    public let koi_srad: Double    // Y
    public let disposition: Disposition
    public init(koi_steff: Double, koi_srad: Double, disposition: Disposition) {
        self.koi_steff = koi_steff; self.koi_srad = koi_srad; self.disposition = disposition
    }
}

// 4) Histograma: koi_slogg por disposición
public typealias SloggBin = HistogramBin

// 5) Histograma: koi_model_snr por disposición
public typealias ModelSNRBin = HistogramBin

// 6) Histograma (log): koi_depth por disposición
//     Para eje log, guarda ya transformado si lo prefieres:
public struct DepthLogBin: Identifiable, Hashable {
    public let id = UUID()
    public let logBinStart: Double
    public let logBinEnd: Double
    public let count: Int
    public let disposition: Disposition
    public var xCenter: Double { (logBinStart + logBinEnd) / 2.0 }
    public init(binStart: Double, binEnd: Double, count: Int, disposition: Disposition, base: Double = 10) {
        self.logBinStart = log(binStart, base: base)
        self.logBinEnd   = log(binEnd, base: base)
        self.count = count
        self.disposition = disposition
    }
}
private func log(_ v: Double, base: Double) -> Double { log(v) / log(base) }

// 7) Histograma (log): koi_period por disposición
public typealias PeriodLogBin = DepthLogBin
