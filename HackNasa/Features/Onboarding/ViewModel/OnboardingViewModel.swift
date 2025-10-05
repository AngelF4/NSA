//
//  OnboardingViewModel.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    // Mostrar siempre el onboarding al iniciar la app (sin persistencia)
    @Published var showOnboarding: Bool = true
}
