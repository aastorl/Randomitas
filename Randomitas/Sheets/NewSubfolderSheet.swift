//
//  NewSubfolderSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

internal import SwiftUI
import PhotosUI

struct NewSubfolderSheet: View {
    @ObservedObject var viewModel: RandomitasViewModel
    let folderPath: [Int]
    @Binding var isPresented: Bool
    @State var name: String = ""
    @State private var isFavorite: Bool = false
    @State private var imagePickerRequest: ImagePickerRequest?
    @State private var selectedImageData: Data?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
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
                    viewModel.addSubfolder(name: name.isEmpty ? "Sin nombre" : name, to: folderPath, isFavorite: isFavorite, imageData: selectedImageData)
                    isPresented = false
                }) {
                    Text("Crear")
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
            .navigationTitle("Nuevo Elemento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { isPresented = false }
                }
            }
            .sheet(item: $imagePickerRequest) { request in
                ImagePickerView(onImagePicked: { image in
                    let resizedImage = image.resized(toMaxDimension: 1024)
                    if let data = resizedImage.jpegData(compressionQuality: 0.8) {
                        selectedImageData = data
                    }
                }, sourceType: request.sourceType)
            }
        }
        .presentationDetents([.fraction(0.45)])
    }
}
