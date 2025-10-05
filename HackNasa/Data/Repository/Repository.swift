//
//  Repository.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import Foundation

enum APIEndpoint {
    case generalData
    case planetKOI(id: String)
    case selectCSV(name: String)
    case uploadCSV(filename: String)
    case listCSVs
    case geminiExplainGeneral
    case geminiExplainSpecific(koiname: String)
    case updateHyperparams
    case generatePlanetImage
    case exoplanetImage(kepoiname: String)
    case modelPrecision
    
    private static let scheme = "http"
    private static let host   = "18.188.234.218"
    
    private var path: String {
        switch self {
        case .generalData:
            return "/GeneralData"
        case .planetKOI(let id):
            return "/planet/kepoi/\(id)"
        case .selectCSV(let name):
            return "/csvs/select/\(name).csv"
        case .uploadCSV:
            return "/upload_raw"
        case .listCSVs:
            return "/csvs"
        case .geminiExplainGeneral:
            return "/Gemini/ExplainGeneral"
        case .geminiExplainSpecific(let koiname):
            return "/Gemini/ExplainSpecific/\(koiname)"
        case .updateHyperparams:
            return "/config/hyperparams"
        case .generatePlanetImage:
            return "/GeneratePlanetImage"
        case .exoplanetImage(let kepoiname):
            let encoded = /*kepoiname.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ??*/ kepoiname
            return "/ExoplanetImage/\(encoded)"
        case .modelPrecision:
            return "/model_precision"
        }
    }
    
    private var defaultMethod: String {
        switch self {
        case .uploadCSV, .updateHyperparams, .selectCSV(_), .generatePlanetImage:
            return "POST"
        case .exoplanetImage(_), .modelPrecision:
            return "GET"
        default:
            return "GET"
        }
    }
    
    private var defaultHeaders: [String: String] {
        switch self {
        case .uploadCSV(let filename):
            return [
                "Content-Type": "application/octet-stream",
                "X-File-Name": filename
            ]
        case .updateHyperparams:
            return ["Content-Type": "application/json"]
        case .generatePlanetImage:
            return ["Content-Type": "application/json"]
        case .modelPrecision:
            return ["Accept": "application/json"]
        default:
            return [:]
        }
    }
    
    /// Construye la URL. Agrega query si la necesitas.
    func url(query: [String: String] = [:]) -> URL? {
        var comps = URLComponents()
        comps.scheme = Self.scheme
        comps.host   = Self.host
        comps.path   = path
        if !query.isEmpty {
            comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return comps.url
    }
    
    /// Crea un URLRequest usando valores por defecto del endpoint.
    /// Puedes enviar `extraHeaders` para sobreescribir/añadir a los headers por defecto.
    func request(body: Data? = nil,
                 query: [String: String] = [:],
                 extraHeaders: [String: String] = [:]) -> URLRequest? {
        guard let url = url(query: query) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = defaultMethod
        let headers = defaultHeaders.merging(extraHeaders) { _, new in new }
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        req.httpBody = body
        return req
    }
    
    /// Compatibilidad con API previa, por si ya se usa en el proyecto.
    func request(method: String = "GET",
                 headers: [String: String] = [:],
                 body: Data? = nil,
                 query: [String: String] = [:]) -> URLRequest? {
        guard let url = url(query: query) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = method
        let headers = self.defaultHeaders.merging(headers) { _, new in new }
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        req.httpBody = body
        return req
    }
}

struct Hyperparams: Codable {
    let numest: Int
    let mxdepth: Int
    let randstate: Int
}

extension APIEndpoint {
    /// Helper para crear cuerpo JSON desde cualquier Encodable.
    static func jsonBody<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }
}
