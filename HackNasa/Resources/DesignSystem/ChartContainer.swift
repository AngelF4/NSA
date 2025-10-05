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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(12)
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
