//
//  MoveCopyOperation.swift
//  Randomitas
//
//  Created by Astor Ludueña on 27/11/2025.
//

import Foundation

struct MoveCopyOperation: Identifiable {
    let id = UUID()
    let items: [Folder]
    let sourceContainerPath: [Int]
    let isCopy: Bool
    
    init(items: [Folder], sourceContainerPath: [Int], isCopy: Bool) {
        self.items = items
        self.sourceContainerPath = sourceContainerPath
        self.isCopy = isCopy
    }
}
