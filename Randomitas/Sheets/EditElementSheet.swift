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
    @State private var showingHiddenAncestorAlert = false
    @State private var hiddenAncestorAlertName = ""
    @State private var validationErrorMessage: String? = nil
    
    init(viewModel: RandomitasViewModel, isPresented: Binding<Bool>, folder: Folder, folderPath: [Int], moveCopyOperation: Binding<MoveCopyOperation?>) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self.folder = folder
        self.folderPath = folderPath
        self._moveCopyOperation = moveCopyOperation
        self._editedName = State(initialValue: folder.name)
        self._selectedImageData = State(initialValue: folder.imageData)
    }
    
    var currentFolder: Folder {
        viewModel.getFolderFromPath(folderPath) ?? folder
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Renombrar
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Nombre del elemento", text: $editedName)
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
                    
                    // Mostrar/Ocultar
                    Button(action: {
                        HapticManager.lightImpact()
                        if let ancestorName = viewModel.getHiddenAncestorName(at: folderPath) {
                            hiddenAncestorAlertName = ancestorName
                            showingHiddenAncestorAlert = true
                        } else {
                            viewModel.toggleFolderHidden(folder: currentFolder, path: folderPath)
                        }
                    }) {
                        HStack {
                            Image(systemName: currentFolder.isHidden ? "eye" : "eye.slash")
                                .foregroundStyle(currentFolder.isHidden ? .green : .orange)
                            Text(currentFolder.isHidden ? "Mostrar" : "Ocultar")
                                .foregroundStyle(currentFolder.isHidden ? .green : .orange)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Imagen
                    if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                        // Imagen existente - mostrar preview con menú contextual
                        Menu {
                            Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .camera) }) {
                                Label("Tomar foto", systemImage: "camera.fill")
                            }
                            Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .photoLibrary) }) {
                                Label("Seleccionar de galería", systemImage: "photo.fill")
                            }
                            Divider()
                            Button(role: .destructive, action: {
                                withAnimation {
                                    selectedImageData = nil
                                    hasImageChanged = true
                                }
                            }) {
                                Label("Eliminar imagen", systemImage: "trash")
                            }
                        } label: {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(12)
                        }
                    } else {
                        // Sin imagen - botón para agregar
                        Menu {
                            Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .camera) }) {
                                Label("Tomar foto", systemImage: "camera.fill")
                            }
                            Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .photoLibrary) }) {
                                Label("Seleccionar de galería", systemImage: "photo.fill")
                            }
                        } label: {
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundStyle(.primary)
                                Text("Agregar imagen")
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
                    }
                    
                    // Botón Confirmar Edición
                    Button(action: {
                        // Aplicar cambios
                        if editedName != folder.name {
                            let validator = FolderNameValidator()
                            let siblings: [Folder]
                            if folderPath.count >= 2, let parent = viewModel.getFolderFromPath(Array(folderPath.dropLast())) {
                                siblings = parent.subfolders.filter { $0.id != folder.id }
                            } else {
                                siblings = viewModel.folders.filter { $0.id != folder.id }
                            }
                            switch validator.validate(editedName, siblings: siblings) {
                            case .success(let validName):
                                viewModel.renameFolder(id: folder.id, newName: validName)
                            case .failure(let error):
                                validationErrorMessage = error.localizedDescription
                                HapticManager.error()
                                return
                            }
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
                }
                .padding(20)
            }
            .navigationTitle("Edición del Elemento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { isPresented = false }
                }
            }
            .alert("Nombre inválido", isPresented: Binding(
                get: { validationErrorMessage != nil },
                set: { if !$0 { validationErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    validationErrorMessage = nil
                }
            } message: {
                Text(validationErrorMessage ?? "")
            }
            // Cámara - cubierta en pantalla completa
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
            // Galería de fotos - modal
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
            .alert("Elemento Protegido", isPresented: $showingHiddenAncestorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Para modificar la visibilidad de este elemento, debes desocultar: \(hiddenAncestorAlertName)")
            }
        }
        .presentationDetents([selectedImageData != nil ? .fraction(0.75) : .fraction(0.55)])
    }
}
