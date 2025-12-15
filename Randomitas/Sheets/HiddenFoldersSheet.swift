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
    @State private var hiddenFolders: [(folder: Folder, path: [Int])] = []
    
    var body: some View {
        NavigationStack {
            List {
                if !hiddenFolders.isEmpty {
                    Section(header: Text("Elementos Ocultos")) {
                        ForEach(Array(hiddenFolders.enumerated()), id: \.element.folder.id) { index, item in
                            Button(action: {
                                highlightedItemId = item.folder.id
                                let parentPath = Array(item.path.dropLast())
                                navigateToFullPath(parentPath)
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
                            viewModel.removeHiddenFolders(at: indices, from: hiddenFolders)
                            hiddenFolders = viewModel.getHiddenFolders()
                        }
                    }
                }
                
                if hiddenFolders.isEmpty {
                    Text("Sin Elementos ocultos")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Elementos Ocultas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                hiddenFolders = viewModel.getHiddenFolders()
            }
        }
    }
}
