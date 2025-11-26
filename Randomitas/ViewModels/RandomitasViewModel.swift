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
    @Published var favorites: [(ItemReference, String)] = []
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
        loadFavorites()
        loadFolderFavorites()
        loadHistory()
    }
    
    private func loadFolders() {
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "parent == nil")
        
        do {
            let entities = try coreDataStack.context.fetch(request)
            // Ordenar por nombre para consistencia
            let sorted = entities.sorted { ($0.name ?? "") < ($1.name ?? "") }
            folders = sorted.map { convertToFolder($0) }
            print("✅ Carpetas raíz cargadas: \(folders.count)")
        } catch {
            print("❌ Error cargando carpetas: \(error)")
        }
    }
    
    private func loadFavorites() {
        let request = NSFetchRequest<FavoritesEntity>(entityName: "FavoritesEntity")
        do {
            let entities = try coreDataStack.context.fetch(request)
            favorites = entities.compactMap {
                guard let id = $0.itemId, let name = $0.itemName, let path = $0.path else { return nil }
                return (ItemReference(id: id, name: name), path)
            }
            print("✅ Favoritos cargados: \(favorites.count)")
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    private func loadFolderFavorites() {
        let request = NSFetchRequest<FolderFavoritesEntity>(entityName: "FolderFavoritesEntity")
        do {
            let entities = try coreDataStack.context.fetch(request)
            folderFavorites = entities.compactMap { entity in
                guard let id = entity.folderId, let name = entity.folderName, let data = entity.pathData else { return nil }
                if let path = try? JSONDecoder().decode([Int].self, from: data) {
                    return (FolderReference(id: id, name: name), path)
                }
                return nil
            }
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    private func loadHistory() {
        let request = NSFetchRequest<HistoryEntity>(entityName: "HistoryEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        do {
            let entities = try coreDataStack.context.fetch(request)
            history = entities.compactMap {
                guard let id = $0.id, let name = $0.itemName, let path = $0.path, let ts = $0.timestamp else { return nil }
                return HistoryEntry(id: id, itemName: name, path: path, timestamp: ts)
            }
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    private func convertToFolder(_ entity: FolderEntity) -> Folder {
        var items: [Item] = []
        if let itemsSet = entity.items as? Set<ItemEntity> {
            items = itemsSet.map { convertToItem($0) }
                .sorted { $0.name < $1.name }
            if !items.isEmpty {
                print("  📦 Items encontrados: \(items.count)")
            }
        }
        
        var subfolders: [Folder] = []
        if let subfoldersSet = entity.subfolders as? Set<FolderEntity> {
            subfolders = subfoldersSet.map { convertToFolder($0) }
                .sorted { $0.name < $1.name }
            if !subfolders.isEmpty {
                print("  📁 Subcarpetas encontradas en '\(entity.name ?? "")': \(subfolders.count)")
            }
        }
        
        return Folder(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            items: items,
            subfolders: subfolders,
            imageData: entity.imageData
        )
    }
    
    private func convertToItem(_ entity: ItemEntity) -> Item {
        return Item(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            imageData: entity.imageData,
            isFavorite: entity.isFavorite
        )
    }
    
    // MARK: - Folders
    func addRootFolder(name: String, isFavorite: Bool = false, imageData: Data? = nil) {
        let folder = NSEntityDescription.insertNewObject(forEntityName: "FolderEntity", into: coreDataStack.context) as! FolderEntity
        folder.id = UUID()
        folder.name = name
        folder.imageData = imageData
        
        coreDataStack.save()
        
        if isFavorite {
            // Para carpetas raíz, el path es simplemente el índice en el array de folders.
            // Pero necesitamos recargar folders primero para saber el índice.
            coreDataStack.refresh()
            loadFolders()
            
            if let index = folders.firstIndex(where: { $0.id == folder.id }) {
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
            print("❌ No se encontró carpeta padre")
            return
        }
        print("✅ Creando subcarpeta '\(name)' en '\(parent.name ?? "sin nombre")'")
        
        let subfolder = NSEntityDescription.insertNewObject(forEntityName: "FolderEntity", into: coreDataStack.context) as! FolderEntity
        subfolder.id = UUID()
        subfolder.name = name
        subfolder.parent = parent
        subfolder.imageData = imageData
        
        print("✅ Parent asignado: \(parent.name ?? "")")
        coreDataStack.save()
        
        if isFavorite {
            coreDataStack.refresh()
            loadFolders()
            
            // Reconstruir el path para la nueva subcarpeta
            // Esto es complejo porque necesitamos encontrar el índice de la nueva subcarpeta
            if let parentFolder = getFolderAtPath(folderPath) {
                if let subIndex = parentFolder.subfolders.firstIndex(where: { $0.id == subfolder.id }) {
                    var newPath = folderPath
                    newPath.append(subIndex)
                    // Necesitamos pasar el objeto Folder struct, no la entidad
                    if let newFolder = getFolderAtPath(newPath) {
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
    
    // MARK: - Items
    func addItem(name: String, to folderPath: [Int], isFavorite: Bool = false, imageData: Data? = nil) {
        guard let folder = getFolderEntity(at: folderPath) else {
            print("❌ No se encontró la carpeta para agregar el item")
            return
        }
        let item = NSEntityDescription.insertNewObject(forEntityName: "ItemEntity", into: coreDataStack.context) as! ItemEntity
        item.id = UUID()
        item.name = name
        item.isFavorite = isFavorite
        item.folder = folder
        item.imageData = imageData
        
        coreDataStack.save()
        
        if isFavorite {
            // Construir el path string
            // Necesitamos los nombres de las carpetas en el path
            if let folderStruct = getFolderAtPath(folderPath) {
                // Esta lógica es un poco inversa, necesitamos el path string completo
                // "Carpeta > Subcarpeta > Item"
                // Podemos reconstruirlo desde folderPath
                var pathNames: [String] = []
                var currentPath: [Int] = []
                
                for index in folderPath {
                    currentPath.append(index)
                    if let f = getFolderAtPath(currentPath) {
                        pathNames.append(f.name)
                    }
                }
                
                let pathString = pathNames.joined(separator: " > ") + " > " + name
                
                // Agregar a favoritos manualmente porque toggleFavorite invierte el estado
                // y aquí sabemos que queremos agregarlo.
                // Pero toggleFavorite verifica si ya existe.
                // Como acabamos de crear el item, seguro no está en la lista de favoritos del VM,
                // pero ItemEntity.isFavorite ya es true.
                // El VM.favorites es una lista separada de tuplas (ItemReference, String).
                
                // Llamamos a toggleFavorite pasando un Item struct temporal
                let itemStruct = Item(id: item.id!, name: name, imageData: imageData, isFavorite: true)
                toggleFavorite(item: itemStruct, path: pathString)
            }
            
            coreDataStack.refresh()
            loadFolders()
        } else {
            coreDataStack.refresh()
            loadFolders()
        }
    }
    
    func deleteItem(id: UUID, from folderPath: [Int]) {
        guard let folder = getFolderEntity(at: folderPath) else { return }
        let request = NSFetchRequest<ItemEntity>(entityName: "ItemEntity")
        request.predicate = NSPredicate(format: "id == %@ AND folder == %@", id as CVarArg, folder)
        do {
            let items = try coreDataStack.context.fetch(request)
            items.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
            coreDataStack.refresh()
            loadFolders()
        } catch {
            print("Error: \(error)")
        }
    }
    
    func findItem(id: UUID, in folderPath: [Int]) -> Item? {
        guard let folder = getFolderAtPath(folderPath) else { return nil }
        return folder.items.first { $0.id == id }
    }
    
    private func getFolderEntity(at indices: [Int]) -> FolderEntity? {
        guard !indices.isEmpty else {
            print("❌ Path vacío")
            return nil
        }
        
        guard indices[0] < folders.count else {
            print("❌ Índice raíz fuera de rango: \(indices[0]) >= \(folders.count)")
            return nil
        }
        
        let rootFolderId = folders[indices[0]].id
        let request = NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
        request.predicate = NSPredicate(format: "id == %@", rootFolderId as CVarArg)
        
        do {
            guard var current = try coreDataStack.context.fetch(request).first else {
                print("❌ No se encontró carpeta raíz con ID: \(rootFolderId)")
                return nil
            }
            
            print("✅ Carpeta encontrada en Core Data: \(current.name ?? "")")
            
            // Navegar a través de las subcarpetas
            for (step, i) in indices.dropFirst().enumerated() {
                // Obtener y ordenar subcarpetas consistentemente
                let subfoldersArray = (current.subfolders as? Set<FolderEntity>)?
                    .sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
                
                guard i < subfoldersArray.count else {
                    print("❌ Subcarpeta en índice \(i) no encontrada (total: \(subfoldersArray.count))")
                    return nil
                }
                
                current = subfoldersArray[i]
                print("✅ Navegado a subcarpeta: \(current.name ?? "")")
            }
            
            return current
        } catch {
            print("❌ Error en getFolderEntity: \(error)")
            return nil
        }
    }
    
    // MARK: - Randomization
    func randomizeFolder(at indices: [Int]) -> (item: Item, path: String)? {
        guard !indices.isEmpty else { return nil }
        let folder = getFolderAtPath(indices)
        return randomizeFolderInternal(folder)
    }
    
    private func getFolderAtPath(_ indices: [Int]) -> Folder? {
        guard !indices.isEmpty, indices[0] < folders.count else { return nil }
        var current = folders[indices[0]]
        for i in 1..<indices.count {
            guard indices[i] < current.subfolders.count else { return nil }
            current = current.subfolders[indices[i]]
        }
        return current
    }
    
    private func randomizeFolderInternal(_ folder: Folder?) -> (item: Item, path: String)? {
        guard let folder = folder else { return nil }
        var allItems: [(Item, String)] = []
        collectItems(from: folder, prefix: folder.name, into: &allItems)
        guard let selected = allItems.randomElement() else { return nil }
        
        let entry = HistoryEntry(itemName: selected.0.name, path: selected.1)
        saveHistory(entry)
        
        return selected
    }
    
    private func collectItems(from folder: Folder, prefix: String, into items: inout [(Item, String)]) {
        for item in folder.items {
            items.append((item, prefix + " > " + item.name))
        }
        for subfolder in folder.subfolders {
            collectItems(from: subfolder, prefix: prefix + " > " + subfolder.name, into: &items)
        }
    }
    
    // MARK: - State Check
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
        return folder.items.isEmpty
    }
    
    func canAddItems(at indices: [Int]) -> Bool {
        guard let folder = getFolderAtPath(indices) else { return false }
        return folder.subfolders.isEmpty
    }
    
    // MARK: - Favorites
    func toggleFavorite(item: Item, path: String) {
        print("⭐ toggleFavorite llamado: itemId=\(item.id), path=\(path)")
        print("⭐ Favoritos actuales: \(favorites.map { $0.1 })")
        
        if let index = favorites.firstIndex(where: { $0.0.id == item.id && $0.1 == path }) {
            print("⭐ Item ya es favorito, eliminando...")
            favorites.remove(at: index)
            deleteFavorite(id: item.id, path: path)
        } else {
            print("⭐ Item no es favorito, agregando...")
            favorites.append((ItemReference(id: item.id, name: item.name), path))
            saveFavorite(id: item.id, name: item.name, path: path)
            print("⭐ Favoritos después de agregar: \(favorites.map { $0.1 })")
        }
    }
    
    private func saveFavorite(id: UUID, name: String, path: String) {
        let fav = NSEntityDescription.insertNewObject(forEntityName: "FavoritesEntity", into: coreDataStack.context) as! FavoritesEntity
        fav.id = UUID()
        fav.itemId = id
        fav.itemName = name
        fav.path = path
        coreDataStack.save()
        loadFavorites()
    }
    
    private func deleteFavorite(id: UUID, path: String) {
        let request = NSFetchRequest<FavoritesEntity>(entityName: "FavoritesEntity")
        request.predicate = NSPredicate(format: "itemId == %@ AND path == %@", id as CVarArg, path)
        do {
            let favs = try coreDataStack.context.fetch(request)
            favs.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
            loadFavorites()
        } catch {
            print("Error: \(error)")
        }
    }
    
    func isFavorite(itemId: UUID, path: String) -> Bool {
        favorites.contains { $0.0.id == itemId && $0.1 == path }
    }

    func removeFavorites(at offsets: IndexSet) {
        offsets.forEach { index in
            let (itemRef, path) = favorites[index]
            deleteFavorite(id: itemRef.id, path: path)
        }
        favorites.remove(atOffsets: offsets)
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
    
    private func deleteFolderFavorite(id: UUID) {
        let request = NSFetchRequest<FolderFavoritesEntity>(entityName: "FolderFavoritesEntity")
        request.predicate = NSPredicate(format: "folderId == %@", id as CVarArg)
        do {
            let favs = try coreDataStack.context.fetch(request)
            favs.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
            loadFolderFavorites()
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
            deleteFolderFavorite(id: folderRef.id)
        }
        folderFavorites.remove(atOffsets: offsets)
    }
    
    // MARK: - History
    private func saveHistory(_ entry: HistoryEntry) {
        let hist = NSEntityDescription.insertNewObject(forEntityName: "HistoryEntity", into: coreDataStack.context) as! HistoryEntity
        hist.id = entry.id
        hist.itemName = entry.itemName
        hist.path = entry.path
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
    
    // MARK: - Images
    func updateFolderImage(imageData: Data?, at folderPath: [Int]) {
        print("📁 updateFolderImage llamado con path: \(folderPath)")
        print("📁 Carpetas disponibles: \(folders.count), buscando índice: \(folderPath.first ?? -1)")
        
        guard let entity = getFolderEntity(at: folderPath) else {
            print("❌ No se encontró la carpeta para actualizar imagen en path: \(folderPath)")
            return
        }
        
        print("✅ Carpeta encontrada: \(entity.name ?? "sin nombre")")
        entity.imageData = imageData
        coreDataStack.save()
        coreDataStack.refresh()
        loadFolders()
        print("✅ Imagen actualizada y carpetas recargadas")
    }
    
    func updateItemImage(imageData: Data?, itemId: UUID) {
        let request = NSFetchRequest<ItemEntity>(entityName: "ItemEntity")
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
        
        do {
            let items = try coreDataStack.context.fetch(request)
            items.first?.imageData = imageData
            coreDataStack.save()
            coreDataStack.refresh()
            loadFolders()
        } catch {
            print("Error: \(error)")
        }
    }
    
    // MARK: - Helper for getting folder from path
    func getFolderFromPath(_ path: [Int]) -> Folder? {
        return getFolderAtPath(path)
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
                print("✅ Carpeta renombrada a: \(newName)")
            }
        } catch {
            print("❌ Error renombrando carpeta: \(error)")
        }
    }
    
    func renameItem(id: UUID, newName: String) {
        let request = NSFetchRequest<ItemEntity>(entityName: "ItemEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let item = try coreDataStack.context.fetch(request).first {
                item.name = newName
                coreDataStack.save()
                coreDataStack.refresh()
                loadFolders()
                print("✅ Item renombrado a: \(newName)")
            }
        } catch {
            print("❌ Error renombrando item: \(error)")
        }
    }
    
    // MARK: - Sort Preferences
    func getSortType(for folderId: UUID) -> SortType {
        let key = "sort_\(folderId.uuidString)"
        if let saved = userDefaults.string(forKey: key), let sortType = SortType(rawValue: saved) {
            return sortType
        }
        return .nameAsc
    }
    
    func setSortType(_ sortType: SortType, for folderId: UUID) {
        let key = "sort_\(folderId.uuidString)"
        userDefaults.set(sortType.rawValue, forKey: key)
        print("💾 Ordenamiento guardado para carpeta: \(sortType.rawValue)")
    }
    
    func sortItems(_ items: [Item], by sortType: SortType) -> [Item] {
        switch sortType {
        case .nameAsc:
            return items.sorted { $0.name < $1.name }
        case .nameDesc:
            return items.sorted { $0.name > $1.name }
        case .dateNewest, .dateOldest:
            // Por ahora, items no tienen fecha. Ordenamos por nombre como fallback
            return items.sorted { $0.name < $1.name }
        }
    }
    
    func sortFolders(_ folders: [Folder], by sortType: SortType) -> [Folder] {
        switch sortType {
        case .nameAsc:
            return folders.sorted { $0.name < $1.name }
        case .nameDesc:
            return folders.sorted { $0.name > $1.name }
        case .dateNewest, .dateOldest:
            // Por ahora, carpetas no tienen fecha. Ordenamos por nombre como fallback
            return folders.sorted { $0.name < $1.name }
        }
    }
    
    // MARK: - View Preferences
    func getViewType(for folderId: UUID) -> ViewType {
        let key = "view_\(folderId.uuidString)"
        if let saved = userDefaults.string(forKey: key), let viewType = ViewType(rawValue: saved) {
            return viewType
        }
        return .list
    }
    
    func setViewType(_ viewType: ViewType, for folderId: UUID) {
        let key = "view_\(folderId.uuidString)"
        userDefaults.set(viewType.rawValue, forKey: key)
        print("💾 Vista guardada para carpeta: \(viewType.rawValue)")
    }
    
    // MARK: - Move & Copy
    func moveItem(id: UUID, to targetFolderPath: [Int]) {
        guard let targetFolder = getFolderEntity(at: targetFolderPath) else { return }
        
        let request = NSFetchRequest<ItemEntity>(entityName: "ItemEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let item = try coreDataStack.context.fetch(request).first {
                item.folder = targetFolder
                coreDataStack.save()
                coreDataStack.refresh()
                loadFolders()
            }
        } catch {
            print("Error moving item: \(error)")
        }
    }
    
    func copyItem(id: UUID, to targetFolderPath: [Int]) {
        guard let targetFolder = getFolderEntity(at: targetFolderPath) else { return }
        
        let request = NSFetchRequest<ItemEntity>(entityName: "ItemEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let originalItem = try coreDataStack.context.fetch(request).first {
                let newItem = NSEntityDescription.insertNewObject(forEntityName: "ItemEntity", into: coreDataStack.context) as! ItemEntity
                newItem.id = UUID()
                newItem.name = originalItem.name
                newItem.imageData = originalItem.imageData
                newItem.isFavorite = false
                newItem.folder = targetFolder
                
                coreDataStack.save()
                coreDataStack.refresh()
                loadFolders()
            }
        } catch {
            print("Error copying item: \(error)")
        }
    }
    
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
        
        if let items = original.items as? Set<ItemEntity> {
            for item in items {
                let newItem = NSEntityDescription.insertNewObject(forEntityName: "ItemEntity", into: coreDataStack.context) as! ItemEntity
                newItem.id = UUID()
                newItem.name = item.name
                newItem.imageData = item.imageData
                newItem.isFavorite = false
                newItem.folder = newFolder
            }
        }
        
        if let subfolders = original.subfolders as? Set<FolderEntity> {
            for sub in subfolders {
                copyFolderRecursive(original: sub, parent: newFolder)
            }
        }
    }
}



  
