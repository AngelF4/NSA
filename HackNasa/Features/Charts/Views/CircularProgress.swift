//
//  CircularProgress.swift
//  PomodoroTimer
//
//  Created by Angel Hernández Gámez on 25/07/25.
//

import SwiftUI
import Charts

struct CircularProgress: View {
    let progress: Double
    var title: String = "Precisión del modelo"
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.tint.tertiary, lineWidth: 30)
            // Work timer arc
            Circle()
                .trim(to: progress)
                .stroke(.tint, style: StrokeStyle(lineWidth: 30, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring, value: progress)
            VStack(spacing: Spacing.s) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(progress.formatted(.percent.precision(.fractionLength(2))))
                    .font(.largeTitle.bold())
            }
        }
    }
}

struct ClassStatsRings: View {
    let title: String
    let stats: ModelPrecision.ClassStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            HStack(spacing: Spacing.m) {
                CircularProgress(progress: stats.f1Score, title: "F1-score")
                    .frame(width: 140, height: 140)
                CircularProgress(progress: stats.precision, title: "Precisión")
                    .frame(width: 140, height: 140)
                CircularProgress(progress: stats.recall, title: "Recall")
                    .frame(width: 140, height: 140)
            }
        }
    }
}

struct StatsBarChart: View {
    let title: String
    let stats: ModelPrecision.ClassStats
    
    private struct Metric: Identifiable { let id = UUID(); let name: String; let value: Double }
    
    private var data: [Metric] {
        [
            .init(name: "F1-score", value: stats.f1Score),
            .init(name: "Precisión", value: stats.precision),
            .init(name: "Recall", value: stats.recall)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Chart(data) { item in
                BarMark(
                    x: .value("Métrica", item.name),
                    y: .value("Valor", item.value)
                )
                .annotation(position: .top) {
                    Text(item.value, format: .percent.precision(.fractionLength(1)))
                        .font(.caption)
                }
            }
            .chartYScale(domain: 0...1.05)
            .frame(height: 220)
        }
    }
}

struct PerClassComparisonChart: View {
    let perClass: [String: ModelPrecision.ClassStats]
    
    private struct Point: Identifiable { let id = UUID(); let clazz: String; let metric: String; let value: Double }
    
    private var data: [Point] {
        perClass.compactMap { (key, s) -> [Point] in
            [
                .init(clazz: key, metric: "F1-score", value: s.f1Score),
                .init(clazz: key, metric: "Precisión", value: s.precision),
                .init(clazz: key, metric: "Recall", value: s.recall)
            ]
        }.flatMap { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Comparación por clase")
                .font(.headline)
                .foregroundStyle(.secondary)
            Chart(data) { p in
                BarMark(
                    x: .value("Métrica", p.metric),
                    y: .value("Valor", p.value)
                )
                .foregroundStyle(by: .value("Clase", p.clazz))
                .position(by: .value("Clase", p.clazz))
                .annotation(position: .top) {
                    Text(p.value, format: .percent.precision(.fractionLength(1)))
                        .font(.caption)
                }
            }
            .chartYScale(domain: 0...1.05)
            .chartLegend(position: .bottom)
            .frame(height: 320)
        }
    }
}

struct CombinedComparisonChart: View {
    let macro: ModelPrecision.ClassStats?
    let weighted: ModelPrecision.ClassStats?
    let perClass: [String: ModelPrecision.ClassStats]
    
    private struct Point: Identifiable { let id = UUID(); let group: String; let metric: String; let value: Double }
    
    private var data: [Point] {
        var rows: [Point] = []
        if let m = macro {
            rows += [
                .init(group: "Macro avg", metric: "F1-score", value: m.f1Score),
                .init(group: "Macro avg", metric: "Precisión", value: m.precision),
                .init(group: "Macro avg", metric: "Recall", value: m.recall)
            ]
        }
        if let w = weighted {
            rows += [
                .init(group: "Weighted avg", metric: "F1-score", value: w.f1Score),
                .init(group: "Weighted avg", metric: "Precisión", value: w.precision),
                .init(group: "Weighted avg", metric: "Recall", value: w.recall)
            ]
        }
        for (key, s) in perClass {
            rows += [
                .init(group: key, metric: "F1-score", value: s.f1Score),
                .init(group: key, metric: "Precisión", value: s.precision),
                .init(group: key, metric: "Recall", value: s.recall)
            ]
        }
        return rows
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Resumen de métricas")
                .font(.headline)
                .foregroundStyle(.secondary)
            Chart(data) { p in
                BarMark(
                    x: .value("Métrica", p.metric),
                    y: .value("Valor", p.value)
                )
                .foregroundStyle(by: .value("Grupo", p.group))
                .position(by: .value("Grupo", p.group))
                .annotation(position: .top) {
                    Text(p.value, format: .percent.precision(.fractionLength(0)))
                        .font(.caption)
                }
            }
            .chartYScale(domain: 0...1.05)
            .chartLegend(position: .bottom)
        }
    }
}

struct PrecisionProgres: View {
    let modelPrecision: ModelPrecision?
    
    var body: some View {
        VStack(spacing: Spacing.m) {
            CircularProgress(progress: modelPrecision?.accuracy ?? 0, title: "Precisión global")
                .frame(width: 180, height: 180)
            if let aggAcc = modelPrecision?.aggregates["accuracy"] {
                Text("Aggregates • accuracy: \(aggAcc.formatted(.percent.precision(.fractionLength(3))))")
            }
        }
        .padding()
    }
}

struct PrecisionBreakdown: View {
    let modelPrecision: ModelPrecision?
    
    var body: some View {
        VStack(spacing: Spacing.l) {
            let subset: [String: ModelPrecision.ClassStats] = [
                "CONFIRMED": modelPrecision?.perClass["CONFIRMED"],
                "FALSE POSITIVE": modelPrecision?.perClass["FALSE POSITIVE"]
            ].compactMapValues { $0 }
            CombinedComparisonChart(
                macro: modelPrecision?.macroAvg,
                weighted: modelPrecision?.weightedAvg,
                perClass: subset
            )
        }
        .padding()
        .frame(height: 240)
    }
}

#Preview {
    let demo = ModelPrecision(
        accuracy: 0.990771259063942,
        aggregates: ["accuracy": 0.990771259063942],
        perClass: [
            "CONFIRMED": .init(f1Score: 0.9870848708487084, precision: 1.0, recall: 0.9744990892531876, support: 549),
            "FALSE POSITIVE": .init(f1Score: 0.9928205128205129, precision: 0.9857433808553971, recall: 1.0, support: 968),
            "macro avg": .init(f1Score: 0.9899526918346107, precision: 0.9928716904276986, recall: 0.9872495446265939, support: 1517),
            "weighted avg": .init(f1Score: 0.9907447926870121, precision: 0.9909028297086516, recall: 0.990771259063942, support: 1517)
        ]
    )
    return VStack(spacing: 32) {
        PrecisionProgres(modelPrecision: demo)
        Divider()
        PrecisionBreakdown(modelPrecision: demo)
    }
}

#Preview {
    CircularProgress(progress: 0.3)
        .frame(width: 250, height: 250)
}
