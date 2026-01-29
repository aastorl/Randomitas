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
    var batchMode: Bool = false // New: enables consecutive creation
    
    @State var name: String = ""
    @State private var isFavorite: Bool = false
    @State private var imagePickerRequest: ImagePickerRequest?
    @State private var selectedImageData: Data?
    @State private var createdCount: Int = 0 // Track items created in batch mode
    @State private var showDuplicateAlert: Bool = false
    @State private var showEmptyNameAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Batch mode indicator
                if batchMode && createdCount > 0 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(createdCount) elemento\(createdCount > 1 ? "s" : "") creado\(createdCount > 1 ? "s" : "")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.bottom, -10) // Reduce extra space from indicator
                }
                
                // Input Fields
                VStack(spacing: 15) {
                    TextField("Nombre del Elemento", text: $name)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Toggle("Agregar a Favoritos", isOn: $isFavorite)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                // Image Picker
                Menu {
                    Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .camera) }) {
                        Label("Tomar foto", systemImage: "camera.fill")
                    }
                    Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .photoLibrary) }) {
                        Label("Seleccionar de galería", systemImage: "photo.fill")
                    }
                    if selectedImageData != nil {
                        Divider()
                        Button(role: .destructive, action: { selectedImageData = nil }) {
                            Label("Eliminar imagen", systemImage: "trash")
                        }
                    }
                } label: {
                    HStack {
                        if selectedImageData != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Imagen Agregada")
                                .foregroundStyle(.primary)
                        } else {
                            Image(systemName: "photo")
                                .foregroundStyle(.primary)
                            Text("Agregar Imagen")
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // Creation Button
                Button(action: {
                    // Check for empty name
                    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        HapticManager.error()
                        showEmptyNameAlert = true
                        return
                    }
                    
                    let nameToCheck = name
                    
                    // Check for duplicate name
                    let existingNames: [String]
                    if let path = folderPath {
                        if let parent = viewModel.getFolderFromPath(path) {
                            existingNames = parent.subfolders.map { $0.name.lowercased() }
                        } else {
                            existingNames = []
                        }
                    } else {
                        existingNames = viewModel.folders.map { $0.name.lowercased() }
                    }
                    
                    if existingNames.contains(nameToCheck.lowercased()) {
                        HapticManager.error()
                        showDuplicateAlert = true
                        return
                    }
                    
                    // Create the element
                    if let path = folderPath {
                        viewModel.addSubfolder(name: nameToCheck, to: path, isFavorite: isFavorite, imageData: selectedImageData)
                    } else {
                        viewModel.addRootFolder(name: nameToCheck, isFavorite: isFavorite, imageData: selectedImageData)
                    }
                    
                    HapticManager.success()
                    
                    if batchMode {
                        // Reset fields for next creation
                        createdCount += 1
                        name = ""
                        isFavorite = false
                        selectedImageData = nil
                    } else {
                        isPresented = false
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
            .navigationTitle(batchMode ? "Nuevo Elemento" : "Nuevo Elemento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(batchMode ? "Listo" : "Cancelar") { isPresented = false }
                }
                if batchMode {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            Text("Nuevo Elemento")
                                .font(.headline)
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
                        selectedImageData = data
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
                    }
                }, sourceType: request.sourceType)
            }
            .alert("Nombre duplicado", isPresented: $showDuplicateAlert) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text("Ya existe un elemento con el mismo nombre")
            }
            .alert("Nombre requerido", isPresented: $showEmptyNameAlert) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text("Por favor ingresa un nombre para el elemento")
            }
        }
        .presentationDetents([.fraction(0.45)])
        .onAppear {
            // Haptic feedback: double for batch mode, single for individual
            if batchMode {
                HapticManager.doubleLightImpact()
            } else {
                HapticManager.lightImpact()
            }
        }
    }
}
