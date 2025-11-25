//
//  ContentView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 13/11/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = RandomitasViewModel()
    @State var showingNewFolderSheet = false
    @State var showingResult = false
    @State var selectedResult: (item: Item, path: String)?
    @State var showingFavorites = false
    @State var showingHistory = false
    @State var currentViewType: RandomitasViewModel.ViewType = .list
    @State var currentSortType: RandomitasViewModel.SortType = .nameAsc
    @State var showingImagePicker = false
    @State var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State var selectedFolderId: UUID?
    
    @State private var editingId: UUID?
    @State private var editingName: String = ""
    @FocusState private var isEditing: Bool
    
    var sortedFolders: [Folder] {
        viewModel.sortFolders(viewModel.folders, by: currentSortType)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // TOOLBAR
                    HStack(spacing: 12) {
                        if !viewModel.folders.isEmpty {
                            Button(action: randomize) {
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
                            
                            Button(action: { showingNewFolderSheet = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 18))
                            }
                            
                            Button(action: { showingHistory = true }) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .border(Color(.systemGray5), width: 1)
                    
                    // CONTENT
                    Group {
                        if viewModel.folders.isEmpty {
                            emptyState
                        } else {
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
            .navigationTitle("Randomitas")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingNewFolderSheet) {
                NewFolderSheet(viewModel: viewModel, isPresented: $showingNewFolderSheet)
            }
            .sheet(isPresented: $showingResult) {
                if let result = selectedResult {
                    ResultSheet(item: result.item, path: result.path, isPresented: $showingResult, viewModel: viewModel, folderPath: [])
                }
            }
            .sheet(isPresented: $showingFavorites) {
                FavoritesSheet(viewModel: viewModel, isPresented: $showingFavorites)
            }
            .sheet(isPresented: $showingHistory) {
                HistorySheet(viewModel: viewModel, isPresented: $showingHistory)
            }
            .sheet(isPresented: $showingImagePicker) {
                if let folderId = selectedFolderId, let idx = viewModel.folders.firstIndex(where: { $0.id == folderId }) {
                    ImagePickerView(onImagePicked: { image in
                        let resizedImage = image.resized(toMaxDimension: 1024)
                        if let data = resizedImage.jpegData(compressionQuality: 0.8) {
                            viewModel.updateFolderImage(imageData: data, at: [idx])
                        }
                    }, sourceType: imageSourceType)
                }
            }
        }
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
                NavigationLink(destination: FolderDetailView(folder: FolderWrapper(folder), folderPath: [idx], viewModel: viewModel)) {
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
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { viewModel.deleteRootFolder(id: folder.id) } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                    Button {
                        editingId = folder.id
                        editingName = folder.name
                        isEditing = true
                    } label: {
                        Label("Renombrar", systemImage: "pencil")
                    }
                    .tint(.orange)
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
                        Button {
                            editingId = folder.id
                            editingName = folder.name
                            isEditing = true
                        } label: {
                            Label("Renombrar", systemImage: "pencil")
                        }
                        Button { viewModel.toggleFolderFavorite(folder: folder, path: [idx]) } label: {
                            Label("Favorito", systemImage: "star")
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
                        Button {
                            editingId = folder.id
                            editingName = folder.name
                            isEditing = true
                        } label: {
                            Label("Renombrar", systemImage: "pencil")
                        }
                        Button { viewModel.toggleFolderFavorite(folder: folder, path: [idx]) } label: {
                            Label("Favorito", systemImage: "star")
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
    
    private func randomize() {
        viewModel.cleanOldHistory()
        if !viewModel.folders.isEmpty {
            let randomIndex = Int.random(in: 0..<viewModel.folders.count)
            selectedResult = viewModel.randomizeFolder(at: [randomIndex])
        }
        if selectedResult != nil { showingResult = true }
    }
}

#Preview {
    ContentView()
}
