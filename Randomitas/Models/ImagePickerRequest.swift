//
//  ImagePickerRequest.swift
//  Randomitas
//
//  Created by Astor Ludueña on 28/11/2025.
//

internal import UIKit

struct ImagePickerRequest: Identifiable {
    let id = UUID()
    let sourceType: UIImagePickerController.SourceType
    
    /// Muestra la cámara en pantalla completa y la galería en un sheet
    var isFullScreen: Bool {
        sourceType == .camera
    }
    
    init(sourceType: UIImagePickerController.SourceType) {
        self.sourceType = sourceType
    }
}

