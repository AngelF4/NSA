//
//  DepthHistogramChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import SwiftUI
import Charts

/// 6) Histograma de profundidad con bins ya en log10.
struct DepthHistogramChart: View {
    let bins: [DepthLogBin]

    var body: some View {
        Chart(bins) { b in
            BarMark(
                x: .value("Bin log10(depth)", b.binLabel),
                y: .value("Conteo", b.count)
            )
            .foregroundStyle(by: .value("Disposición", b.disposition))
        }
        .chartTitle("Distribución logarítmica de profundidad por disposición")
        .chartLegend(.visible)
        .chartXAxisLabel("koi_depth (log10 bins)")
        .chartYAxisLabel("Conteo")
    }
}
