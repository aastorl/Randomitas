//
//  FolderDetailGalleryView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 25/11/2025.
//

internal import SwiftUI

struct FolderDetailGalleryView: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @ObservedObject var folder: FolderWrapper
    let folderPath: [Int]
    let sortedSubfolders: [Folder]
    let sortedItems: [Item]
    
    @Binding var editingId: UUID?
    @Binding var editingName: String
    var isEditing: FocusState<Bool>.Binding
    
    @Binding var selectedItemForImage: Item?
    @Binding var imageSourceType: UIImagePickerController.SourceType
    @Binding var showingImagePicker: Bool
    
    @Binding var showingMoveCopySheet: Bool
    @Binding var moveCopyItem: Item?
    @Binding var moveCopyFolder: Folder?
    @Binding var moveCopyPath: [Int]
    @Binding var isCopyOperation: Bool
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                ForEach(sortedSubfolders, id: \.id) { subfolder in
                    galleryFolderCell(subfolder)
                }
                
                ForEach(sortedItems, id: \.id) { item in
                    galleryItemCell(item)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func galleryFolderCell(_ subfolder: Folder) -> some View {
        let idx = folder.folder.subfolders.firstIndex(where: { $0.id == subfolder.id }) ?? 0
        NavigationLink(destination: FolderDetailView(folder: FolderWrapper(subfolder), folderPath: folderPath + [idx], viewModel: viewModel)) {
            ZStack(alignment: .bottomLeading) {
                if let imageData = subfolder.imageData, let uiImage = UIImage(data: imageData) {
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
                    if editingId == subfolder.id {
                        TextField("Nombre", text: $editingName)
                            .focused(isEditing)
                            .onSubmit {
                                viewModel.renameFolder(id: subfolder.id, newName: editingName)
                                editingId = nil
                            }
                            .font(.headline).fontWeight(.bold).foregroundColor(.white)
                    } else {
                        Text(subfolder.name).font(.headline).fontWeight(.bold).foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .cornerRadius(12)
        }
        .contextMenu {
            Button { viewModel.toggleFolderFavorite(folder: subfolder, path: folderPath + [idx]) } label: {
                Label("Favorito", systemImage: "star")
            }
            Button {
                editingId = subfolder.id
                editingName = subfolder.name
                isEditing.wrappedValue = true
            } label: {
                Label("Renombrar", systemImage: "pencil")
            }
            Button {
                moveCopyFolder = subfolder
                moveCopyItem = nil
                moveCopyPath = folderPath + [idx]
                isCopyOperation = false
                showingMoveCopySheet = true
            } label: {
                Label("Mover", systemImage: "arrow.turn.up.right")
            }
            Button {
                moveCopyFolder = subfolder
                moveCopyItem = nil
                moveCopyPath = folderPath + [idx]
                isCopyOperation = true
                showingMoveCopySheet = true
            } label: {
                Label("Copiar", systemImage: "doc.on.doc")
            }
            Button(role: .destructive) { viewModel.deleteSubfolder(id: subfolder.id, from: folderPath) } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    private func galleryItemCell(_ item: Item) -> some View {
        let itemPath = buildFullPath(item.name)
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
                    .overlay(Image(systemName: "doc.text.fill").font(.system(size: 48)).foregroundColor(.blue))
            }
            
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear]), startPoint: .bottom, endPoint: .top)
                .frame(height: 100)
            
            HStack {
                if editingId == item.id {
                    TextField("Nombre", text: $editingName)
                        .focused(isEditing)
                        .onSubmit {
                            viewModel.renameItem(id: item.id, newName: editingName)
                            editingId = nil
                        }
                        .font(.headline).fontWeight(.bold).foregroundColor(.white)
                } else {
                    Text(item.name).font(.headline).fontWeight(.bold).foregroundColor(.white)
                }
                Spacer()
                Button { viewModel.toggleFavorite(item: item, path: itemPath) } label: {
                    Image(systemName: viewModel.isFavorite(itemId: item.id, path: itemPath) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .cornerRadius(12)
        .contextMenu {
            Button { viewModel.toggleFavorite(item: item, path: itemPath) } label: {
                Label(viewModel.isFavorite(itemId: item.id, path: itemPath) ? "Quitar Favorito" : "Favorito", systemImage: "star")
            }
            Button {
                editingId = item.id
                editingName = item.name
                isEditing.wrappedValue = true
            } label: {
                Label("Renombrar", systemImage: "pencil")
            }
            Button {
                moveCopyItem = item
                moveCopyFolder = nil
                moveCopyPath = folderPath
                isCopyOperation = false
                showingMoveCopySheet = true
            } label: {
                Label("Mover", systemImage: "arrow.turn.up.right")
            }
            Button {
                moveCopyItem = item
                moveCopyFolder = nil
                moveCopyPath = folderPath
                isCopyOperation = true
                showingMoveCopySheet = true
            } label: {
                Label("Copiar", systemImage: "doc.on.doc")
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
            Button(role: .destructive) { viewModel.deleteItem(id: item.id, from: folderPath) } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
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
}
