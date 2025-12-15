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
    var navigateToFullPath: ([Int]) -> Void
    @Binding var highlightedItemId: UUID?
    @State private var searchText = ""
    @State private var foundFolders: [(Folder, [Int], String)] = []
    
    var body: some View {
        NavigationStack {
            List {
                if !foundFolders.isEmpty {
                    Section(header: Text("Elementos Encontrados")) {
                        ForEach(foundFolders, id: \.0.id) { folder, path, parentName in
                            Button(action: {
                                highlightedItemId = folder.id
                                let parentPath = Array(path.dropLast())
                                navigateToFullPath(parentPath)
                                isPresented = false
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(folder.name)
                                            .foregroundColor(.primary)
                                        HStack(spacing: 4) {
                                            Text("< \(parentName)")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                if searchText.isEmpty {
                    Text("Escribe para buscar")
                        .foregroundColor(.gray)
                } else if foundFolders.isEmpty {
                    Text("No se encontraron Elementos")
                        .foregroundColor(.gray)
                }
            }
            .searchable(text: $searchText, prompt: "Buscar Elementos")
            .onChange(of: searchText) { query in
                let results = viewModel.search(query: query)
                foundFolders = results
            }
            .navigationTitle("Buscar")
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
