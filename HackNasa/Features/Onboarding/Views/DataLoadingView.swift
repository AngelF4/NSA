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
        (
            "Numset",
            """
            Define el numero de arboles de decisión que formaran el Random Forest, generalmente, más árboles es mejor, hasta que el rendimiento deja de mejorar significativamente.
            
            Un mayor número puede mejorar la estabilidad del modelo y reducir la varianza, pero incrementa el costo de cómputo. Comienza con un valor moderado y ajústalo con validación cruzada para equilibrar precisión y tiempo de entrenamiento.
            """
        ),
        (
            "Max depth",
            """
            Este hiperparámetro controla la profundidad máxima que puede alcanzar cada árbol de decisión individual en el bosque. Es una forma de controlar la complejidad del modelo para evitar el overfitting.
            
            Profundidades muy grandes tienden a sobreajustar; profundidades pequeñas pueden subajustar. Puedes dejarlo sin límite y regular con otras técnicas, o fijar un máximo razonable y calibrarlo con validación para encontrar el punto óptimo.
            """
        ),
        (
            "Random State",
            """
            Es una semilla de aleatoridad, es fundamental para la reproducibilidad de tus resultados.
            
            Usa el mismo valor durante tus pruebas para poder comparar resultados. Cualquier entero es válido; cambiarlo variará la partición aleatoria y el muestreo, lo que puede afectar ligeramente el desempeño y las métricas.
            """
        ),
        (
            "Resumen",
            "Repasa brevemente la información que ingresarás. Asegúrate de que los valores sean coherentes con tus datos para obtener mejores resultados del análisis."
        )
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
    
    private var isFormValid: Bool {
        Double(numset) != nil && Double(maxDepth) != nil && Double(randomState) != nil
    }
    
    var body: some View {
        GeometryReader { proxy in
            let modalWidth = proxy.size.width * 0.8
            let modalHeight = proxy.size.height * 0.8
            
            ZStack {
                // Fondo: misma imagen y overlay oscuro que en el onboarding
                Image("exoplanets_background")
                    .resizable()
                    .scaledToFill()
                    .opacity(1)
                    .ignoresSafeArea()
                
                Color("secondary")
                    .opacity(0.4)
                    .ignoresSafeArea()
                
                // Modal centrado (80% pantalla)
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
                    .font(.title3)
                    .lineSpacing(4)
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
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .padding(.vertical, 0)
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
            
            Text("Ingresa valores numéricos (se aceptan decimales). Para comenzar, utiliza valores razonables y evita extremos; podrás ajustarlos más adelante según los resultados. Si no estás seguro, prueba con un rango moderado y compara el desempeño.")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                labeledNumericField(title: "Numset", text: $numset)
                labeledNumericField(title: "Max depth", text: $maxDepth)
                labeledNumericField(title: "Random State", text: $randomState)
            }
            
            Button {
                submitHyperparameters()
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
                // TODO: logica de carga de csv
                withAnimation {
                    onboardingViewModel.showOnboarding = false
                }
                
            } label: {
                Text("Ejecutar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.cta)
            .padding(.top, 4)
        }
    }
    
    // MARK: - Helpers
    
    private func labeledNumericField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
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
    
    private func submitHyperparameters() {
        guard let n = Double(numset),
              let m = Double(maxDepth),
              let r = Double(randomState) else {
            return
        }
        // guardar para luego mandarlo al backend (UserDefaults a través de @AppStorage)
        storedNumset = n
        storedMaxDepth = m
        storedRandomState = r
        
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
