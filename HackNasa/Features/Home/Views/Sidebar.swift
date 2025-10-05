//
//  Sidebar.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct Sidebar: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showNewFile = false

    var body: some View {
        List(viewModel.files, id: \.id,
             selection: $viewModel.fileSelected) { file in
            NavigationLink(value: file.id) {
                Label(file.name, systemImage: "text.document")
            }
        }
             .toolbar {
                 ToolbarItem(placement: .primaryAction) {
                     Button("Agregar csv", systemImage: "plus") {
                         showNewFile = true
                     }
                 }
             }
             .sheet(isPresented: $showNewFile) {
                 SidebarUploadSheet(onUploadCompleted: {
                     await viewModel.fetchFiles()
                 })
             }
             .onChange(of: viewModel.fileSelected) {
                 guard viewModel.fileSelected != nil else { return }
                 Task {
                     await viewModel.selectCSV()
                 }
             }
             .refreshable {
                 await viewModel.fetchFiles()
             }
             .navigationTitle("Archivos")
             .navigationBarTitleDisplayMode(.large)
    }
}

private struct SidebarUploadSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// Callback to refresh the sidebar once the upload finishes.
    let onUploadCompleted: () async -> Void

    // MARK: - Hyperparameters form
    @State private var numset: String = ""
    @State private var maxDepth: String = ""
    @State private var randomState: String = ""

    @State private var hyperparamsMessage: String?
    @State private var isSubmittingHyperparams = false

    @AppStorage("hp_numset") private var storedNumset: Double = 0
    @AppStorage("hp_maxDepth") private var storedMaxDepth: Double = 0
    @AppStorage("hp_randomState") private var storedRandomState: Double = 0

    // MARK: - CSV upload
    @State private var showImporter = false
    @State private var selectedFileURL: URL?
    @State private var isUploading = false
    @State private var uploadMessage: String?

    private var isFormValid: Bool {
        Double(numset) != nil && Double(maxDepth) != nil && Double(randomState) != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hyperparametersSection
                    Divider()
                    csvSection
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Configurar análisis")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .onAppear(perform: populateFromStoredValues)
    }

    // MARK: - Sections

    private var hyperparametersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hiperparámetros")
                .font(.title3.bold())

            Text("Ingresa valores numéricos (se aceptan decimales) para configurar el Random Forest.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                labeledNumericField(title: "Numset", text: $numset)
                labeledNumericField(title: "Max depth", text: $maxDepth)
                labeledNumericField(title: "Random State", text: $randomState)
            }

            Button {
                Task { await submitHyperparameters() }
            } label: {
                if isSubmittingHyperparams {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Guardar hiperparámetros")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.cta)
            .disabled(!isFormValid || isSubmittingHyperparams)
            .opacity(isFormValid ? 1 : 0.6)

            if let message = hyperparamsMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: numset) { sanitizeInPlace(&numset) }
        .onChange(of: maxDepth) { sanitizeInPlace(&maxDepth) }
        .onChange(of: randomState) { sanitizeInPlace(&randomState) }
    }

    private var csvSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Archivo CSV")
                .font(.title3.bold())

            Text("Selecciona tu archivo CSV con las observaciones que deseas analizar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Button {
                    showImporter = true
                } label: {
                    Text(selectedFileURL == nil ? "Elegir archivo CSV" : "Cambiar archivo CSV")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.cta)

                if let url = selectedFileURL {
                    Text(url.lastPathComponent)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    selectedFileURL = urls.first
                case .failure:
                    selectedFileURL = nil
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Hiperparámetros guardados")
                    .font(.subheadline.bold())
                    .opacity(0.8)
                Text("Numset: \(storedValueDescription(storedNumset))")
                Text("Max depth: \(storedValueDescription(storedMaxDepth))")
                Text("Random State: \(storedValueDescription(storedRandomState))")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Button {
                Task { await uploadCSVAndSelect() }
            } label: {
                if isUploading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Subir y seleccionar CSV")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.cta)
            .disabled(isUploading)

            if let msg = uploadMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func populateFromStoredValues() {
        if numset.isEmpty, storedNumset != 0 {
            numset = cleanString(from: storedNumset)
        }
        if maxDepth.isEmpty, storedMaxDepth != 0 {
            maxDepth = cleanString(from: storedMaxDepth)
        }
        if randomState.isEmpty, storedRandomState != 0 {
            randomState = cleanString(from: storedRandomState)
        }
    }

    private func submitHyperparameters() async {
        guard let n = Int(numset),
              let m = Int(maxDepth),
              let r = Int(randomState) else {
            await MainActor.run {
                hyperparamsMessage = "Verifica que todos los campos sean numéricos."
            }
            return
        }

        await MainActor.run {
            isSubmittingHyperparams = true
            hyperparamsMessage = nil
        }

        let hp = Hyperparams(numest: n, mxdepth: m, randstate: r)
        guard let body = APIEndpoint.jsonBody(hp),
              let req = APIEndpoint.updateHyperparams.request(body: body) else {
            await MainActor.run {
                hyperparamsMessage = "No se pudo crear la petición."
                isSubmittingHyperparams = false
            }
            return
        }

        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                await MainActor.run {
                    hyperparamsMessage = "El servidor respondió con un error."
                    isSubmittingHyperparams = false
                }
                return
            }
        } catch {
            await MainActor.run {
                hyperparamsMessage = "Error al enviar los hiperparámetros: \(error.localizedDescription)"
                isSubmittingHyperparams = false
            }
            return
        }

        await MainActor.run {
            storedNumset = Double(n)
            storedMaxDepth = Double(m)
            storedRandomState = Double(r)
            hyperparamsMessage = "Hiperparámetros guardados correctamente."
            isSubmittingHyperparams = false
        }
    }

    private func uploadCSVAndSelect() async {
        guard let fileURL = selectedFileURL else {
            await MainActor.run { uploadMessage = "Selecciona un archivo CSV primero." }
            return
        }

        await MainActor.run {
            isUploading = true
            uploadMessage = nil
        }

        let filename = fileURL.lastPathComponent
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            await MainActor.run {
                uploadMessage = "No se pudo leer el archivo: \(error.localizedDescription)"
                isUploading = false
            }
            return
        }

        guard let uploadReq = APIEndpoint.uploadCSV(filename: filename).request(body: data) else {
            await MainActor.run {
                uploadMessage = "No se pudo crear la petición de subida."
                isUploading = false
            }
            return
        }

        do {
            let (_, uploadResp) = try await URLSession.shared.data(for: uploadReq)
            guard let http = uploadResp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                await MainActor.run {
                    uploadMessage = "Fallo al subir el CSV."
                    isUploading = false
                }
                return
            }
        } catch {
            await MainActor.run {
                uploadMessage = "Error de red al subir CSV: \(error.localizedDescription)"
                isUploading = false
            }
            return
        }

        let baseName = filename.hasSuffix(".csv") ? String(filename.dropLast(4)) : filename
        guard let selectReq = APIEndpoint.selectCSV(name: baseName).request() else {
            await MainActor.run {
                uploadMessage = "No se pudo crear la petición selectCSV."
                isUploading = false
            }
            return
        }

        do {
            let (_, selectResp) = try await URLSession.shared.data(for: selectReq)
            guard let http = selectResp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                await MainActor.run {
                    uploadMessage = "Fallo al seleccionar el CSV."
                    isUploading = false
                }
                return
            }
        } catch {
            await MainActor.run {
                uploadMessage = "Error de red al seleccionar CSV: \(error.localizedDescription)"
                isUploading = false
            }
            return
        }

        await onUploadCompleted()

        await MainActor.run {
            uploadMessage = "CSV subido y seleccionado."
            isUploading = false
            dismiss()
        }
    }

    private func labeledNumericField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .opacity(0.8)
            TextField(title, text: text)
                .keyboardType(.decimalPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25))
                )
        }
    }

    private func sanitizeInPlace(_ text: inout String) {
        var result = text.filter { "0123456789.".contains($0) }
        var dotFound = false
        var sanitized = ""
        for ch in result {
            if ch == "." {
                if dotFound { continue }
                dotFound = true
            }
            sanitized.append(ch)
        }
        text = sanitized
    }

    private func storedValueDescription(_ value: Double) -> String {
        value == 0 ? "Sin configurar" : cleanString(from: value)
    }

    private func cleanString(from value: Double) -> String {
        let formatted = String(format: "%.4f", value)
        return formatted
            .replacingOccurrences(of: #"(\.\d*?[1-9])0+$"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\.0+$"#, with: "", options: .regularExpression)
    }
}

#Preview {
    @Previewable @State var viewModel = HomeViewModel()
    
    NavigationSplitView {
        Sidebar(viewModel: viewModel)
    } content: {
        
    } detail: {
        
    }
    
}

