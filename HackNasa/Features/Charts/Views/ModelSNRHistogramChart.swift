//
//  ModelSNRHistogramChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import SwiftUI
import Charts

/// 5) Histograma de SNR con bins log en X (precomputados). El eje usa categorías de texto.
struct ModelSNRHistogramChart: View {
    let bins: [ModelSNRBin]

    var body: some View {
        Chart(bins) { b in
            BarMark(
                x: .value("Bin SNR (log)", b.binLabel),
                y: .value("Conteo", b.count)
            )
            .foregroundStyle(by: .value("Disposición", b.disposition))
        }
        .chartTitle("Distribución logarítmica de SNR del modelo por disposición")
        .chartLegend(.visible)
        .chartXAxisLabel("koi_model_snr (bins log)")
        .chartYAxisLabel("Conteo")
    }
}
