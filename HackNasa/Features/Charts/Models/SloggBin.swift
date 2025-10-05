//
//  SloggBin.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import Foundation

struct SloggBin: Identifiable, Hashable {
    let id = UUID()
    let binLabel: String        // "binStart–binEnd" en log g
    let count: Int
    let disposition: String
}
