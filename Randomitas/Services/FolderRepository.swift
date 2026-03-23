//
//  FolderRepository.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation
import CoreData
import os

/// Repositorio de Core Data para carpetas. Devuelve las carpetas raíz ordenadas y sin duplicados.
@MainActor
final class FolderRepository: FolderRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    private let normalizeName: (String) -> String
    private let logger = Logger(subsystem: "Randomitas", category: "FolderRepository")
    private let imageStore: ImageStore

    init(coreDataStack: CoreDataStack, normalizeName: @escaping (String) -> String, imageStore: ImageStore = .shared) {
        self.coreDataStack = coreDataStack
        self.normalizeName = normalizeName
        self.imageStore = imageStore
    }

    func loadRootFolders() -> [Folder] {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "parent == nil")

        do {
            let entities = try coreDataStack.context.fetch(request)
            let sorted = entities.sorted {
                normalizeName($0.name ?? "").localizedStandardCompare(normalizeName($1.name ?? "")) == .orderedAscending
            }
            return sorted.map { convertToFolder($0) }
        } catch {
            logger.error("Error cargando carpetas: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func getFolderEntity(at indices: [Int], folders: [Folder]) -> FolderEntity? {
        guard !indices.isEmpty else {
            logger.error("Path vacío")
            return nil
        }

        guard indices[0] < folders.count else {
            logger.error("Índice raíz fuera de rango: \(indices[0]) >= \(folders.count)")
            return nil
        }

        let rootFolderId = folders[indices[0]].id
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@", rootFolderId as CVarArg)

        do {
            guard var current = try coreDataStack.context.fetch(request).first else {
                logger.error("No se encontró carpeta raíz con ID: \(rootFolderId.uuidString, privacy: .public)")
                return nil
            }
            logger.info("Carpeta encontrada en Core Data: \(current.name ?? "", privacy: .public)")

            for i in indices.dropFirst() {
                let subfoldersArray = (current.subfolders as? Set<FolderEntity>)?
                    .sorted {
                        normalizeName($0.name ?? "").localizedStandardCompare(normalizeName($1.name ?? "")) == .orderedAscending
                    } ?? []

                guard i < subfoldersArray.count else {
                    logger.error("Subcarpeta en índice \(i) no encontrada (total: \(subfoldersArray.count))")
                    return nil
                }
                current = subfoldersArray[i]
                logger.info("Navegado a subcarpeta: \(current.name ?? "", privacy: .public)")
            }

            return current
        } catch {
            logger.error("Error en getFolderEntity: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func addRootFolder(name: String, imageData: Data?) -> UUID {
        let folder = NSEntityDescription.insertNewObject(forEntityName: "FolderEntity", into: coreDataStack.context) as! FolderEntity
        let newFolderId = UUID()
        folder.id = newFolderId
        folder.name = name
        if let imageData = imageData, let reference = imageStore.saveImageData(imageData) {
            folder.imageData = imageStore.encodeReference(reference)
        } else {
            folder.imageData = nil
        }
        folder.createdAt = Date()
        coreDataStack.save()
        coreDataStack.refresh()
        return newFolderId
    }

    func addSubfolder(name: String, to folderPath: [Int], folders: [Folder], imageData: Data?) -> UUID? {
        guard let parent = getFolderEntity(at: folderPath, folders: folders) else {
            logger.error("No se encontró carpeta padre")
            return nil
        }
        logger.info("Creando subcarpeta '\(name, privacy: .public)' en '\(parent.name ?? "sin nombre", privacy: .public)'")

        let subfolder = NSEntityDescription.insertNewObject(forEntityName: "FolderEntity", into: coreDataStack.context) as! FolderEntity
        let newFolderId = UUID()
        subfolder.id = newFolderId
        subfolder.name = name
        subfolder.parent = parent
        if let imageData = imageData, let reference = imageStore.saveImageData(imageData) {
            subfolder.imageData = imageStore.encodeReference(reference)
        } else {
            subfolder.imageData = nil
        }
        subfolder.createdAt = Date()

        logger.info("Parent asignado: \(parent.name ?? "", privacy: .public)")
        coreDataStack.save()
        coreDataStack.refresh()
        return newFolderId
    }

    func deleteRootFolder(id: UUID) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@ AND parent == nil", id as CVarArg)
        do {
            let folders = try coreDataStack.context.fetch(request)
            folders.forEach { deleteImages(in: $0) }
            folders.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
            coreDataStack.refresh()
        } catch {
            logger.error("Error: \(error.localizedDescription, privacy: .public)")
        }
    }

    func deleteSubfolder(id: UUID, from folderPath: [Int], folders: [Folder]) {
        guard let parent = getFolderEntity(at: folderPath, folders: folders) else { return }
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@ AND parent == %@", id as CVarArg, parent)
        do {
            let subs = try coreDataStack.context.fetch(request)
            subs.forEach { deleteImages(in: $0) }
            subs.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
            coreDataStack.refresh()
        } catch {
            logger.error("Error: \(error.localizedDescription, privacy: .public)")
        }
    }

    func updateFolderImage(imageData: Data?, at folderPath: [Int], folders: [Folder]) -> Bool {
        guard let entity = getFolderEntity(at: folderPath, folders: folders) else {
            logger.error("No se encontró la carpeta para actualizar imagen en path: \(folderPath, privacy: .public)")
            return false
        }
        if let existingData = entity.imageData, let oldRef = imageStore.decodeReference(existingData) {
            imageStore.deleteImage(reference: oldRef)
        }
        if let imageData = imageData, let reference = imageStore.saveImageData(imageData) {
            entity.imageData = imageStore.encodeReference(reference)
        } else {
            entity.imageData = nil
        }
        coreDataStack.save()
        coreDataStack.refresh()
        return true
    }

    func renameFolder(id: UUID, newName: String) -> Bool {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let folder = try coreDataStack.context.fetch(request).first {
                folder.name = newName
                coreDataStack.save()
                coreDataStack.refresh()
                return true
            }
        } catch {
            logger.error("Error renombrando carpeta: \(error.localizedDescription, privacy: .public)")
        }
        return false
    }

    func toggleFolderHidden(at path: [Int], folders: [Folder], favoritesStore: FavoritesStoreProtocol) {
        guard let entity = getFolderEntity(at: path, folders: folders) else { return }
        let newHiddenState = !entity.isHidden
        setFolderHidden(entity: entity, isHidden: newHiddenState, favoritesStore: favoritesStore)
        coreDataStack.save()
        coreDataStack.refresh()
    }

    func setFolderHidden(at path: [Int], isHidden: Bool, folders: [Folder], favoritesStore: FavoritesStoreProtocol) {
        guard let entity = getFolderEntity(at: path, folders: folders) else { return }
        setFolderHidden(entity: entity, isHidden: isHidden, favoritesStore: favoritesStore)
        coreDataStack.save()
        coreDataStack.refresh()
    }

    func moveFolderById(id: UUID, toFolderId targetFolderId: UUID?) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            if let folder = try coreDataStack.context.fetch(request).first {
                if let targetId = targetFolderId {
                    let targetRequest = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
                    targetRequest.predicate = NSPredicate(format: "id == %@", targetId as CVarArg)

                    if let targetFolder = try coreDataStack.context.fetch(targetRequest).first {
                        folder.parent = targetFolder
                    } else {
                        logger.error("Error: Target folder with id \(targetId.uuidString, privacy: .public) not found")
                        return
                    }
                } else {
                    folder.parent = nil
                }
                folder.isHidden = false
                coreDataStack.save()
                coreDataStack.refresh()
            }
        } catch {
            logger.error("Error moving folder: \(error.localizedDescription, privacy: .public)")
        }
    }

    func moveFolder(id: UUID, to targetFolderPath: [Int], folders: [Folder]) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            if let folder = try coreDataStack.context.fetch(request).first {
                if targetFolderPath.isEmpty {
                    folder.parent = nil
                } else if let targetFolder = getFolderEntity(at: targetFolderPath, folders: folders) {
                    folder.parent = targetFolder
                } else {
                    return
                }
                folder.isHidden = false
                coreDataStack.save()
                coreDataStack.refresh()
            }
        } catch {
            logger.error("Error moving folder: \(error.localizedDescription, privacy: .public)")
        }
    }

    func copyFolderById(id: UUID, toFolderId targetFolderId: UUID?) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            if let originalFolder = try coreDataStack.context.fetch(request).first {
                var targetParent: FolderEntity? = nil

                if let targetId = targetFolderId {
                    let targetRequest = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
                    targetRequest.predicate = NSPredicate(format: "id == %@", targetId as CVarArg)
                    targetParent = try coreDataStack.context.fetch(targetRequest).first
                }

                copyFolderRecursive(original: originalFolder, parent: targetParent)
                coreDataStack.save()
                coreDataStack.refresh()
            }
        } catch {
            logger.error("Error copying folder: \(error.localizedDescription, privacy: .public)")
        }
    }

    func copyFolder(id: UUID, to targetFolderPath: [Int], folders: [Folder]) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            if let originalFolder = try coreDataStack.context.fetch(request).first {
                var targetParent: FolderEntity? = nil
                if !targetFolderPath.isEmpty {
                    targetParent = getFolderEntity(at: targetFolderPath, folders: folders)
                }

                copyFolderRecursive(original: originalFolder, parent: targetParent)
                coreDataStack.save()
                coreDataStack.refresh()
            }
        } catch {
            logger.error("Error copying folder: \(error.localizedDescription, privacy: .public)")
        }
    }

    func batchDeleteRootFolders(ids: Set<UUID>) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id IN %@ AND parent == nil", ids as CVarArg)

        do {
            let foldersToDelete = try coreDataStack.context.fetch(request)
            foldersToDelete.forEach { deleteImages(in: $0) }
            foldersToDelete.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
            coreDataStack.refresh()
        } catch {
            logger.error("Error batch deleting root folders: \(error.localizedDescription, privacy: .public)")
        }
    }

    func batchDeleteSubfolders(ids: Set<UUID>, from parentPath: [Int], folders: [Folder]) {
        guard let parent = getFolderEntity(at: parentPath, folders: folders) else { return }
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id IN %@ AND parent == %@", ids as CVarArg, parent)

        do {
            let subs = try coreDataStack.context.fetch(request)
            subs.forEach { deleteImages(in: $0) }
            subs.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
            coreDataStack.refresh()
        } catch {
            logger.error("Error batch deleting subfolders: \(error.localizedDescription, privacy: .public)")
        }
    }

    func batchToggleHiddenRoot(ids: Set<UUID>, favoritesStore: FavoritesStoreProtocol) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id IN %@ AND parent == nil", ids as CVarArg)

        do {
            let foldersToToggle = try coreDataStack.context.fetch(request)
            for folder in foldersToToggle {
                let newState = !folder.isHidden
                setFolderHidden(entity: folder, isHidden: newState, favoritesStore: favoritesStore)
            }
            coreDataStack.save()
            coreDataStack.refresh()
        } catch {
            logger.error("Error batch toggling hidden root: \(error.localizedDescription, privacy: .public)")
        }
    }

    func batchToggleHiddenSubfolders(ids: Set<UUID>, at parentPath: [Int], folders: [Folder], favoritesStore: FavoritesStoreProtocol) {
        guard let parent = getFolderEntity(at: parentPath, folders: folders) else { return }
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id IN %@ AND parent == %@", ids as CVarArg, parent)

        do {
            let subs = try coreDataStack.context.fetch(request)
            for folder in subs {
                let newState = !folder.isHidden
                setFolderHidden(entity: folder, isHidden: newState, favoritesStore: favoritesStore)
            }
            coreDataStack.save()
            coreDataStack.refresh()
        } catch {
            logger.error("Error batch toggling hidden subfolders: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func setFolderHidden(entity: FolderEntity, isHidden: Bool, favoritesStore: FavoritesStoreProtocol) {
        entity.isHidden = isHidden

        if isHidden {
            if let folderId = entity.id {
                favoritesStore.deleteFavorite(id: folderId)
            }
            removeChildrenFavoritesAndUnhide(entity: entity, favoritesStore: favoritesStore)
        }
    }

    private func removeChildrenFavoritesAndUnhide(entity: FolderEntity, favoritesStore: FavoritesStoreProtocol) {
        guard let subfolders = entity.subfolders as? Set<FolderEntity> else { return }
        for child in subfolders {
            child.isHidden = false
            if let childId = child.id {
                favoritesStore.deleteFavorite(id: childId)
            }
            removeChildrenFavoritesAndUnhide(entity: child, favoritesStore: favoritesStore)
        }
    }

    private func copyFolderRecursive(original: FolderEntity, parent: FolderEntity?) {
        let newFolder = NSEntityDescription.insertNewObject(forEntityName: "FolderEntity", into: coreDataStack.context) as! FolderEntity
        newFolder.id = UUID()
        newFolder.name = original.name
        if let originalData = original.imageData {
            if let reference = imageStore.decodeReference(originalData),
               let imageData = imageStore.loadImageData(reference: reference),
               let newRef = imageStore.saveImageData(imageData) {
                newFolder.imageData = imageStore.encodeReference(newRef)
            } else if let newRef = imageStore.saveImageData(originalData) {
                newFolder.imageData = imageStore.encodeReference(newRef)
            } else {
                newFolder.imageData = nil
            }
        }
        newFolder.isHidden = false
        newFolder.parent = parent

        if let subfolders = original.subfolders as? Set<FolderEntity> {
            for sub in subfolders {
                copyFolderRecursive(original: sub, parent: newFolder)
            }
        }
    }

    private func convertToFolder(_ entity: FolderEntity) -> Folder {
        var subfolders: [Folder] = []
        if let subfoldersSet = entity.subfolders as? Set<FolderEntity> {
            let uniqueSubfolders = Dictionary(grouping: subfoldersSet, by: { $0.id ?? UUID() })
                .compactMap { $0.value.first }

            subfolders = uniqueSubfolders.map { convertToFolder($0) }
                .sorted {
                    normalizeName($0.name).localizedStandardCompare(normalizeName($1.name)) == .orderedAscending
                }
            if !subfolders.isEmpty {
                logger.info("Subcarpetas encontradas en '\(entity.name ?? "", privacy: .public)': \(subfolders.count)")
            }
        }

        let resolvedImageData: Data?
        if let data = entity.imageData, let reference = imageStore.decodeReference(data) {
            resolvedImageData = imageStore.loadImageData(reference: reference)
        } else {
            resolvedImageData = entity.imageData
        }

        return Folder(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            subfolders: subfolders,
            imageData: resolvedImageData,
            createdAt: entity.createdAt ?? Date(),
            isHidden: entity.isHidden
        )
    }

    private func deleteImages(in entity: FolderEntity) {
        if let data = entity.imageData, let reference = imageStore.decodeReference(data) {
            imageStore.deleteImage(reference: reference)
        }
        if let subfolders = entity.subfolders as? Set<FolderEntity> {
            for child in subfolders {
                deleteImages(in: child)
            }
        }
    }
}
