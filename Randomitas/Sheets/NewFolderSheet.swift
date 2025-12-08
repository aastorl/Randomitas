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
    @Binding var isPresented: Bool
    @State var name: String = ""
    @State private var isFavorite: Bool = false
    @State private var imagePickerRequest: ImagePickerRequest?
    @State private var selectedImageData: Data?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Nombre de la carpeta", text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Toggle("Agregar a Favoritos", isOn: $isFavorite)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
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
                    if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        HStack {
                            Image(systemName: "photo")
                            Text("Seleccionar Imagen")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.addRootFolder(name: name.isEmpty ? "Sin nombre" : name, isFavorite: isFavorite, imageData: selectedImageData)
                    isPresented = false
                }) {
                    Text("Crear")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Nueva Carpeta")
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
    }
}
