//
//  RandomitasViewModel.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import Foundation
import os
internal import Combine
internal import SwiftUI

@MainActor
class RandomitasViewModel: ObservableObject {
    private let logger = Logger(subsystem: "Randomitas", category: "RandomitasViewModel")
    @Published var folders: [Folder] = []

    // Virtual Root Folder for Unified Architecture
    var rootFolder: Folder {
        Folder(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, name: "Randomitas", subfolders: folders, imageData: nil, createdAt: Date(), isHidden: false)
    }

    @Published var folderFavorites: [FolderReference] = []
    @Published var history: [HistoryEntry] = []
    @Published var lastError: DomainError? = nil

    private let historyLimit: TimeInterval = 86400

    private let folderRepository: FolderRepositoryProtocol
    private let favoritesStore: FavoritesStoreProtocol
    private let preferencesStore: PreferencesStoreProtocol
    private let hiddenFoldersService: HiddenFoldersService
    private let favoritesService: FavoritesService
    private let historyService: HistoryService
    private let folderOperationsService: FolderOperationsService
    private let folderAccessService = FolderAccessService()
    private var hiddenElementsViewState = HiddenElementsViewState()
    private let randomizer = RandomizerService()

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

    init(
        coreDataStack: CoreDataStack = .shared,
        userDefaults: UserDefaults = .standard
    ) {
        let normalize: (String) -> String = { FolderNameNormalizer.normalize($0) }
        self.folderRepository = FolderRepository(coreDataStack: coreDataStack, normalizeName: normalize)
        self.favoritesStore = FavoritesStore(coreDataStack: coreDataStack, normalizeName: normalize)
        self.preferencesStore = FolderPreferencesStore(userDefaults: userDefaults)
        self.hiddenFoldersService = HiddenFoldersService(folderRepository: folderRepository, favoritesStore: favoritesStore)
        self.favoritesService = FavoritesService(store: favoritesStore, hiddenService: hiddenFoldersService)
        self.historyService = HistoryService(store: HistoryStore(coreDataStack: coreDataStack), historyLimit: historyLimit)
        self.folderOperationsService = FolderOperationsService(repository: folderRepository)
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
        folders = folderRepository.loadRootFolders()
        logger.info("Carpetas raíz cargadas: \(self.folders.count)")
    }

    private func loadFolderFavorites() {
        folderFavorites = favoritesService.loadFavorites()
    }

    private func loadHistory() {
        history = historyService.loadHistory()
    }

    // MARK: - Folders
    func addRootFolder(name: String, isFavorite: Bool = false, imageData: Data? = nil) {
        let result = folderOperationsService.addRootFolder(name: name, imageData: imageData)
        guard case .success(let newFolderId) = result else {
            if case .failure(let error) = result {
                recordError(.repository(error))
            }
            return
        }
        let newFolder = Folder(id: newFolderId, name: name, subfolders: [], imageData: imageData, createdAt: Date(), isHidden: false)
        folders = sortFoldersByName(folders + [newFolder])

        if isFavorite, let path = findPathById(newFolderId), let folder = getFolderFromPath(path) {
            _ = toggleFolderFavorite(folder: folder, path: path)
        }
    }

    func deleteRootFolder(id: UUID) {
        folderOperationsService.deleteRootFolder(id: id)
        folders.removeAll { $0.id == id }
    }

    // MARK: - Subfolders
    func addSubfolder(name: String, to folderPath: [Int], isFavorite: Bool = false, imageData: Data? = nil) {
        let result = folderOperationsService.addSubfolder(name: name, to: folderPath, folders: folders, imageData: imageData)
        guard case .success(let newFolderId) = result else {
            if case .failure(let error) = result {
                recordError(.repository(error))
            }
            return
        }

        let newFolder = Folder(id: newFolderId, name: name, subfolders: [], imageData: imageData, createdAt: Date(), isHidden: false)
        folders = insertSubfolder(newFolder, at: folderPath, in: folders)

        if isFavorite, let path = findPathById(newFolderId), let folder = getFolderFromPath(path) {
            _ = toggleFolderFavorite(folder: folder, path: path)
        }
    }

    func deleteSubfolder(id: UUID, from folderPath: [Int]) {
        folderOperationsService.deleteSubfolder(id: id, from: folderPath, folders: folders)
        folders = removeSubfolder(id: id, at: folderPath, in: folders)
    }

    // MARK: - Helper Methods
    private func getFolderAtPath(_ indices: [Int]) -> Folder? {
        folderAccessService.folder(at: indices, in: folders)
    }

    private func sortFoldersByName(_ items: [Folder]) -> [Folder] {
        items.sorted {
            sortName(for: $0.name).localizedStandardCompare(sortName(for: $1.name)) == .orderedAscending
        }
    }

    private func insertSubfolder(_ folder: Folder, at parentPath: [Int], in items: [Folder]) -> [Folder] {
        guard !parentPath.isEmpty else { return sortFoldersByName(items + [folder]) }
        var updated = items
        let index = parentPath[0]
        guard index < updated.count else { return items }
        var parent = updated[index]
        let remainingPath = Array(parentPath.dropFirst())
        parent.subfolders = insertSubfolder(folder, at: remainingPath, in: parent.subfolders)
        updated[index] = parent
        return updated
    }

    private func removeSubfolder(id: UUID, at parentPath: [Int], in items: [Folder]) -> [Folder] {
        guard !parentPath.isEmpty else { return items.filter { $0.id != id } }
        var updated = items
        let index = parentPath[0]
        guard index < updated.count else { return items }
        var parent = updated[index]
        let remainingPath = Array(parentPath.dropFirst())
        if remainingPath.isEmpty {
            parent.subfolders.removeAll { $0.id == id }
        } else {
            parent.subfolders = removeSubfolder(id: id, at: remainingPath, in: parent.subfolders)
        }
        parent.subfolders = sortFoldersByName(parent.subfolders)
        updated[index] = parent
        return updated
    }

    private func updateFolder(at path: [Int], in items: [Folder], transform: (Folder) -> Folder) -> [Folder] {
        guard !path.isEmpty else { return items }
        var updated = items
        let index = path[0]
        guard index < updated.count else { return items }
        if path.count == 1 {
            updated[index] = transform(updated[index])
            return updated
        }
        var parent = updated[index]
        parent.subfolders = updateFolder(at: Array(path.dropFirst()), in: parent.subfolders, transform: transform)
        updated[index] = parent
        return updated
    }

    private func updateFolderById(_ id: UUID, in items: [Folder], transform: (Folder) -> Folder) -> [Folder] {
        items.map { folder in
            if folder.id == id {
                return transform(folder)
            }
            var updated = folder
            updated.subfolders = updateFolderById(id, in: folder.subfolders, transform: transform)
            return updated
        }
    }

    // Helper to normalize names for sorting
    func sortName(for name: String) -> String {
        FolderNameNormalizer.normalize(name)
    }

    /// Returns the uppercase first letter of the normalized sort name for section headers
    func sectionLetter(for folder: Folder) -> String {
        FolderNameNormalizer.sectionLetter(for: folder)
    }

    // MARK: - State Check
    func folderHasSubfolders(at indices: [Int]) -> Bool {
        folderAccessService.folderHasSubfolders(at: indices, in: folders)
    }

    // MARK: - Folder Favorites
    func toggleFolderFavorite(folder: Folder, path: [Int]) -> Bool {
        let result = favoritesService.toggleFavorite(
            folder: folder,
            path: path,
            folders: folders,
            currentFavorites: folderFavorites
        )
        folderFavorites = result.favorites
        return result.showHiddenAlert
    }

    func isFolderFavorite(folderId: UUID) -> Bool {
        folderFavorites.contains { $0.id == folderId }
    }

    /// Busca un folder por UUID en todo el árbol y retorna su path dinámico actual
    func findPathById(_ id: UUID) -> [Int]? {
        FolderTree.findPathById(id, in: folders)
    }

    func removeFolderFavorites(at offsets: IndexSet) {
        folderFavorites = favoritesService.removeFavorites(at: offsets, currentFavorites: folderFavorites)
    }

    // MARK: - Hidden Folders
    func toggleFolderHidden(folder: Folder, path: [Int]) {
        hiddenFoldersService.toggleHidden(at: path, folders: folders)
        loadFolders()
        loadFolderFavorites()
    }

    // Verificar si una carpeta o alguno de sus ancestros está oculto
    func isHiddenOrHasHiddenAncestor(at path: [Int]) -> Bool {
        hiddenFoldersService.isHiddenOrHasHiddenAncestor(at: path, folders: folders)
    }

    /// Returns the name of the first hidden ancestor (NOT including the folder itself)
    func getHiddenAncestorName(at path: [Int]) -> String? {
        hiddenFoldersService.hiddenAncestorName(at: path, folders: folders)
    }

    func isFolderHidden(folderId: UUID) -> Bool {
        hiddenFoldersService.isFolderHidden(folderId: folderId, folders: folders)
    }

    func getHiddenFolders() -> [(folder: Folder, path: [Int])] {
        hiddenFoldersService.hiddenFolders(in: folders)
    }

    func removeHiddenFolders(at offsets: IndexSet, from hiddenFolders: [(folder: Folder, path: [Int])]) {
        offsets.forEach { index in
            let (_, path) = hiddenFolders[index]
            hiddenFoldersService.setHidden(at: path, isHidden: false, folders: folders)
        }
        loadFolders()
        loadFolderFavorites()
    }

    // MARK: - History
    private func saveHistory(_ entry: HistoryEntry) {
        history = historyService.saveHistory(entry)
    }

    func cleanOldHistory() {
        history = historyService.cleanOldHistory()
    }

    func removeHistoryEntry(id: UUID) {
        history = historyService.removeHistoryEntry(id: id)
    }

    // MARK: - Images
    func updateFolderImage(imageData: Data?, at folderPath: [Int]) {
        logger.info("updateFolderImage llamado con path: \(folderPath, privacy: .public)")
        logger.info("Carpetas disponibles: \(self.folders.count), buscando índice: \(folderPath.first ?? -1)")

        switch folderOperationsService.updateFolderImage(imageData: imageData, at: folderPath, folders: folders) {
        case .success:
            folders = updateFolder(at: folderPath, in: folders) { folder in
                var updated = folder
                updated.imageData = imageData
                return updated
            }
            logger.info("Imagen actualizada y carpetas recargadas")
        case .failure(let error):
            recordError(.repository(error))
        }
    }

    // MARK: - Helper for getting folder from path
    func getFolderFromPath(_ path: [Int]) -> Folder? {
        folderAccessService.folder(at: path, in: folders)
    }

    /// Gets the image data for a folder, checking the folder first then its ancestors
    func getInheritedImageData(for path: [Int]) -> Data? {
        folderAccessService.inheritedImageData(for: path, in: folders)
    }

    // MARK: - Rename Methods
    func renameFolder(id: UUID, newName: String) {
        switch folderOperationsService.renameFolder(id: id, newName: newName) {
        case .success:
            folders = updateFolderById(id, in: folders) { folder in
                var updated = folder
                updated.name = newName
                return updated
            }
            logger.info("Carpeta renombrada a: \(newName, privacy: .public)")
        case .failure(let error):
            recordError(.repository(error))
        }
    }

    private func recordError(_ error: DomainError) {
        lastError = error
        logger.error("Domain error: \(error.localizedDescription, privacy: .public)")
    }

    // MARK: - Sort Preferences
    func getSortType(for folderId: UUID?) -> SortType {
        preferencesStore.getSortType(for: folderId)
    }

    func setSortType(_ sortType: SortType, for folderId: UUID?) {
        preferencesStore.setSortType(sortType, for: folderId)
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
            return folders.sorted { $0.createdAt > $1.createdAt }
        case .dateOldest:
            return folders.sorted { $0.createdAt < $1.createdAt }
        }
    }

    // MARK: - View Preferences
    func getViewType(for folderId: UUID?) -> ViewType {
        preferencesStore.getViewType(for: folderId)
    }

    func setViewType(_ viewType: ViewType, for folderId: UUID?) {
        preferencesStore.setViewType(viewType, for: folderId)
    }

    // MARK: - Hidden Elements View State (in-memory only)
    func getShowingHiddenElements(for path: [Int]) -> Bool {
        hiddenElementsViewState.isShowingHiddenElements(for: path)
    }

    func setShowingHiddenElements(_ showing: Bool, for path: [Int]) {
        hiddenElementsViewState.setShowingHiddenElements(showing, for: path)
    }

    // MARK: - Move & Copy
    func moveFolderById(id: UUID, toFolderId targetFolderId: UUID?) {
        folderOperationsService.moveFolderById(id: id, toFolderId: targetFolderId)
        loadFolders()
    }

    func moveFolder(id: UUID, to targetFolderPath: [Int]) {
        folderOperationsService.moveFolder(id: id, to: targetFolderPath, folders: folders)
        loadFolders()
    }

    func copyFolderById(id: UUID, toFolderId targetFolderId: UUID?) {
        folderOperationsService.copyFolderById(id: id, toFolderId: targetFolderId)
        loadFolders()
    }

    func copyFolder(id: UUID, to targetFolderPath: [Int]) {
        folderOperationsService.copyFolder(id: id, to: targetFolderPath, folders: folders)
        loadFolders()
    }

    // MARK: - Batch Operations
    func batchDeleteRootFolders(ids: Set<UUID>) {
        folderOperationsService.batchDeleteRootFolders(ids: ids)
        loadFolders()
    }

    func batchDeleteSubfolders(ids: Set<UUID>, from parentPath: [Int]) {
        folderOperationsService.batchDeleteSubfolders(ids: ids, from: parentPath, folders: folders)
        loadFolders()
    }

    func batchToggleHiddenRoot(ids: Set<UUID>) {
        folderOperationsService.batchToggleHiddenRoot(ids: ids, favoritesStore: favoritesStore)
        loadFolders()
        loadFolderFavorites()
    }

    func batchToggleHiddenSubfolders(ids: Set<UUID>, at parentPath: [Int]) {
        folderOperationsService.batchToggleHiddenSubfolders(ids: ids, at: parentPath, folders: folders, favoritesStore: favoritesStore)
        loadFolders()
        loadFolderFavorites()
    }

    // MARK: - Search
    func getReversedPathString(for path: [Int]) -> String {
        folderAccessService.reversedPathString(for: path, in: folders)
    }

    func search(query: String) -> [(Folder, [Int], String)] {
        FolderTree.search(query: query, in: folders)
    }

    // MARK: - Randomize Folder
    func randomizeCurrentScreen(at path: [Int]) -> (folder: Folder, path: [Int])? {
        randomizer.randomizeCurrentScreen(
            at: path,
            folders: folders,
            findFolder: { self.findFolder(at: $0) },
            isHidden: { self.isHiddenOrHasHiddenAncestor(at: $0) },
            pathString: { self.getFolderPathString(for: $0) },
            saveHistory: { self.saveHistory($0) }
        )
    }

    func randomizeWithChildren(at path: [Int]) -> (folder: Folder, path: [Int])? {
        randomizer.randomizeWithChildren(
            at: path,
            folders: folders,
            findFolder: { self.findFolder(at: $0) },
            isHidden: { self.isHiddenOrHasHiddenAncestor(at: $0) },
            pathString: { self.getFolderPathString(for: $0) },
            saveHistory: { self.saveHistory($0) }
        )
    }

    // Legacy method for compatibility (redirects to randomizeCurrentScreen)
    func randomizeFolderOnly(at path: [Int]) -> (folder: Folder, path: [Int])? {
        randomizeCurrentScreen(at: path)
    }

    func getFolderPathString(for path: [Int]) -> String {
        folderAccessService.folderPathString(for: path, in: folders)
    }

    func findFolder(at path: [Int]) -> Folder? {
        folderAccessService.findFolder(at: path, in: folders)
    }
}
