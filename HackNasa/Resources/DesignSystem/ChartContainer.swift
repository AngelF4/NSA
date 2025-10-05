//
//  ChartContainer.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

struct ChartContainer<Content: View>: View {
    @ViewBuilder
    let content: Content
    
    var body: some View {
        VStack {
            content
        }
        .padding(12)
        .background(Color(.systemBackground), in: .rect(cornerRadius: Radius.m))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.m)
                .stroke(.fill ,lineWidth: 2)
        }
    }
}

#Preview {
    ChartContainer {
        Text("Hola mundo")
    }
}
