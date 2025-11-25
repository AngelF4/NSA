//
//  WidgetsBundle.swift
//  Widgets
//
//  Created by Angel Hernández Gámez on 06/10/25.
//

import WidgetKit
import SwiftUI

@main
struct WidgetsBundle: WidgetBundle {
    var body: some Widget {
        Widgets()
        WidgetsControl()
        WidgetsLiveActivity()
    }
}
