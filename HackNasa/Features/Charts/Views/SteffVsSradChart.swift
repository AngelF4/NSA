//
//  SteffVsSradChart.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//


import SwiftUI
import Charts

// MARK: - 1) Dispersión: koi_steff vs koi_srad por disposición
struct SteffVsSradChart: View {
    let points: [SteffVsSradPoint]
    var body: some View {
        Chart(points) { p in
            PointMark(
                x: .value("Teff (K)", p.koi_steff),
                y: .value("Radio estelar (R☉)", p.koi_srad)
            )
            .foregroundStyle(by: .value("Disposición", p.disposition))
            .opacity(0.6)
        }
        .chartLegend(position: .bottom)
    }
}