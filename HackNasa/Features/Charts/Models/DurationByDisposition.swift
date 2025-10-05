//
//  DurationByDisposition.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import Foundation

struct DurationByDisposition: Identifiable, Hashable {
    let id = UUID()
    let disposition: String     // koi_disposition
    let value: Double           // agregado (media/mediana) de koi_duration
    let stat: String            // "media" o "mediana"
}
