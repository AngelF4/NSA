//
//  GeminiViewModel.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import Foundation
import Combine

class GeminiViewModel: ObservableObject {
    @Published var response: String? = nil
    @Published var isLoading: Bool = false
    
    func askGeneral() async {
        isLoading = true
        guard let req = APIEndpoint.geminiExplainGeneral.request() else {
            isLoading = false
            await MainActor.run { self.response = "No se pudo crear la petición." }
            return
        }
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
                isLoading = false
                await MainActor.run { self.response = "Error HTTP \(code) al consultar Gemini General." }
                return
            }
            let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
            await MainActor.run { self.response = decoded.explanation }
            isLoading = false
        } catch let DecodingError.dataCorrupted(ctx) {
            isLoading = false
            await MainActor.run { self.response = "JSON corrupto: \(ctx.debugDescription)" }
        } catch let DecodingError.keyNotFound(key, ctx) {
            isLoading = false
            await MainActor.run { self.response = "Falta clave \(key.stringValue): \(ctx.debugDescription)" }
        } catch let DecodingError.typeMismatch(type, ctx) {
            isLoading = false
            await MainActor.run { self.response = "Tipo no coincide \(type): \(ctx.debugDescription)" }
        } catch let DecodingError.valueNotFound(type, ctx) {
            isLoading = false
            await MainActor.run { self.response = "Valor no encontrado \(type): \(ctx.debugDescription)" }
        } catch {
            isLoading = false
            await MainActor.run { self.response = "Error de red: \(error.localizedDescription)" }
        }
    }
    
    func askSpecific(koiname: String) async {
        isLoading = true
        guard let req = APIEndpoint.geminiExplainSpecific(koiname: koiname).request() else {
            isLoading = false
            await MainActor.run { self.response = "No se pudo crear la petición." }
            return
        }
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
                await MainActor.run { self.response = "Error HTTP \(code) al consultar Gemini Specific." }
                return
            }
            let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
            await MainActor.run { self.response = decoded.explanation }
            isLoading = false
        } catch {
            isLoading = false
            await MainActor.run { self.response = "Error: \(error.localizedDescription)" }
        }
    }
}

struct GeminiResponse: Decodable {
    let explanation: String
}
