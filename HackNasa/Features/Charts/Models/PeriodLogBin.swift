//
//  PeriodLogBin.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import Foundation

struct PeriodLogBin: Identifiable, Hashable {
    let id = UUID()
    let binLabel: String        // bins en log10(period), "0.0–0.3", "0.3–0.6", ...
    let count: Int
    let disposition: String
}
