//
//  FolderDetailView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 14/11/2025.
internal import SwiftUI
internal import Combine

struct FolderDetailView: View {
    let folder: Folder // Now a plain Folder struct (Root or Subfolder)
    let folderPath: [Int] // Empty for Root
    @ObservedObject var viewModel: RandomitasViewModel
    @Environment(\.dismiss) var dismiss
    
    var highlightedItemId: UUID? = nil
    
    @State var showingNewFolderSheet = false
    @State var isBatchAddMode = false // New: batch add mode flag
    @State var showingRenameSheet = false
    @State var renameTarget: (id: UUID, name: String, type: String)?
    @State var currentViewType: RandomitasViewModel.ViewType = .list
    @State var currentSortType: RandomitasViewModel.SortType = .nameAsc
    @State var imagePickerRequest: ImagePickerRequest?
    @State var showingFavorites = false
    @State var showingHistory = false
    @State var showingHiddenFolders = false
    @State var showingHiddenElements = false // Toggle for hidden elements view
    @State var moveCopyOperation: MoveCopyOperation?
    
    @State private var isSelectionMode = false
    @State private var selectedItemIds = Set<UUID>()
    @State private var showingMultiDeleteConfirmation = false

    @State private var pickerID = UUID()
    @State private var showLabel = false
    @State private var longPressDetected = false
    @State private var toolbarReady = false
    
    // Edit Sheet State
    @State private var editingElement: EditingInfo?
    
    // Search State (Global for Root, local context for sub?)
    // Actually search is usually global.
    @State private var isSearching = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // Folder Result State
    @State private var selectedFolderResult: (folder: Folder, path: [Int])?
    @State private var showingFolderResult = false
    @Binding var navigationPath: NavigationPath
    @State private var navigationHighlightedItemId: UUID? 
    
    // Dynamic access to live data
    var liveFolder: Folder {
        if folderPath.isEmpty {
            return viewModel.rootFolder
        }
        return viewModel.getFolderFromPath(folderPath) ?? folder
    }
    
    var sortedSubfolders: [Folder] {
        let allSubfolders = liveFolder.subfolders
        let filtered = showingHiddenElements 
            ? allSubfolders.filter { $0.isHidden }
            : allSubfolders.filter { !$0.isHidden }
        return viewModel.sortFolders(filtered, by: currentSortType)
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
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // TOOLBAR
                toolbarView
                
                // CONTENT with optional blur background
                ZStack {
                    // Blurred image background (current folder or inherited from ancestor)
                    // Use subtle blur for empty state, normal blur for content
                    if let imageData = inheritedImageData {
                        if liveFolder.subfolders.isEmpty {
                            BlurredImageBackground(imageData: imageData, blurRadius: 25, overlayOpacity: 0.3)
                        } else {
                            BlurredImageBackground(imageData: imageData)
                        }
                    }
                    
                    // Actual content
                    if sortedSubfolders.isEmpty {
                        emptyState
                    } else {
                        mainContentView
                    }
                }
            }
            
            // BOTTOM BAR
            if isSelectionMode {
                selectionActionBar
            } else {
                bottomBarView
            }
            
            // Search Results Overlay
            if isSearching && !searchText.isEmpty {
                searchResultsView
            }
        }
        .navigationDestination(for: FolderDestination.self) { destination in
            if let folder = viewModel.getFolderFromPath(destination.path) {
                FolderDetailView(
                    folder: folder,
                    folderPath: destination.path,
                    viewModel: viewModel,
                    highlightedItemId: navigationHighlightedItemId,
                    navigationPath: $navigationPath
                )
            }
        }
        .navigationTitle(liveFolder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    // Solo mostrar eye.slash cuando el folder ACTUAL está oculto
                    if liveFolder.isHidden {
                        Image(systemName: "eye.slash")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                    Text(liveFolder.name)
                        .font(.headline)
                        .foregroundColor(liveFolder.isHidden ? .gray : .primary)
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                if isSelectionMode {
                    Button("Listo") {
                        HapticManager.lightImpact()
                        isSelectionMode = false
                        selectedItemIds.removeAll()
                    }
                } else {
                    Button(action: {
                        withAnimation(.spring()) {
                            isSearching = true
                            isSearchFocused = true
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    if folderPath.isEmpty {
                        if !isSelectionMode {
                            Menu {
                                Button(action: {
                                    withAnimation {
                                        isSelectionMode = true
                                    }
                                }) {
                                    Label("Seleccionar", systemImage: "checkmark.circle")
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        showingHiddenElements.toggle()
                                    }
                                }) {
                                    if showingHiddenElements {
                                        Label("Volver a Elementos", systemImage: "atom")
                                    } else {
                                        Label("Elementos Ocultos", systemImage: "eye.slash")
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.blue)
                            }
                        } else {
                            let allSelected = !sortedSubfolders.isEmpty && selectedItemIds.count == sortedSubfolders.count
                            Button(action: {
                                HapticManager.selection()
                                if allSelected {
                                    selectedItemIds.removeAll()
                                } else {
                                    let allIds = sortedSubfolders.map { $0.id }
                                    selectedItemIds = Set(allIds)
                                }
                            }) {
                                Label(
                                    allSelected ? "Deseleccionar Todo" : "Seleccionar Todo",
                                    systemImage: allSelected ? "checkmark.circle.badge.xmark.fill" : "checkmark.circle.badge.plus"
                                )
                            }
                            .tint(.blue)
                        }
                    } else {
                        // Subfolder Logic
                        if !isSelectionMode {
                            Button(action: { HapticManager.lightImpact(); viewModel.toggleFolderFavorite(folder: liveFolder, path: folderPath) }) {
                                Image(systemName: viewModel.isFolderFavorite(folderId: liveFolder.id) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                            
                            Menu {
                                // Editar el elemento padre
                                Button(action: {
                                    HapticManager.lightImpact()
                                    editingElement = EditingInfo(folder: liveFolder, path: folderPath)
                                }) {
                                    Label("Editar", systemImage: "pencil")
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        isSelectionMode = true
                                    }
                                }) {
                                    Label("Seleccionar", systemImage: "checkmark.circle")
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        showingHiddenElements.toggle()
                                    }
                                }) {
                                    if showingHiddenElements {
                                        Label("Volver a Elementos", systemImage: "atom")
                                    } else {
                                        Label("Elementos Ocultos", systemImage: "eye.slash")
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.blue)
                            }
                        } else {
                             // Selection Mode in Subfolder -> Show Select All / Deselect All
                             let allSelected = !sortedSubfolders.isEmpty && selectedItemIds.count == sortedSubfolders.count
                             Button(action: {
                                 HapticManager.selection()
                                 if allSelected {
                                     selectedItemIds.removeAll()
                                 } else {
                                     let allIds = sortedSubfolders.map { $0.id }
                                     selectedItemIds = Set(allIds)
                                 }
                             }) {
                                 Label(
                                     allSelected ? "Deseleccionar Todo" : "Seleccionar Todo",
                                     systemImage: allSelected ? "checkmark.circle.badge.xmark.fill" : "checkmark.circle.badge.plus"
                                 )
                             }
                             .tint(.blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            NewFolderSheet(
                viewModel: viewModel,
                folderPath: folderPath.isEmpty ? nil : folderPath,
                isPresented: $showingNewFolderSheet,
                batchMode: isBatchAddMode
            )
            .id(isBatchAddMode)
        }
        .sheet(isPresented: $showingFolderResult) {
            if let folderResult = selectedFolderResult {
                ResultSheet(
                    folder: folderResult.folder,
                    path: folderResult.path,
                    isPresented: $showingFolderResult,
                    viewModel: viewModel,
                    navigateToFullPath: navigateToFullPath,
                    highlightedItemId: $navigationHighlightedItemId
                )
            }
        }
        .sheet(isPresented: $showingFavorites) {
            FavoritesSheet(
                viewModel: viewModel,
                isPresented: $showingFavorites,
                navigateToFullPath: navigateToFullPath,
                highlightedItemId: $navigationHighlightedItemId,
                currentPath: .constant(folderPath)
            )
        }
        .sheet(isPresented: $showingHistory) {
            HistorySheet(
                viewModel: viewModel,
                isPresented: $showingHistory,
                navigateToFullPath: navigateToFullPath,
                highlightedItemId: $navigationHighlightedItemId
            )
        }
        .sheet(isPresented: $showingHiddenFolders) {
            HiddenFoldersSheet(
                viewModel: viewModel,
                isPresented: $showingHiddenFolders,
                navigateToFullPath: navigateToFullPath,
                highlightedItemId: $navigationHighlightedItemId
            )
        }
        .sheet(item: $editingElement) { element in
            EditElementSheet(
                viewModel: viewModel,
                isPresented: Binding(
                    get: { editingElement != nil },
                    set: { if !$0 { editingElement = nil } }
                ),
                folder: element.folder,
                folderPath: element.path,
                moveCopyOperation: $moveCopyOperation
            )
        }
        // Camera - fullscreen cover
        .fullScreenCover(item: Binding(
            get: { imagePickerRequest?.isFullScreen == true ? imagePickerRequest : nil },
            set: { imagePickerRequest = $0 }
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
            get: { imagePickerRequest?.isFullScreen == false ? imagePickerRequest : nil },
            set: { imagePickerRequest = $0 }
        )) { request in
            ImagePickerView(onImagePicked: { image in
                let resizedImage = image.resized(toMaxDimension: 1024)
                if let data = resizedImage.jpegData(compressionQuality: 0.8) {
                    viewModel.updateFolderImage(imageData: data, at: folderPath)
                }
            }, sourceType: request.sourceType)
        }
        .sheet(item: $moveCopyOperation) { operation in
            MoveCopySheet(
                viewModel: viewModel,
                isPresented: Binding(
                    get: { moveCopyOperation != nil },
                    set: { if !$0 { moveCopyOperation = nil } }
                ),
                foldersToMove: operation.items,
                sourceContainerPath: operation.sourceContainerPath,
                isCopy: operation.isCopy,
                onSuccess: {
                    isSelectionMode = false
                    selectedItemIds.removeAll()
                }
            )
        }
        .confirmationDialog("¿Estás seguro?", isPresented: $showingMultiDeleteConfirmation, titleVisibility: .visible) {
            Button("Eliminar \(selectedItemIds.count) elementos", role: .destructive) {
                if folderPath.isEmpty {
                    viewModel.batchDeleteRootFolders(ids: selectedItemIds)
                } else {
                    viewModel.batchDeleteSubfolders(ids: selectedItemIds, from: folderPath)
                }
                isSelectionMode = false
                selectedItemIds.removeAll()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
        .onAppear {
            currentViewType = viewModel.getViewType(for: folderPath.isEmpty ? nil : liveFolder.id)
            currentSortType = viewModel.getSortType(for: folderPath.isEmpty ? nil : liveFolder.id)
            // Forzar re-render para que los gestos se registren correctamente
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                toolbarReady = true
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var toolbarView: some View {
        HStack(spacing: 25) {
            SortMenuView(sortType: $currentSortType)
                .foregroundColor(.blue)
                .font(.system(size: 18))
                .onChange(of: currentSortType) { viewModel.setSortType($0, for: folderPath.isEmpty ? nil : liveFolder.id) }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            
            Menu {
                Picker("Vista", selection: $currentViewType) {
                    Text("Lista").tag(RandomitasViewModel.ViewType.list)
                    Text("Cuadrícula").tag(RandomitasViewModel.ViewType.grid)
                    Text("Galería").tag(RandomitasViewModel.ViewType.gallery)
                }
                .onChange(of: currentViewType) { newValue in
                    viewModel.setViewType(newValue, for: folderPath.isEmpty ? nil : liveFolder.id)
                }
            } label: {
                Image(systemName: "rectangle.grid.1x2")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            
            Button(action: { HapticManager.lightImpact(); showingHistory = true }) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            
            if !showingHiddenElements && !isSelectionMode {
                Button {
                    // Solo abrir en modo normal si NO fue un long press
                    if !longPressDetected {
                        HapticManager.lightImpact()
                        isBatchAddMode = false
                        showingNewFolderSheet = true
                    }
                    longPressDetected = false
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("addElementButton")
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            longPressDetected = true
                            isBatchAddMode = true
                            showingNewFolderSheet = true
                        }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .zIndex(1)
        .id(toolbarReady) // Fuerza re-render para que los gestos se registren
    }


    private var mainContentView: some View {
        // Shared Views are now Generic
        switch currentViewType {
        case .list:
            AnyView(FolderDetailListView(
                viewModel: viewModel,
                folderPath: folderPath,
                sortedSubfolders: sortedSubfolders,
                editingElement: $editingElement,

                imagePickerRequest: $imagePickerRequest,
                moveCopyOperation: $moveCopyOperation,
                isSelectionMode: $isSelectionMode,
                navigationPath: $navigationPath,
                selectedItemIds: $selectedItemIds,
                onOpenSearch: {
                    withAnimation {
                        isSearching = true
                        isSearchFocused = true
                    }
                },
                highlightedItemId: highlightedItemId
            ))
        case .grid:
            AnyView(FolderDetailGridView(
                viewModel: viewModel,
                folderPath: folderPath,
                sortedSubfolders: sortedSubfolders,
                editingElement: $editingElement,

                imagePickerRequest: $imagePickerRequest,
                moveCopyOperation: $moveCopyOperation,
                isSelectionMode: $isSelectionMode,
                navigationPath: $navigationPath,
                selectedItemIds: $selectedItemIds,
                onOpenSearch: {
                    withAnimation {
                        isSearching = true
                        isSearchFocused = true
                    }
                },
                highlightedItemId: highlightedItemId
            ))
        case .gallery:
            AnyView(FolderDetailGalleryView(
                viewModel: viewModel,
                folderPath: folderPath,
                sortedSubfolders: sortedSubfolders,
                editingElement: $editingElement,

                imagePickerRequest: $imagePickerRequest,
                moveCopyOperation: $moveCopyOperation,
                isSelectionMode: $isSelectionMode,
                navigationPath: $navigationPath,
                selectedItemIds: $selectedItemIds,
                onOpenSearch: {
                    withAnimation {
                        isSearching = true
                        isSearchFocused = true
                    }
                },
                highlightedItemId: highlightedItemId
            ))
        }
    }
    
    @ViewBuilder
    private var selectionActionBar: some View {
        if isSelectionMode {
            VStack(spacing: 0) {
                Spacer()
                
                // Selection count indicator
                if !selectedItemIds.isEmpty {
                    Text("\(selectedItemIds.count) seleccionado\(selectedItemIds.count > 1 ? "s" : "")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
                
                HStack(spacing: 12) {
                    // Move
                    Button(action: {
                        HapticManager.mediumImpact()
                        let selectedFolders = sortedSubfolders.filter { selectedItemIds.contains($0.id) }
                        guard !selectedFolders.isEmpty else { return }
                        moveCopyOperation = MoveCopyOperation(items: selectedFolders, sourceContainerPath: folderPath, isCopy: false)
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.turn.up.right")
                                .font(.system(size: 22, weight: .medium))
                            Text("Mover")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(selectedItemIds.isEmpty ? Color(.systemGray5) : Color.blue.opacity(0.12))
                        .foregroundColor(selectedItemIds.isEmpty ? .gray : .blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedItemIds.isEmpty)
                    
                    // Copy
                    Button(action: {
                        HapticManager.mediumImpact()
                        let selectedFolders = sortedSubfolders.filter { selectedItemIds.contains($0.id) }
                        guard !selectedFolders.isEmpty else { return }
                        moveCopyOperation = MoveCopyOperation(items: selectedFolders, sourceContainerPath: folderPath, isCopy: true)
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 22, weight: .medium))
                            Text("Copiar")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(selectedItemIds.isEmpty ? Color(.systemGray5) : Color.blue.opacity(0.12))
                        .foregroundColor(selectedItemIds.isEmpty ? .gray : .blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedItemIds.isEmpty)
                    
                    // Hide
                    Button(action: {
                        HapticManager.mediumImpact()
                        guard !selectedItemIds.isEmpty else { return }
                        if folderPath.isEmpty {
                             viewModel.batchToggleHiddenRoot(ids: selectedItemIds)
                        } else {
                             viewModel.batchToggleHiddenSubfolders(ids: selectedItemIds, at: folderPath)
                        }
                        
                        isSelectionMode = false
                        selectedItemIds.removeAll()
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 22, weight: .medium))
                            Text("Ocultar")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(selectedItemIds.isEmpty ? Color(.systemGray5) : Color.orange.opacity(0.12))
                        .foregroundColor(selectedItemIds.isEmpty ? .gray : .orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedItemIds.isEmpty)
                    
                    // Delete
                    Button(action: {
                        HapticManager.warning()
                        showingMultiDeleteConfirmation = true
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 22, weight: .medium))
                            Text("Eliminar")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(selectedItemIds.isEmpty ? Color(.systemGray5) : Color.red.opacity(0.12))
                        .foregroundColor(selectedItemIds.isEmpty ? .gray : .red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedItemIds.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: -4)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: -1)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(2)
        }
    }
    
    @ViewBuilder
    private var bottomBarView: some View {
        VStack {
            Spacer()
                
                if isSearching {
                    // SEARCH BAR MODE
                HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            TextField("Buscar Elementos...", text: $searchText)
                            .focused($isSearchFocused)
                            .submitLabel(.search)
                            .onSubmit {
                                // Optional: Action on submit
                            }
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        Button("Cancelar") {
                            withAnimation(.spring()) {
                                isSearching = false
                                searchText = ""
                                isSearchFocused = false
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // NORMAL MODE
                    ZStack {
                        // Static shadow layer - always present, no animation
                        HStack {
                            // Shadow placeholder for Hidden button
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 56, height: 56)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                            
                            Spacer()
                            
                            // Shadow placeholder for Shuffle button
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 72, height: 72)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                            
                            Spacer()
                            
                            // Shadow placeholder for Favorites button
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 56, height: 56)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal, 16)
                        
                        // Animated buttons layer
                        HStack {
                            // Hidden Folders Button
                            Button(action: { HapticManager.lightImpact(); showingHiddenFolders = true }) {
                                Image(systemName: "eye.slash")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.orange)
                                    .frame(width: 56, height: 56)
                                    .clipShape(Circle())
                                    .glassEffect(.clear)
                            }
                            
                            Spacer()
                            
                            // Shuffle Button (Center)
                            Menu {
                                if !liveFolder.subfolders.isEmpty {
                                    Button(action: randomizeCurrentScreen) {
                                        Label("Randomizar Elemento", systemImage: "atom")
                                    }
                                }
                                Button(action: randomizeAll) {
                                    Label("Randomizar todo", systemImage: "shuffle")
                                }
                            } label: {
                                Image("ShuffleIcon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .frame(width: 72, height: 72)
                                    .clipShape(Circle())
                                    .glassEffect(.clear)
                            }
                            
                            Spacer()
                            
                            // Favorites Button
                            Button(action: { HapticManager.lightImpact(); showingFavorites = true }) {
                                Image(systemName: "star")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.yellow)
                                    .frame(width: 56, height: 56)
                                    .clipShape(Circle())
                                    .glassEffect(.clear)
                            }
                        }
                        .padding(.horizontal, 16)
                        .transition(.scale.combined(with: .opacity))
                    }
                    .padding(.bottom, 0)
                    .padding(.top, 20)
                    .background(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black.opacity(0.05), location: 0.3),
                                .init(color: .black.opacity(0.15), location: 0.6),
                                .init(color: .black.opacity(0.35), location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .padding(.top, -40)
                        .padding(.bottom, -100)
                    )
                }
        }
    }
    
    @ViewBuilder
    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // Header background
            Color(.systemBackground)
                .frame(height: 1)
                .ignoresSafeArea()
            
            List {
                let results = viewModel.search(query: searchText)
                if !results.isEmpty {
                    Section(header: Text("Elementos encontrados:")) {
                        ForEach(results, id: \.0.id) { folder, path, parentName in
                            Button(action: {
                                navigationHighlightedItemId = folder.id
                                // Navigate directly to the element
                                navigateToFullPath(path)
                                
                                // Reset search
                                isSearching = false
                                searchText = ""
                                isSearchFocused = false
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(folder.name)
                                            .foregroundColor(.primary)
                                        HStack(spacing: 4) {
                                            Text("< \(parentName)")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                } else {
                    Text("No se encontraron Elementos")
                    .foregroundColor(.gray)
                }
            }
            .listStyle(.plain)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .padding(.bottom, 80)
        .zIndex(1)
        .transition(.opacity)
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: showingHiddenElements ? "eye.slash" : "bookmark.slash")
                .font(.system(size: 60))
            
            VStack(spacing: 8) {
                if showingHiddenElements {
                    Text("Sin Elementos Ocultos")
                        .font(.headline)
                    Text("Los elementos ocultos aparecerán aquí")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                } else {
                    Text(folderPath.isEmpty ? "Sin Elementos creados" : "Sin Elementos guardados")
                        .font(.headline)
                    Text(folderPath.isEmpty ? "Crea un Elemento para comenzar" : "Crea uno nuevo.")
                        .font(.subheadline)
                }
            }
            
            if !showingHiddenElements {
                HStack(spacing: 16) {
                    if folderPath.isEmpty {
                        // Big Button for Root
                        Button {
                            if !longPressDetected {
                                HapticManager.lightImpact()
                                isBatchAddMode = false
                                showingNewFolderSheet = true
                            }
                            longPressDetected = false
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                Text("Nuevo Elemento")
                                    .font(.headline)
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: 250)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .glassEffect(.clear)
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    longPressDetected = true
                                    isBatchAddMode = true
                                    showingNewFolderSheet = true
                                }
                        )
                    } else {
                        // Square Button for Sub
                        Button {
                            if !longPressDetected {
                                HapticManager.lightImpact()
                                isBatchAddMode = false
                                showingNewFolderSheet = true
                            }
                            longPressDetected = false
                        } label: {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 100, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .glassEffect(.clear)
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    longPressDetected = true
                                    isBatchAddMode = true
                                    showingNewFolderSheet = true
                                }
                        )
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions

    private func randomizeCurrentScreen() {
        HapticManager.mediumImpact()
        viewModel.cleanOldHistory()
        if let folderResult = viewModel.randomizeCurrentScreen(at: folderPath) {
            selectedFolderResult = folderResult
            showingFolderResult = true
        }
    }
    
    private func randomizeAll() {
        HapticManager.mediumImpact()
        viewModel.cleanOldHistory()
        if let folderResult = viewModel.randomizeAll() {
            selectedFolderResult = folderResult
            showingFolderResult = true
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

class FolderWrapper: ObservableObject {
    @Published var folder: Folder
    init(_ folder: Folder) { self.folder = folder }
}
