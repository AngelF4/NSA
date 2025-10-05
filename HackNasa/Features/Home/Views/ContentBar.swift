//
//  ContentBar.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

enum Route: Hashable {
    case general
    case detail(id: String)
}

struct ContentBar: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var geminiVM: GeminiViewModel
    
    var body: some View {
        List {
            if viewModel.fileSelected != nil {
                    Section {
                        NavigationLink(value: Route.general) {
                            Label("General", systemImage: "star")
                        }
                    }
                    Section("Exoplanetas") {
                        if viewModel.isLoading {
                            ProgressView()
                        } else if let datasets = viewModel.dataset {
                            ForEach(datasets, id: \.id) { item in
                                NavigationLink(value: Route.detail(id: item.id)) {
                                    Label(item.name, systemImage: "globe.americas.fill")
                                }
                            }
                        } else {
                            Text("Sin registros")
                        }
                    }
                    
            } else {
                ContentUnavailableView("Aún sin datos", systemImage: "globe.americas.fill", description:
                        Text("Selecciona un archivo para mostrar los planetas")
                )
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Exoplanetas")
        .refreshable {
            await viewModel.selectCSV()
        }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .general:
//                GeneralView() // tu vista de resumen
                GeneralDetail(viewModel: viewModel, geminiVM: geminiVM, position: .constant(nil))
            case .detail(let id):
                if let item = viewModel.dataset?.first(where: { $0.id == id }) {
                     // tu vista de detalle
                    DetailColumn()
                } else if viewModel.isLoading {
                    ProgressView()
                } else {
                    ContentUnavailableView("No encontrado", systemImage: "magnifyingglass")
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selection: UUID? = nil
    @Previewable @State var viewModel = HomeViewModel()
    NavigationSplitView {
        Sidebar(viewModel: viewModel)
    } content: {
        ContentBar(viewModel: viewModel, geminiVM: GeminiViewModel())
    } detail: {
        Text("Detalle")
            .foregroundStyle(.secondary)
    }
}
