//
//  Sidebar.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

enum Panel: Hashable {
    case dataset(Dataset.ID)
}

struct Sidebar: View {
    @ObservedObject var homeViewModel: HomeViewModel
    var body: some View {
        List {
            ForEach(homeViewModel.folders, id: \.id) { folder in
                Section(folder.name) {
                    ForEach(folder.Datasets, id: \.id) { dataset in
                        
                    }
                }
            }
        }
        .navigationTitle("Datos")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationSplitView {
        Sidebar(homeViewModel: HomeViewModel())
    } detail: {
        
    }
}
