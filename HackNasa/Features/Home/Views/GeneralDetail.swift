//
//  GeneralDetail.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI
import SwiftUIPager

struct GeneralDetail: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var geminiVM: GeminiViewModel
    @Binding var position: UUID?
    @State private var page = Page.withIndex(0)
    @State private var tableSelection = Set<String>()
    @State private var sortOrder: [KeyPathComparator<DatasetRow>] = [
        .init(\.name, order: .forward)
    ]
    
    private struct ChartItem: Identifiable, Equatable, Hashable {
        let id = UUID()
        let view: AnyView
        static func == (lhs: ChartItem, rhs: ChartItem) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }
    
    private struct DatasetRow: Identifiable {
        let id: String
        let keplerName: String?
        let kepoiName: String
        let name: String
        let koiSteff: Double?
        let koiDisposition: String
        let koiDuration: Double?
        let koiSrad: Double?
        let koiSlogg: Double?
        let koiModelSnr: Double?
        let koiDepth: Double?
        let koiPeriod: Double?
    }
    
    private func rows() -> [DatasetRow] {
        let data = viewModel.dataset ?? []
        return data.map { d in
            DatasetRow(
                id: d.id,
                keplerName: d.keplerName,
                kepoiName: d.kepoiName,
                name: d.name,
                koiSteff: d.koiSteff,
                koiDisposition: d.koiDisposition,
                koiDuration: d.koiDuration,
                koiSrad: d.koiSrad,
                koiSlogg: d.koiSlogg,
                koiModelSnr: d.koiModelSnr,
                koiDepth: d.koiDepth,
                koiPeriod: d.koiPeriod
            )
        }
    }
    
    @ViewBuilder
    private func number(_ v: Double?, _ frac: Int) -> some View {
        if let v { Text(v.formatted(.number.precision(.fractionLength(frac)))) }
        else { Text("—").foregroundStyle(.secondary) }
    }
    
    private func charts(_ vm: HomeViewModel) -> [ChartItem] {
        [
            .init(view: AnyView(SteffVsSradChart(points: vm.datasetPointsSteffSrad()))),
            .init(view: AnyView(DurationByDispositionChart(data: vm.durationAgg(stat: "media")))),
            .init(view: AnyView(SteffHistogramChart(bins: vm.steffBins(step: 250)))),
            .init(view: AnyView(SloggHistogramChart(bins: vm.sloggBins(step: 0.2)))),
            .init(view: AnyView(ModelSNRHistogramChart(bins: vm.snrLogBins(edges: [0.1,0.3,1,3,10,30,100])))),
            .init(view: AnyView(DepthHistogramChart(bins: vm.depthLogBins(step: 0.5)))),
            .init(view: AnyView(PeriodHistogramChart(bins: vm.periodLogBins(step: 0.3)))),
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            GeometryReader { proxy in
                let items = charts(viewModel)
                
                Pager(page: page, data: items, id: \.id) { item in
                    ChartContainer {
                        item.view
                    }
                    .frame(height: 240)
                    
                }
                .preferredItemSize(CGSize(width: proxy.frame(in: .global).width - 80, height: 240))
                .itemSpacing(Spacing.l)
                .interactive(scale: 0.92)
                .horizontal()
                .padding(.horizontal, 40) // peek
                .onPageChanged { idx in
                    if items.indices.contains(idx) { position = items[idx].id }
                }
            }
            Button {
                guard geminiVM.response == nil else { return }
                Task {
                    await geminiVM.askGeneral()
                }
            } label: {
                GroupBox {
                    if geminiVM.isLoading {
                        ProgressView()
                    } else if let response = geminiVM.response {
                        ScrollView {
                            Text(response)
                                .multilineTextAlignment(.leading)
                                .transition(.blurReplace)
                        }
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
            
            // Tabla de datos para iPad
            Table(rows().sorted(using: sortOrder), selection: $tableSelection, sortOrder: $sortOrder) {
                TableColumn("Nombre", value: \.name)
                TableColumn("Disp.") { r in Text(r.koiDisposition) }
                TableColumn("T* (K)") { r in number(r.koiSteff, 0) }.width(min: 80, ideal: 100, max: 120)
                TableColumn("Dur. (d)") { r in number(r.koiDuration, 2) }
                TableColumn("R* (R☉)") { r in number(r.koiSrad, 2) }
                TableColumn("log g") { r in number(r.koiSlogg, 2) }
                TableColumn("SNR") { r in number(r.koiModelSnr, 2) }
                TableColumn("Depth") { r in number(r.koiDepth, 3) }
                TableColumn("Per. (d)") { r in number(r.koiPeriod, 3) }
            }
        }
        .padding(20)
        .navigationTitle("Graficas Generales")
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
        .onAppear {
            let items = charts(viewModel)
            if let current = position, let idx = items.firstIndex(where: { $0.id == current }) {
                page = Page.withIndex(idx)
            } else {
                position = items.first?.id
                page = Page.withIndex(0)
            }
        }
        .onChange(of: position) { _, newValue in
            let items = charts(viewModel)
            if let id = newValue, let idx = items.firstIndex(where: { $0.id == id }) {
                page.update(.new(index: idx))
            }
        }
    }
}

#Preview {
    Home()
}

#Preview {
    GeneralDetail(viewModel: HomeViewModel(), geminiVM: GeminiViewModel(), position: .constant(nil))
}
