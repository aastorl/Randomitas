//
//  HiddenFoldersSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña on 05/12/2025.
//

internal import SwiftUI

struct HiddenFoldersSheet: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @Binding var isPresented: Bool
    var navigateToFullPath: ([Int]) -> Void
    @Binding var highlightedItemId: UUID?
    
    // Computed property - reactivo a cambios en viewModel.folders
    private var hiddenFolders: [(folder: Folder, path: [Int])] {
        viewModel.getHiddenFolders()
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !hiddenFolders.isEmpty {
                    Section() {
                        ForEach(Array(hiddenFolders.enumerated()), id: \.element.folder.id) { index, item in
                            Button(action: {
                                highlightedItemId = item.folder.id
                                navigateToFullPath(item.path)
                                isPresented = false
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.folder.name)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        HStack(spacing: 4) {
                                            Text("< \(viewModel.getReversedPathString(for: item.path))")
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
                            // Necesitamos capturar los folders actuales antes de borrar
                            let currentHiddenFolders = hiddenFolders
                            viewModel.removeHiddenFolders(at: indices, from: currentHiddenFolders)
                        }
                    }
                }
                
                if hiddenFolders.isEmpty {
                    Text("Sin Elementos ocultos")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Elementos Ocultos")
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

