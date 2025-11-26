//
//  FolderDetailListView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 25/11/2025.
//

internal import SwiftUI

struct FolderDetailListView: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @ObservedObject var folder: FolderWrapper
    let folderPath: [Int]
    let sortedSubfolders: [Folder]
    let sortedItems: [Item]
    
    @Binding var editingId: UUID?
    @Binding var editingName: String
    var isEditing: FocusState<Bool>.Binding
    
    @State private var selectedItemForImage: Item?
    @State private var subfolderToDelete: UUID?
    @State private var itemToDelete: UUID?
    @Binding var imageSourceType: UIImagePickerController.SourceType
    @Binding var showingImagePicker: Bool
    
    @Binding var showingMoveCopySheet: Bool
    @Binding var moveCopyItem: Item?
    @Binding var moveCopyFolder: Folder?
    @Binding var moveCopyPath: [Int]
    @Binding var isCopyOperation: Bool
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            if !sortedSubfolders.isEmpty {
                Section(header: Text("Subcarpetas")) {
                    ForEach(sortedSubfolders, id: \.id) { subfolder in
                        subfolderRow(subfolder)
                    }
                }
            }
            
            if !sortedItems.isEmpty {
                Section(header: Text("Items")) {
                    ForEach(sortedItems, id: \.id) { item in
                        itemRow(item)
                    }
                }
            }
            
            if sortedSubfolders.isEmpty && sortedItems.isEmpty {
                Text("Vacío").foregroundColor(.gray)
            }
        }
        .alert("¿Seguro quieres eliminar esta Carpeta?", isPresented: .constant(subfolderToDelete != nil)) {
            Button("Cancelar", role: .cancel) {
                subfolderToDelete = nil
            }
            Button("Eliminar", role: .destructive) {
                if let id = subfolderToDelete {
                    viewModel.deleteSubfolder(id: id, from: folderPath)
                    subfolderToDelete = nil
                    dismiss()
                }
            }
        }
        .alert("¿Seguro quieres eliminar este Item?", isPresented: .constant(itemToDelete != nil)) {
            Button("Cancelar", role: .cancel) {
                itemToDelete = nil
            }
            Button("Eliminar", role: .destructive) {
                if let id = itemToDelete {
                    viewModel.deleteItem(id: id, from: folderPath)
                    itemToDelete = nil
                }
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
                        .focused(isEditing)
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
            Button(role: .destructive) { subfolderToDelete = subfolder.id } label: {
                Label("Eliminar", systemImage: "trash")
            }
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
                    .focused(isEditing)
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
            Button(role: .destructive) { itemToDelete = item.id } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
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
