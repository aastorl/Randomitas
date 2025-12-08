//
//  ResultSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña on 01/12/2025.
//

internal import SwiftUI

struct ResultSheet: View {
    let folder: Folder
    let path: [Int]
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: RandomitasViewModel
    @Binding var navigationPath: [Int]?
    
    var currentFolder: Folder {
        if let foundFolder = viewModel.findFolder(at: path) {
            return foundFolder
        }
        return folder
    }
    
    @State var isFavorite: Bool = false
    @State var imagePickerRequest: ImagePickerRequest?
    
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
                                if let imageData = currentFolder.imageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(minWidth: 0, maxWidth: .infinity)
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
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: 64))
                                            .foregroundColor(.blue)
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
                                                    viewModel.renameFolder(id: folder.id, newName: editingName)
                                                    isEditingName = false
                                                }
                                        } else {
                                            Text(currentFolder.name)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    Spacer()
                                    Button(action: { 
                                        editingName = currentFolder.name
                                        isEditingName = true
                                        isFocused = true
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Divider()
                                
                                // Contenido
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Contenido")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    HStack {
                                        if !currentFolder.subfolders.isEmpty {
                                            Text("\(currentFolder.subfolders.count) carpeta\(currentFolder.subfolders.count == 1 ? "" : "s")")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Botones de acción
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                // Favorito
                                Button(action: {
                                    isFavorite.toggle()
                                    viewModel.toggleFolderFavorite(folder: currentFolder, path: path)
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
                                        imagePickerRequest = ImagePickerRequest(sourceType: .camera)
                                    }) {
                                        Label("Tomar foto", systemImage: "camera.fill")
                                    }
                                    Button(action: {
                                        imagePickerRequest = ImagePickerRequest(sourceType: .photoLibrary)
                                    }) {
                                        Label("Seleccionar galería", systemImage: "photo.fill")
                                    }
                                    if currentFolder.imageData != nil {
                                        Divider()
                                        Button(role: .destructive, action: {
                                            viewModel.updateFolderImage(imageData: nil, at: path)
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
                                
                                // Abrir Carpeta
                                Button(action: {
                                    navigationPath = path
                                    isPresented = false
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "folder.fill")
                                        Text("Abrir carpeta")
                                            .font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
            }
            .sheet(item: $imagePickerRequest) { request in
                ImagePickerView(onImagePicked: { image in
                    let resizedImage = image.resized(toMaxDimension: 1024)
                    if let data = resizedImage.jpegData(compressionQuality: 0.8) {
                        viewModel.updateFolderImage(imageData: data, at: path)
                    }
                }, sourceType: request.sourceType)
            }
        }
        .onAppear {
            isFavorite = viewModel.isFolderFavorite(folderId: currentFolder.id)
        }
    }
}
