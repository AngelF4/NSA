//
//  SteffHistogramChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//


import SwiftUI
import Charts

// MARK: - 3) Histograma lineal: koi_steff por disposición
struct SteffHistogramChart: View {
    let bins: [SteffBin]  // usa HistogramBin
    var body: some View {
        Chart(bins) { bin in
            RectangleMark(
                xStart: .value("Inicio bin", bin.binStart),
                xEnd:   .value("Fin bin", bin.binEnd),
                y:      .value("Conteo", bin.count)
            )
            .foregroundStyle(by: .value("Disposición", bin.disposition))
        }
        .chartLegend(position: .bottom)
        .chartXAxisLabel("Teff (K)")
        .chartYAxisLabel("Conteo")
    }
}
