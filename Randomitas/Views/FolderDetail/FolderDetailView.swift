//
//  FolderDetailView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 14/11/2025.
//

import SwiftUI
internal import Combine

struct FolderDetailView: View {
    @ObservedObject var folder: FolderWrapper
    let folderPath: [Int]
    @ObservedObject var viewModel: RandomitasViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var showingNewSubfolderSheet = false
    @State var showingNewItemSheet = false
    @State var showingResult = false
    @State var selectedResult: (item: Item, path: String)?
    @State var showingRenameSheet = false
    @State var renameTarget: (id: UUID, name: String, type: String)?
    @State var currentViewType: RandomitasViewModel.ViewType = .list
    @State var currentSortType: RandomitasViewModel.SortType = .nameAsc
    @State var showingImagePicker = false
    @State var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State var selectedItemForImage: Item?
    @State var showingFavorites = false
    
    @State private var editingId: UUID?
    @State private var editingName: String = ""
    @FocusState private var isEditing: Bool
    
    var canAddSubfolders: Bool {
        viewModel.canAddSubfolder(at: folderPath)
    }
    
    var canAddItems: Bool {
        viewModel.canAddItems(at: folderPath)
    }
    
    var hasItems: Bool {
        viewModel.folderHasItems(at: folderPath)
    }
    
    var hasSubfolders: Bool {
        viewModel.folderHasSubfolders(at: folderPath)
    }
    
    var sortedSubfolders: [Folder] {
        viewModel.sortFolders(folder.folder.subfolders, by: currentSortType)
    }
    
    var sortedItems: [Item] {
        viewModel.sortItems(folder.folder.items, by: currentSortType)
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // TOOLBAR
                HStack(spacing: 12) {
                    if hasItems || hasSubfolders {
                        Button(action: randomizeFolder) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    
                    Spacer(minLength: 8)
                    
                    HStack(spacing: 10) {
                        SortMenuView(sortType: $currentSortType)
                            .foregroundColor(.blue)
                        
                        Menu {
                            Picker("Vista", selection: $currentViewType) {
                                Text("Lista").tag(RandomitasViewModel.ViewType.list)
                                Text("Cuadrícula").tag(RandomitasViewModel.ViewType.grid)
                                Text("Galería").tag(RandomitasViewModel.ViewType.gallery)
                            }
                        } label: {
                            Image(systemName: "rectangle.grid.1x2")
                                .foregroundColor(.blue)
                        }
                        
                        if canAddSubfolders {
                            Button(action: { showingNewSubfolderSheet = true }) {
                                Image(systemName: "folder.badge.plus")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if canAddItems {
                            Button(action: { showingNewItemSheet = true }) {
                                Image(systemName: "doc.badge.plus")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .border(Color(.systemGray5), width: 1)
                
                // CONTENT
                Group {
                    switch currentViewType {
                    case .list:
                        listView
                    case .grid:
                        gridView
                    case .gallery:
                        galleryView
                    }
                }
            }
            
            // FLOATING BUTTON
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingFavorites = true }) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.yellow)
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(folder.folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: { viewModel.toggleFolderFavorite(folder: folder.folder, path: folderPath) }) {
                        Image(systemName: viewModel.isFolderFavorite(folderId: folder.folder.id) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                    
                    Menu {
                        Button(action: {
                            editingId = folder.folder.id
                            editingName = folder.folder.name
                            isEditing = true
                        }) {
                            Label("Renombrar", systemImage: "pencil")
                        }
                        Menu {
                            Button(action: { imageSourceType = .camera; showingImagePicker = true }) {
                                Label("Tomar foto", systemImage: "camera.fill")
                            }
                            Button(action: { imageSourceType = .photoLibrary; showingImagePicker = true }) {
                                Label("Seleccionar de galería", systemImage: "photo.fill")
                            }
                            if folder.folder.imageData != nil {
                                Divider()
                                Button(role: .destructive, action: { viewModel.updateFolderImage(imageData: nil, at: folderPath) }) {
                                    Label("Eliminar imagen", systemImage: "trash")
                                }
                            }
                        } label: {
                            Label("Editar imagen", systemImage: "photo")
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
        .sheet(isPresented: $showingNewItemSheet) {
            NewItemInFolderSheet(viewModel: viewModel, folderPath: folderPath, isPresented: $showingNewItemSheet)
        }
        .sheet(isPresented: $showingFavorites) {
            FavoritesSheet(viewModel: viewModel, isPresented: $showingFavorites)
        }
        .sheet(isPresented: $showingResult) {
            if let result = selectedResult {
                ResultSheet(item: result.item, path: result.path, isPresented: $showingResult, viewModel: viewModel, folderPath: folderPath)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(onImagePicked: { image in
                let resizedImage = image.resized(toMaxDimension: 1024)
                if let data = resizedImage.jpegData(compressionQuality: 0.8) {
                    if let item = selectedItemForImage {
                        viewModel.updateItemImage(imageData: data, itemId: item.id)
                    } else {
                        viewModel.updateFolderImage(imageData: data, at: folderPath)
                    }
                }
                selectedItemForImage = nil
            }, sourceType: imageSourceType)
        }
        .onAppear {
            currentViewType = viewModel.getViewType(for: folder.folder.id)
            currentSortType = viewModel.getSortType(for: folder.folder.id)
        }
        .onChange(of: currentViewType) { viewModel.setViewType($0, for: folder.folder.id) }
        .onChange(of: currentSortType) { viewModel.setSortType($0, for: folder.folder.id) }
    }
    
    @ViewBuilder
    private var listView: some View {
        List {
            if hasSubfolders {
                Section(header: Text("Subcarpetas")) {
                    ForEach(sortedSubfolders, id: \.id) { subfolder in
                        subfolderRow(subfolder)
                    }
                }
            }
            
            if hasItems {
                Section(header: Text("Items")) {
                    ForEach(sortedItems, id: \.id) { item in
                        itemRow(item)
                    }
                }
            }
            
            if !hasSubfolders && !hasItems {
                Text("Vacío").foregroundColor(.gray)
            }
        }
    }
    
    @ViewBuilder
    private func subfolderRow(_ subfolder: Folder) -> some View {
        let idx = folder.folder.subfolders.firstIndex(where: { $0.id == subfolder.id }) ?? 0
        NavigationLink(destination: FolderDetailView(folder: FolderWrapper(subfolder), folderPath: folderPath + [idx], viewModel: viewModel)) {
            HStack(spacing: 12) {
                if let imageData = subfolder.imageData, let uiImage = UIImage(data: imageData) {
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
                
                if editingId == subfolder.id {
                    TextField("Nombre", text: $editingName)
                        .focused($isEditing)
                        .onSubmit {
                            viewModel.renameFolder(id: subfolder.id, newName: editingName)
                            editingId = nil
                        }
                } else {
                    Text(subfolder.name)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { viewModel.deleteSubfolder(id: subfolder.id, from: folderPath); dismiss() } label: {
                Label("Eliminar", systemImage: "trash")
            }
            Button {
                editingId = subfolder.id
                editingName = subfolder.name
                isEditing = true
            } label: {
                Label("Renombrar", systemImage: "pencil")
            }
            .tint(.orange)
        }
    }
    
    @ViewBuilder
    private func itemRow(_ item: Item) -> some View {
        let itemPath = buildFullPath(item.name)
        HStack(spacing: 12) {
            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipped()
                    .cornerRadius(6)
            } else {
                Image(systemName: "doc.fill")
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
            }
            
            if editingId == item.id {
                TextField("Nombre", text: $editingName)
                    .focused($isEditing)
                    .onSubmit {
                        viewModel.renameItem(id: item.id, newName: editingName)
                        editingId = nil
                    }
            } else {
                Text(item.name)
            }
            Spacer()
            Button { viewModel.toggleFavorite(item: item, path: itemPath) } label: {
                Image(systemName: viewModel.isFavorite(itemId: item.id, path: itemPath) ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { viewModel.deleteItem(id: item.id, from: folderPath) } label: {
                Label("Eliminar", systemImage: "trash")
            }
            Button {
                editingId = item.id
                editingName = item.name
                isEditing = true
            } label: {
                Label("Renombrar", systemImage: "pencil")
            }
            .tint(.orange)
            Button {
                selectedItemForImage = item
                imageSourceType = .photoLibrary
                showingImagePicker = true
            } label: {
                Label("Imagen", systemImage: "photo")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button {
                editingId = item.id
                editingName = item.name
                isEditing = true
            } label: {
                Label("Renombrar", systemImage: "pencil")
            }
            Button { viewModel.toggleFavorite(item: item, path: itemPath) } label: {
                Label(viewModel.isFavorite(itemId: item.id, path: itemPath) ? "Quitar Favorito" : "Favorito", systemImage: "star")
            }
            Button(role: .destructive) { viewModel.deleteItem(id: item.id, from: folderPath) } label: {
                Label("Eliminar", systemImage: "trash")
            }
            Menu {
                Button(action: { selectedItemForImage = item; imageSourceType = .camera; showingImagePicker = true }) {
                    Label("Tomar foto", systemImage: "camera.fill")
                }
                Button(action: { selectedItemForImage = item; imageSourceType = .photoLibrary; showingImagePicker = true }) {
                    Label("Seleccionar de galería", systemImage: "photo.fill")
                }
                if item.imageData != nil {
                    Divider()
                    Button(role: .destructive, action: { viewModel.updateItemImage(imageData: nil, itemId: item.id) }) {
                        Label("Eliminar imagen", systemImage: "trash")
                    }
                }
            } label: {
                Label("Editar imagen", systemImage: "photo")
            }
        }
    }
    
    @ViewBuilder
    private var gridView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if hasSubfolders {
                    Text("Subcarpetas").font(.headline).padding(.horizontal)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(sortedSubfolders, id: \.id) { subfolder in
                            let idx = folder.folder.subfolders.firstIndex(where: { $0.id == subfolder.id }) ?? 0
                            NavigationLink(destination: FolderDetailView(folder: FolderWrapper(subfolder), folderPath: folderPath + [idx], viewModel: viewModel)) {
                                gridFolderCell(subfolder)
                            }
                            .contextMenu {
                                Button {
                                    editingId = subfolder.id
                                    editingName = subfolder.name
                                    isEditing = true
                                } label: {
                                    Label("Renombrar", systemImage: "pencil")
                                }
                                Button { viewModel.toggleFolderFavorite(folder: subfolder, path: folderPath + [idx]) } label: {
                                    Label("Favorito", systemImage: "star")
                                }
                                Button(role: .destructive) { viewModel.deleteSubfolder(id: subfolder.id, from: folderPath) } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                if hasItems {
                    Text("Items").font(.headline).padding(.horizontal)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(sortedItems, id: \.id) { item in
                            let itemPath = buildFullPath(item.name)
                            gridItemCell(item)
                                .contextMenu {
                                    Button {
                                        editingId = item.id
                                        editingName = item.name
                                        isEditing = true
                                    } label: {
                                        Label("Renombrar", systemImage: "pencil")
                                    }
                                    Button { viewModel.toggleFavorite(item: item, path: itemPath) } label: {
                                        Label("Favorito", systemImage: "star")
                                    }
                                    Button(role: .destructive) { viewModel.deleteItem(id: item.id, from: folderPath) } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                    Menu {
                                        Button(action: { selectedItemForImage = item; imageSourceType = .camera; showingImagePicker = true }) {
                                            Label("Tomar foto", systemImage: "camera.fill")
                                        }
                                        Button(action: { selectedItemForImage = item; imageSourceType = .photoLibrary; showingImagePicker = true }) {
                                            Label("Seleccionar de galería", systemImage: "photo.fill")
                                        }
                                        if item.imageData != nil {
                                            Divider()
                                            Button(role: .destructive, action: { viewModel.updateItemImage(imageData: nil, itemId: item.id) }) {
                                                Label("Eliminar imagen", systemImage: "trash")
                                            }
                                        }
                                    } label: {
                                        Label("Editar imagen", systemImage: "photo")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                
                if !hasSubfolders && !hasItems {
                    Text("Vacío").foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private var galleryView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                if hasSubfolders {
                    ForEach(sortedSubfolders, id: \.id) { subfolder in
                        let idx = folder.folder.subfolders.firstIndex(where: { $0.id == subfolder.id }) ?? 0
                        NavigationLink(destination: FolderDetailView(folder: FolderWrapper(subfolder), folderPath: folderPath + [idx], viewModel: viewModel)) {
                            galleryFolderCell(subfolder)
                        }
                        .contextMenu {
                            Button {
                                editingId = subfolder.id
                                editingName = subfolder.name
                                isEditing = true
                            } label: {
                                Label("Renombrar", systemImage: "pencil")
                            }
                            Button { viewModel.toggleFolderFavorite(folder: subfolder, path: folderPath + [idx]) } label: {
                                Label("Favorito", systemImage: "star")
                            }
                            Button(role: .destructive) { viewModel.deleteSubfolder(id: subfolder.id, from: folderPath) } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
                }
                
                if hasItems {
                    ForEach(sortedItems, id: \.id) { item in
                        let itemPath = buildFullPath(item.name)
                        galleryItemCell(item)
                            .contextMenu {
                                Button {
                                    editingId = item.id
                                    editingName = item.name
                                    isEditing = true
                                } label: {
                                    Label("Renombrar", systemImage: "pencil")
                                }
                                Button { viewModel.toggleFavorite(item: item, path: itemPath) } label: {
                                    Label("Favorito", systemImage: "star")
                                }
                                Button(role: .destructive) { viewModel.deleteItem(id: item.id, from: folderPath) } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                                Menu {
                                    Button(action: { selectedItemForImage = item; imageSourceType = .camera; showingImagePicker = true }) {
                                        Label("Tomar foto", systemImage: "camera.fill")
                                    }
                                    Button(action: { selectedItemForImage = item; imageSourceType = .photoLibrary; showingImagePicker = true }) {
                                        Label("Seleccionar de galería", systemImage: "photo.fill")
                                    }
                                    if item.imageData != nil {
                                        Divider()
                                        Button(role: .destructive, action: { viewModel.updateItemImage(imageData: nil, itemId: item.id) }) {
                                            Label("Eliminar imagen", systemImage: "trash")
                                        }
                                    }
                                } label: {
                                    Label("Editar imagen", systemImage: "photo")
                                }
                            }
                    }
                }
                
                if !hasSubfolders && !hasItems {
                    Text("Vacío").foregroundColor(.gray).frame(maxHeight: .infinity, alignment: .center)
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
            }
            .frame(height: 120)
            .cornerRadius(8)
            
            if editingId == folder.id {
                TextField("Nombre", text: $editingName)
                    .focused($isEditing)
                    .onSubmit {
                        viewModel.renameFolder(id: folder.id, newName: editingName)
                        editingId = nil
                    }
                    .font(.caption).fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            } else {
                Text(folder.name).font(.caption).fontWeight(.semibold).lineLimit(2)
            }
        }
    }
    
    @ViewBuilder
    private func gridItemCell(_ item: Item) -> some View {
        VStack(spacing: 8) {
            ZStack {
                if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 120)
                        .clipped()
                } else {
                    LinearGradient(gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 120)
                        .overlay(Image(systemName: "doc.fill").font(.system(size: 32)).foregroundColor(.gray))
                }
            }
            .frame(height: 120)
            .cornerRadius(8)
            
            if editingId == item.id {
                TextField("Nombre", text: $editingName)
                    .focused($isEditing)
                    .onSubmit {
                        viewModel.renameItem(id: item.id, newName: editingName)
                        editingId = nil
                    }
                    .font(.caption).fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            } else {
                Text(item.name).font(.caption).fontWeight(.semibold).lineLimit(2)
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
                        .font(.headline).fontWeight(.bold).foregroundColor(.white)
                } else {
                    Text(folder.name).font(.headline).fontWeight(.bold).foregroundColor(.white)
                }
                Spacer()
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func galleryItemCell(_ item: Item) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()
            } else {
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 300)
                    .overlay(Image(systemName: "doc.fill").font(.system(size: 48)).foregroundColor(.gray))
            }
            
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear]), startPoint: .bottom, endPoint: .top)
                .frame(height: 100)
            
            HStack {
                if editingId == item.id {
                    TextField("Nombre", text: $editingName)
                        .focused($isEditing)
                        .onSubmit {
                            viewModel.renameItem(id: item.id, newName: editingName)
                            editingId = nil
                        }
                        .font(.headline).fontWeight(.bold).foregroundColor(.white)
                } else {
                    Text(item.name).font(.headline).fontWeight(.bold).foregroundColor(.white)
                }
                Spacer()
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .cornerRadius(12)
    }
    
    private func buildFullPath(_ itemName: String) -> String {
        var pathComponents: [String] = []
        
        if !folderPath.isEmpty {
            var currentFolder = viewModel.folders[folderPath[0]]
            pathComponents.append(currentFolder.name)
            
            for i in 1..<folderPath.count {
                if folderPath[i] < currentFolder.subfolders.count {
                    currentFolder = currentFolder.subfolders[folderPath[i]]
                    pathComponents.append(currentFolder.name)
                }
            }
        }
        
        pathComponents.append(itemName)
        return pathComponents.joined(separator: " > ")
    }
    
    private func randomizeFolder() {
        viewModel.cleanOldHistory()
        selectedResult = viewModel.randomizeFolder(at: folderPath)
        if selectedResult != nil { showingResult = true }
    }
}

class FolderWrapper: ObservableObject {
    @Published var folder: Folder
    init(_ folder: Folder) { self.folder = folder }
}
