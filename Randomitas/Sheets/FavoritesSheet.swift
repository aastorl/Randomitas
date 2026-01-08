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
    
    var body: some View {
        NavigationStack {
            List {
                // Carpetas Favoritas
                if !viewModel.folderFavorites.isEmpty {
                    Section(header: Text("")) {
                        ForEach(viewModel.folderFavorites, id: \.0.id) { fav in
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
                            viewModel.removeFolderFavorites(at: indices)
                        }
                    }
                }
                
                if viewModel.folderFavorites.isEmpty {
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
