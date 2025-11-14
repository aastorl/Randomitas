//
//  RandomitasViewModel.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import Foundation
internal import Combine

class RandomitasViewModel: ObservableObject {
    @Published var folders: [Folder] = []
    @Published var favorites: [(ItemReference, String)] = []
    @Published var folderFavorites: [(FolderReference, [Int])] = []
    @Published var history: [HistoryEntry] = []
    @Published var viewType: ViewType = .list
    
    private let historyLimit: TimeInterval = 86400 // 24 horas
    
    enum ViewType: String {
        case list = "Lista"
        case grid = "Cuadrícula"
        case gallery = "Galería"
    }
    
    // MARK: - Folders Management (Root Level)
    func addRootFolder(name: String) {
        folders.append(Folder(name: name))
    }
    
    func deleteRootFolder(id: UUID) {
        folders.removeAll { $0.id == id }
    }
    
    // MARK: - Subfolder Management
    func addSubfolder(name: String, to folderPath: [Int]) {
        var current = folders
        addSubfolderRecursive(&current, name: name, at: folderPath)
        folders = current
    }
    
    private func addSubfolderRecursive(_ folders: inout [Folder], name: String, at indices: [Int]) {
        guard !indices.isEmpty else { return }
        
        if indices.count == 1 {
            if let lastIdx = indices.first {
                folders[lastIdx].subfolders.append(Folder(name: name))
            }
        } else {
            let firstIndex = indices.first!
            let remainingIndices = Array(indices.dropFirst())
            addSubfolderRecursive(&folders[firstIndex].subfolders, name: name, at: remainingIndices)
        }
    }
    
    func deleteSubfolder(id: UUID, from folderPath: [Int]) {
        var current = folders
        deleteSubfolderRecursive(&current, id: id, at: folderPath)
        folders = current
    }
    
    private func deleteSubfolderRecursive(_ folders: inout [Folder], id: UUID, at indices: [Int]) {
        guard !indices.isEmpty else { return }
        
        if indices.count == 1 {
            if let lastIdx = indices.first {
                folders[lastIdx].subfolders.removeAll { $0.id == id }
            }
        } else {
            let firstIndex = indices.first!
            let remainingIndices = Array(indices.dropFirst())
            deleteSubfolderRecursive(&folders[firstIndex].subfolders, id: id, at: remainingIndices)
        }
    }
    
    // MARK: - Items Management (Only inside folders)
    func addItem(name: String, to folderPath: [Int]) {
        var current = folders
        addItemRecursive(&current, name: name, at: folderPath)
        folders = current
    }
    
    private func addItemRecursive(_ folders: inout [Folder], name: String, at indices: [Int]) {
        guard !indices.isEmpty else { return }
        
        if indices.count == 1 {
            if let lastIdx = indices.first {
                folders[lastIdx].items.append(Item(name: name))
            }
        } else {
            let firstIndex = indices.first!
            let remainingIndices = Array(indices.dropFirst())
            addItemRecursive(&folders[firstIndex].subfolders, name: name, at: remainingIndices)
        }
    }
    
    func deleteItem(id: UUID, from folderPath: [Int]) {
        var current = folders
        deleteItemRecursive(&current, id: id, at: folderPath)
        folders = current
    }
    
    private func deleteItemRecursive(_ folders: inout [Folder], id: UUID, at indices: [Int]) {
        guard !indices.isEmpty else { return }
        
        if indices.count == 1 {
            if let lastIdx = indices.first {
                folders[lastIdx].items.removeAll { $0.id == id }
            }
        } else {
            let firstIndex = indices.first!
            let remainingIndices = Array(indices.dropFirst())
            deleteItemRecursive(&folders[firstIndex].subfolders, id: id, at: remainingIndices)
        }
    }
    
    // MARK: - Randomization
    func randomizeFolder(at indices: [Int]) -> (item: Item, path: String)? {
        guard !indices.isEmpty else { return nil }
        
        let folder = getFolderAtPath(indices)
        return randomizeFolderInternal(folder, indices: indices)
    }
    
    private func getFolderAtPath(_ indices: [Int]) -> Folder? {
        guard !indices.isEmpty else { return nil }
        guard indices[0] < folders.count else { return nil }
        
        var current = folders[indices[0]]
        
        for i in 1..<indices.count {
            guard indices[i] < current.subfolders.count else { return nil }
            current = current.subfolders[indices[i]]
        }
        
        return current
    }
    
    private func randomizeFolderInternal(_ folder: Folder?, indices: [Int]) -> (item: Item, path: String)? {
        guard let folder = folder else { return nil }
        
        var allItems: [(Item, String)] = []
        collectItems(from: folder, prefix: folder.name, into: &allItems)
        
        guard let selected = allItems.randomElement() else { return nil }
        
        let entry = HistoryEntry(itemName: selected.0.name, path: selected.1)
        history.append(entry)
        addToFavorites(item: selected.0, path: selected.1)
        
        return selected
    }
    
    private func collectItems(
        from folder: Folder,
        prefix: String,
        into items: inout [(Item, String)]
    ) {
        for item in folder.items {
            items.append((item, prefix + " > " + item.name))
        }
        for subfolder in folder.subfolders {
            collectItems(from: subfolder, prefix: prefix + " > " + subfolder.name, into: &items)
        }
    }
    
    // MARK: - Folder State Check
    func folderHasItems(at indices: [Int]) -> Bool {
        guard let folder = getFolderAtPath(indices) else { return false }
        return !folder.items.isEmpty
    }
    
    func folderHasSubfolders(at indices: [Int]) -> Bool {
        guard let folder = getFolderAtPath(indices) else { return false }
        return !folder.subfolders.isEmpty
    }
    
    func canAddSubfolder(at indices: [Int]) -> Bool {
        guard let folder = getFolderAtPath(indices) else { return false }
        return folder.items.isEmpty // Solo puede tener subcarpetas si NO tiene items
    }
    
    func canAddItems(at indices: [Int]) -> Bool {
        guard let folder = getFolderAtPath(indices) else { return false }
        return folder.subfolders.isEmpty // Solo puede tener items si NO tiene subcarpetas
    }
    
    // MARK: - Favorites
    func toggleFavorite(item: Item, path: String) {
        if let index = favorites.firstIndex(where: { $0.0.id == item.id && $0.1 == path }) {
            favorites.remove(at: index)
        } else {
            favorites.append((ItemReference(id: item.id, name: item.name), path))
        }
    }
    
    private func addToFavorites(item: Item, path: String) {
        if !favorites.contains(where: { $0.0.id == item.id && $0.1 == path }) {
            favorites.append((ItemReference(id: item.id, name: item.name), path))
        }
    }
    
    func isFavorite(itemId: UUID, path: String) -> Bool {
        favorites.contains { $0.0.id == itemId && $0.1 == path }
    }
    
    // MARK: - Folder Favorites
    func toggleFolderFavorite(folder: Folder, path: [Int]) {
        if let index = folderFavorites.firstIndex(where: { $0.0.id == folder.id }) {
            folderFavorites.remove(at: index)
        } else {
            folderFavorites.append((FolderReference(id: folder.id, name: folder.name), path))
        }
    }
    
    func isFolderFavorite(folderId: UUID) -> Bool {
        folderFavorites.contains { $0.0.id == folderId }
    }
    
    // MARK: - History
    func cleanOldHistory() {
        let cutoffDate = Date().addingTimeInterval(-historyLimit)
        history.removeAll { $0.timestamp < cutoffDate }
    }
    
    // MARK: - Clear Data
    func deleteAllFolders() {
        folders.removeAll()
    }
}
