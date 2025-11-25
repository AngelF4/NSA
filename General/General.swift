//
//  General.swift
//  General
//
//  Created by Angel Hernández Gámez on 06/10/25.
//

import AppIntents

struct General: AppIntent {
    static var title: LocalizedStringResource { "General" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
