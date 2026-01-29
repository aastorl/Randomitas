//
//  FavoritesSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

internal import SwiftUI

struct FavoritesSheet: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @Binding var isPresented: Bool
    var navigateToFullPath: ([Int]) -> Void
    @Binding var highlightedItemId: UUID?
    @Binding var currentPath: [Int]
    
    // Computed property - filtra favoritos que aún existen
    private var validFavorites: [(FolderReference, [Int])] {
        viewModel.folderFavorites.filter { fav in
            // Verificar que el folder aún existe en el path indicado
            if let folder = viewModel.getFolderFromPath(fav.1) {
                return folder.id == fav.0.id
            }
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Carpetas Favoritas
                if !validFavorites.isEmpty {
                    Section(header: Text("")) {
                        ForEach(validFavorites, id: \.0.id) { fav in
                            Button(action: {
                                highlightedItemId = fav.0.id
                                
                                // Navegar directamente a la carpeta favorita
                                let targetPath = fav.1
                                
                                navigateToFullPath(targetPath)
                                isPresented = false
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(fav.0.name)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        HStack(spacing: 4) {
                                            Text("< \(viewModel.getReversedPathString(for: fav.1))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .onDelete { indices in
                            // Necesitamos mapear los índices de validFavorites a folderFavorites
                            let validFavs = validFavorites
                            let idsToRemove = indices.map { validFavs[$0].0.id }
                            
                            // Encontrar los índices reales en folderFavorites
                            let realIndices = IndexSet(viewModel.folderFavorites.enumerated()
                                .filter { idsToRemove.contains($0.element.0.id) }
                                .map { $0.offset })
                            
                            viewModel.removeFolderFavorites(at: realIndices)
                        }
                    }
                }
                
                if validFavorites.isEmpty {
                    Text("Sin Elementos Favoritos")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Favoritos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
