//
//  FavoritesService.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation

struct ToggleFavoriteResult {
    let favorites: [FolderReference]
    let showHiddenAlert: Bool
}

/// Domain rules for favorites (e.g., hidden elements cannot be favorited).
@MainActor
final class FavoritesService {
    private let store: FavoritesStoreProtocol
    private let hiddenService: HiddenFoldersService

    init(store: FavoritesStoreProtocol, hiddenService: HiddenFoldersService) {
        self.store = store
        self.hiddenService = hiddenService
    }

    func loadFavorites() -> [FolderReference] {
        store.loadFavorites()
    }

    func toggleFavorite(folder: Folder, path: [Int], folders: [Folder], currentFavorites: [FolderReference]) -> ToggleFavoriteResult {
        if currentFavorites.contains(where: { $0.id == folder.id }) {
            store.deleteFavorite(id: folder.id)
            return ToggleFavoriteResult(favorites: store.loadFavorites(), showHiddenAlert: false)
        }

        if hiddenService.isHiddenOrHasHiddenAncestor(at: path, folders: folders) {
            return ToggleFavoriteResult(favorites: currentFavorites, showHiddenAlert: true)
        }

        store.saveFavorite(id: folder.id, name: folder.name)
        return ToggleFavoriteResult(favorites: store.loadFavorites(), showHiddenAlert: false)
    }

    func removeFavorites(at offsets: IndexSet, currentFavorites: [FolderReference]) -> [FolderReference] {
        offsets.forEach { index in
            let folderRef = currentFavorites[index]
            store.deleteFavorite(id: folderRef.id)
        }
        return store.loadFavorites()
    }
}
