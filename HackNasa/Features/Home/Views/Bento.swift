//
//  Bento.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

struct Bento: View {
    let dataset: Dataset
    
    var body: some View {
        HStack(spacing: Spacing.l) {
            VStack(spacing: Spacing.l) {
                ChartContainer {
                    Text("hooal")
                }
                ChartContainer {
                    Text("hooal")
                }
            }
            VStack(spacing: Spacing.l) {
                ChartContainer {
                    Text("hooal")
                }
                ChartContainer {
                    Text("hooal")
                }
                ChartContainer {
                    Text("hooal")
                }
            }
            VStack(spacing: Spacing.l) {
                ChartContainer {
                    Text("hooal")
                }
                ChartContainer {
                    Text("hooal")
                }
                ChartContainer {
                    Text("hooal")
                }
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            GeometryReader { geo in
                let end = min(geo.size.width, geo.size.height) / 2
                RadialGradient(
                    stops: [
                        .init(color: Color("secondaryColor"), location: 0.0), // 0% en el centro
                        .init(color: .clear,  location: 1.0)  // 100% hacia afuera
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

#Preview {
    Bento(dataset: Dataset(title: "", data: Data()))
}
