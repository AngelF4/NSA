import SwiftUI
import UniformTypeIdentifiers

struct DataLoadingView: View {
    // Fases del modal
    private enum Phase {
        case onboarding
        case form
        case loading
        case csvPrompt
    }
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @State private var phase: Phase = .onboarding
    
    // Onboarding (4 pasos)
    @State private var currentStep: Int = 0
    private let steps: [(title: String, body: String)] = [
        ("Numset", "Define el numero de arboles de decisión que formaran el Random Forest, generalmente, más árboles es mejor, hasta que el rendimiento deja de mejorar significativamente."),
        ("Max depth", "Este hiperparámetro controla la profundidad máxima que puede alcanzar cada árbol de decisión individual en el bosque. Es una forma de controlar la complejidad del modelo para evitar el overfitting."),
        ("Random State", "Es una semilla de aleatoridad, es fundamental para la reproducibilidad de tus resultados."),
        ("Resumen", "Repasa brevemente la información que ingresarás. Asegúrate de que los valores sean coherentes con tus datos para obtener mejores resultados del análisis.")
    ]
    
    // Formulario (entrada como texto, validación numérica)
    @State private var numset: String = ""
    @State private var maxDepth: String = ""
    @State private var randomState: String = ""
    
    // Persistencia (para usar más adelante) -> UserDefaults a través de @AppStorage
    @AppStorage("hp_numset") private var storedNumset: Double = 0
    @AppStorage("hp_maxDepth") private var storedMaxDepth: Double = 0
    @AppStorage("hp_randomState") private var storedRandomState: Double = 0
    
    // Carga de archivo CSV (fase final)
    @State private var showImporter = false
    @State private var selectedFileURL: URL?
    @State private var isUploading = false
    @State private var uploadMessage: String?
    
    private var isFormValid: Bool {
        Double(numset) != nil && Double(maxDepth) != nil && Double(randomState) != nil
    }
    
    var body: some View {
        GeometryReader { proxy in
            let modalWidth = proxy.size.width * 0.7
            let modalHeight = proxy.size.height * 0.7
            
            ZStack {
                // Fondo: misma imagen y overlay oscuro que en el onboarding
                Image("exoplanets_background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                Color("secondary")
                    .opacity(0.35)
                    .ignoresSafeArea()
                
                // Modal centrado (70% pantalla)
                VStack(spacing: 0) {
                    // Imagen superior (1/3 del modal)
                    Image("exoplanets_background")
                        .resizable()
                        .scaledToFill()
                        .frame(height: modalHeight / 3)
                        .clipped()
                    
                    // Contenido del modal
                    VStack(alignment: .leading, spacing: 16) {
                        switch phase {
                        case .onboarding:
                            onboardingContent
                        case .form:
                            formContent
                        case .loading:
                            loadingContent
                        case .csvPrompt:
                            csvPromptContent
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(width: modalWidth, height: modalHeight)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)) // border radius
                .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12))
                )
            }
        }
    }
    
    // MARK: - Subviews
    
    private var onboardingContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Guía rápida")
                .font(.system(size: 22, weight: .bold))
            
            Text("Paso \(currentStep + 1) de \(steps.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(steps[currentStep].title)
                .font(.title2).bold()
            
            ScrollView {
                Text(steps[currentStep].body)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
            
            // Indicador de progreso
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Circle()
                        .fill(i == currentStep ? Color.white : Color.white.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
                Spacer()
            }
            .padding(.top, 4)
            
            // Botones Previous (blanco) / Next (azul .cta)
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut) {
                        if currentStep > 0 { currentStep -= 1 }
                    }
                } label: {
                    Text("Previous")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.black)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .opacity(currentStep == 0 ? 0.6 : 1)
                .disabled(currentStep == 0)
                
                Button {
                    withAnimation(.easeInOut) {
                        if currentStep < steps.count - 1 {
                            currentStep += 1
                        } else {
                            // Terminado el onboarding: pasar al formulario
                            phase = .form
                        }
                    }
                } label: {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.cta) // tonos azules/accent del app
            }
            .padding(.top, 4)
        }
    }
    
    private var formContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configura los hiperparámetros")
                .font(.system(size: 22, weight: .bold))
            
            Text("Ingresa valores numéricos (se aceptan decimales).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                labeledNumericField(title: "Numset", text: $numset)
                labeledNumericField(title: "Max depth", text: $maxDepth)
                labeledNumericField(title: "Random State", text: $randomState)
            }
            
            Button {
                Task {
                    await submitHyperparameters()
                }
            } label: {
                Text("Subir hiperparámetros")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.cta)
            .disabled(!isFormValid)
            .opacity(isFormValid ? 1 : 0.6)
        }
        .onChange(of: numset) { sanitizeInPlace(&numset) }
        .onChange(of: maxDepth) { sanitizeInPlace(&maxDepth) }
        .onChange(of: randomState) { sanitizeInPlace(&randomState) }
    }
    
    private var loadingContent: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
            Text("Configurando parámetros...")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var csvPromptContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subir archivo csv para su análisis")
                .font(.system(size: 22, weight: .bold))
            
            // Breve explicación
            Text("Selecciona tu archivo CSV con las observaciones que deseas analizar. Idealmente debe incluir encabezados y estar separado por comas. Asegúrate de que los datos estén limpios para obtener mejores resultados.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Botón para subir CSV
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    showImporter = true
                } label: {
                    Text(selectedFileURL == nil ? "Subir archivo CSV" : "Cambiar archivo CSV")
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
            
            // Resumen de hiperparámetros guardados (opcional)
            VStack(alignment: .leading, spacing: 6) {
                Text("Hiperparámetros guardados")
                    .font(.subheadline).bold()
                    .opacity(0.8)
                Text("Numset: \(storedNumset)")
                Text("Max depth: \(storedMaxDepth)")
                Text("Random State: \(storedRandomState)")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            
            // Botón de ejecución (navegará a Home en el futuro)
            Button {
                isUploading = true
                Task {
                    await uploadCSVAndSelect()
                    isUploading = false
                }
            } label: {
                Text(isUploading ? "Subiendo..." : "Ejecutar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.cta)
            .padding(.top, 4)
            
            if let msg = uploadMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Helpers
    
    // Sube el CSV en binario y luego selecciona ese CSV en el backend.
    private func uploadCSVAndSelect() async {
        guard let fileURL = selectedFileURL else {
            await MainActor.run { uploadMessage = "Selecciona un archivo CSV primero." }
            return
        }
        let filename = fileURL.lastPathComponent
        // Cargar datos binarios del archivo
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            await MainActor.run { uploadMessage = "No se pudo leer el archivo: \(error.localizedDescription)" }
            return
        }
        
        // 1) Subir binario a /upload_raw con header X-File-Name
        guard let uploadReq = APIEndpoint.uploadCSV(filename: filename).request(body: data) else {
            await MainActor.run { uploadMessage = "No se pudo crear la petición de subida." }
            return
        }
        do {
            let (_, uploadResp) = try await URLSession.shared.data(for: uploadReq)
            guard let http = uploadResp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                await MainActor.run { uploadMessage = "Fallo al subir el CSV. Código inesperado." }
                return
            }
        } catch {
            await MainActor.run { uploadMessage = "Error de red al subir CSV: \(error.localizedDescription)" }
            return
        }
        
        // 2) Llamar a /csvs/select/{name}.csv con POST (name sin extensión)
        let baseName = filename.hasSuffix(".csv") ? String(filename.dropLast(4)) : filename
        guard let selectReq = APIEndpoint.selectCSV(name: baseName).request() else {
            await MainActor.run { uploadMessage = "No se pudo crear la petición selectCSV." }
            return
        }
        do {
            let (_, selectResp) = try await URLSession.shared.data(for: selectReq)
            guard let http = selectResp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                await MainActor.run { uploadMessage = "Fallo al seleccionar el CSV. Código inesperado." }
                return
            }
        } catch {
            await MainActor.run { uploadMessage = "Error de red al seleccionar CSV: \(error.localizedDescription)" }
            return
        }
        
        await MainActor.run {
            uploadMessage = "CSV subido y seleccionado."
            onboardingViewModel.showOnboarding = false
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
        // Mantener solo dígitos y un único punto decimal
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
    
    private func submitHyperparameters() async {
        guard let n = Int(numset),
              let m = Int(maxDepth),
              let r = Int(randomState) else {
            return
        }
        // guardar para luego mandarlo al backend (UserDefaults a través de @AppStorage)
        // 1) Arma el modelo
        let hp = Hyperparams(numest: n, mxdepth: m, randstate: r)
        
        // 2) Codifica el JSON
        guard let body = APIEndpoint.jsonBody(hp) else { fatalError("JSON inválido") }
        
        // 3) Crea el request (POST + Content-Type ya vienen por defecto)
        guard let req = APIEndpoint.updateHyperparams.request(body: body) else { fatalError("URL inválida") }
        
        // 4) Llama al backend
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                print("No se completo la petición")
                return
            }
        } catch {
            print("No se completo la petición \(error)")
        }
        
        
        // Simular envío y carga de ~5 segundos
        withAnimation(.easeInOut) {
            phase = .loading
        }
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await MainActor.run {
                withAnimation(.easeInOut) {
                    phase = .csvPrompt
                }
            }
        }
    }
}

#Preview {
    DataLoadingView()
        .environmentObject(OnboardingViewModel())
}
