//
//  HistoryEntry.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import Foundation

struct HistoryEntry: Identifiable {
    let id: UUID
    let itemId: UUID // ID of the element for navigation
    let itemName: String
    let path: String
    let folderPath: [Int] // Numeric path for navigation
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        itemId: UUID,
        itemName: String,
        path: String,
        folderPath: [Int],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.itemId = itemId
        self.itemName = itemName
        self.path = path
        self.folderPath = folderPath
        self.timestamp = timestamp
    }
}
