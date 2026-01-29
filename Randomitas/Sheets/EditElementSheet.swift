//
//  EditElementSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña on 08/01/2026.
//

internal import SwiftUI

struct EditingInfo: Identifiable {
    let id: UUID
    let folder: Folder
    let path: [Int]
    
    init(folder: Folder, path: [Int]) {
        self.id = folder.id
        self.folder = folder
        self.path = path
    }
}

struct EditElementSheet: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @Binding var isPresented: Bool
    
    let folder: Folder
    let folderPath: [Int]
    
    @State private var editedName: String
    @State private var imagePickerRequest: ImagePickerRequest?
    @State private var selectedImageData: Data?
    @State private var hasImageChanged: Bool = false
    @Binding var moveCopyOperation: MoveCopyOperation?
    
    init(viewModel: RandomitasViewModel, isPresented: Binding<Bool>, folder: Folder, folderPath: [Int], moveCopyOperation: Binding<MoveCopyOperation?>) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self.folder = folder
        self.folderPath = folderPath
        self._moveCopyOperation = moveCopyOperation
        self._editedName = State(initialValue: folder.name)
        self._selectedImageData = State(initialValue: folder.imageData)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Renombrar
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Nombre del Elemento", text: $editedName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                // Mover/Copiar
                Menu {
                    Button(action: {
                        moveCopyOperation = MoveCopyOperation(items: [folder], sourceContainerPath: Array(folderPath.dropLast()), isCopy: false)
                        isPresented = false
                    }) {
                        Label("Mover", systemImage: "arrow.turn.up.right")
                    }
                    Button(action: {
                        moveCopyOperation = MoveCopyOperation(items: [folder], sourceContainerPath: Array(folderPath.dropLast()), isCopy: true)
                        isPresented = false
                    }) {
                        Label("Copiar", systemImage: "doc.on.doc")
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.turn.up.right")
                            .foregroundStyle(.primary)
                        Text("Mover/Copiar")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // Imagen - Opciones inteligentes
                Menu {
                    if selectedImageData != nil {
                        // Si tiene imagen: Editar y Eliminar
                        Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .camera) }) {
                            Label("Tomar foto", systemImage: "camera.fill")
                        }
                        Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .photoLibrary) }) {
                            Label("Seleccionar de galería", systemImage: "photo.fill")
                        }
                        Divider()
                        Button(role: .destructive, action: {
                            selectedImageData = nil
                            hasImageChanged = true
                        }) {
                            Label("Eliminar imagen", systemImage: "trash")
                        }
                    } else {
                        // Si no tiene imagen: Solo agregar
                        Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .camera) }) {
                            Label("Tomar foto", systemImage: "camera.fill")
                        }
                        Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .photoLibrary) }) {
                            Label("Seleccionar de galería", systemImage: "photo.fill")
                        }
                    }
                } label: {
                    HStack {
                        if selectedImageData != nil {
                            Image(systemName: "photo.fill")
                            // .foregroundStyle(.primary) - Removed to avoid potential conflicts or compilation issues with older modifiers if any
                            Text("Editar Imagen")
                                .foregroundStyle(.primary)
                        } else {
                            Image(systemName: "photo")
                                .foregroundStyle(.primary)
                            Text("Agregar Imagen")
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // Botón Confirmar Edición
                Button(action: {
                    // Aplicar cambios
                    if editedName != folder.name {
                        viewModel.renameFolder(id: folder.id, newName: editedName)
                    }
                    
                    if hasImageChanged || selectedImageData != folder.imageData {
                        viewModel.updateFolderImage(imageData: selectedImageData, at: folderPath)
                    }
                    
                    HapticManager.success()
                    isPresented = false
                }) {
                    Text("Confirmar Edición")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Edición del Elemento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { isPresented = false }
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
                        selectedImageData = data
                        hasImageChanged = true
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
                        selectedImageData = data
                        hasImageChanged = true
                    }
                }, sourceType: request.sourceType)
            }
        }
        .presentationDetents([.fraction(0.5)])
    }
}
