//
//  CTAButtonStyle.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

///Boton para el onboarding Call To Action
struct CTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .shadow(color: .primary, radius: 10)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 50)
            .glassEffect(.regular
                .tint(.accent
                    .opacity(configuration.isPressed ? 0.4 : 0.2)
                )
            )
            .background(Color.clear)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == CTAButtonStyle {
    static var cta: CTAButtonStyle { CTAButtonStyle() }
}

#Preview {
    Button("Hola mundo") {
        
    }
    .buttonStyle(.cta)
    .padding()
}
