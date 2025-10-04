//
//  Theme.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

enum ColorRole {
    case accent, accentOn, surface, surfaceOn, danger
}
struct Palette {
    let accent: Color
    let accentOn: Color
    let surface: Color
    let surfaceOn: Color
    let danger: Color
}

// Foundations/Theme.swift
struct Theme {
    let palette: Palette
    static let `default` = Theme(palette: .init(
        accent: .accentColor,
        accentOn: .white,
        surface: .black.opacity(0.1),
        surfaceOn: .primary,
        danger: .red
    ))
}
