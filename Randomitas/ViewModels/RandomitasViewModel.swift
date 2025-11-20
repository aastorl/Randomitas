//
//  RandomitasViewModel.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import Foundation
import CoreData
internal import Combine

class RandomitasViewModel: ObservableObject {
    @Published var folders: [Folder] = []
    @Published var favorites: [(ItemReference, String)] = []
    @Published var folderFavorites: [(FolderReference, [Int])] = []
    @Published var history: [HistoryEntry] = []
    @Published var viewType: ViewType = .list
    
    private let historyLimit: TimeInterval = 86400
    private let coreDataStack = CoreDataStack.shared
    
    enum ViewType: String {
        case list = "Lista"
        case grid = "Cuadrícula"
        case gallery = "Galería"
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
    func addRootFolder(name: String) {
        let folder = NSEntityDescription.insertNewObject(forEntityName: "FolderEntity", into: coreDataStack.context) as! FolderEntity
        folder.id = UUID()
        folder.name = name
        coreDataStack.save()
        coreDataStack.refresh()
        loadFolders()
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
    func addSubfolder(name: String, to folderPath: [Int]) {
        guard let parent = getFolderEntity(at: folderPath) else {
            print("❌ No se encontró carpeta padre")
            return
        }
        print("✅ Creando subcarpeta '\(name)' en '\(parent.name ?? "sin nombre")'")
        
        let subfolder = NSEntityDescription.insertNewObject(forEntityName: "FolderEntity", into: coreDataStack.context) as! FolderEntity
        subfolder.id = UUID()
        subfolder.name = name
        subfolder.parent = parent
        
        print("✅ Parent asignado: \(parent.name ?? "")")
        coreDataStack.save()
        coreDataStack.refresh()
        loadFolders()
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
    func addItem(name: String, to folderPath: [Int]) {
        guard let folder = getFolderEntity(at: folderPath) else {
            print("❌ No se encontró la carpeta para agregar el item")
            return
        }
        let item = NSEntityDescription.insertNewObject(forEntityName: "ItemEntity", into: coreDataStack.context) as! ItemEntity
        item.id = UUID()
        item.name = name
        item.isFavorite = false
        item.folder = folder
        coreDataStack.save()
        coreDataStack.refresh()
        loadFolders()
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
        if let index = favorites.firstIndex(where: { $0.0.id == item.id && $0.1 == path }) {
            favorites.remove(at: index)
            deleteFavorite(id: item.id, path: path)
        } else {
            favorites.append((ItemReference(id: item.id, name: item.name), path))
            saveFavorite(id: item.id, name: item.name, path: path)
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
        guard let entity = getFolderEntity(at: folderPath) else {
            print("❌ No se encontró la carpeta para actualizar imagen")
            return
        }
        entity.imageData = imageData
        coreDataStack.save()
        coreDataStack.refresh()
        loadFolders()
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
}




  
