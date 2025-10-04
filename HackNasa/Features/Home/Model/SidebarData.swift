//
//  SidebarData.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import Foundation

struct Dataset: Identifiable {
    let id = UUID()
    
    let title: String
    let data: Data
    let creationDate: Date = .now
    
    let hiperparameters: hiperparameters
}

struct hiperparameters {
    var numberOfLayers: Int
    var maxDepth: Int
    var randomState: Int
}
