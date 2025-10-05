//
//  GeminiViewModel.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//

import Foundation
import Combine
import UIKit

class GeminiViewModel: ObservableObject {
    @Published var response: String? = nil
    @Published var isLoading: Bool = false
    @Published var isLoadingImage: Bool = false
    @Published var image: UIImage? = nil
    
    func getImage(kepoiname: String) async {
        isLoadingImage = true
        defer { isLoadingImage = false }
        await MainActor.run { self.response = nil }
        
        // Función para descargar imagen
        func downloadImage() async throws -> UIImage {
            guard let imgReq = APIEndpoint.exoplanetImage(kepoiname: kepoiname).request() else {
                await MainActor.run { self.response = "No se pudo crear la petición de descarga de imagen." }
                throw URLError(.badURL)
            }
            let (data, resp) = try await URLSession.shared.data(for: imgReq)
            guard let http = resp as? HTTPURLResponse else {
                await MainActor.run { self.response = "Respuesta no HTTP." }
                throw URLError(.badServerResponse)
            }
            if http.statusCode == 404 {
                throw URLError(.fileDoesNotExist)
            }
            guard (200..<300).contains(http.statusCode) else {
                await MainActor.run { self.response = "HTTP \(http.statusCode) al obtener imagen." }
                throw URLError(.badServerResponse)
            }
            if let mime = http.value(forHTTPHeaderField: "Content-Type"), !mime.starts(with: "image/") {
                await MainActor.run { self.response = "Tipo de contenido no soportado: \(mime)" }
                throw URLError(.cannotDecodeContentData)
            }
            guard let uiimg = UIImage(data: data) else {
                await MainActor.run { self.response = "No se pudo decodificar la imagen." }
                throw URLError(.cannotDecodeContentData)
            }
            return uiimg
        }
        
        // Función para generar imagen
        func generateImage() async throws {
            struct GeneratePlanetImagePayload: Encodable { let kepoi_name: String }
            let payload = GeneratePlanetImagePayload(kepoi_name: kepoiname)
            guard let genReq = APIEndpoint.generatePlanetImage.request(body: APIEndpoint.jsonBody(payload)) else {
                await MainActor.run { self.response = "No se pudo crear la petición de generación de imagen." }
                throw URLError(.badURL)
            }
            let (genData, genResp) = try await URLSession.shared.data(for: genReq)
            guard let genHTTP = genResp as? HTTPURLResponse, (200..<300).contains(genHTTP.statusCode) else {
                let code = (genResp as? HTTPURLResponse)?.statusCode ?? -1
                await MainActor.run { self.response = "Error HTTP \(code) al generar la imagen." }
                throw URLError(.badServerResponse)
            }
            // No se usa la respuesta, solo se genera la imagen en backend
        }
        
        do {
            // Intentar descargar imagen primero
            let img = try await downloadImage()
            await MainActor.run { self.image = img }
        } catch {
            if let urlError = error as? URLError, urlError.code == .fileDoesNotExist {
                // Si 404, generar imagen y reintentar descargar
                do {
                    try await generateImage()
                    let img = try await downloadImage()
                    await MainActor.run { self.image = img }
                } catch let DecodingError.dataCorrupted(ctx) {
                    await MainActor.run { self.response = "JSON corrupto en generación: \(ctx.debugDescription)" }
                } catch let DecodingError.keyNotFound(key, ctx) {
                    await MainActor.run { self.response = "Falta clave \(key.stringValue) en generación: \(ctx.debugDescription)" }
                } catch let DecodingError.typeMismatch(type, ctx) {
                    await MainActor.run { self.response = "Tipo no coincide \(type) en generación: \(ctx.debugDescription)" }
                } catch let DecodingError.valueNotFound(type, ctx) {
                    await MainActor.run { self.response = "Valor no encontrado \(type) en generación: \(ctx.debugDescription)" }
                } catch {
                    await MainActor.run { self.response = "Error de red: \(error.localizedDescription)" }
                }
            } else if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let ctx):
                    await MainActor.run { self.response = "JSON corrupto en generación: \(ctx.debugDescription)" }
                case .keyNotFound(let key, let ctx):
                    await MainActor.run { self.response = "Falta clave \(key.stringValue) en generación: \(ctx.debugDescription)" }
                case .typeMismatch(let type, let ctx):
                    await MainActor.run { self.response = "Tipo no coincide \(type) en generación: \(ctx.debugDescription)" }
                case .valueNotFound(let type, let ctx):
                    await MainActor.run { self.response = "Valor no encontrado \(type) en generación: \(ctx.debugDescription)" }
                @unknown default:
                    await MainActor.run { self.response = "Error desconocido de decodificación." }
                }
            } else {
                await MainActor.run { self.response = "Error de red: \(error.localizedDescription)" }
            }
        }
    }
    
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
    
    func clearData() {
        response = nil
        isLoading = false
        isLoadingImage = false
        image = nil
    }
}

struct GeminiResponse: Decodable {
    let explanation: String
}

struct GenerateImageResponse: Decodable {
    let path: String
    
    private enum CodingKeys: String, CodingKey { case path, image_path, url, imageURL }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let p = try c.decodeIfPresent(String.self, forKey: .path) { self.path = p; return }
        if let p = try c.decodeIfPresent(String.self, forKey: .image_path) { self.path = p; return }
        if let p = try c.decodeIfPresent(String.self, forKey: .url) { self.path = p; return }
        if let p = try c.decodeIfPresent(String.self, forKey: .imageURL) { self.path = p; return }
        throw DecodingError.keyNotFound(CodingKeys.path, .init(codingPath: c.codingPath, debugDescription: "No se encontró 'path' en la respuesta"))
    }
}
