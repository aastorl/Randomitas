//
//  ContentView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 13/11/2025.
//

internal import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = RandomitasViewModel()
    @State var showingNewFolderSheet = false
    @State var showingFavorites = false
    @State var showingHistory = false
    @State var showingHiddenFolders = false
    @State var currentViewType: RandomitasViewModel.ViewType = .list
    @State var currentSortType: RandomitasViewModel.SortType = .nameAsc
    @State var showingImagePicker = false
    @State var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State var selectedFolderId: UUID?
    @State var moveCopyOperation: MoveCopyOperation?
    
    @State private var editingId: UUID?
    @State private var editingName: String = ""
    @FocusState private var isEditing: Bool
    @State private var pickerID = UUID()
    @State private var folderToDelete: UUID?
    @State private var showLabel = false
    
    // Search State
    @State private var isSearching = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // Folder Result State
    @State private var selectedFolderResult: (folder: Folder, path: [Int])?
    @State private var showingFolderResult = false
    @State private var navigationPath = NavigationPath()
    @State private var highlightedItemId: UUID?
    
    // Selection Mode State (Root)
    @State private var isSelectionMode = false
    @State private var selectedItemIds = Set<UUID>()
    @State private var showingMultiDeleteConfirmation = false
    
    var sortedFolders: [Folder] {
        viewModel.sortFolders(viewModel.folders, by: currentSortType)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // TOOLBAR
                    toolbarView
                    
                    // CONTENT
                    Group {
                        if viewModel.folders.isEmpty {
                            emptyState
                        } else {
                            mainContentView
                        }
                    }
                }
                
                // BOTTOM BAR
                bottomBarView
                
                // Selection Action Bar
                if isSelectionMode {
                    selectionActionBar
                        .transition(.move(edge: .bottom))
                        .zIndex(2)
                }
                
                // Search Results Overlay
                if isSearching && !searchText.isEmpty {
                    searchResultsView
                }
                
                // Removed - using navigationDestination instead
            }
            .navigationTitle("Randomitas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelectionMode {
                        Button("Hecho") {
                            withAnimation {
                                isSelectionMode = false
                                selectedItemIds.removeAll()
                            }
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
                     // Empty - removed "Seleccionar" button
                }
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
            .sheet(isPresented: $showingNewFolderSheet) {
                NewFolderSheet(viewModel: viewModel, isPresented: $showingNewFolderSheet)
            }
            .sheet(isPresented: $showingFolderResult) {
                if let folderResult = selectedFolderResult {
                    ResultSheet(
                        folder: folderResult.folder,
                        path: folderResult.path,
                        isPresented: $showingFolderResult,
                        viewModel: viewModel,
                        navigateToFullPath: navigateToFullPath,
                        highlightedItemId: $highlightedItemId
                    )
                    .presentationDetents([.height(620)])
                }
            }
            .sheet(isPresented: $showingFavorites) {
                FavoritesSheet(
                    viewModel: viewModel,
                    isPresented: $showingFavorites,
                    navigateToFullPath: navigateToFullPath,
                    highlightedItemId: $highlightedItemId
                )
            }
            .navigationDestination(for: FolderDestination.self) { destination in
                if let folder = getFolderAtPath(destination.path) {
                    FolderDetailView(
                        folder: FolderWrapper(folder),
                        folderPath: destination.path,
                        viewModel: viewModel,
                        highlightedItemId: highlightedItemId,
                        navigationPath: $navigationPath
                    )
                }
            }
            .sheet(isPresented: $showingHistory) {
                HistorySheet(viewModel: viewModel, isPresented: $showingHistory)
            }
            .sheet(isPresented: $showingHiddenFolders) {
                HiddenFoldersSheet(
                    viewModel: viewModel,
                    isPresented: $showingHiddenFolders,
                    navigateToFullPath: navigateToFullPath,
                    highlightedItemId: $highlightedItemId
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                if let folderId = selectedFolderId, let idx = viewModel.folders.firstIndex(where: { $0.id == folderId }) {
                    ImagePickerView(onImagePicked: { image in
                        let resizedImage = image.resized(toMaxDimension: 1024)
                        if let data = resizedImage.jpegData(compressionQuality: 0.8) {
                            viewModel.updateFolderImage(imageData: data, at: [idx])
                        }
                    }, sourceType: imageSourceType)
                    .id(pickerID)
                }
            }
            .alert("¿Seguro quieres eliminar este Elemento?", isPresented: .constant(folderToDelete != nil)) {
                Button("Cancelar", role: .cancel) {
                    folderToDelete = nil
                }
                Button("Eliminar", role: .destructive) {
                    if let id = folderToDelete {
                        viewModel.deleteRootFolder(id: id)
                        folderToDelete = nil
                    }
                }
            }
            .alert("¿Eliminar \(selectedItemIds.count) elementos?", isPresented: $showingMultiDeleteConfirmation) {
                 Button("Cancelar", role: .cancel) { }
                 Button("Eliminar", role: .destructive) {
                     // Batch Delete
                     viewModel.batchDeleteRootFolders(ids: selectedItemIds)
                     isSelectionMode = false
                     selectedItemIds.removeAll()
                 }
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
                    isCopy: operation.isCopy
                )
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
                .onChange(of: currentSortType) { viewModel.setSortType($0, for: nil) }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            
            Menu {
                Picker("Vista", selection: $currentViewType) {
                    Text("Lista").tag(RandomitasViewModel.ViewType.list)
                    Text("Cuadrícula").tag(RandomitasViewModel.ViewType.grid)
                    Text("Galería").tag(RandomitasViewModel.ViewType.gallery)
                }
                .onChange(of: currentViewType) { newValue in
                    viewModel.setViewType(newValue, for: nil)
                }
            } label: {
                Image(systemName: "rectangle.grid.1x2")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            
            Button(action: { showingHistory = true }) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            
            Button(action: { showingNewFolderSheet = true }) {
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
    
    @ViewBuilder
    private var mainContentView: some View {
        switch currentViewType {
        case .list:
            listView
        case .grid:
            gridView
        case .gallery:
            galleryView
        }
    }
    
    @ViewBuilder
    private var bottomBarView: some View {
        // Hide bottom bar when renaming (keyboard is active)
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
                            if !viewModel.folders.isEmpty {
                                Button(action: randomizeCurrentScreen) {
                                    Label("Randomizar este Elemento", systemImage: "atom")
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
    private var selectionActionBar: some View {
        VStack {
            Spacer()
            HStack {
                // Move
                Button(action: {
                    let items = getSelectedFolders()
                    if !items.isEmpty {
                        moveCopyOperation = MoveCopyOperation(items: items, sourceContainerPath: [], isCopy: false)
                    }
                }) {
                    VStack {
                        Image(systemName: "arrow.turn.up.right")
                        Text("Mover").font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(selectedItemIds.isEmpty)
                
                // Copy
                Button(action: {
                    let items = getSelectedFolders()
                    if !items.isEmpty {
                        moveCopyOperation = MoveCopyOperation(items: items, sourceContainerPath: [], isCopy: true)
                    }
                }) {
                    VStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copiar").font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(selectedItemIds.isEmpty)
                
                // Hide/Show (Assume toggle based on majority? Or just toggle all? "Ocultar" implies set to hidden. )
                // User said "Ocultar".
                // I will use viewModel.batchSetHidden(ids: ..., hidden: true/false).
                // Or just toggle.
                Button(action: {
                    viewModel.batchToggleHiddenRoot(ids: selectedItemIds)
                    isSelectionMode = false
                    selectedItemIds.removeAll()
                }) {
                    VStack {
                        Image(systemName: "eye.slash")
                        Text("Ocultar").font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(selectedItemIds.isEmpty)
                
                // Delete
                Button(role: .destructive, action: {
                    showingMultiDeleteConfirmation = true
                }) {
                    VStack {
                        Image(systemName: "trash")
                        Text("Eliminar").font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(selectedItemIds.isEmpty)
            }
            .padding()
            .background(Color(.systemBackground).shadow(radius: 2))
        }
    }
    
    // Helper to get selected Folder objects
    private func getSelectedFolders() -> [Folder] {
        return viewModel.folders.filter { selectedItemIds.contains($0.id) }
    }

    @ViewBuilder
    private var searchResultsView: some View {
         // ... match existing ...
        VStack(spacing: 0) {
            // Header background to cover navigation bar area
            Color(.systemBackground)
                .frame(height: 1) // Minimal height, just to set background
                .ignoresSafeArea()
            
            List {
                let results = viewModel.search(query: searchText)
                if !results.isEmpty {
                    Section(header: Text("Elementos encontrados:")) {
                        ForEach(results, id: \.0.id) { folder, path, parentName in
                            Button(action: {
                                highlightedItemId = folder.id
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
                    Text("No se encontraron elementos")
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
                Text("Sin Elementos creados")
                .font(.headline)
                Text("Crea un Elemento para comenzar")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Button(action: { showingNewFolderSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Nuevo Elemento")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var listView: some View {
        List(selection: $selectedItemIds) {
            ForEach(sortedFolders, id: \.id) { folder in
                let idx = viewModel.folders.firstIndex(where: { $0.id == folder.id }) ?? 0
                ZStack(alignment: .leading) {
                NavigationLink(destination: FolderDetailView(
                    folder: FolderWrapper(folder),
                    folderPath: [idx],
                    viewModel: viewModel,
                    navigationPath: $navigationPath
                )) {
                    EmptyView()
                }
                    .opacity(0)
                    .disabled(isSelectionMode) // Disable navigation in selection mode
                    
                    HStack(spacing: 12) {
                        Image(systemName: "atom")
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)

                        if editingId == folder.id {
                            TextField("Nombre", text: $editingName)
                                .focused($isEditing)
                                .onSubmit {
                                    viewModel.renameFolder(id: folder.id, newName: editingName)
                                    editingId = nil
                                }
                        } else {
                            Text(folder.name)
                        }
                        
                        // Icono para carpetas ocultas
                        if folder.isHidden {
                            Image(systemName: "eye.slash")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                        
                        Spacer()
                        
                        // Indicador de navegación personalizado
                        if folder.subfolders.isEmpty {
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(.systemGray3))
                                .font(.system(size: 14, weight: .semibold))
                        } else {
                            Image(systemName: "arrow.right")
                                .foregroundColor(Color(.systemGray3))
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { folderToDelete = folder.id } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button { viewModel.toggleFolderFavorite(folder: folder, path: [idx]) } label: {
                        Label("Favorito", systemImage: viewModel.isFolderFavorite(folderId: folder.id) ? "star.fill" : "star")
                    }
                    Button {
                        editingId = folder.id
                        editingName = folder.name
                        isEditing = true
                    } label: {
                        Label("Renombrar", systemImage: "pencil")
                    }
                    Button {
                        isSelectionMode = true
                        selectedItemIds.insert(folder.id)
                    } label: {
                        Label("Seleccionar", systemImage: "checkmark.circle")
                    }
                    Button {
                        moveCopyOperation = MoveCopyOperation(items: [folder], sourceContainerPath: [], isCopy: false)
                    } label: {
                        Label("Mover", systemImage: "arrow.turn.up.right")
                    }
                    Button {
                        moveCopyOperation = MoveCopyOperation(items: [folder], sourceContainerPath: [], isCopy: true)
                    } label: {
                        Label("Copiar", systemImage: "doc.on.doc")
                    }
                    Button {
                        viewModel.toggleFolderHidden(folder: folder, path: [idx])
                    } label: {
                        Label(folder.isHidden ? "Mostrar" : "Ocultar", systemImage: folder.isHidden ? "eye" : "eye.slash")
                    }
                    Button(role: .destructive) { viewModel.deleteRootFolder(id: folder.id) } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }
        }
        .environment(\.editMode, .constant(isSelectionMode ? .active : .inactive))
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 80)
        }
    }
    
    @ViewBuilder
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(sortedFolders, id: \.id) { folder in
                    let idx = viewModel.folders.firstIndex(where: { $0.id == folder.id }) ?? 0
                    ZStack {
                        NavigationLink(destination: FolderDetailView(
                            folder: FolderWrapper(folder),
                            folderPath: [idx],
                            viewModel: viewModel,
                            navigationPath: $navigationPath
                        )) {
                            gridFolderCell(folder)
                                .overlay(
                                    ZStack {
                                        if isSelectionMode {
                                            Color.black.opacity(selectedItemIds.contains(folder.id) ? 0.3 : 0.0)
                                            VStack {
                                                HStack {
                                                    Spacer()
                                                    Image(systemName: selectedItemIds.contains(folder.id) ? "checkmark.circle.fill" : "circle")
                                                        .foregroundColor(selectedItemIds.contains(folder.id) ? .blue : .white)
                                                        .background(selectedItemIds.contains(folder.id) ? Color.white : Color.clear)
                                                        .clipShape(Circle())
                                                        .font(.system(size: 24))
                                                        .padding(6)
                                                        .shadow(radius: 2)
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                )
                        }
                        .disabled(isSelectionMode)
                        .onTapGesture {
                            if isSelectionMode {
                                if selectedItemIds.contains(folder.id) {
                                    selectedItemIds.remove(folder.id)
                                } else {
                                    selectedItemIds.insert(folder.id)
                                }
                            }
                        }
                    }
                    .contextMenu {
                        Button { viewModel.toggleFolderFavorite(folder: folder, path: [idx]) } label: {
                            Label("Favorito", systemImage: viewModel.isFolderFavorite(folderId: folder.id) ? "star.fill" : "star")
                        }
                        Button {
                            editingId = folder.id
                            editingName = folder.name
                            isEditing = true
                        } label: {
                            Label("Renombrar", systemImage: "pencil")
                        }
                        Button {
                            isSelectionMode = true
                            selectedItemIds.insert(folder.id)
                        } label: {
                            Label("Seleccionar", systemImage: "checkmark.circle")
                        }
                        Button {
                            moveCopyOperation = MoveCopyOperation(items: [folder], sourceContainerPath: [], isCopy: false)
                        } label: {
                            Label("Mover", systemImage: "arrow.turn.up.right")
                        }
                        Button {
                            moveCopyOperation = MoveCopyOperation(items: [folder], sourceContainerPath: [], isCopy: true)
                        } label: {
                            Label("Copiar", systemImage: "doc.on.doc")
                        }
                        Button(role: .destructive) { viewModel.deleteRootFolder(id: folder.id) } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
    }
    
    @ViewBuilder
    private var galleryView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                ForEach(sortedFolders, id: \.id) { folder in
                    let idx = viewModel.folders.firstIndex(where: { $0.id == folder.id }) ?? 0
                    NavigationLink(destination: FolderDetailView(
                        folder: FolderWrapper(folder),
                        folderPath: [idx],
                        viewModel: viewModel,
                        navigationPath: $navigationPath
                    )) {
                        galleryFolderCell(folder)
                    }
                    .disabled(isSelectionMode) // Disable nav if in selection mode (even if gallery doesn't support selection explicitly yet, consistent behavior)
                    .contextMenu {
                        Button { viewModel.toggleFolderFavorite(folder: folder, path: [idx]) } label: {
                            Label("Favorito", systemImage: viewModel.isFolderFavorite(folderId: folder.id) ? "star.fill" : "star")
                        }
                        Button {
                            editingId = folder.id
                            editingName = folder.name
                            isEditing = true
                        } label: {
                            Label("Renombrar", systemImage: "pencil")
                        }
                        Button {
                            moveCopyOperation = MoveCopyOperation(items: [folder], sourceContainerPath: [], isCopy: false)
                        } label: {
                            Label("Mover", systemImage: "arrow.turn.up.right")
                        }
                        Button {
                            moveCopyOperation = MoveCopyOperation(items: [folder], sourceContainerPath: [], isCopy: true)
                        } label: {
                            Label("Copiar", systemImage: "doc.on.doc")
                        }
                        Button {
                            viewModel.toggleFolderHidden(folder: folder, path: [idx])
                        } label: {
                            Label(folder.isHidden ? "Mostrar" : "Ocultar", systemImage: folder.isHidden ? "eye" : "eye.slash")
                        }
                        Button(role: .destructive) { viewModel.deleteRootFolder(id: folder.id) } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
    }
    
    @ViewBuilder
    private func gridFolderCell(_ folder: Folder) -> some View {
        VStack(spacing: 8) {
            ZStack {
                if let imageData = folder.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 100)
                        .clipped()
                } else {
                    LinearGradient(gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 100)
                        .overlay(Image(systemName: "atom").font(.system(size: 32)).foregroundColor(.blue))
                }
                
                // Indicador de carpeta oculta (esquina superior derecha)
                if folder.isHidden {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "eye.slash")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(6)
                }
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            if editingId == folder.id {
                TextField("Nombre", text: $editingName)
                    .focused($isEditing)
                    .onSubmit {
                        viewModel.renameFolder(id: folder.id, newName: editingName)
                        editingId = nil
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 35, alignment: .top)
            } else {
                Text(folder.name)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .frame(height: 35, alignment: .top)
            }
        }
    }
    
    @ViewBuilder
    private func galleryFolderCell(_ folder: Folder) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let imageData = folder.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()
            } else {
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 300)
                    .overlay(Image(systemName: "atom").font(.system(size: 48)).foregroundColor(.blue))
            }
            
            // Indicador de carpeta oculta (esquina superior derecha)
            if folder.isHidden {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "eye.slash")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(12)
            }
            
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear]), startPoint: .bottom, endPoint: .top)
                .frame(height: 100)
            
            HStack {
                if editingId == folder.id {
                    TextField("Nombre", text: $editingName)
                        .focused($isEditing)
                        .onSubmit {
                            viewModel.renameFolder(id: folder.id, newName: editingName)
                            editingId = nil
                        }
                        .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(.white)
                } else {
                    Text(folder.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    
    private func randomizeCurrentScreen() {
        viewModel.cleanOldHistory()
        if let folderResult = viewModel.randomizeCurrentScreen(at: []) {
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
    
    // MARK: - Helper Functions
    private func buildFolderViewFromPath(_ path: [Int]) -> FolderDetailView? {
        guard let folder = getFolderAtPath(path) else { return nil }
        
        return FolderDetailView(
            folder: FolderWrapper(folder),
            folderPath: path,
            viewModel: viewModel,
            highlightedItemId: highlightedItemId,
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
    
    /// Navigates to a path by building the full hierarchy
    /// e.g., for path [0, 1, 2], pushes [0], [0,1], [0,1,2]
    private func navigateToFullPath(_ targetPath: [Int]) {
        // Clear existing navigation path
        navigationPath.removeLast(navigationPath.count)
        
        // Build and push full hierarchy
        for i in 1...targetPath.count {
            let partialPath = Array(targetPath.prefix(i))
            navigationPath.append(FolderDestination(path: partialPath))
        }
    }
    
    private func extractFolderPath(from pathString: String) -> [Int]? {
        let components = pathString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        return components.compactMap { Int($0) }
    }
}

#Preview {
    ContentView()
}
