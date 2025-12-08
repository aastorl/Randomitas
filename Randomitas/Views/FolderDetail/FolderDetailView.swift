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
    
    @State var showingNewSubfolderSheet = false
    @State var showingRenameSheet = false
    @State var renameTarget: (id: UUID, name: String, type: String)?
    @State var currentViewType: RandomitasViewModel.ViewType = .list
    @State var currentSortType: RandomitasViewModel.SortType = .nameAsc
    @State var imagePickerRequest: ImagePickerRequest?
    @State var showingFavorites = false
    @State var showingHiddenFolders = false
    @State var moveCopyOperation: MoveCopyOperation?
    
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
    @State private var navigationToFolder: [Int]?
    
    var sortedSubfolders: [Folder] {
        viewModel.sortFolders(folder.folder.subfolders, by: currentSortType)
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // TOOLBAR
                toolbarView
                
                // CONTENT
                Group {
                    if folder.folder.subfolders.isEmpty {
                        emptyState
                    } else {
                        mainContentView
                    }
                }
            }
            
            // BOTTOM BAR
            bottomBarView
            
            // Search Results Overlay
            if isSearching && !searchText.isEmpty {
                searchResultsView
            }
            
            // Programmatic navigation to folder from ResultSheet
            if let navPath = navigationToFolder, let folderView = buildFolderViewFromPath(navPath) {
                NavigationLink(destination: folderView, isActive: .constant(true)) {
                    EmptyView()
                }
                .hidden()
                .onAppear {
                    navigationToFolder = nil
                }
            }
        }
        .navigationTitle(folder.folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(folder.folder.name)
                    .font(.headline)
                    .foregroundColor(folder.folder.isHidden ? .gray : .primary)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
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
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: { viewModel.toggleFolderFavorite(folder: folder.folder, path: folderPath) }) {
                        Image(systemName: viewModel.isFolderFavorite(folderId: folder.folder.id) ? "star.fill" : "star")
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
                            if folder.folder.imageData != nil {
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
        .sheet(isPresented: $showingNewSubfolderSheet) {
            NewSubfolderSheet(viewModel: viewModel, folderPath: folderPath, isPresented: $showingNewSubfolderSheet)
        }
        .sheet(isPresented: $showingFolderResult) {
            if let folderResult = selectedFolderResult {
                ResultSheet(folder: folderResult.folder, path: folderResult.path, isPresented: $showingFolderResult, viewModel: viewModel, navigationPath: $navigationToFolder)
            }
        }
        .sheet(isPresented: $showingFavorites) {
            FavoritesSheet(viewModel: viewModel, isPresented: $showingFavorites)
        }
        .sheet(isPresented: $showingHiddenFolders) {
            HiddenFoldersSheet(viewModel: viewModel, isPresented: $showingHiddenFolders)
        }
        .navigationDestination(for: FavoriteDestination.self) { destination in
            if let folderView = buildFolderViewFromPath(destination.path) {
                folderView
            }
        }
        .navigationDestination(for: HiddenDestination.self) { destination in
            if let folderView = buildFolderViewFromPath(destination.path) {
                folderView
            }
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
                folderToMove: operation.folder,
                currentPath: operation.sourcePath,
                isCopy: operation.isCopy
            )
        }
        .onAppear {
            currentViewType = viewModel.getViewType(for: folder.folder.id)
            currentSortType = viewModel.getSortType(for: folder.folder.id)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var toolbarView: some View {
        HStack(spacing: 25) {
            SortMenuView(sortType: $currentSortType)
                .foregroundColor(.blue)
                .font(.system(size: 18))
                .onChange(of: currentSortType) { viewModel.setSortType($0, for: folder.folder.id) }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            
            Menu {
                Picker("Vista", selection: $currentViewType) {
                    Text("Lista").tag(RandomitasViewModel.ViewType.list)
                    Text("Cuadrícula").tag(RandomitasViewModel.ViewType.grid)
                    Text("Galería").tag(RandomitasViewModel.ViewType.gallery)
                }
                .onChange(of: currentViewType) { newValue in
                    viewModel.setViewType(newValue, for: folder.folder.id)
                }
            } label: {
                Image(systemName: "rectangle.grid.1x2")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            
            Menu {
                Button(action: { showingNewSubfolderSheet = true }) {
                    Label("Nueva Subcarpeta", systemImage: "folder.badge.plus")
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .border(Color(.systemGray5), width: 1)
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        switch currentViewType {
        case .list:
            FolderDetailListView(
                viewModel: viewModel,
                folder: folder,
                folderPath: folderPath,
                sortedSubfolders: sortedSubfolders,
                editingId: $editingId,
                editingName: $editingName,
                isEditing: $isEditing,
                imagePickerRequest: $imagePickerRequest,
                moveCopyOperation: $moveCopyOperation
            )
        case .grid:
            FolderDetailGridView(
                viewModel: viewModel,
                folder: folder,
                folderPath: folderPath,
                sortedSubfolders: sortedSubfolders,
                editingId: $editingId,
                editingName: $editingName,
                isEditing: $isEditing,
                imagePickerRequest: $imagePickerRequest,
                moveCopyOperation: $moveCopyOperation
            )
        case .gallery:
            FolderDetailGalleryView(
                viewModel: viewModel,
                folder: folder,
                folderPath: folderPath,
                sortedSubfolders: sortedSubfolders,
                editingId: $editingId,
                editingName: $editingName,
                isEditing: $isEditing,
                imagePickerRequest: $imagePickerRequest,
                moveCopyOperation: $moveCopyOperation
            )
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
                        TextField("Buscar items y carpetas...", text: $searchText)
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
                    if !folder.folder.subfolders.isEmpty {
                        Menu {
                            Button(action: randomizeCurrentScreen) {
                                Label("Randomizar esta pantalla", systemImage: "square.dashed")
                            }
                            Button(action: randomizeWithChildren) {
                                Label("Randomizar esta pantalla + hijos", systemImage: "square.stack.3d.down.right")
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
                .transition(.scale.combined(with: .opacity))
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
                    Section(header: Text("Carpetas")) {
                        ForEach(results, id: \.0.id) { folder, path in
                            NavigationLink(value: FavoriteDestination(path: path)) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                    Text(folder.name)
                                }
                            }
                        }
                    }
                } else {
                    Text("No se encontraron resultados")
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
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Carpeta vacía")
                    .font(.headline)
                Text("Agrega subcarpetas")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                Button(action: { showingNewSubfolderSheet = true }) {
                    VStack {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                        Text("Subcarpeta")
                            .font(.caption)
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
    
    private func randomizeWithChildren() {
        viewModel.cleanOldHistory()
        if let folderResult = viewModel.randomizeWithChildren(at: folderPath) {
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
            viewModel: viewModel
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
}

class FolderWrapper: ObservableObject {
    @Published var folder: Folder
    init(_ folder: Folder) { self.folder = folder }
}
