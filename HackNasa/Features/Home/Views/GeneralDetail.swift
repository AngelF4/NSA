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
    // Cache de datos derivados para evitar trabajo pesado en cada render
    @State private var chartItems: [ChartItem] = []
    @State private var cachedRows: [DatasetRow] = []
    
    private struct ChartItem: Identifiable, Equatable, Hashable {
        let id: UUID
        let view: AnyView
        init(key: String, view: AnyView) {
            // Stable UUID from key string to avoid recomputation churn
            if let data = key.data(using: .utf8) {
                var hasher = Hasher()
                hasher.combine(data)
                let hash = hasher.finalize()
                // Derive UUID bytes deterministically from hash
                var bytes = withUnsafeBytes(of: hash.bigEndian, Array.init)
                while bytes.count < 16 { bytes.append(0) }
                let uuid = UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
                self.id = uuid
            } else {
                self.id = UUID()
            }
            self.view = view
        }
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
        var items: [ChartItem] = []
        items.append(ChartItem(key: "precision", view: AnyView(PrecisionProgres(modelPrecision: vm.presicion).frame(maxWidth: .infinity))))
        items.append(ChartItem(key: "steff_srad", view: AnyView(SteffVsSradChart(points: vm.steffVsSradPoints))))
        items.append(ChartItem(key: "duration_disposition", view: AnyView(DurationByDispositionChart(data: vm.durationAggData))))
        items.append(ChartItem(key: "steff_hist", view: AnyView(SteffHistogramChart(bins: vm.steffBinsData))))
        items.append(ChartItem(key: "slogg_hist", view: AnyView(SloggHistogramChart(bins: vm.sloggBinsData))))
        items.append(ChartItem(key: "snr_hist", view: AnyView(ModelSNRHistogramChart(bins: vm.snrLogBinsData))))
        items.append(ChartItem(key: "depth_hist", view: AnyView(DepthHistogramChart(bins: vm.depthLogBinsData))))
        items.append(ChartItem(key: "period_hist", view: AnyView(PeriodHistogramChart(bins: vm.periodLogBinsData))))
        return items
    }
    
    /// Recalcula filas de tabla y gráficas sólo cuando cambian los datos relevantes
    private func recomputeDerivedData() {
        cachedRows = rows()
        chartItems = charts(viewModel)
    }
    
    /// Sincroniza la página del carrusel con la posición seleccionada
    private func syncPageWithPosition() {
        guard !chartItems.isEmpty else { return }
        if let current = position, let idx = chartItems.firstIndex(where: { $0.id == current }) {
            page = Page.withIndex(idx)
        } else {
            position = chartItems.first?.id
            page = Page.withIndex(0)
        }
    }
    
    private struct LoadingSkeleton: View {
        var body: some View {
            Group {
                HStack(spacing: Spacing.l) {
                    RoundedRectangle(cornerRadius: 24)
                    RoundedRectangle(cornerRadius: 24)
                }
                .frame(height: 400)
                RoundedRectangle(cornerRadius: 24)
                    .overlay { ProgressView() }
            }
            .foregroundStyle(.fill)
        }
    }
    
    private struct GeminiSection: View {
        @ObservedObject var geminiVM: GeminiViewModel
        @ObservedObject var viewModel: HomeViewModel
        var action: () -> Void
        var body: some View {
            Button(action: action) {
                GroupBox {
                    if geminiVM.isLoading {
                        ProgressView()
                    } else if let response = geminiVM.response {
                        ScrollView { Text(response).multilineTextAlignment(.leading).transition(.blurReplace) }
                    }
                } label: {
                    HStack {
                        Label("Pregúntale a Gemini", systemImage: "sparkles")
                        Spacer()
                        if viewModel.isLoadingPrecision && viewModel.presicion == nil {
                            ProgressView().scaleEffect(0.7)
                        }
                    }
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
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // Extracted to reduce type-checker load
    @ViewBuilder
    private func ChartsPager(width: CGFloat) -> some View {
        let items = chartItems
        let itemWidth = max(0, width - 80)
        let itemSize = CGSize(width: itemWidth, height: 240)
        Pager(page: page, data: items, id: \.id) { item in
            ChartContainer {
                item.view
            }
            .frame(height: 240)
        }
        .preferredItemSize(itemSize)
        .itemSpacing(Spacing.l)
        .interactive(scale: 0.92)
        .horizontal()
        .padding(.horizontal, 40)
        .onPageChanged { idx in
            if items.indices.contains(idx) { position = items[idx].id }
        }
    }

    // Extracted table to separate builder
    private var datasetTable: some View {
        Table(cachedRows.sorted(using: sortOrder), selection: $tableSelection, sortOrder: $sortOrder) {
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            // Carga inicial del dataset: mostramos skeleton de charts + tabla
            if viewModel.isLoadingDataset && (viewModel.dataset == nil || viewModel.dataset?.isEmpty == true) {
                LoadingSkeleton()
            } else {
                // Contenido principal cuando ya hay dataset
                GeometryReader { proxy in
                    let width = proxy.size.width
                    ChartsPager(width: width)
                }
                
                // Indicador pequeño si se está actualizando el dataset pero ya había datos
                if viewModel.isLoadingDataset && (viewModel.dataset?.isEmpty == false) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Actualizando dataset…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                
                GeminiSection(geminiVM: geminiVM, viewModel: viewModel) {
                    guard geminiVM.response == nil else { return }
                    Task { await geminiVM.askGeneral() }
                }
                
                // Tabla de datos para iPad
                datasetTable
            }
        }
        .padding(20)
        .navigationTitle("Graficas Generales")
        .background(
            GeometryReader { geo in
                let end: CGFloat = min(geo.size.width, geo.size.height) / 2
                RadialGradient(
                    stops: [
                        .init(color: Color("secondaryColor"), location: 0.0),
                        .init(color: .clear, location: 1.0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: end
                )
                .ignoresSafeArea()
            }
        )
        // Usamos onAppear y onChange para recalcular datos derivados sólo cuando cambian
        .onAppear {
            recomputeDerivedData()
            syncPageWithPosition()
        }
        .onChange(of: viewModel.dataset?.count) { _, _ in
            recomputeDerivedData()
            syncPageWithPosition()
        }
        .onChange(of: viewModel.presicion) { _, _ in
            recomputeDerivedData()
            syncPageWithPosition()
        }
        .onChange(of: position) { _, newValue in
            guard let id = newValue else { return }
            let idx = chartItems.firstIndex(where: { $0.id == id })
            if let idx { page.update(.new(index: idx)) }
        }
    }
}

#Preview {
    Home()
}

#Preview {
    GeneralDetail(viewModel: HomeViewModel(), geminiVM: GeminiViewModel(), position: .constant(nil))
}
