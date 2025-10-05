//
//  HomeViewModel.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var folders: [Folder] = []
    @Published var models: [ModelInfo] = []
    
    init() {
        Task {
            await getModels()
        }
    }
    
    func firstSelection() -> Panel {
        let folder = folders.first
        let dataset = folder?.Datasets.first
        
        guard let dataset = dataset, let folder = folder else { return .emptyState }
        
        return .dataset(dataset.id, folder.id)
    }
    
    func getModels() async {
        //TODO: Logica de obtener modelos
        
        let models: [ModelInfo] = [
            ModelInfo(id: UUID(), name: "RandomForest_v1"),
            ModelInfo(id: UUID(), name: "SVM_linear"),
            ModelInfo(id: UUID(), name: "XGBoost_2025-10-01")
        ]
        for model in models {
            self.models.append(model)
        }
    }

}
