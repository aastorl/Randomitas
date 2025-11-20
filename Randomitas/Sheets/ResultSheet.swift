//
//  ResultSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import SwiftUI

struct ResultSheet: View {
    let item: Item
    let path: String
    @Binding var isPresented: Bool
    let viewModel: RandomitasViewModel
    let folderPath: [Int]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button("Cerrar") { isPresented = false }
                Spacer()
            }
            .padding()
            
            Spacer()
            
            VStack(spacing: 12) {
                // Mostrar imagen si existe
                if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .cornerRadius(12)
                        .padding()
                } else {
                    // Mostrar icono si no hay imagen
                    Image(systemName: "gift.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.purple)
                }
                
                // Nombre del item
                Text(item.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                // Path
                Text(path)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Botones: Editar imagen + Favorito
                HStack(spacing: 16) {
                    ImageEditorMenu(imageData: Binding(
                        get: { item.imageData },
                        set: { viewModel.updateItemImage(imageData: $0, itemId: item.id) }
                    ))
                    
                    Button(action: { viewModel.toggleFavorite(item: item, path: path) }) {
                        Image(systemName: viewModel.isFavorite(itemId: item.id, path: path) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                }
                .padding()
            }
            
            Spacer()
        }
    }
}
