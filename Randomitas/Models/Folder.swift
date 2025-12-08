//
//  Folder.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import Foundation

struct Folder: Identifiable, Codable {
    let id: UUID
    var name: String
    var subfolders: [Folder]
    var imageData: Data?
    var createdAt: Date
    var isHidden: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        subfolders: [Folder] = [],
        imageData: Data? = nil,
        createdAt: Date = Date(),
        isHidden: Bool = false
    ) {
        self.id = id
        self.name = name
        self.subfolders = subfolders
        self.imageData = imageData
        self.createdAt = createdAt
        self.isHidden = isHidden
    }
}
