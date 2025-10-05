//
//  HomeViewModel.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var files: [FilesLoaded] = []
    @Published var fileSelected: FilesLoaded.ID? = nil
    @Published var dataset: GeneralDataset? = nil
    
    init() {
        
        Task {
            await fetchFiles()
        }
    }
    
    func fetchDataset() async {
        let json = """
            [
              {
                "kepid": 1234567
                "kepler_name": "Kepler-22 b",
                "kepoi_name": "K02200.01",
                "name": "Kepler-22 b",
                "koi_steff": 5778,
                "koi_disposition": "CANDIDATE",
                "koi_duration": 3.7,
                "koi_srad": 1.02,
                "koi_slogg": 4.44,
                "koi_model_snr": 12.3,
                "koi_depth": 850.0,
                "koi_period": 12.345
              },
              {
                "kepid": 09876543
                "kepler_name": null,
                "kepoi_name": "KOI-351.01",
                "name": "KOI-351.01",
                "koi_steff": 6100,
                "koi_disposition": "CONFIRMED",
                "koi_duration": 5.1,
                "koi_srad": 1.3,
                "koi_slogg": 4.2,
                "koi_model_snr": 18.9,
                "koi_depth": 520.0,
                "koi_period": 331.6
              }
            ]
            """
        guard let data = json.data(using: .utf8) else { return }

        do {
            let decoder = JSONDecoder()
            let datasets = try decoder.decode([GeneralDataset].self, from: data)
            dataset = datasets.first
            print("Dataset cargado correctamente: \(datasets.count) registros")
        } catch {
            print("Error al decodificar JSON:", error)
        }
        
    }
    
    func fetchFiles() async {
        files = [
            .init(name: "hola.csv"),
            .init(name: "1.csv"),
            .init(name: "2.csv"),
            .init(name: "3.csv"),
        ]
        automaticSelection()
    }
    private func automaticSelection() {
        let firstFile = files.first?.id
        fileSelected = firstFile
    }
}
