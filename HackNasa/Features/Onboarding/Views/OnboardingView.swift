import SwiftUI

struct OnboardingView: View {
    @State private var hasStarted = false
    @State private var currentPhrase = 0
    @State private var isComplete = false
    @State private var navigateToDataLoading = false
    
    let phrases = [
        "Miles de estrellas brillan en el universo",
        "Algunas ocultan secretos extraordinarios",
        "Un ligero cambio en su luz revela planetas distantes",
        "El método de tránsito detecta estas inmersiones",
        "Cada dip podría ser un nuevo mundo",
        "Tu misión: clasificar candidatos a exoplanetas"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo con imagen
                ZStack {
                    // Imagen de fondo
                    Image("exoplanets_background")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                    // Overlay oscuro para mejorar legibilidad
                    Color(hex: "0B1E3D")
                        .opacity(0.7)
                        .ignoresSafeArea()
                }
                
                if !hasStarted {
                    // Vista inicial con botón
                    VStack(spacing: 24) {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            Text("Explora mundos más allá del sistema solar")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Text("Ingresa datos astronómicos y descubre si corresponden a un exoplaneta.")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 50)
                        }
                        
                        Button("Comenzar Exploración") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                hasStarted = true
                            }
                            startOnboarding()
                        }
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .padding(.top, 32)


                        
                        Spacer()
                        
                        /*Text("placeholder")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.bottom, 60)*/
                    }
                } else {
                    // Contenedor de frases
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Título de la app (solo visible al final)
                        if isComplete {
                            Text("NombreApp")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.bottom, 40)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        ZStack {
                            ForEach(0..<phrases.count, id: \.self) { index in
                                PhraseView(
                                    text: phrases[index],
                                    isActive: currentPhrase == index,
                                    isPast: currentPhrase > index
                                )
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                    
                    //Indicadores de progreso
                    /*VStack {
                        Spacer()
                        
                        HStack(spacing: 8) {
                            ForEach(0..<phrases.count, id: \.self) { index in
                                Circle()
                                    .fill(currentPhrase >= index ? Color(hex: "FFD700") : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: currentPhrase)
                            }
                        }
                        .padding(.bottom, 60)
                    }*/
                    
                    // boton de continuar al final del onboarding
                    if isComplete {
                        VStack {
                            Spacer()
                            
                            Button(action: {
                                navigateToDataLoading = true
                            }) {
                                Text("Comenzar")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 60)
                                    .padding(.vertical, 16)
                            }
                            .buttonStyle(.borderless)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .padding(.bottom, 150)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToDataLoading) {
                DataLoadingView()
            }
        }
    }
    
    private func startOnboarding() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.8)) {
                if currentPhrase < phrases.count - 1 {
                    currentPhrase += 1
                } else {
                    isComplete = true
                    timer.invalidate()
                }
            }
        }
    }
}

// MARK: - Phrase View
struct PhraseView: View {
    let text: String
    let isActive: Bool
    let isPast: Bool
    
    var body: some View {
        Text(text)
            .font(.system(size: 32, weight: .medium))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .opacity(isActive ? 1.0 : isPast ? 0.0 : 0.3)
            .scaleEffect(isActive ? 1.0 : isPast ? 0.85 : 0.95)
            .blur(radius: isActive ? 0 : isPast ? 8 : 4)
            .offset(y: isPast ? -50 : 0)
            .animation(.easeInOut(duration: 0.8), value: isActive)
            .animation(.easeInOut(duration: 0.8), value: isPast)
    }
}

struct DataLoadingView: View {
    var body: some View {
        ZStack {
            Color(hex: "0B1E3D")
                .ignoresSafeArea()
            
            Text("Pantalla de Carga de Datos")
                .font(.title)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    OnboardingView()
}
