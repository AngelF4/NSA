//
//  DurationByDispositionChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI
import Charts

// MARK: - 2) Barras: duración agregada por disposición
struct DurationByDispositionChart: View {
    let bars: [DurationByDisposition]   // x = disposición, y = duración (media/mediana)
    var body: some View {
        Chart(bars) { b in
            BarMark(
                x: .value("Disposición", b.x),
                y: .value("Duración (hrs)", b.y)
            )
        }
        .chartYAxisLabel("Duración (hrs)")
        .chartXAxisLabel("Disposición")
    }
}
