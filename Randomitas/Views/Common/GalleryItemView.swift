//
//  GalleryItemView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 21/11/2025.
//

import SwiftUI

struct GalleryItemView: View {
    let item: Item
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    let onEditImage: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Imagen o blur
            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "doc.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                )
            }
            
            // Gradiente oscuro en la parte inferior
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 80)
            
            // Nombre y favorito
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.system(size: 18))
                }
            }
            .padding(12)
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

struct GalleryFolderView: View {
    let folder: Folder
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    let onEditImage: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageData = folder.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "folder.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                )
            }
            
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 80)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text(folder.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.system(size: 18))
                }
            }
            .padding(12)
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
