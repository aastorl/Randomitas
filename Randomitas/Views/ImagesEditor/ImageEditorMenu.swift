//
//  ImageEditorMenu.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 18/11/2025.
//

import SwiftUI

struct ImageEditorMenu: View {
    @Binding var imageData: Data?
    @State var showImagePicker = false
    @State var showCamera = false
    @State var cameraPermissionDenied = false
    @State var photoPermissionDenied = false
    
    var body: some View {
        Menu {
            Button(action: { openCamera() }) {
                Label("Tomar foto", systemImage: "camera.fill")
            }
            
            Button(action: { openPhotoLibrary() }) {
                Label("Seleccionar de galería", systemImage: "photo.fill")
            }
            
            if imageData != nil {
                Divider()
                Button(role: .destructive, action: { deleteImage() }) {
                    Label("Eliminar imagen", systemImage: "trash.fill")
                }
            }
        } label: {
            Image(systemName: "photo")
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(
                onImagePicked: { image in
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        imageData = data
                    }
                },
                sourceType: .photoLibrary
            )
        }
        .sheet(isPresented: $showCamera) {
            ImagePickerView(
                onImagePicked: { image in
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        imageData = data
                    }
                },
                sourceType: .camera
            )
        }
        .alert("Permiso denegado", isPresented: $cameraPermissionDenied) {
            Button("OK") { }
        } message: {
            Text("Necesitas permitir el acceso a la cámara en Configuración")
        }
        .alert("Permiso denegado", isPresented: $photoPermissionDenied) {
            Button("OK") { }
        } message: {
            Text("Necesitas permitir el acceso a la galería en Configuración")
        }
    }
    
    private func openCamera() {
        PermissionManager.shared.requestCameraPermission { granted in
            if granted {
                showCamera = true
            } else {
                cameraPermissionDenied = true
            }
        }
    }
    
    private func openPhotoLibrary() {
        PermissionManager.shared.requestPhotoLibraryPermission { granted in
            if granted {
                showImagePicker = true
            } else {
                photoPermissionDenied = true
            }
        }
    }
    
    private func deleteImage() {
        imageData = nil
    }
}
