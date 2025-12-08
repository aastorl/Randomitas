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
    @State private var navigationToFolder: [Int]?
    
    var sortedFolders: [Folder] {
        viewModel.sortFolders(viewModel.folders, by: currentSortType)
    }
    
    var body: some View {
        NavigationStack {
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
            .navigationTitle("Randomitas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            }
            .sheet(isPresented: $showingNewFolderSheet) {
                NewFolderSheet(viewModel: viewModel, isPresented: $showingNewFolderSheet)
            }
            .sheet(isPresented: $showingFolderResult) {
                if let folderResult = selectedFolderResult {
                    ResultSheet(folder: folderResult.folder, path: folderResult.path, isPresented: $showingFolderResult, viewModel: viewModel, navigationPath: $navigationToFolder)
                }
            }
            .sheet(isPresented: $showingFavorites) {
                FavoritesSheet(viewModel: viewModel, isPresented: $showingFavorites)
            }
            .navigationDestination(for: FavoriteDestination.self) { destination in
                if let folderView = buildFolderViewFromPath(destination.path) {
                    folderView
                }
            }
            .sheet(isPresented: $showingHistory) {
                HistorySheet(viewModel: viewModel, isPresented: $showingHistory)
            }
            .sheet(isPresented: $showingHiddenFolders) {
                HiddenFoldersSheet(viewModel: viewModel, isPresented: $showingHiddenFolders)
            }
            .navigationDestination(for: HiddenDestination.self) { destination in
                if let folderView = buildFolderViewFromPath(destination.path) {
                    folderView
                }
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
            .alert("¿Seguro quieres eliminar esta Carpeta?", isPresented: .constant(folderToDelete != nil)) {
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
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var toolbarView: some View {
        HStack(spacing: 25) {
            SortMenuView(sortType: $currentSortType)
                .foregroundColor(.blue)
                .font(.system(size: 18))
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            
            Menu {
                Picker("Vista", selection: $currentViewType) {
                    Text("Lista").tag(RandomitasViewModel.ViewType.list)
                    Text("Cuadrícula").tag(RandomitasViewModel.ViewType.grid)
                    Text("Galería").tag(RandomitasViewModel.ViewType.gallery)
                }
            } label: {
                Image(systemName: "rectangle.grid.1x2")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            
            Button(action: { showingHistory = true }) {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            
            Button(action: { showingNewFolderSheet = true }) {
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
            listView
        case .grid:
            gridView
        case .gallery:
            galleryView
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
                    if !viewModel.folders.isEmpty {
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
                .frame(height: 1) // Minimal height, just to set background
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
                Text("Sin carpetas")
                    .font(.headline)
                Text("Crea una para comenzar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button(action: { showingNewFolderSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                    Text("Nueva Carpeta")
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
        List {
            ForEach(sortedFolders, id: \.id) { folder in
                let idx = viewModel.folders.firstIndex(where: { $0.id == folder.id }) ?? 0
                ZStack(alignment: .leading) {
                    NavigationLink(destination: FolderDetailView(folder: FolderWrapper(folder), folderPath: [idx], viewModel: viewModel)) {
                        EmptyView()
                    }
                    .opacity(0)
                    
                    HStack(spacing: 12) {
                        if let imageData = folder.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipped()
                                .cornerRadius(6)
                        } else {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                        }

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
                        moveCopyOperation = MoveCopyOperation(folder: folder, sourcePath: [idx], isCopy: false)
                    } label: {
                        Label("Mover", systemImage: "arrow.turn.up.right")
                    }
                    Button {
                        moveCopyOperation = MoveCopyOperation(folder: folder, sourcePath: [idx], isCopy: true)
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
    }
    
    @ViewBuilder
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(sortedFolders, id: \.id) { folder in
                    let idx = viewModel.folders.firstIndex(where: { $0.id == folder.id }) ?? 0
                    NavigationLink(destination: FolderDetailView(folder: FolderWrapper(folder), folderPath: [idx], viewModel: viewModel)) {
                        gridFolderCell(folder)
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
                            moveCopyOperation = MoveCopyOperation(folder: folder, sourcePath: [idx], isCopy: false)
                        } label: {
                            Label("Mover", systemImage: "arrow.turn.up.right")
                        }
                        Button {
                            moveCopyOperation = MoveCopyOperation(folder: folder, sourcePath: [idx], isCopy: true)
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
        }
    }
    
    @ViewBuilder
    private var galleryView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                ForEach(sortedFolders, id: \.id) { folder in
                    let idx = viewModel.folders.firstIndex(where: { $0.id == folder.id }) ?? 0
                    NavigationLink(destination: FolderDetailView(folder: FolderWrapper(folder), folderPath: [idx], viewModel: viewModel)) {
                        galleryFolderCell(folder)
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
                            moveCopyOperation = MoveCopyOperation(folder: folder, sourcePath: [idx], isCopy: false)
                        } label: {
                            Label("Mover", systemImage: "arrow.turn.up.right")
                        }
                        Button {
                            moveCopyOperation = MoveCopyOperation(folder: folder, sourcePath: [idx], isCopy: true)
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
                        .frame(height: 120)
                        .clipped()
                } else {
                    LinearGradient(gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 120)
                        .overlay(Image(systemName: "folder.fill").font(.system(size: 32)).foregroundColor(.blue))
                }
                
                // Indicador de carpeta oculta (esquina superior derecha)
                if folder.isHidden {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "eye.slash")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .frame(height: 120)
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
            } else {
                Text(folder.name)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
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
                    .overlay(Image(systemName: "folder.fill").font(.system(size: 48)).foregroundColor(.blue))
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
    
    private func randomizeWithChildren() {
        viewModel.cleanOldHistory()
        if let folderResult = viewModel.randomizeWithChildren(at: []) {
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

#Preview {
    ContentView()
}
