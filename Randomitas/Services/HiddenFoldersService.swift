//
//  HiddenFoldersService.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation

/// Encapsulates hidden-folder rules (ancestors, batch updates).
@MainActor
final class HiddenFoldersService {
    private let folderRepository: FolderRepositoryProtocol
    private let favoritesStore: FavoritesStoreProtocol

    init(folderRepository: FolderRepositoryProtocol, favoritesStore: FavoritesStoreProtocol) {
        self.folderRepository = folderRepository
        self.favoritesStore = favoritesStore
    }

    func toggleHidden(at path: [Int], folders: [Folder]) {
        folderRepository.toggleFolderHidden(at: path, folders: folders, favoritesStore: favoritesStore)
    }

    func setHidden(at path: [Int], isHidden: Bool, folders: [Folder]) {
        folderRepository.setFolderHidden(at: path, isHidden: isHidden, folders: folders, favoritesStore: favoritesStore)
    }

    func isHiddenOrHasHiddenAncestor(at path: [Int], folders: [Folder]) -> Bool {
        for i in 1...path.count {
            let ancestorPath = Array(path.prefix(i))
            if let entity = folderRepository.getFolderEntity(at: ancestorPath, folders: folders), entity.isHidden {
                return true
            }
        }
        return false
    }

    func hiddenAncestorName(at path: [Int], folders: [Folder]) -> String? {
        guard path.count >= 2 else { return nil }
        for i in 1..<path.count {
            let ancestorPath = Array(path.prefix(i))
            if let entity = folderRepository.getFolderEntity(at: ancestorPath, folders: folders), entity.isHidden {
                return entity.name ?? "Elemento"
            }
        }
        return nil
    }

    func isFolderHidden(folderId: UUID, folders: [Folder]) -> Bool {
        FolderTree.isFolderHiddenRecursive(folders: folders, targetId: folderId)
    }

    func hiddenFolders(in folders: [Folder]) -> [(folder: Folder, path: [Int])] {
        FolderTree.collectHiddenFolders(from: folders)
    }
}
