//
//  SteffVsSradPoint.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import Foundation

struct SteffVsSradPoint: Identifiable, Hashable {
    let id = UUID()
    let steff: Double           // koi_steff
    let srad: Double            // koi_srad
    let disposition: String     // koi_disposition
}
