//
//  Sidebar.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

enum Panel: Hashable {
    case emptyState
    case dataset(Dataset.ID, Folder.ID)
}

struct Sidebar: View {
    @Binding var selection: Panel?
    @ObservedObject var homeViewModel: HomeViewModel
    @State private var searchText: String = ""
    var body: some View {
        List {
            ForEach(homeViewModel.folders.indices, id: \.self) { i in
                Section(isExpanded: $homeViewModel.folders[i].isExpanded) {
                    ForEach(homeViewModel.folders[i].Datasets, id: \.id) { dataset in
                        let isSelected = selection == .dataset(dataset.id, homeViewModel.folders[i].id)
                        
                        Button {
                            selection = .dataset(dataset.id, homeViewModel.folders[i].id)
                        } label: {
                            HStack {
                                Label(dataset.title, systemImage: "text.document")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .imageScale(.small)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .listRowInsets(.init(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                    }
                } header: {
                    Label(homeViewModel.folders[i].name, systemImage: "folder")
                }
            }
        }
        .navigationTitle("Datos")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText)
    }
}

#Preview {
    @Previewable @State var selection: Panel? = nil
    @Previewable @State var viewModel = HomeViewModel()
    
    let datasets: [Dataset] = [
        .init(title: "hola.csv", data: Data(), hiperparameters: hiperparameters(numberOfLayers: 5, maxDepth: 5, randomState: 5)),
        .init(title: "adios.csv", data: Data(), hiperparameters: hiperparameters(numberOfLayers: 5, maxDepth: 5, randomState: 5)),
        .init(title: "mundo.csv", data: Data(), hiperparameters: hiperparameters(numberOfLayers: 5, maxDepth: 5, randomState: 5)),
    ]
    NavigationSplitView {
        Sidebar(selection: $selection, homeViewModel: viewModel)
    } detail: {
        DetailColumn(selection: $selection, viewModel: viewModel)
    }
    .onAppear {
        viewModel.folders = [
            .init(name: "Proyecto 1", Datasets: datasets),
            .init(name: "Proyecto 2", Datasets: datasets),
            .init(name: "Proyecto 3", Datasets: datasets),
            .init(name: "Proyecto 4", Datasets: datasets),
            .init(name: "Proyecto 5", Datasets: datasets)
        ]
    }
}

