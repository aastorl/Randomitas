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
    
    @State var showingRenameSheet = false
    @State var isFavorite: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { isPresented = false }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Atrás")
                            }
                            .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Imagen grande
                            ZStack {
                                if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 300)
                                        .clipped()
                                } else {
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .frame(height: 300)
                                    .overlay(
                                        Image(systemName: "doc.fill")
                                            .font(.system(size: 64))
                                            .foregroundColor(.gray)
                                    )
                                }
                            }
                            .cornerRadius(16)
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                // Nombre
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Nombre")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(item.name)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                    Spacer()
                                    Button(action: { showingRenameSheet = true }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Divider()
                                
                                // Ruta
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ubicación")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(path)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Botones de acción
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    // Favorito
                                    Button(action: {
                                        isFavorite.toggle()
                                        viewModel.toggleFavorite(item: item, path: path)
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: isFavorite ? "star.fill" : "star")
                                            Text(isFavorite ? "Favorito" : "Agregar")
                                                .font(.subheadline)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(isFavorite ? Color.yellow.opacity(0.2) : Color(.systemGray6))
                                        .foregroundColor(isFavorite ? .yellow : .primary)
                                        .cornerRadius(10)
                                    }
                                    
                                    // Imagen
                                    Menu {
                                        Button(action: {}) {
                                            Label("Tomar foto", systemImage: "camera.fill")
                                        }
                                        Button(action: {}) {
                                            Label("Seleccionar galería", systemImage: "photo.fill")
                                        }
                                        if item.imageData != nil {
                                            Divider()
                                            Button(role: .destructive, action: {
                                                viewModel.updateItemImage(imageData: nil, itemId: item.id)
                                            }) {
                                                Label("Eliminar imagen", systemImage: "trash")
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "photo")
                                            Text("Imagen")
                                                .font(.subheadline)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .foregroundColor(.primary)
                                        .cornerRadius(10)
                                    }
                                }
                                
                                // Eliminar
                                Button(role: .destructive, action: {
                                    viewModel.deleteItem(id: item.id, from: folderPath)
                                    isPresented = false
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash")
                                        Text("Eliminar item")
                                            .font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.2))
                                    .foregroundColor(.red)
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingRenameSheet) {
                RenameSheet(
                    itemId: item.id,
                    currentName: item.name,
                    onRename: { newName in
                        viewModel.renameItem(id: item.id, newName: newName)
                    },
                    isPresented: $showingRenameSheet
                )
            }
        }
        .onAppear {
            isFavorite = viewModel.isFavorite(itemId: item.id, path: path)
        }
    }
}
