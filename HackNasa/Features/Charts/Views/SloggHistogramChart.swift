//
//  SloggHistogramChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import SwiftUI
import Charts

/// 4) Histograma de log g por disposición con bins precomputados.
struct SloggHistogramChart: View {
    let bins: [SloggBin]

    var body: some View {
        Chart(bins) { b in
            BarMark(
                x: .value("Bin log g", b.binLabel),
                y: .value("Conteo", b.count)
            )
            .foregroundStyle(by: .value("Disposición", b.disposition))
        }
        .chartTitle("Distribución de log g estelar por disposición")
        .chartLegend(.visible)
        .chartXAxisLabel("koi_slogg (bins)")
        .chartYAxisLabel("Conteo")
    }
}
