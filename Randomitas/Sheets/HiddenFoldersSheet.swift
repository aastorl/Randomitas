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
    
    @State private var sortType: RandomitasViewModel.SortType = .nameAsc
    @State private var showingPathPopup: (name: String, path: String)? = nil
    
    private var hiddenFolders: [(folder: Folder, path: [Int])] {
        viewModel.getHiddenFolders()
    }
    
    private var sortedHiddenFolders: [(folder: Folder, path: [Int])] {
        switch sortType {
        case .nameAsc:
            return hiddenFolders.sorted { $0.folder.name.localizedCaseInsensitiveCompare($1.folder.name) == .orderedAscending }
        case .nameDesc:
            return hiddenFolders.sorted { $0.folder.name.localizedCaseInsensitiveCompare($1.folder.name) == .orderedDescending }
        case .dateNewest:
            return hiddenFolders.sorted { ($0.folder.createdAt ?? Date.distantPast) > ($1.folder.createdAt ?? Date.distantPast) }
        case .dateOldest:
            return hiddenFolders.sorted { ($0.folder.createdAt ?? Date.distantPast) < ($1.folder.createdAt ?? Date.distantPast) }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if sortedHiddenFolders.isEmpty {
                    SheetEmptyStateView(
                        icon: "eye.slash",
                        title: "Sin Elementos Ocultos",
                        subtitle: "Los elementos que ocultes aparecerán aquí"
                    )
                } else {
                    List {
                        Section() {
                            ForEach(Array(sortedHiddenFolders.enumerated()), id: \.element.folder.id) { index, item in
                                let pathString = viewModel.getReversedPathString(for: item.path)
                                let inheritedImage = viewModel.getInheritedImageData(for: item.path)
                                
                                SheetRowView(
                                    name: item.folder.name,
                                    imageData: inheritedImage,
                                    onTap: {
                                        highlightedItemId = item.folder.id
                                        navigateToFullPath(item.path)
                                        isPresented = false
                                    },
                                    onLongPress: {
                                        HapticManager.lightImpact()
                                        showingPathPopup = (name: item.folder.name, path: pathString)
                                    }
                                )
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowBackground(Color(.systemBackground).opacity(0.7))
                            }
                            .onDelete { indices in
                                let currentSorted = sortedHiddenFolders
                                let foldersToRemove = indices.map { currentSorted[$0] }
                                let originalIndices = IndexSet(foldersToRemove.compactMap { folder in
                                    hiddenFolders.firstIndex(where: { $0.folder.id == folder.folder.id })
                                })
                                viewModel.removeHiddenFolders(at: originalIndices, from: hiddenFolders)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 0)
                }
            }
            .navigationTitle("Elementos Ocultos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !sortedHiddenFolders.isEmpty {
                        Menu {
                            Section("Nombre") {
                                Button(action: { sortType = .nameAsc }) {
                                    HStack {
                                        Text("A → Z")
                                        if sortType == .nameAsc {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                Button(action: { sortType = .nameDesc }) {
                                    HStack {
                                        Text("Z → A")
                                        if sortType == .nameDesc {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            Section("Fecha") {
                                Button(action: { sortType = .dateNewest }) {
                                    HStack {
                                        Text("Más reciente")
                                        if sortType == .dateNewest {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                Button(action: { sortType = .dateOldest }) {
                                    HStack {
                                        Text("Más antiguo")
                                        if sortType == .dateOldest {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        isPresented = false
                    }
                }
            }
            .alert(showingPathPopup?.name ?? "", isPresented: Binding(
                get: { showingPathPopup != nil },
                set: { if !$0 { showingPathPopup = nil } }
            )) {
                Button("OK", role: .cancel) {
                    showingPathPopup = nil
                }
            } message: {
                if let popup = showingPathPopup {
                    Text("< \(popup.path)")
                }
            }
        }
    }
}
