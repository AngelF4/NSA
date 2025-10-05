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
    @AppStorage("showOnboarding") var showOnboarding: Bool = true
    
    
}
