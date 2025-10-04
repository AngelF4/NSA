//
//  Folder.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import Foundation

struct Folder: Identifiable {
    let id = UUID()
    
    let name: String
    
    var Datasets: [Dataset] = []
}
