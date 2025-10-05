//
//  ContentBar.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

struct ContentBar: View {
    @ObservedObject var viewModel: HomeViewModel
    var body: some View {
        List {
            if let fileSelected = viewModel.fileSelected {
                
            } else {
                ContentUnavailableView("Aún sin datos", systemImage: "globe.americas.fill", description:
                        Text("Selecciona un archivo para mostrar los planetas")
                )
            }
        }
        .navigationTitle("Exoplanetas")
    }
}

#Preview {
    @Previewable @State var selection: UUID? = nil
    @Previewable @State var viewModel = HomeViewModel()
    NavigationSplitView {
        Sidebar(viewModel: viewModel, selection: $selection)
    } content: {
        ContentBar(viewModel: viewModel)
    } detail: {
        
    }
}
