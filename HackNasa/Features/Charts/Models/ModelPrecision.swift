//
//  ModelPrecision.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 05/10/25.
//


import Foundation

struct ModelPrecision: Decodable {
    let accuracy: Double
    let aggregates: [String: Double]
    let perClass: [String: ClassStats]

    enum CodingKeys: String, CodingKey {
        case accuracy
        case aggregates
        case perClass = "per_class"
    }

    struct ClassStats: Decodable {
        let f1Score: Double
        let precision: Double
        let recall: Double
        let support: Int

        enum CodingKeys: String, CodingKey {
            case f1Score = "f1-score"
            case precision
            case recall
            case support
        }
    }

    // Accesos convenientes
    var confirmed: ClassStats? { perClass["CONFIRMED"] }
    var falsePositive: ClassStats? { perClass["FALSE POSITIVE"] }
    var macroAvg: ClassStats? { perClass["macro avg"] }
    var weightedAvg: ClassStats? { perClass["weighted avg"] }
}