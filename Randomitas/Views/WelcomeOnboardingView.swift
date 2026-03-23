//
//  WelcomeOnboardingView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 31/01/2026.
//

internal import SwiftUI

// MARK: - Display Mode
enum AppInfoMode {
    case onboarding  // First time: "Crea tu primer elemento"
    case info        // From menu: "Entendido"
}

struct WelcomeOnboardingView: View {
    var mode: AppInfoMode = .onboarding
    var onCreateFirstElement: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                Spacer().frame(height: 40)
                
                // App Icon / Logo
                VStack(spacing: 16) {
                    Image("ShuffleIcon")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text(mode == .onboarding ? "Bienvenido a Randomitas!" : "Cómo funciona Randomitas")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(mode == .onboarding
                         ? "Tu app definitiva para randomizar lo que quieras."
                         : "Todo lo que necesitás saber sobre la app.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)
                
                // Features
                VStack(spacing: 24) {
                    FeatureRow(
                        icon: "atom",
                        iconColor: .blue,
                        title: "Elementos",
                        description: "Crea elementos que pueden contener otros elementos dentro, organizá todo como quieras."
                    )
                    
                    FeatureRow(
                        icon: "ShuffleIcon",
                        iconColor: .blue,
                        title: "Randomización",
                        description: "Presioná el botón de mezcla para elegir un elemento al azar entre todos los visibles.",
                        isAssetImage: true
                    )
                    
                    FeatureRow(
                        icon: "photo.fill",
                        iconColor: .green,
                        title: "Imágenes",
                        description: "Adjuntá fotos a tus elementos para identificarlos visualmente."
                    )
                    
                    FeatureRow(
                        icon: "star.fill",
                        iconColor: .yellow,
                        title: "Favoritos",
                        description: "Marcá tus elementos favoritos para acceder rápidamente desde cualquier nivel."
                    )
                    
                    FeatureRow(
                        icon: "eye.slash.fill",
                        iconColor: .orange,
                        title: "Ocultar",
                        description: "Ocultá elementos para que no aparezcan al randomizar, sin eliminarlos."
                    )
                    
                    FeatureRow(
                        icon: "arrow.turn.up.right",
                        iconColor: .teal,
                        title: "Mover y Copiar",
                        description: "Reorganizá tus elementos moviéndolos o copiándolos entre elementos."
                    )
                    
                    FeatureRow(
                        icon: "checkmark.circle",
                        iconColor: .indigo,
                        title: "Selección Múltiple",
                        description: "Seleccioná varios elementos a la vez para moverlos, copiarlos, ocultarlos o eliminarlos."
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer().frame(height: 40)
                
                // CTA Button
                if mode == .onboarding {
                    Button(action: {
                        HapticManager.mediumImpact()
                        onCreateFirstElement?()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Crea tu primer elemento!")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120) // Space for bottom bar buttons
                } else {
                    Button(action: {
                        HapticManager.lightImpact()
                        onDismiss?()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text("Entendido")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
        .navigationTitle(mode == .info ? "Info" : "")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Feature Row Component
private struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    var isAssetImage: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Container
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                if isAssetImage {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 22, height: 22)
                        .foregroundColor(iconColor)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(iconColor)
                }
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}
