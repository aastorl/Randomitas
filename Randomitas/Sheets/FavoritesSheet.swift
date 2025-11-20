//
//  FavoritesSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import SwiftUI

struct FavoriteDestination: Identifiable, Hashable {
    let id = UUID()
    let type: DestinationType
    let path: [Int]
    let pathString: String
    
    enum DestinationType {
        case folder
        case item
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FavoriteDestination, rhs: FavoriteDestination) -> Bool {
        lhs.id == rhs.id
    }
}

struct FavoritesSheet: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @Binding var isPresented: Bool
    @State var selectedDestination: FavoriteDestination?
    
    var body: some View {
        NavigationStack {
            List {
                // Carpetas Favoritas
                if !viewModel.folderFavorites.isEmpty {
                    Section(header: Text("Carpetas")) {
                        ForEach(viewModel.folderFavorites, id: \.0.id) { fav in
                            NavigationLink(value: FavoriteDestination(type: .folder, path: fav.1, pathString: "")) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(fav.0.name)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .onDelete { indices in
                            viewModel.folderFavorites.remove(atOffsets: indices)
                        }
                    }
                }
                
                // Items Favoritos
                if !viewModel.favorites.isEmpty {
                    Section(header: Text("Items")) {
                        ForEach(viewModel.favorites, id: \.0.id) { fav in
                            if let path = extractFolderPathForItem(from: fav.1) {
                                NavigationLink(value: FavoriteDestination(type: .item, path: path, pathString: fav.1)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(fav.0.name)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Text(fav.1)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .onDelete { indices in
                            viewModel.favorites.remove(atOffsets: indices)
                        }
                    }
                }
                
                if viewModel.favorites.isEmpty && viewModel.folderFavorites.isEmpty {
                    Text("Sin favoritos")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Favoritos")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: FavoriteDestination.self) { destination in
                if destination.type == .folder {
                    if let folderView = buildFolderViewFromPath(destination.path) {
                        folderView
                    }
                } else {
                    if let folderView = buildFolderView(from: destination.pathString) {
                        folderView
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { isPresented = false }
                }
            }
        }
    }
    
    private func buildFolderView(from pathString: String) -> FolderDetailView? {
        guard let path = extractFolderPath(from: pathString) else { return nil }
        guard let folder = getFolderAtPath(path) else { return nil }
        
        return FolderDetailView(
            folder: FolderWrapper(folder),
            folderPath: path,
            viewModel: viewModel
        )
    }
    
    private func buildFolderViewFromPath(_ path: [Int]) -> FolderDetailView? {
        guard let folder = getFolderAtPath(path) else { return nil }
        
        return FolderDetailView(
            folder: FolderWrapper(folder),
            folderPath: path,
            viewModel: viewModel
        )
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
    
    
    private func extractFolderPathForItem(from pathString: String) -> [Int]? {
        // pathString es como "Carpeta > Subcarpeta > Item"
        // Retornamos la ruta a la carpeta PADRE (sin el item final)
        return extractFolderPath(from: pathString)
    }
    
    private func extractFolderPath(from pathString: String) -> [Int]? {
        let components = pathString.split(separator: ">").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        guard !components.isEmpty else { return nil }
        
        // El último componente es el item, los anteriores son carpetas
        let folderNames = Array(components.dropLast())
        
        guard !folderNames.isEmpty else { return nil }
        
        // Buscamos el índice de la carpeta raíz
        if let rootIndex = viewModel.folders.firstIndex(where: { $0.name == folderNames.first }) {
            var path = [rootIndex]
            
            // Si hay más de una carpeta en la ruta, necesitamos encontrar las subcarpetas
            if folderNames.count > 1 {
                var currentFolder = viewModel.folders[rootIndex]
                
                for folderName in folderNames.dropFirst() {
                    if let subIndex = currentFolder.subfolders.firstIndex(where: { $0.name == folderName }) {
                        path.append(subIndex)
                        currentFolder = currentFolder.subfolders[subIndex]
                    } else {
                        return nil
                    }
                }
            }
            
            return path
        }
        
        return nil
    }
}
