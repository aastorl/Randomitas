//
//  FavoritesStore.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation
import CoreData
import os

/// Almacén de Core Data para favoritos. Devuelve las referencias sin duplicados y ordenadas por nombre.
@MainActor
final class FavoritesStore: FavoritesStoreProtocol {
    private let coreDataStack: CoreDataStack
    private let normalizeName: (String) -> String
    private let logger = Logger(subsystem: "Randomitas", category: "FavoritesStore")

    init(coreDataStack: CoreDataStack, normalizeName: @escaping (String) -> String) {
        self.coreDataStack = coreDataStack
        self.normalizeName = normalizeName
    }

    func loadFavorites() -> [FolderReference] {
        let request = NSFetchRequest<FolderFavoritesEntity>(entityName: "FolderFavoritesEntity")
        do {
            let entities = try coreDataStack.context.fetch(request)
            let allFolderFavorites = entities.compactMap { entity -> FolderReference? in
                guard let id = entity.folderId, let name = entity.folderName else { return nil }
                return FolderReference(id: id, name: name)
            }

            let uniqueFolderFavorites = Dictionary(grouping: allFolderFavorites, by: { $0.id })
                .compactMap { $0.value.first }
                .sorted {
                    normalizeName($0.name).localizedStandardCompare(normalizeName($1.name)) == .orderedAscending
                }

            return uniqueFolderFavorites
        } catch {
            logger.error("Error: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func saveFavorite(id: UUID, name: String) {
        let fav = NSEntityDescription.insertNewObject(forEntityName: "FolderFavoritesEntity", into: coreDataStack.context) as! FolderFavoritesEntity
        fav.id = UUID()
        fav.folderId = id
        fav.folderName = name
        coreDataStack.save()
    }

    func deleteFavorite(id: UUID) {
        let request = NSFetchRequest<FolderFavoritesEntity>(entityName: "FolderFavoritesEntity")
        request.predicate = NSPredicate(format: "folderId == %@", id as CVarArg)
        do {
            let favs = try coreDataStack.context.fetch(request)
            favs.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
        } catch {
            logger.error("Error: \(error.localizedDescription, privacy: .public)")
        }
    }
}
