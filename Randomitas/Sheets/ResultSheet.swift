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
    var navigateToFullPath: ([Int]) -> Void
    @Binding var highlightedItemId: UUID?
    
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
                                        Image(systemName: "atom")
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
                                
                                // Ubicación
                                let pathString = viewModel.getReversedPathString(for: path)
                                if !pathString.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Ubicación")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        HStack(spacing: 4) {
                                            Text("< \(pathString)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
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
                                    highlightedItemId = currentFolder.id
                                    navigateToFullPath(path)
                                    isPresented = false
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "atom")
                                        Text("Abrir Elemento")
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
    
    // MARK: - Subvistas
    
    private var folderImageView: some View {
        Group {
            if let imageData = currentFolder.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderImage
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var placeholderImage: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "atom")
                .font(.system(size: 48))
                .foregroundColor(.blue)
        )
    }
    
    private var nameSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Nombre")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isEditingName {
                    TextField("Nombre", text: $editingName)
                        .font(.title3.bold())
                        .focused($isFocused)
                        .onSubmit {
                            viewModel.renameFolder(id: folder.id, newName: editingName)
                            isEditingName = false
                        }
                } else {
                    Text(currentFolder.name)
                        .font(.title3.bold())
                }
            }
            
            Spacer()
            
            Button {
                editingName = currentFolder.name
                isEditingName = true
                isFocused = true
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var contentInfo: some View {
        HStack {
            Label("\(currentFolder.subfolders.count)", systemImage: "folder")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                favoriteButton
                imageMenuButton
            }
            openFolderButton
        }
    }
    
    private var favoriteButton: some View {
        Button {
            isFavorite.toggle()
            viewModel.toggleFolderFavorite(folder: currentFolder, path: path)
        } label: {
            Label(isFavorite ? "Favorito" : "Agregar",
                  systemImage: isFavorite ? "star.fill" : "star")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isFavorite ? Color.yellow.opacity(0.2) : Color(.systemGray6))
                .foregroundColor(isFavorite ? .yellow : .primary)
                .cornerRadius(10)
        }
    }
    
    private var imageMenuButton: some View {
        Menu {
            Button {
                imagePickerRequest = ImagePickerRequest(sourceType: .camera)
            } label: {
                Label("Tomar foto", systemImage: "camera.fill")
            }
            
            Button {
                imagePickerRequest = ImagePickerRequest(sourceType: .photoLibrary)
            } label: {
                Label("Galería", systemImage: "photo.fill")
            }
            
            if currentFolder.imageData != nil {
                Divider()
                Button(role: .destructive) {
                    viewModel.updateFolderImage(imageData: nil, at: path)
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
        } label: {
            Label("Imagen", systemImage: "photo")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(10)
        }
    }
    
    private var openFolderButton: some View {
        Button {
            highlightedItemId = currentFolder.id
            let parentPath = Array(path.dropLast())
            navigateToFullPath(parentPath)
            isPresented = false
        } label: {
            Label("Abrir Elemento", systemImage: "atom")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    // MARK: - Helpers
    
    private func handleImagePicked(_ image: UIImage) {
        let resizedImage = image.resized(toMaxDimension: 1024)
        if let data = resizedImage.jpegData(compressionQuality: 0.8) {
            viewModel.updateFolderImage(imageData: data, at: path)
        }
    }
}
