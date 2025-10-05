//
//  ModelSNRHistogramChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//


import SwiftUI
import Charts

// MARK: - 5) Histograma log10: koi_model_snr por disposición
struct ModelSNRHistogramChart: View {
    let bins: [ModelSNRBin]
    var body: some View {
        Chart(bins) { bin in
            RectangleMark(
                xStart: .value("Inicio bin", bin.binStart),
                xEnd:   .value("Fin bin", bin.binEnd),
                y:      .value("Conteo", bin.count)
            )
            .foregroundStyle(by: .value("Disposición", bin.disposition))
        }
        .chartXScale(type: .log)
        .chartXAxisLabel("Model SNR (log)")
        .chartYAxisLabel("Conteo")
    }
}
