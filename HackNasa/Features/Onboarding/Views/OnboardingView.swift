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
    
    // Ancho máximo deseado para los CTA
    private let ctaMaxWidth: CGFloat = 320
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                ZStack {
                    // background image
                    Image("exoplanets_background")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                    // overlay oscuro
                    Color("secondary")
                        .opacity(0.35)
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
                                // Reiniciamos el estado por si se vuelve a esta pantalla
                                currentPhrase = 0
                                isComplete = false
                            }
                        }
                        .buttonStyle(.cta)
                        .frame(maxWidth: ctaMaxWidth)
                        .padding(.top, 32)
                        
                        Spacer()
                    }
                } else {
                    // Contenedor de frases
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Título de la app (solo visible al final)
                        if isComplete {
                            Text("Luxe")
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
                    
                    // Botones inferiores del onboarding
                    VStack {
                        Spacer()
                        
                        if isComplete {
                            // CTA final para comenzar
                            Button("Comenzar") {
                                navigateToDataLoading = true
                            }
                            .buttonStyle(.cta)
                            .frame(maxWidth: ctaMaxWidth)
                            .padding(.bottom, 150)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            // CTA para avanzar manualmente
                            Button("Siguiente") {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    if currentPhrase < phrases.count - 1 {
                                        currentPhrase += 1
                                        if currentPhrase == phrases.count - 1 {
                                            // La siguiente pulsación marcará completion
                                        }
                                    } else {
                                        // Al llegar al último, marcamos completion
                                        isComplete = true
                                    }
                                }
                            }
                            .buttonStyle(.cta)
                            .frame(maxWidth: ctaMaxWidth)
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

#Preview {
    OnboardingView()
        .environmentObject(OnboardingViewModel())
}
