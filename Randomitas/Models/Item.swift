//
//  Item.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//


import Foundation

struct Item: Identifiable, Codable {
    let id: UUID
    var name: String
    var imageData: Data?
    var isFavorite: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        imageData: Data? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.imageData = imageData
        self.isFavorite = isFavorite
    }
}
