//
//  WelcomeOnboardingView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 31/01/2026.
//

internal import SwiftUI

struct WelcomeOnboardingView: View {
    var onCreateFirstElement: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // App Icon / Logo
            VStack(spacing: 16) {
                Image(systemName: "atom")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(.blue)
                
                Text("Bienvenido a Randomitas!")
                    .font(.title.bold())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Tu app definitiva para randomizar lo que quieras.")
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
                    description: "Crea elementos que pueden contener otros elementos dentro."
                )
                
                FeatureRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Favoritos",
                    description: "Marca tus elementos favoritos para acceder rápidamente."
                )
                
                FeatureRow(
                    icon: "eye.slash.fill",
                    iconColor: .orange,
                    title: "Ocultar",
                    description: "Oculta elementos de la randomización si lo deseas."
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // CTA Button
            Button(action: {
                HapticManager.mediumImpact()
                onCreateFirstElement()
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
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Feature Row Component
private struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Container
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
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
