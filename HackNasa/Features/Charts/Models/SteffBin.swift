//
//  SteffBin.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import Foundation

struct SteffBin: Identifiable, Hashable {
    let id = UUID()
    let binLabel: String        // "binStart–binEnd" en K
    let count: Int
    let disposition: String
}
