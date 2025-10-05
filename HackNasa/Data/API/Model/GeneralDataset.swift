//
//  GeneralDataset.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import Foundation

struct GeneralDataset: Identifiable, Codable {
    var id: String //kepid

    var keplerName: String?
    var kepoiName: String
    var name: String //Este es el nombre que se muestra

    var koiSteff: Double
    var koiDisposition: String
    var koiDuration: Double
    var koiSrad: Double
    var koiSlogg: Double
    var koiModelSnr: Double
    var koiDepth: Double
    var koiPeriod: Double

    enum CodingKeys: String, CodingKey {
        case id = "kepid"
        case keplerName = "kepler_name"
        case kepoiName = "kepoi_name"
        case name
        case koiSteff = "koi_steff"
        case koiDisposition = "koi_disposition"
        case koiDuration = "koi_duration"
        case koiSrad = "koi_srad"
        case koiSlogg = "koi_slogg"
        case koiModelSnr = "koi_model_snr"
        case koiDepth = "koi_depth"
        case koiPeriod = "koi_period"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Acepta `kepid` como Int o String, y guárdalo como String
        if let intId = try? c.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            self.id = try c.decode(String.self, forKey: .id)
        }
        self.keplerName = try c.decodeIfPresent(String.self, forKey: .keplerName)
        self.kepoiName = try c.decode(String.self, forKey: .kepoiName)
        // Nombre mostrado: usa el provisto o deriva de Kepler/KOI
        let providedName = try c.decodeIfPresent(String.self, forKey: .name)
        self.name = providedName ?? self.keplerName ?? self.kepoiName

        self.koiSteff = try c.decode(Double.self, forKey: .koiSteff)
        self.koiDisposition = try c.decode(String.self, forKey: .koiDisposition)
        self.koiDuration = try c.decode(Double.self, forKey: .koiDuration)
        self.koiSrad = try c.decode(Double.self, forKey: .koiSrad)
        self.koiSlogg = try c.decode(Double.self, forKey: .koiSlogg)
        self.koiModelSnr = try c.decode(Double.self, forKey: .koiModelSnr)
        self.koiDepth = try c.decode(Double.self, forKey: .koiDepth)
        self.koiPeriod = try c.decode(Double.self, forKey: .koiPeriod)
    }
}

//JSON esperado
//[
//  {
//    // Nombre oficial si existe; si no, usa KOI.
//    "kepid": 1234567
//    "kepler_name": "Kepler-22 b",   // string | null
//    "kepoi_name": "K02200.01",      // string
//    "name": "Kepler-22 b",          // kepler_name ?? kepoi_name
//
//    // Datos físicos
//    "koi_steff": 5778,              // K > 0
//    "koi_disposition": "CANDIDATE", // "CANDIDATE" | "CONFIRMED" | "FALSE POSITIVE"
//    "koi_duration": 3.7,            // horas >= 0
//    "koi_srad": 1.02,               // R☉ > 0
//    "koi_slogg": 4.44,              // log10(cm/s^2) ~ 3–5
//    "koi_model_snr": 12.3,          // >= 0
//    "koi_depth": 850.0,             // ppm >= 0
//    "koi_period": 12.345            // días > 0
//  },
//  {
//    "kepler_name": null,
//    "kepoi_name": "KOI-351.01",
//    "name": "KOI-351.01",
//
//    "koi_steff": 6100,
//    "koi_disposition": "CONFIRMED",
//    "koi_duration": 5.1,
//    "koi_srad": 1.3,
//    "koi_slogg": 4.2,
//    "koi_model_snr": 18.9,
//    "koi_depth": 520.0,
//    "koi_period": 331.6
//  }
//]
