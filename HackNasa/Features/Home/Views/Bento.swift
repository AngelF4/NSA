//
//  Bento.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

struct Bento: View {
    let dataset: Dataset
    
    private let outerPadding: CGFloat = 20
    
    var body: some View {
        GeometryReader { geo in
            // Altura disponible real para los recuadros dentro del padding
            let columnHeight = geo.size.height - outerPadding * 2
            let interItemSpacing = Spacing.l
            // Tres recuadros => 2 separaciones internas
            let availableHeight = columnHeight - (2 * interItemSpacing)
            
            // Columna 2: 1/4, 2/4, 1/4
            let smallC2 = availableHeight / 4
            let largeC2 = availableHeight / 2
            
            // Columna 3:
            // Abajo ≈ 1/2 del alto disponible, arriba y medio del mismo tamaño con el resto.
            let bottomC3 = availableHeight * 0.5
            let remainingC3 = max(0, availableHeight - bottomC3)
            let topC3 = remainingC3 / 2
            let midC3 = topC3
            
            HStack(spacing: Spacing.l) {
                // Columna 1: dos recuadros que llenan por igual
                VStack(spacing: Spacing.l) {
                    ChartContainer {
                        Text("hooal")
                    }
                    .frame(maxHeight: .infinity)
                    
                    ChartContainer {
                        Text("hooal")
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Columna 2: 1/4, 2/4, 1/4
                VStack(spacing: Spacing.l) {
                    ChartContainer {
                        Text("hooal")
                    }
                    .frame(height: smallC2)
                    
                    ChartContainer {
                        Text("hooal")
                    }
                    .frame(height: largeC2)
                    
                    ChartContainer {
                        Text("hooal")
                    }
                    .frame(height: smallC2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Columna 3: top = middle, bottom ≈ 1/2
                VStack(spacing: Spacing.l) {
                    ChartContainer {
                        Text("hooal")
                    }
                    .frame(height: topC3)
                    
                    ChartContainer {
                        Text("hooal")
                    }
                    .frame(height: midC3)
                    
                    ChartContainer {
                        Text("hooal")
                    }
                    .frame(height: bottomC3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(outerPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                GeometryReader { geo in
                    let end = min(geo.size.width, geo.size.height) / 2
                    RadialGradient(
                        stops: [
                            .init(color: Color("secondaryColor"), location: 0.0),
                            .init(color: .clear,  location: 1.0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: end
                    )
                }
                .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    Bento(dataset: Dataset(title: "", data: Data()))
}
