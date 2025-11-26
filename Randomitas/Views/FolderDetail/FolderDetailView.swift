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
    @State var showingMoveCopySheet = false
    @State var moveCopyItem: Item?
    @State var moveCopyFolder: Folder?
    @State var moveCopyPath: [Int] = []
    @State var isCopyOperation = false
    
    @State private var editingId: UUID?
    @State private var editingName: String = ""
    @FocusState private var isEditing: Bool
    @State private var pickerID = UUID()
    @State private var showLabel = false
    
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
                HStack(spacing: 25) {
                    SortMenuView(sortType: $currentSortType)
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .onChange(of: currentSortType) { viewModel.setSortType($0, for: folder.folder.id) }
                        .frame(maxWidth: .infinity)
                    
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
                    }
                    
                    Menu {
                        Button(action: { showingNewSubfolderSheet = true }) {
                            Label("Nueva Subcarpeta", systemImage: "folder.badge.plus")
                        }
                        .disabled(!canAddSubfolders)
                        
                        Button(action: { showingNewItemSheet = true }) {
                            Label("Nuevo Item", systemImage: "doc.badge.plus")
                        }
                        .disabled(!canAddItems)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .border(Color(.systemGray5), width: 1)
                
                // CONTENT
                Group {
                    if folder.folder.subfolders.isEmpty && folder.folder.items.isEmpty {
                        emptyState
                    } else {
                        switch currentViewType {
                        case .list:
                            FolderDetailListView(
                                viewModel: viewModel,
                                folder: folder,
                                folderPath: folderPath,
                                sortedSubfolders: sortedSubfolders,
                                sortedItems: sortedItems,
                                editingId: $editingId,
                                editingName: $editingName,
                                isEditing: $isEditing,
                                imageSourceType: $imageSourceType,
                                showingImagePicker: $showingImagePicker,
                                showingMoveCopySheet: $showingMoveCopySheet,
                                moveCopyItem: $moveCopyItem,
                                moveCopyFolder: $moveCopyFolder,
                                moveCopyPath: $moveCopyPath,
                                isCopyOperation: $isCopyOperation
                            )
                        case .grid:
                            FolderDetailGridView(
                                viewModel: viewModel,
                                folder: folder,
                                folderPath: folderPath,
                                sortedSubfolders: sortedSubfolders,
                                sortedItems: sortedItems,
                                editingId: $editingId,
                                editingName: $editingName,
                                isEditing: $isEditing,
                                selectedItemForImage: $selectedItemForImage,
                                imageSourceType: $imageSourceType,
                                showingImagePicker: $showingImagePicker,
                                showingMoveCopySheet: $showingMoveCopySheet,
                                moveCopyItem: $moveCopyItem,
                                moveCopyFolder: $moveCopyFolder,
                                moveCopyPath: $moveCopyPath,
                                isCopyOperation: $isCopyOperation
                            )
                        case .gallery:
                            FolderDetailGalleryView(
                                viewModel: viewModel,
                                folder: folder,
                                folderPath: folderPath,
                                sortedSubfolders: sortedSubfolders,
                                sortedItems: sortedItems,
                                editingId: $editingId,
                                editingName: $editingName,
                                isEditing: $isEditing,
                                selectedItemForImage: $selectedItemForImage,
                                imageSourceType: $imageSourceType,
                                showingImagePicker: $showingImagePicker,
                                showingMoveCopySheet: $showingMoveCopySheet,
                                moveCopyItem: $moveCopyItem,
                                moveCopyFolder: $moveCopyFolder,
                                moveCopyPath: $moveCopyPath,
                                isCopyOperation: $isCopyOperation
                            )
                        }
                    }
                }
            }
            
            // FLOATING BUTTON
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    if !folder.folder.subfolders.isEmpty || !folder.folder.items.isEmpty {
                        Button(action: randomize) {
                            HStack(spacing: 10) {
                                Image(systemName: "shuffle")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                if showLabel {
                                    Text(": Shuffle")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .transition(.move(edge: .leading).combined(with: .opacity))
                                }
                                Spacer()
                            }
                            .padding(.leading, 20)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.ultraThinMaterial)
                            .cornerRadius(28)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .onAppear {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                                    showLabel = true
                                }
                            }
                        }
                    } else {
                        Spacer()
                    }
                    
                    Button(action: { showingFavorites = true }) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.yellow)
                            .frame(width: 56, height: 56)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
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
                            Button(action: { imageSourceType = .camera; pickerID = UUID(); showingImagePicker = true }) {
                                Label("Tomar foto", systemImage: "camera.fill")
                            }
                            Button(action: { imageSourceType = .photoLibrary; pickerID = UUID(); showingImagePicker = true }) {
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
        .sheet(isPresented: $showingResult) {
            if let result = selectedResult {
                ResultSheet(item: result.item, path: result.path, isPresented: $showingResult, viewModel: viewModel, folderPath: folderPath)
            }
        }
        .sheet(isPresented: $showingFavorites) {
            FavoritesSheet(viewModel: viewModel, isPresented: $showingFavorites)
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
            .id(pickerID)
        }
        .sheet(isPresented: $showingMoveCopySheet) {
            MoveCopySheet(
                viewModel: viewModel,
                isPresented: $showingMoveCopySheet,
                itemToMove: moveCopyItem,
                folderToMove: moveCopyFolder,
                currentPath: moveCopyPath,
                isCopy: isCopyOperation
            )
        }
        .onAppear {
            currentViewType = viewModel.getViewType(for: folder.folder.id)
            currentSortType = viewModel.getSortType(for: folder.folder.id)
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
                Text("Carpeta vacía")
                    .font(.headline)
                Text("Agrega subcarpetas o items")
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
                
                Button(action: { showingNewItemSheet = true }) {
                    VStack {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                        Text("Item")
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

    private func randomize() {
        viewModel.cleanOldHistory()
        if !folder.folder.items.isEmpty || !folder.folder.subfolders.isEmpty {
            selectedResult = viewModel.randomizeFolder(at: folderPath)
        }
        if selectedResult != nil { showingResult = true }
    }
}

class FolderWrapper: ObservableObject {
    @Published var folder: Folder
    init(_ folder: Folder) { self.folder = folder }
}

