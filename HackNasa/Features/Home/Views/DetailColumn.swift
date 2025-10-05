//
//  DetailColumn.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//


import SwiftUI

struct DetailColumn: View {
    let generalDataset: GeneralDataset
    @ObservedObject var geminiVM: GeminiViewModel
    
    var body: some View {
        VStack(spacing: Spacing.m) {
            ScrollView {
                DatasetContainer {
                    Text("Disposition")
                        .font(.headline)
                    Text(generalDataset.koiDisposition)
                        .font(.title.bold())
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    guard geminiVM.response == nil else { return }
                    Task {
                        await geminiVM.askSpecific(koiname: generalDataset.kepoiName)
                    }
                } label: {
                    GroupBox {
                        if geminiVM.isLoading {
                            ProgressView()
                        } else if let response = geminiVM.response {
                            Text(response)
                                .transition(.blurReplace)
                        }
                    } label: {
                        Label("Preguntale a Gemini", systemImage: "sparkles")
                            .foregroundStyle(.secondary)
                    }
                    .background(
                        AngularGradient(
                            gradient: Gradient(colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red]),
                            center: .center
                        )
                        .mask(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(lineWidth: 10)
                                .blur(radius: 2)
                        )
                        .blur(radius: 7)
                        // expande hacia afuera para que luzca como shadow
                    )
                }
                .buttonStyle(.plain)
                
                HStack(spacing: Spacing.m) {
                    VStack(spacing: Spacing.m) {
                        DatasetContainer(background: .accent) {
                            Text("koiSteff")
                                .font(.headline)
                            Text(generalDataset.koiSteff?.description ?? "")
                                .font(.title.bold())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        DatasetContainer {
                            Text("koiDuration")
                                .font(.headline)
                            Text(generalDataset.koiDuration?.description ?? "")
                                .font(.title.bold())
                        }
                        .frame(maxWidth: .infinity)
                        DatasetContainer {
                            Text("koiSrad")
                                .font(.headline)
                            Text(generalDataset.koiSrad?.description ?? "")
                                .font(.title.bold())
                        }
                        .frame(maxWidth: .infinity)
                        DatasetContainer {
                            Text("koiSlogg")
                                .font(.headline)
                            Text(generalDataset.koiSlogg?.description ?? "")
                                .font(.title.bold())
                        }
                        .frame(maxWidth: .infinity)
                    }
                    VStack(spacing: Spacing.m) {
                        DatasetContainer {
                            Text("koiModelSnr")
                                .font(.headline)
                            Text(generalDataset.koiModelSnr?.description ?? "")
                                .font(.title.bold())
                        }
                        .frame(maxWidth: .infinity)
                        DatasetContainer {
                            Text("koiDepth")
                                .font(.headline)
                            Text(generalDataset.koiDepth?.description ?? "")
                                .font(.title.bold())
                        }
                        .frame(maxWidth: .infinity)
                        DatasetContainer {
                            Text("koiPeriod")
                                .font(.headline)
                            Text(generalDataset.koiPeriod?.description ?? "")
                                .font(.title.bold())
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(generalDataset.name)
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

struct DatasetContainer<Content: View>: View {
    var background: Color = .clear
    @ViewBuilder
    var content: Content
    
    var body: some View {
        VStack {
            content
        }
        .padding(12)
        .background(background, in: .rect(cornerRadius: Radius.m))
        
    }
}

#Preview {
    Home()
}
