//
//  MoveCopyOperation.swift
//  Randomitas
//
//  Created by Astor Ludueña on 27/11/2025.
//

import Foundation

struct MoveCopyOperation: Identifiable {
    let id = UUID()
    let folder: Folder
    let sourcePath: [Int]
    let isCopy: Bool
    
    init(folder: Folder, sourcePath: [Int], isCopy: Bool) {
        self.folder = folder
        self.sourcePath = sourcePath
        self.isCopy = isCopy
    }
}
