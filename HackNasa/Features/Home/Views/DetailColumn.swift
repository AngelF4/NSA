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
    
    @State private var models: [ModelInfo] = [
        .init(id: UUID(), name: "RandomForest_v1"),
        .init(id: UUID(), name: "SVM_linear"),
        .init(id: UUID(), name: "XGBoost_2025-10-01")
    ]
    @State private var selectedModelID: ModelInfo.ID? = nil

    private var selectedModelName: String {
        models.first(where: { $0.id == selectedModelID })?.name ?? "Modelo"
    }
    
    var body: some View {
        Group {
            switch selection ?? .emptyState {
            case .emptyState:
                Text("Hola parece que aún no selecciónas un dataset.")
            case .dataset(let datasetID, let folderID):
                Bento()
                    .navigationTitle(viewModel.folders.first(where: { $0.id == folderID })!.Datasets.first(where: { $0.id == datasetID })!.title.capitalized)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(models) { model in
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
