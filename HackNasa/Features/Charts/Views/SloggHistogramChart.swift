//
//  SloggHistogramChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//


import SwiftUI
import Charts

// MARK: - 4) Histograma lineal: koi_slogg por disposición
struct SloggHistogramChart: View {
    let bins: [SloggBin]
    var body: some View {
        Chart(bins) { bin in
            RectangleMark(
                xStart: .value("Inicio bin", bin.binStart),
                xEnd:   .value("Fin bin", bin.binEnd),
                y:      .value("Conteo", bin.count)
            )
            .foregroundStyle(by: .value("Disposición", bin.disposition))
        }
        .chartXAxisLabel("log g (cm/s²)")
        .chartYAxisLabel("Conteo")
    }
}
