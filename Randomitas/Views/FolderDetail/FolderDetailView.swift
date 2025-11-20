//
//  FolderDetailView.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
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
    
    var body: some View {
        List {
            subfoldersSection
            itemsSection
            emptyStateSection
        }
        .navigationTitle(folder.folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.folderHasItems(at: folderPath) || viewModel.folderHasSubfolders(at: folderPath) {
                    Button(action: randomizeFolder) {
                        Image(systemName: "shuffle")
                            .foregroundColor(.blue)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                toolbarButtons
            }
        }
        .sheet(isPresented: $showingNewSubfolderSheet) {
            NewSubfolderSheet(
                viewModel: viewModel,
                folderPath: folderPath,
                isPresented: $showingNewSubfolderSheet
            )
        }
        .sheet(isPresented: $showingNewItemSheet) {
            NewItemInFolderSheet(
                viewModel: viewModel,
                folderPath: folderPath,
                isPresented: $showingNewItemSheet
            )
        }
        .sheet(isPresented: $showingResult) {
            if let result = selectedResult {
                ResultSheet(item: result.item, path: result.path, isPresented: $showingResult, viewModel: viewModel, folderPath: folderPath)
            }
        }
    }
    
    @ViewBuilder
    private var subfoldersSection: some View {
        if hasSubfolders {
            Section(header: Text("Subcarpetas")) {
                ForEach(folder.folder.subfolders.indices, id: \.self) { idx in
                    let subfolder = folder.folder.subfolders[idx]
                    NavigationLink(destination: FolderDetailView(
                        folder: FolderWrapper(subfolder),
                        folderPath: folderPath + [idx],
                        viewModel: viewModel
                    )) {
                        HStack {
                            if let imageData = subfolder.imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 30, height: 30)
                                    .cornerRadius(4)
                            } else {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                            }
                            Text(subfolder.name)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive, action: {
                            viewModel.deleteSubfolder(id: subfolder.id, from: folderPath)
                            dismiss()
                        }) {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var itemsSection: some View {
        if hasItems {
            Section(header: Text("Items")) {
                ForEach(folder.folder.items, id: \.id) { item in
                    HStack {
                        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                                .cornerRadius(4)
                        } else {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                        }
                        
                        Text(item.name)
                        Spacer()
                        
                        ImageEditorMenu(imageData: Binding(
                            get: { item.imageData },
                            set: { viewModel.updateItemImage(imageData: $0, itemId: item.id) }
                        ))
                        
                        Button(action: {
                            print("⭐ Botón estrella presionado para item: \(item.name)")
                            let fullPath = buildFullPath(item.name)
                            viewModel.toggleFavorite(item: item, path: fullPath)
                        }) {
                            Image(systemName: viewModel.isFavorite(itemId: item.id, path: buildFullPath(item.name)) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive, action: {
                            viewModel.deleteItem(id: item.id, from: folderPath)
                        }) {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateSection: some View {
        if !hasSubfolders && !hasItems {
            Section {
                Text("Esta carpeta está vacía")
                    .foregroundColor(.gray)
            }
        }
    }
    
    @ViewBuilder
    private var toolbarButtons: some View {
        HStack(spacing: 16) {
            Button(action: { viewModel.toggleFolderFavorite(folder: folder.folder, path: folderPath) }) {
                Image(systemName: viewModel.isFolderFavorite(folderId: folder.folder.id) ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }
            
            ImageEditorMenu(imageData: Binding(
                get: { folder.folder.imageData },
                set: {
                    print("🖼️ Intentando actualizar imagen en path: \(folderPath)")
                    viewModel.updateFolderImage(imageData: $0, at: folderPath)
                }
            ))
            
            if canAddSubfolders {
                Button(action: { showingNewSubfolderSheet = true }) {
                    Image(systemName: "folder.badge.plus")
                }
            }
            
            if canAddItems {
                Button(action: { showingNewItemSheet = true }) {
                    Image(systemName: "doc.badge.plus")
                }
            }
        }
    }
    
    // Construir ruta completa desde la raíz hasta el item
    private func buildFullPath(_ itemName: String) -> String {
        var pathComponents: [String] = []
        
        // Obtener la carpeta actual desde el path
        var currentFolder = viewModel.folders[folderPath[0]]
        pathComponents.append(currentFolder.name)
        
        // Navegar a través de las subcarpetas si existen
        for i in 1..<folderPath.count {
            currentFolder = currentFolder.subfolders[folderPath[i]]
            pathComponents.append(currentFolder.name)
        }
        
        pathComponents.append(itemName)
        let fullPath = pathComponents.joined(separator: " > ")
        print("🔗 Ruta generada para item: \(fullPath)")
        return fullPath
    }
    
    private func randomizeFolder() {
        viewModel.cleanOldHistory()
        selectedResult = viewModel.randomizeFolder(at: folderPath)
        if selectedResult != nil {
            showingResult = true
        }
    }
}

class FolderWrapper: ObservableObject {
    @Published var folder: Folder
    
    init(_ folder: Folder) {
        self.folder = folder
    }
}
