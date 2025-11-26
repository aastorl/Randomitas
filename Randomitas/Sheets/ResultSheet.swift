//
//  ResultSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

internal import SwiftUI

struct ResultSheet: View {
    let item: Item
    let path: String
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: RandomitasViewModel
    let folderPath: [Int]
    
    var currentItem: Item {
        // Find the item in the view model to get live updates
        // This is a simplified lookup, assuming we can find it. 
        // In a real app we might want a more robust way to find the item by ID across all folders
        // For now, we rely on the fact that we passed the item and it should exist.
        // We can try to find it in the current folderPath if provided, or search globally if needed.
        // Since RandomitasViewModel structure is nested, a global search by ID is expensive.
        // However, we know where it came from usually.
        // Let's try to find it in the folderPath first.
        
        if let foundItem = viewModel.findItem(id: item.id, in: folderPath) {
            return foundItem
        }
        // Fallback to the passed item if not found (e.g. just deleted)
        return item
    }
    
    @State var isFavorite: Bool = false
    @State var showingImagePicker = false
    @State var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var pickerID = UUID()
    
    // Inline Renaming
    @State private var isEditingName = false
    @State private var editingName = ""
    @FocusState private var isFocused: Bool
    
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
                                if let imageData = currentItem.imageData, let uiImage = UIImage(data: imageData) {
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
                                        if isEditingName {
                                            TextField("Nombre", text: $editingName)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .focused($isFocused)
                                                .onSubmit {
                                                    viewModel.renameItem(id: item.id, newName: editingName)
                                                    isEditingName = false
                                                }
                                        } else {
                                            Text(currentItem.name)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    Spacer()
                                    Button(action: { 
                                        editingName = currentItem.name
                                        isEditingName = true
                                        isFocused = true
                                    }) {
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
                                        viewModel.toggleFavorite(item: currentItem, path: path)
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
                                        Button(action: {
                                            imageSourceType = .camera
                                            pickerID = UUID()
                                            showingImagePicker = true
                                        }) {
                                            Label("Tomar foto", systemImage: "camera.fill")
                                        }
                                        Button(action: {
                                            imageSourceType = .photoLibrary
                                            pickerID = UUID()
                                            showingImagePicker = true
                                        }) {
                                            Label("Seleccionar galería", systemImage: "photo.fill")
                                        }
                                        if currentItem.imageData != nil {
                                            Divider()
                                            Button(role: .destructive, action: {
                                                viewModel.updateItemImage(imageData: nil, itemId: currentItem.id)
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
                                    viewModel.deleteItem(id: currentItem.id, from: folderPath)
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
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerView(onImagePicked: { image in
                    let resizedImage = image.resized(toMaxDimension: 1024)
                    if let data = resizedImage.jpegData(compressionQuality: 0.8) {
                        viewModel.updateItemImage(imageData: data, itemId: currentItem.id)
                    }
                }, sourceType: imageSourceType)
                .id(pickerID)
            }
        }
        .onAppear {
            isFavorite = viewModel.isFavorite(itemId: currentItem.id, path: path)
        }
    }
}
