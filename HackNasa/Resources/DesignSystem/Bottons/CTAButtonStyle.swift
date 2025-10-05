//
//  CTAButtonStyle.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

/// Botón para el onboarding Call To Action (tamaño estándar)
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

/// Variante más grande para CTA (solo para el onboarding inicial)
struct CTALargeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold)) // fuente un poco más grande
            .shadow(color: .primary, radius: 10)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 60) // más alto
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

extension ButtonStyle where Self == CTALargeButtonStyle {
    static var ctaLarge: CTALargeButtonStyle { CTALargeButtonStyle() }
}

#Preview {
    VStack(spacing: 16) {
        Button("CTA normal") {}
            .buttonStyle(.cta)

        Button("CTA grande") {}
            .buttonStyle(.ctaLarge)
    }
    .padding()
}
