//
//  RandomitasViewModel.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import Foundation
import CoreData
internal import Combine
internal import SwiftUI

class RandomitasViewModel: ObservableObject {
    @Published var folders: [Folder] = []
    
    // Virtual Root Folder for Unified Architecture
    var rootFolder: Folder {
        Folder(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, name: "Randomitas", subfolders: folders, imageData: nil, createdAt: Date(), isHidden: false)
    }
    
    @Published var folderFavorites: [(FolderReference, [Int])] = []
    @Published var history: [HistoryEntry] = []
    @Published var viewType: ViewType = .list
    
    private let historyLimit: TimeInterval = 86400
    private let coreDataStack = CoreDataStack.shared
    private let userDefaults = UserDefaults.standard
    
    enum ViewType: String {
        case list = "Lista"
        case grid = "Cuadrícula"
        case gallery = "Galería"
    }
    
    enum SortType: String {
        case nameAsc = "name_asc"
        case nameDesc = "name_desc"
        case dateNewest = "date_newest"
        case dateOldest = "date_oldest"
    }
    
    init() {
        loadAllData()
    }
    
    private func loadAllData() {
        loadFolders()
        loadFolderFavorites()
        loadHistory()
        
        // Limpieza deshabilitada - causaba que los elementos ocultos se borraran al reiniciar
        // cleanAllHiddenSubfolders()
    }
    
    private func loadFolders() {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "parent == nil")
        
        do {
            let entities = try coreDataStack.context.fetch(request)
            // Ordenar por nombre para consistencia
            let sorted = entities.sorted {
                self.sortName(for: $0.name ?? "").localizedStandardCompare(self.sortName(for: $1.name ?? "")) == .orderedAscending
            }
            folders = sorted.map { convertToFolder($0) }
            print("Carpetas raíz cargadas: \(folders.count)")
        } catch {
            print("Error cargando carpetas: \(error)")
        }
    }
    

    private func loadFolderFavorites() {
        let request = NSFetchRequest<FolderFavoritesEntity>(entityName: "FolderFavoritesEntity")
        do {
            let entities = try coreDataStack.context.fetch(request)
            let allFolderFavorites = entities.compactMap { entity -> (FolderReference, [Int])? in
                guard let id = entity.folderId, let name = entity.folderName, let data = entity.pathData else { return nil }
                if let path = try? JSONDecoder().decode([Int].self, from: data) {
                    return (FolderReference(id: id, name: name), path)
                }
                return nil
            }
            
            // Deduplicate by Folder ID
            let uniqueFolderFavorites = Dictionary(grouping: allFolderFavorites, by: { $0.0.id })
                .compactMap { $0.value.first }
                .sorted {
                    self.sortName(for: $0.0.name).localizedStandardCompare(self.sortName(for: $1.0.name)) == .orderedAscending
                }
            
            folderFavorites = uniqueFolderFavorites
        } catch {
            print("Error: \(error)")
        }
    }
    
    private func loadHistory() {
        let request = NSFetchRequest<HistoryEntity>(entityName: "HistoryEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        do {
            let entities = try coreDataStack.context.fetch(request)
            history = entities.compactMap {
                guard let id = $0.id, let name = $0.itemName, let path = $0.path, let ts = $0.timestamp else { return nil }
                // Provide default values for old entries without new fields
                let itemId = $0.itemId ?? UUID()
                let folderPathData = $0.folderPath
                let folderPath: [Int] = folderPathData.flatMap { try? JSONDecoder().decode([Int].self, from: $0) } ?? []
                return HistoryEntry(id: id, itemId: itemId, itemName: name, path: path, folderPath: folderPath, timestamp: ts)
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    private func convertToFolder(_ entity: FolderEntity) -> Folder {
        var subfolders: [Folder] = []
        if let subfoldersSet = entity.subfolders as? Set<FolderEntity> {
            // Deduplicate by ID
            let uniqueSubfolders = Dictionary(grouping: subfoldersSet, by: { $0.id ?? UUID() })
                .compactMap { $0.value.first }
            
            subfolders = uniqueSubfolders.map { convertToFolder($0) }
                .sorted {
                    self.sortName(for: $0.name).localizedStandardCompare(self.sortName(for: $1.name)) == .orderedAscending
                }
            if !subfolders.isEmpty {
                print("Subcarpetas encontradas en '\(entity.name ?? "")': \(subfolders.count)")
            }
        }
        
        return Folder(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            subfolders: subfolders,
            imageData: entity.imageData,
            createdAt: entity.createdAt ?? Date(),
            isHidden: entity.isHidden
        )
    }
    

    // MARK: - Folders
    func addRootFolder(name: String, isFavorite: Bool = false, imageData: Data? = nil) {
        let folder = NSEntityDescription.insertNewObject(forEntityName: "FolderEntity", into: coreDataStack.context) as! FolderEntity
        let newFolderId = UUID() // Guardar el UUID antes de cualquier refresh
        folder.id = newFolderId
        folder.name = name
        folder.imageData = imageData
        folder.createdAt = Date()
        
        coreDataStack.save()
        
        if isFavorite {
            coreDataStack.refresh()
            loadFolders()
            
            // Usar newFolderId en vez de folder.id (que se invalida después del refresh)
            if let index = folders.firstIndex(where: { $0.id == newFolderId }) {
                toggleFolderFavorite(folder: folders[index], path: [index])
            }
        } else {
            coreDataStack.refresh()
            loadFolders()
        }
    }
    
    func deleteRootFolder(id: UUID) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@ AND parent == nil", id as CVarArg)
        do {
            let folders = try coreDataStack.context.fetch(request)
            folders.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
            coreDataStack.refresh()
            loadFolders()
        } catch {
            print("Error: \(error)")
        }
    }
    
    // MARK: - Subfolders
    func addSubfolder(name: String, to folderPath: [Int], isFavorite: Bool = false, imageData: Data? = nil) {
        guard let parent = getFolderEntity(at: folderPath) else {
            print("No se encontró carpeta padre")
            return
        }
        print("Creando subcarpeta '\(name)' en '\(parent.name ?? "sin nombre")'")
        
        let subfolder = NSEntityDescription.insertNewObject(forEntityName: "FolderEntity", into: coreDataStack.context) as! FolderEntity
        let newFolderId = UUID() // Guardar el UUID antes de cualquier refresh
        subfolder.id = newFolderId
        subfolder.name = name
        subfolder.parent = parent
        subfolder.imageData = imageData
        subfolder.createdAt = Date()
        
        print("Parent asignado: \(parent.name ?? "")")
        coreDataStack.save()
        
        if isFavorite {
            coreDataStack.refresh()
            loadFolders()
            
            // Reconstruir el path para la nueva subcarpeta
            // Usamos newFolderId (guardado antes del refresh) en lugar de subfolder.id
            if let parentFolder = getFolderAtPath(folderPath) {
                if let subIndex = parentFolder.subfolders.firstIndex(where: { $0.id == newFolderId }) {
                    var newPath = folderPath
                    newPath.append(subIndex)
                    if let newFolder = getFolderAtPath(newPath) {
                        print("Agregando '\(newFolder.name)' a favoritos con path \(newPath)")
                        toggleFolderFavorite(folder: newFolder, path: newPath)
                    }
                }
            }
        } else {
            coreDataStack.refresh()
            loadFolders()
        }
    }
    
    func deleteSubfolder(id: UUID, from folderPath: [Int]) {
        guard let parent = getFolderEntity(at: folderPath) else { return }
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@ AND parent == %@", id as CVarArg, parent)
        do {
            let subs = try coreDataStack.context.fetch(request)
            subs.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
            coreDataStack.refresh()
            loadFolders()
        } catch {
            print("Error: \(error)")
        }
    }
    

    
    // MARK: - Helper Methods
    private func getFolderAtPath(_ indices: [Int]) -> Folder? {
        guard !indices.isEmpty, indices[0] < folders.count else { return nil }
        var current = folders[indices[0]]
        for i in 1..<indices.count {
            guard indices[i] < current.subfolders.count else { return nil }
            current = current.subfolders[indices[i]]
        }
        return current
    }
    
    private func getFolderEntity(at indices: [Int]) -> FolderEntity? {
        guard !indices.isEmpty else {
            print("Path vacío")
            return nil
        }
        
        guard indices[0] < folders.count else {
            print("Índice raíz fuera de rango: \(indices[0]) >= \(folders.count)")
            return nil
        }
        
        let rootFolderId = folders[indices[0]].id
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@", rootFolderId as CVarArg)
        
        do {
            guard var current = try coreDataStack.context.fetch(request).first else {
                print("No se encontró carpeta raíz con ID: \(rootFolderId)")
                return nil
            }
            
            print("Carpeta encontrada en Core Data: \(current.name ?? "")")
            
            // Navegar a través de las subcarpetas
            for (step, i) in indices.dropFirst().enumerated() {
                // Obtener y ordenar subcarpetas consistentemente
                let subfoldersArray = (current.subfolders as? Set<FolderEntity>)?
                    .sorted {
                        self.sortName(for: $0.name ?? "").localizedStandardCompare(self.sortName(for: $1.name ?? "")) == .orderedAscending
                    } ?? []
                
                guard i < subfoldersArray.count else {
                    print("Subcarpeta en índice \(i) no encontrada (total: \(subfoldersArray.count))")
                    return nil
                }
                
                current = subfoldersArray[i]
                print("Navegado a subcarpeta: \(current.name ?? "")")
            }
            
            return current
        } catch {
            print("Error en getFolderEntity: \(error)")
            return nil
        }
    }
    
    // Helper to normalize names for sorting
    private func sortName(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("the ") {
            return String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }
    
    // MARK: - State Check
    func folderHasSubfolders(at indices: [Int]) -> Bool {
        guard let folder = getFolderAtPath(indices) else { return false }
        return !folder.subfolders.isEmpty
    }

    // MARK: - Folder Favorites
    func toggleFolderFavorite(folder: Folder, path: [Int]) {
        if let index = folderFavorites.firstIndex(where: { $0.0.id == folder.id }) {
            folderFavorites.remove(at: index)
            deleteFolderFavorite(id: folder.id)
        } else {
            folderFavorites.append((FolderReference(id: folder.id, name: folder.name), path))
            saveFolderFavorite(id: folder.id, name: folder.name, path: path)
        }
    }
    
    private func saveFolderFavorite(id: UUID, name: String, path: [Int]) {
        let fav = NSEntityDescription.insertNewObject(forEntityName: "FolderFavoritesEntity", into: coreDataStack.context) as! FolderFavoritesEntity
        fav.id = UUID()
        fav.folderId = id
        fav.folderName = name
        if let data = try? JSONEncoder().encode(path) {
            fav.pathData = data
        }
        coreDataStack.save()
        loadFolderFavorites()
    }
    
    private func deleteFolderFavorite(id: UUID, reload: Bool = true) {
        let request = NSFetchRequest<FolderFavoritesEntity>(entityName: "FolderFavoritesEntity")
        request.predicate = NSPredicate(format: "folderId == %@", id as CVarArg)
        do {
            let favs = try coreDataStack.context.fetch(request)
            favs.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
            if reload {
                loadFolderFavorites()
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func isFolderFavorite(folderId: UUID) -> Bool {
        folderFavorites.contains { $0.0.id == folderId }
    }

    func removeFolderFavorites(at offsets: IndexSet) {
        offsets.forEach { index in
            let (folderRef, _) = folderFavorites[index]
            deleteFolderFavorite(id: folderRef.id, reload: false)
        }
        loadFolderFavorites()
    }
    
    // MARK: - Hidden Folders
    
    func toggleFolderHidden(folder: Folder, path: [Int]) {
        guard let entity = getFolderEntity(at: path) else { return }
        
        let newHiddenState = !entity.isHidden
        
        // Actualizar la carpeta y todas sus subcarpetas (jerárquico)
        setFolderHidden(entity: entity, isHidden: newHiddenState)
        
        coreDataStack.save()
        coreDataStack.refresh()
        loadFolders()
    }
    
    private func setFolderHidden(entity: FolderEntity, isHidden: Bool) {
        // Solo marcar la carpeta actual, NO tocar las subcarpetas
        entity.isHidden = isHidden
        // Las subcarpetas mantienen su propio estado isHidden independientemente
    }

    
    // Verificar si una carpeta o alguno de sus ancestros está oculto
    func isHiddenOrHasHiddenAncestor(at path: [Int]) -> Bool {
        // Verificar cada nivel del path para ver si algún ancestro está oculto
        for i in 1...path.count {
            let ancestorPath = Array(path.prefix(i))
            if let entity = getFolderEntity(at: ancestorPath), entity.isHidden {
                return true
            }
        }
        return false
    }
    
    func isFolderHidden(folderId: UUID) -> Bool {
        // Buscar en la estructura de folders
        return isFolderHiddenRecursive(folders: folders, targetId: folderId)
    }
    
    private func isFolderHiddenRecursive(folders: [Folder], targetId: UUID) -> Bool {
        for folder in folders {
            if folder.id == targetId {
                return folder.isHidden
            }
            if isFolderHiddenRecursive(folders: folder.subfolders, targetId: targetId) {
                return true
            }
        }
        return false
    }
    
    func getHiddenFolders() -> [(folder: Folder, path: [Int])] {
        var hiddenFolders: [(Folder, [Int])] = []
        
        for (index, folder) in folders.enumerated() {
            collectHiddenFolders(from: folder, currentPath: [index], into: &hiddenFolders)
        }
        
        return hiddenFolders
    }
    
    private func collectHiddenFolders(from folder: Folder, currentPath: [Int], into result: inout [(Folder, [Int])]) {
        if folder.isHidden {
            result.append((folder, currentPath))
            // No seguir buscando en subcarpetas si la carpeta padre ya está oculta
            return
        }
        
        for (index, subfolder) in folder.subfolders.enumerated() {
            collectHiddenFolders(from: subfolder, currentPath: currentPath + [index], into: &result)
        }
    }
    
    func removeHiddenFolders(at offsets: IndexSet, from hiddenFolders: [(folder: Folder, path: [Int])]) {
        offsets.forEach { index in
            let (_, path) = hiddenFolders[index]
            if let entity = getFolderEntity(at: path) {
                setFolderHidden(entity: entity, isHidden: false)
            }
        }
        coreDataStack.save()
        coreDataStack.refresh()
        loadFolders()
    }
    // MARK: - History
    private func saveHistory(_ entry: HistoryEntry) {
        let hist = NSEntityDescription.insertNewObject(forEntityName: "HistoryEntity", into: coreDataStack.context) as! HistoryEntity
        hist.id = entry.id
        hist.itemId = entry.itemId
        hist.itemName = entry.itemName
        hist.path = entry.path
        hist.folderPath = try? JSONEncoder().encode(entry.folderPath)
        hist.timestamp = entry.timestamp
        history.append(entry)
        coreDataStack.save()
        cleanOldHistory()
    }
    
    func cleanOldHistory() {
        let cutoff = Date().addingTimeInterval(-historyLimit)
        let request = NSFetchRequest<HistoryEntity>(entityName: "HistoryEntity")
        request.predicate = NSPredicate(format: "timestamp < %@", cutoff as NSDate)
        do {
            let old = try coreDataStack.context.fetch(request)
            old.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
            history.removeAll { $0.timestamp < cutoff }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func removeHistoryEntry(id: UUID) {
        let request = NSFetchRequest<HistoryEntity>(entityName: "HistoryEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let entity = try coreDataStack.context.fetch(request).first {
                coreDataStack.context.delete(entity)
                coreDataStack.save()
                history.removeAll { $0.id == id }
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    // MARK: - Images
    func updateFolderImage(imageData: Data?, at folderPath: [Int]) {
        print("updateFolderImage llamado con path: \(folderPath)")
        print("Carpetas disponibles: \(folders.count), buscando índice: \(folderPath.first ?? -1)")
        
        guard let entity = getFolderEntity(at: folderPath) else {
            print("No se encontró la carpeta para actualizar imagen en path: \(folderPath)")
            return
        }
        
        print("Carpeta encontrada: \(entity.name ?? "sin nombre")")
        entity.imageData = imageData
        coreDataStack.save()
        coreDataStack.refresh()
        loadFolders()
        print("Imagen actualizada y carpetas recargadas")
    }
    

    // MARK: - Helper for getting folder from path
    func getFolderFromPath(_ path: [Int]) -> Folder? {
        return getFolderAtPath(path)
    }
    
    /// Gets the image data for a folder, checking the folder first then its ancestors
    func getInheritedImageData(for path: [Int]) -> Data? {
        // First check if current folder has its own image
        if let folder = getFolderAtPath(path), let imageData = folder.imageData {
            return imageData
        }
        
        // If not, traverse ancestors from closest to root
        guard !path.isEmpty else { return nil }
        
        for endIndex in stride(from: path.count - 1, through: 1, by: -1) {
            let ancestorPath = Array(path.prefix(endIndex))
            if let ancestor = getFolderAtPath(ancestorPath),
               let imageData = ancestor.imageData {
                return imageData
            }
        }
        
        // Check root level folder
        if path.count >= 1 {
            let rootPath = [path[0]]
            if let rootFolder = getFolderAtPath(rootPath),
               let imageData = rootFolder.imageData {
                return imageData
            }
        }
        
        return nil
    }
    
    // MARK: - Rename Methods
    func renameFolder(id: UUID, newName: String) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let folder = try coreDataStack.context.fetch(request).first {
                folder.name = newName
                coreDataStack.save()
                coreDataStack.refresh()
                loadFolders()
                print("Carpeta renombrada a: \(newName)")
            }
        } catch {
            print("Error renombrando carpeta: \(error)")
        }
    }
    

    // MARK: - Sort Preferences
    // MARK: - Sort Preferences
    func getSortType(for folderId: UUID?) -> SortType {
        let key = "sort_\(folderId?.uuidString ?? "root")"
        if let saved = userDefaults.string(forKey: key), let sortType = SortType(rawValue: saved) {
            return sortType
        }
        return .nameAsc
    }
    
    func setSortType(_ sortType: SortType, for folderId: UUID?) {
        let key = "sort_\(folderId?.uuidString ?? "root")"
        userDefaults.set(sortType.rawValue, forKey: key)
        print("Ordenamiento guardado para carpeta: \(sortType.rawValue)")
    }
    

    func sortFolders(_ folders: [Folder], by sortType: SortType) -> [Folder] {
        switch sortType {
        case .nameAsc:
            return folders.sorted {
                self.sortName(for: $0.name).localizedStandardCompare(self.sortName(for: $1.name)) == .orderedAscending
            }
        case .nameDesc:
            return folders.sorted {
                self.sortName(for: $0.name).localizedStandardCompare(self.sortName(for: $1.name)) == .orderedDescending
            }
        case .dateNewest:
            // Más reciente primero (fecha más nueva primero)
            return folders.sorted { $0.createdAt > $1.createdAt }
        case .dateOldest:
            // Más antiguo primero (fecha más vieja primero)
            return folders.sorted { $0.createdAt < $1.createdAt }
        }
    }
    
    // MARK: - View Preferences
    func getViewType(for folderId: UUID?) -> ViewType {
        let key = "view_\(folderId?.uuidString ?? "root")"
        if let saved = userDefaults.string(forKey: key), let viewType = ViewType(rawValue: saved) {
            return viewType
        }
        return .list
    }
    
    func setViewType(_ viewType: ViewType, for folderId: UUID?) {
        let key = "view_\(folderId?.uuidString ?? "root")"
        userDefaults.set(viewType.rawValue, forKey: key)
        print("Vista guardada para carpeta: \(viewType.rawValue)")
    }
    
    // MARK: - Move & Copy

    // Nueva versión que usa ID del destino (más seguro para operaciones batch)
    func moveFolderById(id: UUID, toFolderId targetFolderId: UUID?) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let folder = try coreDataStack.context.fetch(request).first {
                if let targetId = targetFolderId {
                    // Buscar carpeta destino por ID
                    let targetRequest = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
                    targetRequest.predicate = NSPredicate(format: "id == %@", targetId as CVarArg)
                    
                    if let targetFolder = try coreDataStack.context.fetch(targetRequest).first {
                        folder.parent = targetFolder
                    } else {
                        print("Error: Target folder with id \(targetId) not found")
                        return
                    }
                } else {
                    // Mover a root
                    folder.parent = nil
                }
                coreDataStack.save()
                coreDataStack.refresh()
                loadFolders()
            }
        } catch {
            print("Error moving folder: \(error)")
        }
    }
    
    // Versión original (para compatibilidad) - ahora solo recarga al final
    func moveFolder(id: UUID, to targetFolderPath: [Int]) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let folder = try coreDataStack.context.fetch(request).first {
                if targetFolderPath.isEmpty {
                    folder.parent = nil
                } else {
                    if let targetFolder = getFolderEntity(at: targetFolderPath) {
                        folder.parent = targetFolder
                    } else {
                        return
                    }
                }
                coreDataStack.save()
                coreDataStack.refresh()
                loadFolders()
            }
        } catch {
            print("Error moving folder: \(error)")
        }
    }
    
    // Nueva versión que usa ID del destino (más seguro para operaciones batch)
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
                loadFolders()
            }
        } catch {
            print("Error copying folder: \(error)")
        }
    }
    
    func copyFolder(id: UUID, to targetFolderPath: [Int]) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let originalFolder = try coreDataStack.context.fetch(request).first {
                var targetParent: FolderEntity? = nil
                if !targetFolderPath.isEmpty {
                    targetParent = getFolderEntity(at: targetFolderPath)
                }
                
                copyFolderRecursive(original: originalFolder, parent: targetParent)
                
                coreDataStack.save()
                coreDataStack.refresh()
                loadFolders()
            }
        } catch {
            print("Error copying folder: \(error)")
        }
    }
    
    private func copyFolderRecursive(original: FolderEntity, parent: FolderEntity?) {
        let newFolder = NSEntityDescription.insertNewObject(forEntityName: "FolderEntity", into: coreDataStack.context) as! FolderEntity
        newFolder.id = UUID()
        newFolder.name = original.name
        newFolder.imageData = original.imageData
        newFolder.parent = parent
        
        if let subfolders = original.subfolders as? Set<FolderEntity> {
            for sub in subfolders {
                copyFolderRecursive(original: sub, parent: newFolder)
            }
        }
    }
    
    // MARK: - Batch Operations
    func batchDeleteRootFolders(ids: Set<UUID>) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id IN %@ AND parent == nil", ids as CVarArg)
        
        do {
            let foldersToDelete = try coreDataStack.context.fetch(request)
            foldersToDelete.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
            coreDataStack.refresh()
            loadFolders()
        } catch {
            print("Error batch deleting root folders: \(error)")
        }
    }
    
    func batchDeleteSubfolders(ids: Set<UUID>, from parentPath: [Int]) {
        guard let parent = getFolderEntity(at: parentPath) else { return }
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id IN %@ AND parent == %@", ids as CVarArg, parent)
        
        do {
            let subs = try coreDataStack.context.fetch(request)
            subs.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
            coreDataStack.refresh()
            loadFolders()
        } catch {
            print("Error batch deleting subfolders: \(error)")
        }
    }
    
    func batchToggleHiddenRoot(ids: Set<UUID>) {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id IN %@ AND parent == nil", ids as CVarArg)
        
        do {
            let foldersToToggle = try coreDataStack.context.fetch(request)
            for folder in foldersToToggle {
                let newState = !folder.isHidden
                setFolderHidden(entity: folder, isHidden: newState)
            }
            coreDataStack.save()
            coreDataStack.refresh()
            loadFolders()
        } catch {
            print("Error batch toggling hidden root: \(error)")
        }
    }
    
    func batchToggleHiddenSubfolders(ids: Set<UUID>, at parentPath: [Int]) {
        guard let parent = getFolderEntity(at: parentPath) else { return }
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id IN %@ AND parent == %@", ids as CVarArg, parent)
        
        do {
            let subs = try coreDataStack.context.fetch(request)
            for folder in subs {
                let newState = !folder.isHidden
                setFolderHidden(entity: folder, isHidden: newState)
            }
            coreDataStack.save()
            coreDataStack.refresh()
            loadFolders()
        } catch {
            print("Error batch toggling hidden subfolders: \(error)")
        }
    }
    
    // MARK: - Search
    func getReversedPathString(for path: [Int]) -> String {
        var names = ["Randomitas"]
        var currentLevelFolders = folders
        
        let parentPath = path.dropLast() // We want path to the parent
        
        for index in parentPath {
            if index < currentLevelFolders.count {
                let folder = currentLevelFolders[index]
                names.append(folder.name)
                currentLevelFolders = folder.subfolders
            } else {
                break
            }
        }
        
        return names.reversed().joined(separator: " < ")
    }
    
    func search(query: String) -> [(Folder, [Int], String)] {
        guard !query.isEmpty else { return [] }
        
        var foundFolders: [(Folder, [Int], String)] = []
        
        // Helper recursive function
        func searchRecursive(folders: [Folder], currentPath: [Int], parentNames: [String]) {
            for (index, folder) in folders.enumerated() {
                let newPath = currentPath + [index]
                
                // Check folder name (Prefix Match)
                if folder.name.lowercased().hasPrefix(query.lowercased()) {
                    let pathString = parentNames.reversed().joined(separator: " < ")
                    foundFolders.append((folder, newPath, pathString))
                }
                
                // Recurse into subfolders
                var newParentNames = parentNames
                newParentNames.append(folder.name)
                searchRecursive(folders: folder.subfolders, currentPath: newPath, parentNames: newParentNames)
            }
        }
        
        searchRecursive(folders: folders, currentPath: [], parentNames: ["Randomitas"])
        return foundFolders
    }
    
    // MARK: - Randomize Folder
    
    // Mode 1: Randomize only current screen (direct children)
    func randomizeCurrentScreen(at path: [Int]) -> (folder: Folder, path: [Int])? {
        let foldersToRandomize: [Folder]
        
        if path.isEmpty {
            // Root level - randomize from all folders
            foldersToRandomize = folders
        } else {
            // Inside a folder - randomize from subfolders
            guard let parentFolder = findFolder(at: path) else { return nil }
            foldersToRandomize = parentFolder.subfolders
        }
        
        // Filtrar carpetas ocultas (incluyendo las que tienen ancestros ocultos)
        var visibleFolders: [Folder] = []
        for (index, folder) in foldersToRandomize.enumerated() {
            let folderPath = path + [index]
            if !isHiddenOrHasHiddenAncestor(at: folderPath) {
                visibleFolders.append(folder)
            }
        }
        
        guard !visibleFolders.isEmpty else { return nil }
        
        let randomIndex = Int.random(in: 0..<visibleFolders.count)
        let selectedFolder = visibleFolders[randomIndex]
        
        // Encontrar el índice real en la lista original para construir el path correcto
        guard let originalIndex = foldersToRandomize.firstIndex(where: { $0.id == selectedFolder.id }) else { return nil }
        let resultPath = path + [originalIndex]
        
        // Save to history
        // Use dropLast() to exclude the current folder name from the path string
        let pathString = getFolderPathString(for: Array(resultPath.dropLast()))
        let entry = HistoryEntry(itemId: selectedFolder.id, itemName: selectedFolder.name, path: pathString, folderPath: resultPath)
        saveHistory(entry)
        
        return (selectedFolder, resultPath)
    }
    
    // Mode 2: Randomize current screen + all children (recursive)
    func randomizeWithChildren(at path: [Int]) -> (folder: Folder, path: [Int])? {
        var allFolders: [(folder: Folder, path: [Int])] = []
        
        if path.isEmpty {
            // Root level - collect all folders recursively
            collectAllFolders(from: folders, currentPath: [], into: &allFolders)
        } else {
            // Inside a folder - collect this folder's subfolders recursively
            guard let parentFolder = findFolder(at: path) else { return nil }
            collectAllFolders(from: parentFolder.subfolders, currentPath: path, into: &allFolders)
        }
        
        // Filtrar carpetas ocultas (incluyendo las que tienen ancestros ocultos)
        allFolders = allFolders.filter { !isHiddenOrHasHiddenAncestor(at: $0.path) }
        
        guard !allFolders.isEmpty else { return nil }
        
        let randomIndex = Int.random(in: 0..<allFolders.count)
        let selected = allFolders[randomIndex]
        
        // Save to history
        // Use dropLast() to exclude the current folder name from the path string
        let pathString = getFolderPathString(for: Array(selected.path.dropLast()))
        let entry = HistoryEntry(itemId: selected.folder.id, itemName: selected.folder.name, path: pathString, folderPath: selected.path)
        saveHistory(entry)
        
        return selected
    }
    
    // Mode 3: Randomize all folders in the entire app
    func randomizeAll() -> (folder: Folder, path: [Int])? {
        var allFolders: [(folder: Folder, path: [Int])] = []
        
        // Collect all folders from root
        collectAllFolders(from: folders, currentPath: [], into: &allFolders)
        
        // Filtrar carpetas ocultas (incluyendo las que tienen ancestros ocultos)
        allFolders = allFolders.filter { !isHiddenOrHasHiddenAncestor(at: $0.path) }
        
        guard !allFolders.isEmpty else { return nil }
        
        let randomIndex = Int.random(in: 0..<allFolders.count)
        let selected = allFolders[randomIndex]
        
        // Save to history
        // Use dropLast() to exclude the current folder name from the path string
        let pathString = getFolderPathString(for: Array(selected.path.dropLast()))
        let entry = HistoryEntry(itemId: selected.folder.id, itemName: selected.folder.name, path: pathString, folderPath: selected.path)
        saveHistory(entry)
        
        return selected
    }
    
    // Helper: Collect all folders recursively
    private func collectAllFolders(from folders: [Folder], currentPath: [Int], into result: inout [(folder: Folder, path: [Int])]) {
        for (index, folder) in folders.enumerated() {
            let folderPath = currentPath + [index]
            result.append((folder, folderPath))
            
            // Recursively collect subfolders
            if !folder.subfolders.isEmpty {
                collectAllFolders(from: folder.subfolders, currentPath: folderPath, into: &result)
            }
        }
    }
    
    // Legacy method for compatibility (redirects to randomizeCurrentScreen)
    func randomizeFolderOnly(at path: [Int]) -> (folder: Folder, path: [Int])? {
        return randomizeCurrentScreen(at: path)
    }
    
    func getFolderPathString(for path: [Int]) -> String {
        var names: [String] = []
        var currentList = folders
        
        for index in path {
            if index < currentList.count {
                let folder = currentList[index]
                names.append(folder.name)
                currentList = folder.subfolders
            } else {
                break
            }
        }
        
        return names.joined(separator: " > ")
    }
    
    func findFolder(at path: [Int]) -> Folder? {
        guard !path.isEmpty else { return nil }
        guard path[0] < folders.count else { return nil }
        
        var current = folders[path[0]]
        
        for i in 1..<path.count {
            guard path[i] < current.subfolders.count else { return nil }
            current = current.subfolders[path[i]]
        }
        
        return current
    }
}



  
