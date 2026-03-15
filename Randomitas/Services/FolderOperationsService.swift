//
//  FolderOperationsService.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation

/// Domain operations for creating, deleting, moving and copying folders.
@MainActor
final class FolderOperationsService {
    private let repository: FolderRepositoryProtocol

    init(repository: FolderRepositoryProtocol) {
        self.repository = repository
    }

    func addRootFolder(name: String, imageData: Data?) -> Result<UUID, RepositoryError> {
        let id = repository.addRootFolder(name: name, imageData: imageData)
        return .success(id)
    }

    func addSubfolder(name: String, to folderPath: [Int], folders: [Folder], imageData: Data?) -> Result<UUID, RepositoryError> {
        guard let id = repository.addSubfolder(name: name, to: folderPath, folders: folders, imageData: imageData) else {
            return .failure(.notFound("carpeta padre"))
        }
        return .success(id)
    }

    func deleteRootFolder(id: UUID) {
        repository.deleteRootFolder(id: id)
    }

    func deleteSubfolder(id: UUID, from folderPath: [Int], folders: [Folder]) {
        repository.deleteSubfolder(id: id, from: folderPath, folders: folders)
    }

    func updateFolderImage(imageData: Data?, at folderPath: [Int], folders: [Folder]) -> Result<Void, RepositoryError> {
        let success = repository.updateFolderImage(imageData: imageData, at: folderPath, folders: folders)
        return success ? .success(()) : .failure(.notFound("carpeta"))
    }

    func renameFolder(id: UUID, newName: String) -> Result<Void, RepositoryError> {
        let success = repository.renameFolder(id: id, newName: newName)
        return success ? .success(()) : .failure(.notFound("carpeta"))
    }

    func moveFolderById(id: UUID, toFolderId targetFolderId: UUID?) {
        repository.moveFolderById(id: id, toFolderId: targetFolderId)
    }

    func moveFolder(id: UUID, to targetFolderPath: [Int], folders: [Folder]) {
        repository.moveFolder(id: id, to: targetFolderPath, folders: folders)
    }

    func copyFolderById(id: UUID, toFolderId targetFolderId: UUID?) {
        repository.copyFolderById(id: id, toFolderId: targetFolderId)
    }

    func copyFolder(id: UUID, to targetFolderPath: [Int], folders: [Folder]) {
        repository.copyFolder(id: id, to: targetFolderPath, folders: folders)
    }

    func batchDeleteRootFolders(ids: Set<UUID>) {
        repository.batchDeleteRootFolders(ids: ids)
    }

    func batchDeleteSubfolders(ids: Set<UUID>, from parentPath: [Int], folders: [Folder]) {
        repository.batchDeleteSubfolders(ids: ids, from: parentPath, folders: folders)
    }

    func batchToggleHiddenRoot(ids: Set<UUID>, favoritesStore: FavoritesStoreProtocol) {
        repository.batchToggleHiddenRoot(ids: ids, favoritesStore: favoritesStore)
    }

    func batchToggleHiddenSubfolders(ids: Set<UUID>, at parentPath: [Int], folders: [Folder], favoritesStore: FavoritesStoreProtocol) {
        repository.batchToggleHiddenSubfolders(ids: ids, at: parentPath, folders: folders, favoritesStore: favoritesStore)
    }
}
