//
//  DurationByDispositionChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import SwiftUI
import Charts

/// 2) Barras por disposición con valor agregado (media/mediana) de duración.
struct DurationByDispositionChart: View {
    let data: [DurationByDisposition]
    private var statLabel: String {
        data.first?.stat.capitalized ?? "Media"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Duración \(statLabel) por disposición KOI")
                .font(.headline)
                .foregroundStyle(.secondary)
            Chart(data) { row in
                BarMark(
                    x: .value("Disposición", row.disposition),
                    y: .value("Duración (\(row.stat))", row.value)
                )
                .annotation(position: .top) {
                    Text(row.value.formatted(.number.precision(.fractionLength(2))))
                        .font(.caption2)
                }
            }
            .chartLegend(.hidden)
            .chartXAxisLabel("koi_disposition")
            .chartYAxisLabel("koi_duration (\(data.first?.stat ?? "media"))")
        }
    }
}
