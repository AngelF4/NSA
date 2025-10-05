//
//  ModelSNRBin.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import Foundation

struct ModelSNRBin: Identifiable, Hashable {
    let id = UUID()
    let binLabel: String        // bins log (p. ej. "0.1–0.3", "0.3–1", "1–3", ...)
    let count: Int
    let disposition: String
}
