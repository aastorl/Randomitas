//
//  GridItemView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 21/11/2025.
//

import SwiftUI

struct GridItemView: View {
    let item: Item
    let folder: Folder
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    let onEditImage: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Imagen o color blur
                if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "doc.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                    )
                }
                
                // Botón de favorito
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .padding(8)
                }
            }
            .cornerRadius(8)
            
            // Nombre
            Text(item.name)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(2)
                .truncationMode(.tail)
        }
        .contextMenu {
            Button(action: onRename) {
                Label("Renombrar", systemImage: "pencil")
            }
            Button(action: onEditImage) {
                Label("Editar imagen", systemImage: "photo")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}

struct GridFolderView: View {
    let folder: Folder
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    let onEditImage: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let imageData = folder.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "folder.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    )
                }
                
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .padding(8)
                }
            }
            .cornerRadius(8)
            
            Text(folder.name)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(2)
                .truncationMode(.tail)
        }
        .contextMenu {
            Button(action: onRename) {
                Label("Renombrar", systemImage: "pencil")
            }
            Button(action: onEditImage) {
                Label("Editar imagen", systemImage: "photo")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}
