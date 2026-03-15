//
//  FolderDetailView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 14/11/2025.
internal import SwiftUI
internal import Combine
internal import Combine


struct FolderDetailView: View {
    let folder: Folder // Now a plain Folder struct (Root or Subfolder)
    let folderPath: [Int] // Empty for Root
    @ObservedObject var viewModel: RandomitasViewModel
    @Environment(\.dismiss) var dismiss
    
    var highlightedItemId: UUID? = nil

    @StateObject private var uiState = FolderDetailViewState()
    
    /// True if the current folder or any ancestor is hidden
    var isInHiddenContext: Bool {
        if folderPath.isEmpty { return false }
        return viewModel.isHiddenOrHasHiddenAncestor(at: folderPath)
    }
    

    @FocusState private var isSearchFocused: Bool
    
    // Folder Result State
    @Binding var navigationPath: NavigationPath
    
    // Dynamic access to live data
    var liveFolder: Folder {
        if folderPath.isEmpty {
            return viewModel.rootFolder
        }
        return viewModel.getFolderFromPath(folderPath) ?? folder
    }
    
    var sortedSubfolders: [Folder] {
        let allSubfolders = liveFolder.subfolders
        let filtered = uiState.showingHiddenElements 
            ? allSubfolders.filter { $0.isHidden }
            : allSubfolders.filter { !$0.isHidden }
        return viewModel.sortFolders(filtered, by: uiState.currentSortType)
    }
    
    /// Gets the image data for blur background, checking current folder first then ancestors
    var inheritedImageData: Data? {
        // First check if current folder has its own image
        if let imageData = liveFolder.imageData {
            return imageData
        }
        
        // If not, traverse ancestors from closest to root
        // folderPath = [0, 2, 1] means: root folder at index 0, then subfolder at index 2, then subfolder at index 1
        // We need to check each ancestor starting from the closest (parent) to the root
        guard !folderPath.isEmpty else { return nil }
        
        // Check each ancestor path from parent to root
        for endIndex in stride(from: folderPath.count - 1, through: 1, by: -1) {
            let ancestorPath = Array(folderPath.prefix(endIndex))
            if let ancestor = viewModel.getFolderFromPath(ancestorPath),
               let imageData = ancestor.imageData {
                return imageData
            }
        }
        
        // Check root level folder (first index)
        if folderPath.count >= 1 {
            let rootPath = [folderPath[0]]
            if let rootFolder = viewModel.getFolderFromPath(rootPath),
               let imageData = rootFolder.imageData {
                return imageData
            }
        }
        
        return nil
    }
    
    var body: some View {
        viewWithLifecycle
    }

    private var viewWithLifecycle: some View {
        viewWithAlerts
            .onAppear {
                uiState.currentViewType = viewModel.getViewType(for: folderPath.isEmpty ? nil : liveFolder.id)
                uiState.currentSortType = viewModel.getSortType(for: folderPath.isEmpty ? nil : liveFolder.id)
                uiState.showingHiddenElements = viewModel.getShowingHiddenElements(for: folderPath)
                // Forzar re-render para que los gestos se registren correctamente
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    uiState.toolbarReady = true
                }
            }
            .onReceive(viewModel.$lastError) { error in
                guard let error = error else { return }
                uiState.errorMessage = error.localizedDescription
                uiState.showingErrorAlert = true
                viewModel.lastError = nil
            }
    }

    private var viewWithAlerts: some View {
        viewWithSheets
            .confirmationDialog("¿Estás seguro?", isPresented: $uiState.showingMultiDeleteConfirmation, titleVisibility: .visible) {
                Button("Eliminar \(uiState.selectedItemIds.count) elementos", role: .destructive) {
                    if folderPath.isEmpty {
                        viewModel.batchDeleteRootFolders(ids: uiState.selectedItemIds)
                    } else {
                        viewModel.batchDeleteSubfolders(ids: uiState.selectedItemIds, from: folderPath)
                    }
                    uiState.isSelectionMode = false
                    uiState.selectedItemIds.removeAll()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .modifier(AlertsModifier(
                showFirstElementAlert: $uiState.showFirstElementAlert,
                showingEmptyRandomizeAlert: $uiState.showingEmptyRandomizeAlert,
                showingHiddenAncestorAlert: $uiState.showingHiddenAncestorAlert,
                hiddenAncestorAlertName: uiState.hiddenAncestorAlertName,
                showingHiddenRandomizeAlert: $uiState.showingHiddenRandomizeAlert,
                showHiddenFavoriteAlert: $uiState.showHiddenFavoriteAlert
            ))
            .alert("Error", isPresented: $uiState.showingErrorAlert) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text(uiState.errorMessage ?? "Ha ocurrido un error inesperado")
            }
    }

    private var viewWithSheets: some View {
        viewWithImagePickers
            .sheet(item: $uiState.moveCopyOperation) { operation in
                MoveCopySheet(
                    viewModel: viewModel,
                    isPresented: Binding(
                        get: { uiState.moveCopyOperation != nil },
                        set: { if !$0 { uiState.moveCopyOperation = nil } }
                    ),
                    foldersToMove: operation.items,
                    sourceContainerPath: operation.sourceContainerPath,
                    isCopy: operation.isCopy,
                    onSuccess: {
                        uiState.isSelectionMode = false
                        uiState.selectedItemIds.removeAll()
                    }
                )
            }
    }

    private var viewWithImagePickers: some View {
        viewWithPrimarySheets
            // Camera - fullscreen cover
            .fullScreenCover(item: Binding(
                get: { uiState.imagePickerRequest?.isFullScreen == true ? uiState.imagePickerRequest : nil },
                set: { uiState.imagePickerRequest = $0 }
            )) { request in
                ImagePickerView(onImagePicked: { image in
                    let resizedImage = image.resized(toMaxDimension: 1024)
                    if let data = resizedImage.jpegData(compressionQuality: 0.8) {
                        viewModel.updateFolderImage(imageData: data, at: folderPath)
                    }
                }, sourceType: request.sourceType)
                .ignoresSafeArea()
            }
            // Photo Library - sheet
            .sheet(item: Binding(
                get: { uiState.imagePickerRequest?.isFullScreen == false ? uiState.imagePickerRequest : nil },
                set: { uiState.imagePickerRequest = $0 }
            )) { request in
                ImagePickerView(onImagePicked: { image in
                    let resizedImage = image.resized(toMaxDimension: 1024)
                    if let data = resizedImage.jpegData(compressionQuality: 0.8) {
                        viewModel.updateFolderImage(imageData: data, at: folderPath)
                    }
                }, sourceType: request.sourceType)
            }
    }

    private var viewWithPrimarySheets: some View {
        viewWithToolbar
            .sheet(isPresented: $uiState.showingNewFolderSheet) {
                NewFolderSheet(
                    viewModel: viewModel,
                    folderPath: folderPath.isEmpty ? nil : folderPath,
                    isPresented: $uiState.showingNewFolderSheet,
                    batchMode: uiState.isBatchAddMode
                )
                .id(uiState.isBatchAddMode)
            }
            .sheet(isPresented: $uiState.showingFolderResult) {
                if let folderResult = uiState.selectedFolderResult {
                    ResultSheet(
                        folder: folderResult.folder,
                        path: folderResult.path,
                        isPresented: $uiState.showingFolderResult,
                        viewModel: viewModel,
                        navigateToFullPath: navigateToFullPath,
                        highlightedItemId: $uiState.navigationHighlightedItemId,
                        showHiddenFavoriteAlert: $uiState.showHiddenFavoriteAlert
                    )
                }
            }
            .sheet(isPresented: $uiState.showingFavorites) {
                FavoritesSheet(
                    viewModel: viewModel,
                    isPresented: $uiState.showingFavorites,
                    navigateToFullPath: navigateToFullPath,
                    highlightedItemId: $uiState.navigationHighlightedItemId,
                    currentPath: .constant(folderPath)
                )
            }
            .sheet(isPresented: $uiState.showingHistory) {
                HistorySheet(
                    viewModel: viewModel,
                    isPresented: $uiState.showingHistory,
                    navigateToFullPath: navigateToFullPath,
                    highlightedItemId: $uiState.navigationHighlightedItemId
                )
            }
            .sheet(isPresented: $uiState.showingHiddenFolders) {
                HiddenFoldersSheet(
                    viewModel: viewModel,
                    isPresented: $uiState.showingHiddenFolders,
                    navigateToFullPath: navigateToFullPath,
                    highlightedItemId: $uiState.navigationHighlightedItemId
                )
            }
            .sheet(item: $uiState.editingElement) { element in
                EditElementSheet(
                    viewModel: viewModel,
                    isPresented: Binding(
                        get: { uiState.editingElement != nil },
                        set: { if !$0 { uiState.editingElement = nil } }
                    ),
                    folder: element.folder,
                    folderPath: element.path,
                    moveCopyOperation: $uiState.moveCopyOperation
                )
            }
    }

    private var viewWithToolbar: some View {
        viewWithNavigation
            .navigationTitle(liveFolder.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                FolderDetailNavBarContent(
                    viewModel: viewModel,
                    uiState: uiState,
                    liveFolder: liveFolder,
                    folderPath: folderPath,
                    sortedSubfolders: sortedSubfolders,
                    isInHiddenContext: isInHiddenContext,
                    isSearchFocused: $isSearchFocused
                )
            }
    }

    private var viewWithNavigation: some View {
        mainLayout
            .navigationDestination(for: FolderDestination.self) { destination in
                if let folder = viewModel.getFolderFromPath(destination.path) {
                    FolderDetailView(
                        folder: folder,
                        folderPath: destination.path,
                        viewModel: viewModel,
                        highlightedItemId: uiState.navigationHighlightedItemId,
                        navigationPath: $navigationPath
                    )
                }
            }
            .navigationDestination(isPresented: $uiState.showingInfo) {
                WelcomeOnboardingView(mode: .info, onDismiss: {
                    uiState.showingInfo = false
                })
            }
    }

    private var mainLayout: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            contentStack
            overlayStack
        }
    }

    private var contentStack: some View {
        VStack(spacing: 0) {
            FolderDetailToolbarView(
                viewModel: viewModel,
                uiState: uiState,
                folderPath: folderPath,
                liveFolder: liveFolder
            )
            ZStack {
                contentBackground
                contentBody
            }
        }
    }

    private var contentBackground: some View {
        Group {
            if let imageData = inheritedImageData {
                if liveFolder.subfolders.isEmpty {
                    BlurredImageBackground(imageData: imageData, blurRadius: 25, overlayOpacity: 0.3)
                } else {
                    BlurredImageBackground(imageData: imageData)
                }
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.15),
                        Color.blue.opacity(0.05),
                        Color(.systemBackground).opacity(0.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
    }

    private var contentBody: some View {
        Group {
            if sortedSubfolders.isEmpty {
                FolderDetailEmptyStateView(
                    uiState: uiState,
                    folderPath: folderPath,
                    liveFolder: liveFolder,
                    isInHiddenContext: isInHiddenContext
                )
            } else {
                FolderDetailContentView(
                    viewModel: viewModel,
                    folderPath: folderPath,
                    sortedSubfolders: sortedSubfolders,
                    sortType: uiState.currentSortType,
                    viewType: uiState.currentViewType,
                    isInHiddenContext: isInHiddenContext,
                    showingHiddenAncestorAlert: $uiState.showingHiddenAncestorAlert,
                    hiddenAncestorAlertName: $uiState.hiddenAncestorAlertName,
                    showHiddenFavoriteAlert: $uiState.showHiddenFavoriteAlert,
                    editingElement: $uiState.editingElement,
                    imagePickerRequest: $uiState.imagePickerRequest,
                    moveCopyOperation: $uiState.moveCopyOperation,
                    isSelectionMode: $uiState.isSelectionMode,
                    selectedItemIds: $uiState.selectedItemIds,
                    navigationPath: $navigationPath,
                    onOpenSearch: {
                        withAnimation {
                            uiState.isSearching = true
                            isSearchFocused = true
                        }
                    },
                    highlightedItemId: highlightedItemId
                )
            }
        }
    }

    private var overlayStack: some View {
        Group {
            if !(folderPath.isEmpty && liveFolder.subfolders.isEmpty) {
                if uiState.isSelectionMode {
                    FolderDetailSelectionBarView(
                        viewModel: viewModel,
                        uiState: uiState,
                        sortedSubfolders: sortedSubfolders,
                        folderPath: folderPath,
                        isInHiddenContext: isInHiddenContext,
                        liveFolder: liveFolder
                    )
                } else {
                    FolderDetailBottomBarView(
                        uiState: uiState,
                        isInHiddenContext: isInHiddenContext,
                        randomizeAction: randomizeCurrentScreen,
                        isSearchFocused: $isSearchFocused
                    )
                }
            }
            if uiState.isSearching && !uiState.searchText.isEmpty {
                FolderDetailSearchResultsView(
                    viewModel: viewModel,
                    uiState: uiState,
                    navigateToFullPath: navigateToFullPath,
                    isSearchFocused: $isSearchFocused
                )
            }
        }
    }
    
    // MARK: - Helper Functions

    private func randomizeCurrentScreen() {
        HapticManager.mediumImpact()
        viewModel.cleanOldHistory()
        if let folderResult = viewModel.randomizeCurrentScreen(at: folderPath) {
            uiState.selectedFolderResult = folderResult
            uiState.showingFolderResult = true
        } else {
            HapticManager.warning()
            uiState.showingEmptyRandomizeAlert = true
        }
    }
    

    
    /// Navigates to a path by building the full hierarchy
    private func navigateToFullPath(_ targetPath: [Int]) {
        // Clear existing navigation path
        navigationPath.removeLast(navigationPath.count)
        
        // Build and push full hierarchy
        for i in 1...targetPath.count {
            let partialPath = Array(targetPath.prefix(i))
            navigationPath.append(FolderDestination(path: partialPath))
        }
    }
}

// MARK: - Alerts ViewModifier (extracted to reduce body complexity)
private struct AlertsModifier: ViewModifier {
    @Binding var showFirstElementAlert: Bool
    @Binding var showingEmptyRandomizeAlert: Bool
    @Binding var showingHiddenAncestorAlert: Bool
    var hiddenAncestorAlertName: String
    @Binding var showingHiddenRandomizeAlert: Bool
    @Binding var showHiddenFavoriteAlert: Bool
    
    func body(content: Content) -> some View {
        content
            .alert("Sin Elementos", isPresented: $showFirstElementAlert) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text("Crea tu primer elemento para comenzar")
            }
            .alert("Sin Elementos", isPresented: $showingEmptyRandomizeAlert) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text("No hay elementos disponibles para randomizar.")
            }
            .alert("Elemento Protegido", isPresented: $showingHiddenAncestorAlert) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text("Para modificar la visibilidad de este elemento, debes desocultar: \(hiddenAncestorAlertName)")
            }
            .alert("Elemento Oculto", isPresented: $showingHiddenRandomizeAlert) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text("Los elementos ocultos no participan en la randomización. Desoculta este elemento para poder randomizar.")
            }
            .alert("Elemento Oculto", isPresented: $showHiddenFavoriteAlert) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text("Los elementos ocultos no pueden ser favoritos. Desoculta este elemento primero.")
            }
    }
}
