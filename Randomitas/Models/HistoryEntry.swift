//
//  HistoryEntry.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import Foundation

struct HistoryEntry: Identifiable {
    let id: UUID
    let itemName: String
    let path: String
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        itemName: String,
        path: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.itemName = itemName
        self.path = path
        self.timestamp = timestamp
    }
}
