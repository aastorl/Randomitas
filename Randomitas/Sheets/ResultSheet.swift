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
    @Binding var showHiddenFavoriteAlert: Bool
    
    var currentFolder: Folder {
        if let foundFolder = viewModel.findFolder(at: path) {
            return foundFolder
        }
        return folder
    }
    
    
    var isFavorite: Bool {
        viewModel.isFolderFavorite(folderId: currentFolder.id)
    }
    @State var imagePickerRequest: ImagePickerRequest?
    @State private var selectedDetent: PresentationDetent = .height(280)
    @State private var showingHiddenAncestorAlert = false
    @State private var hiddenAncestorAlertName = ""
    
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
                            // Imagen grande con context menu (solo si tiene imagen)
                            if let imageData = currentFolder.imageData, let uiImage = UIImage(data: imageData) {
                                Menu {
                                    Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .camera) }) {
                                        Label("Tomar foto", systemImage: "camera.fill")
                                    }
                                    Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .photoLibrary) }) {
                                        Label("Seleccionar de galería", systemImage: "photo.fill")
                                    }
                                    Divider()
                                    Button(role: .destructive, action: {
                                        viewModel.updateFolderImage(imageData: nil, at: path)
                                    }) {
                                        Label("Eliminar imagen", systemImage: "trash")
                                    }
                                } label: {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .frame(height: 300)
                                        .clipped()
                                        .cornerRadius(16)
                                        .padding(.horizontal)
                                }
                            }
                            
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
                                                    viewModel.renameFolder(id: currentFolder.id, newName: editingName)
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
                                HStack(spacing: 8) {
                                    // Favorito
                                    Button(action: {
                                        HapticManager.lightImpact()
                                        showHiddenFavoriteAlert = viewModel.toggleFolderFavorite(folder: currentFolder, path: path)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: isFavorite ? "star.fill" : "star")
                                                .font(.subheadline)
                                            Text(isFavorite ? "Favorito" : "Agregar")
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 8)
                                        .background(isFavorite ? Color.yellow.opacity(0.2) : Color(.systemGray6))
                                        .foregroundColor(isFavorite ? .yellow : .primary)
                                        .cornerRadius(10)
                                    }
                                    
                                    // Ocultar
                                    Button(action: {
                                        HapticManager.lightImpact()
                                        viewModel.toggleFolderHidden(folder: currentFolder, path: path)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "eye.slash")
                                                .font(.subheadline)
                                            Text("Ocultar")
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 8)
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.orange)
                                        .cornerRadius(10)
                                    }
                                    
                                    // Agregar Imagen (solo si no tiene)
                                    if currentFolder.imageData == nil {
                                        Menu {
                                            Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .camera) }) {
                                                Label("Tomar foto", systemImage: "camera.fill")
                                            }
                                            Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .photoLibrary) }) {
                                                Label("Seleccionar de galería", systemImage: "photo.fill")
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "photo")
                                                    .font(.subheadline)
                                                Text("Imagen")
                                                    .font(.subheadline)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.7)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 8)
                                            .background(Color(.systemGray6))
                                            .foregroundColor(.primary)
                                            .cornerRadius(10)
                                        }
                                    }
                                }


                                // Abrir Carpeta
                                Button(action: {
                                    HapticManager.mediumImpact()
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
            // Camera - fullscreen cover
            .fullScreenCover(item: Binding(
                get: { imagePickerRequest?.isFullScreen == true ? imagePickerRequest : nil },
                set: { imagePickerRequest = $0 }
            )) { request in
                ImagePickerView(onImagePicked: { image in
                    let resizedImage = image.resized(toMaxDimension: 1024)
                    if let data = resizedImage.jpegData(compressionQuality: 0.8) {
                        viewModel.updateFolderImage(imageData: data, at: path)
                    }
                }, sourceType: request.sourceType)
                .ignoresSafeArea()
            }
            // Photo Library - sheet
            .sheet(item: Binding(
                get: { imagePickerRequest?.isFullScreen == false ? imagePickerRequest : nil },
                set: { imagePickerRequest = $0 }
            )) { request in
                ImagePickerView(onImagePicked: { image in
                    let resizedImage = image.resized(toMaxDimension: 1024)
                    if let data = resizedImage.jpegData(compressionQuality: 0.8) {
                        viewModel.updateFolderImage(imageData: data, at: path)
                    }
                }, sourceType: request.sourceType)
            }
        }
        .onAppear {
            selectedDetent = currentFolder.imageData != nil ? .height(620) : .height(280)
        }
        .onChange(of: currentFolder.imageData) { _, newValue in
            withAnimation {
                selectedDetent = newValue != nil ? .height(620) : .height(280)
            }
        }
        .presentationDetents(currentFolder.imageData != nil ? [.height(280), .height(620)] : [.height(280)], selection: $selectedDetent)
        .presentationContentInteraction(.scrolls)
        .alert("Elemento Oculto", isPresented: $showHiddenFavoriteAlert) {
            Button("Ok", role: .cancel) { }
        } message: {
            Text("Los elementos ocultos no pueden ser favoritos. Desoculta este elemento primero.")
        }
        .alert("Elemento Protegido", isPresented: $showingHiddenAncestorAlert) {
            Button("Ok", role: .cancel) { }
        } message: {
            Text("Para modificar la visibilidad de este elemento, debes desocultar: \(hiddenAncestorAlertName)")
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
                            viewModel.renameFolder(id: currentFolder.id, newName: editingName)
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
            HapticManager.lightImpact()
            showHiddenFavoriteAlert = viewModel.toggleFolderFavorite(folder: currentFolder, path: path)
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
