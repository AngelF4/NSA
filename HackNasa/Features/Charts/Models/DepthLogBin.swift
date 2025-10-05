//
//  DepthLogBin.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import Foundation

struct DepthLogBin: Identifiable, Hashable {
    let id = UUID()
    let binLabel: String        // bins en log10(depth), ya formateados "−5.0–−4.5"
    let count: Int
    let disposition: String
}
