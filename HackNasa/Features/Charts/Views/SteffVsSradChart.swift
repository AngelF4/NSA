//
//  SteffVsSradChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI
import Charts

// MARK: - Charts

/// 1) Dispersión Teff vs Srad, color por disposición.
struct SteffVsSradChart: View {
    let points: [SteffVsSradPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Relación entre temperatura efectiva y radio estelar")
                .font(.headline)
                .foregroundStyle(.secondary)
            Chart(points) { p in
                PointMark(
                    x: .value("Teff (K)", p.steff),
                    y: .value("Radio estelar (R☉)", p.srad)
                )
                .foregroundStyle(by: .value("Disposición", p.disposition))
                .symbol(by: .value("Disposición", p.disposition))
            }
            .chartLegend(.visible)
            .chartXAxisLabel("koi_steff")
            .chartYAxisLabel("koi_srad")
        }
    }
}

// MARK: - Previews (datos simulados para ver estructura)

#Preview("Steff vs Srad") {
    let mock = [
        SteffVsSradPoint(steff: 5200, srad: 0.9, disposition: "CONFIRMED"),
        SteffVsSradPoint(steff: 6100, srad: 1.2, disposition: "CANDIDATE"),
        SteffVsSradPoint(steff: 4800, srad: 0.8, disposition: "FALSE POSITIVE"),
    ]
    SteffVsSradChart(points: mock).padding()
}

#Preview("Duración por disposición") {
    let mock = [
        DurationByDisposition(disposition: "CONFIRMED", value: 5.4, stat: "media"),
        DurationByDisposition(disposition: "CANDIDATE", value: 4.8, stat: "media"),
        DurationByDisposition(disposition: "FALSE POSITIVE", value: 6.1, stat: "media"),
    ]
    DurationByDispositionChart(data: mock).padding()
}

#Preview("Hist Teff") {
    let mock = [
        SteffBin(binLabel: "4000–4250", count: 8, disposition: "CONFIRMED"),
        SteffBin(binLabel: "4000–4250", count: 3, disposition: "CANDIDATE"),
        SteffBin(binLabel: "4250–4500", count: 12, disposition: "CONFIRMED"),
    ]
    SteffHistogramChart(bins: mock).padding()
}

#Preview("Hist log g") {
    let mock = [
        SloggBin(binLabel: "4.0–4.2", count: 10, disposition: "CONFIRMED"),
        SloggBin(binLabel: "4.0–4.2", count: 6, disposition: "CANDIDATE"),
    ]
    SloggHistogramChart(bins: mock).padding()
}

#Preview("Hist SNR (log)") {
    let mock = [
        ModelSNRBin(binLabel: "0.1–0.3", count: 5, disposition: "CONFIRMED"),
        ModelSNRBin(binLabel: "0.3–1", count: 9, disposition: "CANDIDATE"),
        ModelSNRBin(binLabel: "1–3", count: 4, disposition: "FALSE POSITIVE"),
    ]
    ModelSNRHistogramChart(bins: mock).padding()
}

#Preview("Hist Depth log") {
    let mock = [
        DepthLogBin(binLabel: "−5.0–−4.5", count: 7, disposition: "CONFIRMED"),
        DepthLogBin(binLabel: "−5.0–−4.5", count: 2, disposition: "CANDIDATE"),
    ]
    DepthHistogramChart(bins: mock).padding()
}

#Preview("Hist Period log") {
    let mock = [
        PeriodLogBin(binLabel: "0.0–0.3", count: 6, disposition: "CONFIRMED"),
        PeriodLogBin(binLabel: "0.3–0.6", count: 3, disposition: "CANDIDATE"),
    ]
    PeriodHistogramChart(bins: mock).padding()
}
