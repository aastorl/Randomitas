//
//  ImagePickerRequest.swift
//  Randomitas
//
//  Created by Astor Ludueña on 28/11/2025.
//

import UIKit

struct ImagePickerRequest: Identifiable {
    let id = UUID()
    let sourceType: UIImagePickerController.SourceType
    
    /// Camera should be presented fullscreen, photo library as sheet
    var isFullScreen: Bool {
        sourceType == .camera
    }
    
    init(sourceType: UIImagePickerController.SourceType) {
        self.sourceType = sourceType
    }
}

