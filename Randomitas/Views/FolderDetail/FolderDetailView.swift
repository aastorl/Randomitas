//
//  FolderDetailView.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import SwiftUI

struct FolderDetailView: View {
    let folder: Folder
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
        .navigationTitle(folder.name)
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
                ResultSheet(item: result.item, path: result.path, isPresented: $showingResult)
            }
        }
    }
    
    @ViewBuilder
    private var subfoldersSection: some View {
        if hasSubfolders {
            Section(header: Text("Subcarpetas")) {
                ForEach(folder.subfolders, id: \.id) { subfolder in
                    NavigationLink(destination: FolderDetailView(
                        folder: subfolder,
                        folderPath: folderPath + [folder.subfolders.firstIndex(where: { $0.id == subfolder.id }) ?? 0],
                        viewModel: viewModel
                    )) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
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
                ForEach(folder.items) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Button(action: { viewModel.toggleFavorite(item: item, path: buildPath(item.name)) }) {
                            Image(systemName: viewModel.isFavorite(itemId: item.id, path: buildPath(item.name)) ? "star.fill" : "star")
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
            Button(action: { viewModel.toggleFolderFavorite(folder: folder, path: folderPath) }) {
                Image(systemName: viewModel.isFolderFavorite(folderId: folder.id) ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }
            
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
    
    private func buildPath(_ itemName: String) -> String {
        return folder.name + " > " + itemName
    }
    
    private func randomizeFolder() {
        viewModel.cleanOldHistory()
        selectedResult = viewModel.randomizeFolder(at: folderPath)
        if selectedResult != nil {
            showingResult = true
        }
    }
}
