//
//  ContentView.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var onboardingViewModel  = OnboardingViewModel()
    
    var body: some View {
        if onboardingViewModel.showOnboarding {
            OnboardingView()
                .environmentObject(onboardingViewModel)
        } else {
            Home()
        }
    }
}

#Preview {
    ContentView()
        
}
