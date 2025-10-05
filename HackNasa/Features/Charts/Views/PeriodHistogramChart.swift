//
//  PeriodHistogramChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import SwiftUI
import Charts

/// 7) Histograma de periodo orbital con bins en log10.
struct PeriodHistogramChart: View {
    let bins: [PeriodLogBin]

    var body: some View {
        Chart(bins) { b in
            BarMark(
                x: .value("Bin log10(period)", b.binLabel),
                y: .value("Conteo", b.count)
            )
            .foregroundStyle(by: .value("Disposición", b.disposition))
        }
        .chartTitle("Distribución logarítmica del período orbital por disposición")
        .chartLegend(.visible)
        .chartXAxisLabel("koi_period (log10 bins)")
        .chartYAxisLabel("Conteo")
    }
}
