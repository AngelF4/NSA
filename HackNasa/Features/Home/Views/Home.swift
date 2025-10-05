//
//  Home.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

struct Home: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var geminiVM = GeminiViewModel()
    
    var body: some View {
        NavigationSplitView {
            Sidebar(viewModel: viewModel)
        } content: {
            ContentBar(viewModel: viewModel, geminiVM: geminiVM)
        } detail: {
            ProgressView("Cargando...")
        }
    }
}

#Preview {
    Home()
}
