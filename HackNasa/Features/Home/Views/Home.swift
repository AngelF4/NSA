//
//  Home.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

struct Home: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationSplitView {
            Text("SideBar")
        } content: {
            Text("Content")
        } detail: {
            Text("detail")
        }
    }
}

#Preview {
    Home()
}
