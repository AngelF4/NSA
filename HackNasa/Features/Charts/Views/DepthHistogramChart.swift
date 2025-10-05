//
//  DepthHistogramChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//


import SwiftUI
import Charts

// MARK: - 6) Histograma log10: koi_depth por disposición
struct DepthHistogramChart: View {
    let bins: [DepthLogBin] // ya guardan x en log10 si usaste DepthLogBin
    var body: some View {
        Chart(bins) { bin in
            RectangleMark(
                xStart: .value("log10 Inicio", bin.logBinStart),
                xEnd:   .value("log10 Fin", bin.logBinEnd),
                y:      .value("Conteo", bin.count)
            )
            .foregroundStyle(by: .value("Disposición", bin.disposition))
        }
        .chartXAxisLabel("log10(Depth ppm)")
        .chartYAxisLabel("Conteo")
    }
}
