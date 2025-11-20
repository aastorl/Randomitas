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
    var items: [Item]
    var subfolders: [Folder]
    var imageData: Data?
    
    init(
        id: UUID = UUID(),
        name: String,
        items: [Item] = [],
        subfolders: [Folder] = [],
        imageData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.items = items
        self.subfolders = subfolders
        self.imageData = imageData
    }
}
