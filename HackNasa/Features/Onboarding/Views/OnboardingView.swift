import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var navigateToDataLoading = false
    
    // Pasos del onboarding (según tu guion)
    private let steps: [(message: String, cta: String)] = [
        (
            "¡Bienvenido a bordo! Nuestro objetivo es identificar nuevos mundos fuera de nuestro sistema solar",
            "¿Cómo lo podemos lograr?"
        ),
        (
            "Los sensores detectan una disminución en la luz de una estrella. Esta -sombra- indica que un exoplaneta ha pasado por delante (un tránsito)",
            "Continuar"
        ),
        (
            "Tu misión es entrenar un agente de IA o un modelo de machine learning. Debes clasificar los tránsitos: candidato planetario, planeta ya conocido, o no planeta",
            "Descubrir exoplanetas"
        )
    ]
    
    // Ancho máximo deseado para los CTA
    private let ctaMaxWidth: CGFloat = 320
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo con imagen y overlay
                ZStack {
                    Image("exoplanets_background")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                    Color("secondary")
                        .opacity(0.35)
                        .ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Mensaje del paso actual
                    Text(steps[currentStep].message)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.4), value: currentStep)
                    
                    Spacer()
                    
                    // CTA del paso actual (versión más grande)
                    Button(steps[currentStep].cta) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            if currentStep < steps.count - 1 {
                                currentStep += 1
                            } else {
                                // Último paso: continuar a la guía rápida (DataLoadingView con su onboarding interno)
                                navigateToDataLoading = true
                            }
                        }
                    }
                    .buttonStyle(.ctaLarge)
                    .frame(maxWidth: ctaMaxWidth)
                    .padding(.bottom, 150)
                }
            }
            .navigationDestination(isPresented: $navigateToDataLoading) {
                // Aquí arrancamos la guía rápida original (Numset, Max depth, etc.)
                DataLoadingView()
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(OnboardingViewModel())
}
