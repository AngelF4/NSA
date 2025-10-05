//
//  DetailColumn.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//


import SwiftUI

struct ModelInfo: Identifiable, Hashable {
    let id: UUID
    let name: String
}

struct DetailColumn: View {
    @Binding var selection: Panel?
    @ObservedObject var viewModel: HomeViewModel

    @State private var selectedModelID: ModelInfo.ID? = nil

    private var selectedModelName: String {
        viewModel.models.first(where: { $0.id == selectedModelID })?.name ?? "Modelo"
    }
    
    var body: some View {
        Group {
            switch selection ?? .emptyState {
            case .emptyState:
                Text("Hola parece que aún no selecciónas un dataset.")
            case .dataset(let datasetID, let folderID):
                Bento(dataset: Dataset(title: "", data: Data()))
                    .navigationTitle(viewModel.folders.first(where: { $0.id == folderID })!.Datasets.first(where: { $0.id == datasetID })!.title.capitalized)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(viewModel.models) { model in
                        Button {
                            selectedModelID = model.id
                        } label: {
                            HStack {
                                Text(model.name)
                                Spacer()
                                if model.id == selectedModelID {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    Divider()
                    Button("Administrar modelos…") {
                        // Navegar a gestión de modelos si aplica
                    }
                } label: {
                    HStack {
                        Text(selectedModelName)
                        Image(systemName: "sparkles")
                    }
                }
            }
            ToolbarSpacer()
            ToolbarItem(placement: .primaryAction) {
                Button("Nuevo dataset", systemImage: "plus") {
                    
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selection: Panel? = nil
    @Previewable @State var viewModel = HomeViewModel()
    
    let datasets: [Dataset] = [
        .init(title: "hola.csv", data: Data()),
        .init(title: "adios.csv", data: Data()),
        .init(title: "mundo.csv", data: Data()),
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
