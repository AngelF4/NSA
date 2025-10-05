//
//  SteffHistogramChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import SwiftUI
import Charts

/// 3) Histograma de Teff por disposición con bins precomputados.
struct SteffHistogramChart: View {
    let bins: [SteffBin]

    var body: some View {
        Chart(bins) { b in
            BarMark(
                x: .value("Bin Teff (K)", b.binLabel),
                y: .value("Conteo", b.count)
            )
            .foregroundStyle(by: .value("Disposición", b.disposition))
        }
        .chartLegend(.visible)
        .chartXAxisLabel("koi_steff (bins)")
        .chartYAxisLabel("Conteo")
    }
}
