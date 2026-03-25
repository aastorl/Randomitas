//
//  ServiceProtocols.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation
import CoreData

protocol FolderRepositoryProtocol: AnyObject {
    func loadRootFolders() -> [Folder]
    func getFolderEntity(at indices: [Int], folders: [Folder]) -> FolderEntity?
    func addRootFolder(name: String, imageData: Data?) -> UUID
    func addSubfolder(name: String, to folderPath: [Int], folders: [Folder], imageData: Data?) -> UUID?
    func deleteRootFolder(id: UUID)
    func deleteSubfolder(id: UUID, from folderPath: [Int], folders: [Folder])
    func updateFolderImage(imageData: Data?, at folderPath: [Int], folders: [Folder]) -> Bool
    func renameFolder(id: UUID, newName: String) -> Bool
    func toggleFolderHidden(at path: [Int], folders: [Folder], favoritesStore: FavoritesStoreProtocol)
    func setFolderHidden(at path: [Int], isHidden: Bool, folders: [Folder], favoritesStore: FavoritesStoreProtocol)
    func moveFolderById(id: UUID, toFolderId targetFolderId: UUID?)
    func moveFolder(id: UUID, to targetFolderPath: [Int], folders: [Folder])
    func copyFolderById(id: UUID, toFolderId targetFolderId: UUID?)
    func copyFolder(id: UUID, to targetFolderPath: [Int], folders: [Folder])
    func batchDeleteRootFolders(ids: Set<UUID>)
    func batchDeleteSubfolders(ids: Set<UUID>, from parentPath: [Int], folders: [Folder])
    func batchToggleHiddenRoot(ids: Set<UUID>, favoritesStore: FavoritesStoreProtocol)
    func batchToggleHiddenSubfolders(ids: Set<UUID>, at parentPath: [Int], folders: [Folder], favoritesStore: FavoritesStoreProtocol)
}

protocol FavoritesStoreProtocol: AnyObject {
    func loadFavorites() -> [FolderReference]
    func saveFavorite(id: UUID, name: String)
    func deleteFavorite(id: UUID)
}

protocol HistoryStoreProtocol: AnyObject {
    func loadHistory() -> [HistoryEntry]
    func saveHistory(_ entry: HistoryEntry)
    func deleteHistoryOlderThan(_ cutoff: Date)
    func deleteHistoryEntry(id: UUID)
    func deleteAllHistory()
}

protocol PreferencesStoreProtocol: AnyObject {
    func getSortType(for folderId: UUID?) -> RandomitasViewModel.SortType
    func setSortType(_ sortType: RandomitasViewModel.SortType, for folderId: UUID?)
    func getViewType(for folderId: UUID?) -> RandomitasViewModel.ViewType
    func setViewType(_ viewType: RandomitasViewModel.ViewType, for folderId: UUID?)
}
