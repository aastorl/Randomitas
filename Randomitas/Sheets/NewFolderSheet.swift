//
//  NewFolderSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

internal import SwiftUI
import PhotosUI

struct NewFolderSheet: View {
    @ObservedObject var viewModel: RandomitasViewModel
    var folderPath: [Int]? = nil
    @Binding var isPresented: Bool
    var batchMode: Bool = false // Activa la creación consecutiva
    
    @State var name: String = ""
    @State private var isFavorite: Bool = false
    @State private var imagePickerRequest: ImagePickerRequest?
    @State private var selectedImageData: Data?
    @State private var createdCount: Int = 0 // Contador de elementos creados en el lote
    @State private var createdNames: [String] = [] // Nombres de los elementos creados
    @State private var createdIds: [UUID] = [] // IDs de los elementos creados para deshacer
    @State private var showCreatedListPopup: Bool = false
    @State private var showDuplicateAlert: Bool = false
    @State private var showEmptyNameAlert: Bool = false
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(spacing: 20) {
                // Indicador del modo por lotes
                if batchMode && createdCount > 0 {
                    Button(action: {
                        showCreatedListPopup = true
                    }) {
                        HStack {
                            Image(systemName: "atom")
                                .foregroundColor(.green)
                            Text("\(createdCount) elemento\(createdCount > 1 ? "s" : "") creado\(createdCount > 1 ? "s" : "")")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .padding(.bottom, -10)
                }
                
                // Campos de entrada
                VStack(spacing: 15) {
                    TextField("Nombre del elemento", text: $name)
                        .focused($isNameFieldFocused)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Toggle("Agregar a Favoritos", isOn: $isFavorite)
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
                
                // Botón de creación
                Button(action: {
                    let validator = FolderNameValidator()
                    let siblings: [Folder]
                    if let path = folderPath, let parent = viewModel.getFolderFromPath(path) {
                        siblings = parent.subfolders
                    } else {
                        siblings = viewModel.folders
                    }

                    switch validator.validate(name, siblings: siblings) {
                    case .success(let validName):
                        // Crear el elemento
                        let newId: UUID?
                        if let path = folderPath {
                            newId = viewModel.addSubfolder(name: validName, to: path, isFavorite: isFavorite, imageData: selectedImageData)
                        } else {
                            newId = viewModel.addRootFolder(name: validName, isFavorite: isFavorite, imageData: selectedImageData)
                        }

                        if let id = newId {
                            createdIds.append(id)
                        }

                        HapticManager.success()

                        if batchMode {
                            // Reiniciar campos para la siguiente creación
                            createdCount += 1
                            createdNames.append(validName)
                            name = ""
                            isFavorite = false
                            selectedImageData = nil
                        } else {
                            isPresented = false
                        }
                    case .failure(let error):
                        HapticManager.error()
                        isNameFieldFocused = false
                        switch error {
                        case .emptyName:
                            showEmptyNameAlert = true
                        case .duplicateName:
                            showDuplicateAlert = true
                        }
                        return
                    }

                }) {
                    HStack {
                        Text(batchMode ? "Crear y Continuar" : "Crear")
                            .font(.headline)
                        if batchMode {
                            Image(systemName: "arrow.right")
                        }
                    }
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
            .navigationTitle(batchMode ? "Nuevo Elemento" : "Nuevo Elemento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(batchMode ? "Listo" : "Cancelar") { isPresented = false }
                }
                if batchMode {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.stack.3d.up")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            Text("Nuevo Elemento")
                                .font(.headline)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancelar") {
                            // Deshacer todas las creaciones en esta sesión del modo por lotes
                            for id in createdIds {
                                if let path = folderPath {
                                    viewModel.deleteSubfolder(id: id, from: path)
                                } else {
                                    viewModel.deleteRootFolder(id: id)
                                }
                            }
                            isPresented = false
                        }
                        .foregroundColor(.red)
                    }
                }
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
                    }
                }, sourceType: request.sourceType)
            }
            .alert("Nombre duplicado", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Ya existe un elemento con el mismo nombre")
            }
            .alert("Nombre requerido", isPresented: $showEmptyNameAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Por favor ingresa un nombre para el elemento")
            }
            .alert("Elementos Creados", isPresented: $showCreatedListPopup) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(createdNames.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
            }
        }
        .presentationDetents([selectedImageData != nil ? .fraction(0.65) : .fraction(0.45)])
        .onAppear {
            // Respuesta háptica: doble para lote posterior, simple al instante
            if batchMode {
                HapticManager.doubleLightImpact()
            } else {
                HapticManager.lightImpact()
            }
        }
    }
}
