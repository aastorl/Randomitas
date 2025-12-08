//
//  SearchSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña on 01/12/2025.
//

internal import SwiftUI

struct SearchSheet: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var foundFolders: [(Folder, [Int])] = []
    
    var body: some View {
        NavigationStack {
            List {
                if !foundFolders.isEmpty {
                    Section(header: Text("Carpetas")) {
                        ForEach(foundFolders, id: \.0.id) { folder, path in
                            NavigationLink(value: FavoriteDestination(path: path)) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                    Text(folder.name)
                                }
                            }
                        }
                    }
                }
                
                if searchText.isEmpty {
                    Text("Escribe para buscar")
                        .foregroundColor(.gray)
                } else if foundFolders.isEmpty {
                    Text("No se encontraron resultados")
                        .foregroundColor(.gray)
                }
            }
            .searchable(text: $searchText, prompt: "Buscar carpetas")
            .onChange(of: searchText) { query in
                let results = viewModel.search(query: query)
                foundFolders = results
            }
            .navigationTitle("Buscar")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: FavoriteDestination.self) { destination in
                if let folderView = buildFolderViewFromPath(destination.path) {
                    folderView
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func buildFolderViewFromPath(_ path: [Int]) -> FolderDetailView? {
        guard !path.isEmpty else { return nil }
        
        var currentFolder = viewModel.folders[path[0]]
        for i in 1..<path.count {
            guard i < path.count, path[i] < currentFolder.subfolders.count else { return nil }
            currentFolder = currentFolder.subfolders[path[i]]
        }
        
        return FolderDetailView(
            folder: FolderWrapper(currentFolder),
            folderPath: path,
            viewModel: viewModel
        )
    }
}
