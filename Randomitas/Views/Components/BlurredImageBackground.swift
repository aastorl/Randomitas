//
//  BlurredImageBackground.swift
//  Randomitas
//
//  Created by Astor Ludueña on 21/01/2026.
//

internal import SwiftUI

/// Un fondo de imagen sutilmente difuminado que se adapta al modo claro/oscuro
struct BlurredImageBackground: View {
    let imageData: Data?
    var blurRadius: CGFloat = 50
    var overlayOpacity: Double? = nil // nil significa usar valores adaptativos predeterminados
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if let imageData = imageData, let uiImage = UIImage(data: imageData) {
            GeometryReader { geometry in
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .blur(radius: blurRadius)
                    .overlay(
                        // Superposición adaptativa para legibilidad
                        colorScheme == .dark
                            ? Color.black.opacity(overlayOpacity ?? 0.6)
                            : Color.white.opacity(overlayOpacity ?? 0.7)
                    )
                    .clipped()
            }
            .ignoresSafeArea()
        }
    }
}
