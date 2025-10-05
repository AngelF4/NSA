//
//  PeriodHistogramChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//


import SwiftUI
import Charts

// MARK: - 7) Histograma log10: koi_period por disposición
struct PeriodHistogramChart: View {
    let bins: [PeriodLogBin]
    var body: some View {
        Chart(bins) { bin in
            RectangleMark(
                xStart: .value("log10 Inicio", bin.logBinStart),
                xEnd:   .value("log10 Fin", bin.logBinEnd),
                y:      .value("Conteo", bin.count)
            )
            .foregroundStyle(by: .value("Disposición", bin.disposition))
        }
        .chartXAxisLabel("log10(Periodo días)")
        .chartYAxisLabel("Conteo")
    }
}
