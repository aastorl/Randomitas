//
//  FolderDetailView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 14/11/2025.
//

internal import SwiftUI
internal import Combine

struct FolderDetailView: View {
    @ObservedObject var folder: FolderWrapper
    let folderPath: [Int]
    @ObservedObject var viewModel: RandomitasViewModel
    @Environment(\.dismiss) var dismiss
    
    var highlightedItemId: UUID? = nil // Added property
    
    @State var showingNewSubfolderSheet = false
    @State var showingRenameSheet = false
    @State var renameTarget: (id: UUID, name: String, type: String)?
    @State var currentViewType: RandomitasViewModel.ViewType = .list
    @State var currentSortType: RandomitasViewModel.SortType = .nameAsc
    @State var imagePickerRequest: ImagePickerRequest?
    @State var showingFavorites = false
    @State var showingHiddenFolders = false
    @State var moveCopyOperation: MoveCopyOperation?
    
    @State private var isSelectionMode = false
    @State private var selectedItemIds = Set<UUID>()
    @State private var showingMultiDeleteConfirmation = false

    @State private var editingId: UUID?
    @State private var editingName: String = ""
    @FocusState private var isEditing: Bool
    @State private var pickerID = UUID()
    @State private var showLabel = false
    
    // Search State
    @State private var isSearching = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // Folder Result State
    @State private var selectedFolderResult: (folder: Folder, path: [Int])?
    @State private var showingFolderResult = false
    @Binding var navigationPath: NavigationPath
    @State private var navigationHighlightedItemId: UUID? // For programmatic navigation
    
    var liveFolder: Folder {
        getFolderAtPath(folderPath) ?? folder.folder
    }
    
    var sortedSubfolders: [Folder] {
        viewModel.sortFolders(liveFolder.subfolders, by: currentSortType)
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // TOOLBAR
                toolbarView
                
                // CONTENT
                Group {
                    if liveFolder.subfolders.isEmpty {
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
            
            // Removed - using navigationDestination instead
        }
        .navigationDestination(for: FolderDestination.self) { destination in
            if let folder = getFolderAtPath(destination.path) {
                FolderDetailView(
                    folder: FolderWrapper(folder),
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
                Text(liveFolder.name)
                    .font(.headline)
                    .foregroundColor(liveFolder.isHidden ? .gray : .primary)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                if isSelectionMode {
                    Button("Listo") {
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
                    if !isSelectionMode {
                        Button(action: { viewModel.toggleFolderFavorite(folder: liveFolder, path: folderPath) }) {
                            Image(systemName: viewModel.isFolderFavorite(folderId: liveFolder.id) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                        
                        Menu {
                            Menu {
                                Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .camera) }) {
                                    Label("Tomar foto", systemImage: "camera.fill")
                                }
                                Button(action: { imagePickerRequest = ImagePickerRequest(sourceType: .photoLibrary) }) {
                                    Label("Seleccionar de Galería", systemImage: "photo.fill")
                                }
                                if liveFolder.imageData != nil {
                                    Divider()
                                    Button(role: .destructive, action: { viewModel.updateFolderImage(imageData: nil, at: folderPath) }) {
                                        Label("Eliminar Imagen", systemImage: "trash")
                                    }
                                }
                            } label: {
                                Label("Editar Imagen", systemImage: "photo")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewSubfolderSheet) {
            NewSubfolderSheet(viewModel: viewModel, folderPath: folderPath, isPresented: $showingNewSubfolderSheet)
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
                .presentationDetents([.height(620)])
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
        .sheet(isPresented: $showingHiddenFolders) {
            HiddenFoldersSheet(
                viewModel: viewModel,
                isPresented: $showingHiddenFolders,
                navigateToFullPath: navigateToFullPath,
                highlightedItemId: $navigationHighlightedItemId
            )
        }
        .sheet(item: $imagePickerRequest) { request in
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
                viewModel.batchDeleteSubfolders(ids: selectedItemIds, from: folderPath)
                isSelectionMode = false
                selectedItemIds.removeAll()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
        .onAppear {
            currentViewType = viewModel.getViewType(for: liveFolder.id)
            currentSortType = viewModel.getSortType(for: liveFolder.id)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var toolbarView: some View {
        HStack(spacing: 25) {
            SortMenuView(sortType: $currentSortType)
                .foregroundColor(.blue)
                .font(.system(size: 18))
                .onChange(of: currentSortType) { viewModel.setSortType($0, for: liveFolder.id) }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            
            Menu {
                Picker("Vista", selection: $currentViewType) {
                    Text("Lista").tag(RandomitasViewModel.ViewType.list)
                    Text("Cuadrícula").tag(RandomitasViewModel.ViewType.grid)
                    Text("Galería").tag(RandomitasViewModel.ViewType.gallery)
                }
                .onChange(of: currentViewType) { newValue in
                    viewModel.setViewType(newValue, for: liveFolder.id)
                }
            } label: {
                Image(systemName: "rectangle.grid.1x2")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            
            Button(action: { showingNewSubfolderSheet = true }) {
                Image(systemName: "plus")
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4) // Added shadow
        .zIndex(1) // Ensure it stays on top
    }


    private var mainContentView: some View {
        switch currentViewType {
        case .list:
            AnyView(FolderDetailListView(
                viewModel: viewModel,
                folder: FolderWrapper(liveFolder),
                folderPath: folderPath,
                sortedSubfolders: sortedSubfolders,
                editingId: $editingId,
                editingName: $editingName,
                isEditing: $isEditing,
                imagePickerRequest: $imagePickerRequest,
                moveCopyOperation: $moveCopyOperation,
                isSelectionMode: $isSelectionMode,
                navigationPath: $navigationPath,
                selectedItemIds: $selectedItemIds,
                highlightedItemId: highlightedItemId
            ))
        case .grid:
            AnyView(FolderDetailGridView(
                viewModel: viewModel,
                folder: FolderWrapper(liveFolder),
                folderPath: folderPath,
                sortedSubfolders: sortedSubfolders,
                editingId: $editingId,
                editingName: $editingName,
                isEditing: $isEditing,
                imagePickerRequest: $imagePickerRequest,
                moveCopyOperation: $moveCopyOperation,
                isSelectionMode: $isSelectionMode,
                navigationPath: $navigationPath,
                selectedItemIds: $selectedItemIds,
                highlightedItemId: highlightedItemId
            ))
        case .gallery:
            AnyView(FolderDetailGalleryView(
                viewModel: viewModel,
                folder: FolderWrapper(liveFolder),
                folderPath: folderPath,
                sortedSubfolders: sortedSubfolders,
                editingId: $editingId,
                editingName: $editingName,
                isEditing: $isEditing,
                imagePickerRequest: $imagePickerRequest,
                moveCopyOperation: $moveCopyOperation,
                isSelectionMode: $isSelectionMode,
                navigationPath: $navigationPath,
                selectedItemIds: $selectedItemIds,
                highlightedItemId: highlightedItemId
            ))
        }
    }
    
    @ViewBuilder
    private var selectionActionBar: some View {
        if isSelectionMode {
            VStack(spacing: 0) {
                Spacer()
                HStack(spacing: 0) { // Spacing 0 to distribute evenly
                    // Move
                    Button(action: {
                        let selectedFolders = sortedSubfolders.filter { selectedItemIds.contains($0.id) }
                        guard !selectedFolders.isEmpty else { return }
                        moveCopyOperation = MoveCopyOperation(items: selectedFolders, sourceContainerPath: folderPath, isCopy: false)
                    }) {
                        VStack {
                            Image(systemName: "arrow.turn.up.right")
                                .font(.system(size: 20))
                            Text("Mover")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(selectedItemIds.isEmpty)
                    
                    // Copy
                    Button(action: {
                        let selectedFolders = sortedSubfolders.filter { selectedItemIds.contains($0.id) }
                        guard !selectedFolders.isEmpty else { return }
                        moveCopyOperation = MoveCopyOperation(items: selectedFolders, sourceContainerPath: folderPath, isCopy: true)
                    }) {
                        VStack {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 20))
                            Text("Copiar")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(selectedItemIds.isEmpty)
                    
                    // Hide
                    Button(action: {
                        guard !selectedItemIds.isEmpty else { return }
                        viewModel.batchToggleHiddenSubfolders(ids: selectedItemIds, at: folderPath)
                        isSelectionMode = false
                        selectedItemIds.removeAll()
                    }) {
                        VStack {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 20))
                            Text("Ocultar")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(selectedItemIds.isEmpty)
                    
                    // Delete
                    Button(action: {
                        showingMultiDeleteConfirmation = true
                    }) {
                        VStack {
                            Image(systemName: "trash")
                                .font(.system(size: 20))
                            Text("Eliminar")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(selectedItemIds.isEmpty)
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
            }
            .transition(.move(edge: .bottom))
            .zIndex(2) // Above other content
        }
    }
    
    @ViewBuilder
    private var bottomBarView: some View {
        if !isEditing {
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
                    HStack(spacing: 16) {
                        // Hidden Folders Button
                        Button(action: { showingHiddenFolders = true }) {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(uiColor: .systemBackground))
                                .frame(width: 56, height: 56)
                                .background(Color.primary)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        
                        // Shuffle Button (Center Pill)
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
                            HStack(spacing: 8) {
                                Image(systemName: "shuffle")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Shuffle")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.primary)
                            .foregroundColor(Color(uiColor: .systemBackground))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        
                        // Favorites Button
                        Button(action: { showingFavorites = true }) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(uiColor: .systemBackground))
                                .frame(width: 56, height: 56)
                                .background(Color.primary)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 0)
                    .padding(.top, 20)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                            .padding(.top, -20)
                            .padding(.bottom, -100)
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    @ViewBuilder
    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // Header background to cover navigation bar area
            Color(.systemBackground)
                .frame(height: 1) // Minimal height
                .ignoresSafeArea()
            
            List {
                let results = viewModel.search(query: searchText)
                if !results.isEmpty {
                    Section(header: Text("Elementos encontrados:")) {
                        ForEach(results, id: \.0.id) { folder, path, parentName in
                            Button(action: {
                                navigationHighlightedItemId = folder.id
                                // Navigate to parent path with full hierarchy
                                let parentPath = Array(path.dropLast())
                                navigateToFullPath(parentPath)
                                
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
        .padding(.bottom, 80) // Keep space for bottom bar
        .zIndex(1)
        .transition(.opacity)
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bookmark.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Sin Elementos guardados.")
                    .font(.headline)
                Text("Crea uno nuevo.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                Button(action: { showingNewSubfolderSheet = true }) {
                    VStack {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                    .frame(width: 100, height: 80)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions

    private func randomizeCurrentScreen() {
        viewModel.cleanOldHistory()
        if let folderResult = viewModel.randomizeCurrentScreen(at: folderPath) {
            selectedFolderResult = folderResult
            showingFolderResult = true
        }
    }
    
    private func randomizeAll() {
        viewModel.cleanOldHistory()
        if let folderResult = viewModel.randomizeAll() {
            selectedFolderResult = folderResult
            showingFolderResult = true
        }
    }
    
    private func buildFolderViewFromPath(_ path: [Int]) -> FolderDetailView? {
        guard let folder = getFolderAtPath(path) else { return nil }
        
        return FolderDetailView(
            folder: FolderWrapper(folder),
            folderPath: path,
            viewModel: viewModel,
            highlightedItemId: navigationHighlightedItemId,
            navigationPath: $navigationPath
        )
    }
    
    private func buildFolderView(from pathString: String) -> FolderDetailView? {
        guard let path = extractFolderPath(from: pathString) else { return nil }
        return buildFolderViewFromPath(path)
    }
    
    private func getFolderAtPath(_ indices: [Int]) -> Folder? {
        guard !indices.isEmpty else { return nil }
        guard indices[0] < viewModel.folders.count else { return nil }
        
        var current = viewModel.folders[indices[0]]
        
        for i in 1..<indices.count {
            guard indices[i] < current.subfolders.count else { return nil }
            current = current.subfolders[indices[i]]
        }
        
        return current
    }
    
    private func extractFolderPath(from pathString: String) -> [Int]? {
        let components = pathString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        return components.compactMap { Int($0) }
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
