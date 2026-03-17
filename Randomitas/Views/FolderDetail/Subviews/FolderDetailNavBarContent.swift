//
//  FolderDetailNavBarContent.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

internal import SwiftUI

struct FolderDetailNavBarContent: ToolbarContent {
    @ObservedObject var viewModel: RandomitasViewModel
    @ObservedObject var uiState: FolderDetailViewState
    let liveFolder: Folder
    let folderPath: [Int]
    let sortedSubfolders: [Folder]
    let isInHiddenContext: Bool
    var isSearchFocused: FocusState<Bool>.Binding
    let isPadLandscape: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 6) {
                Text(liveFolder.name)
                    .font(.headline)
                    .foregroundColor(isInHiddenContext ? .orange : .primary)
            }
        }

        ToolbarItem(placement: .navigationBarLeading) {
            if uiState.isSelectionMode {
                Button("Listo") {
                    HapticManager.lightImpact()
                    uiState.isSelectionMode = false
                    uiState.selectedItemIds.removeAll()
                }
            } else if !isPadLandscape || folderPath.isEmpty {
                Button(action: {
                    if folderPath.isEmpty && liveFolder.subfolders.isEmpty {
                        uiState.showFirstElementAlert = true
                    } else {
                        withAnimation(.spring()) {
                            uiState.isSearching = true
                            isSearchFocused.wrappedValue = true
                        }
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.blue)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 6) {
                if folderPath.isEmpty {
                    if !uiState.isSelectionMode {
                        if liveFolder.subfolders.isEmpty {
                            Menu {
                                Button(action: {
                                    uiState.showingInfo = true
                                }) {
                                    Label("Info", systemImage: "info.circle")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.blue)
                            }
                        } else {
                            Menu {
                                if !sortedSubfolders.isEmpty {
                                    Button(action: {
                                        withAnimation {
                                            uiState.isSelectionMode = true
                                        }
                                    }) {
                                        Label("Seleccionar", systemImage: "checkmark.circle")
                                    }
                                }

                                if !isInHiddenContext {
                                    Button(action: {
                                        withAnimation {
                                            uiState.showingHiddenElements.toggle()
                                            viewModel.setShowingHiddenElements(uiState.showingHiddenElements, for: folderPath)
                                        }
                                    }) {
                                        if uiState.showingHiddenElements {
                                            Label("Volver a Elementos", systemImage: "atom")
                                        } else {
                                            Label("Elementos Ocultos", systemImage: "eye.slash")
                                        }
                                    }
                                }

                                Divider()

                                Button(action: {
                                    uiState.showingInfo = true
                                }) {
                                    Label("Info", systemImage: "info.circle")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        let allSelected = !sortedSubfolders.isEmpty && uiState.selectedItemIds.count == sortedSubfolders.count
                        Button(action: {
                            HapticManager.selection()
                            if allSelected {
                                uiState.selectedItemIds.removeAll()
                            } else {
                                let allIds = sortedSubfolders.map { $0.id }
                                uiState.selectedItemIds = Set(allIds)
                            }
                        }) {
                            Label(
                                allSelected ? "Deseleccionar Todo" : "Seleccionar Todo",
                                systemImage: allSelected ? "checkmark.circle.badge.xmark.fill" : "checkmark.circle.badge.plus"
                            )
                        }
                        .tint(.blue)
                    }
                } else {
                    if !uiState.isSelectionMode {
                        Button(action: {
                            HapticManager.lightImpact()
                            uiState.showHiddenFavoriteAlert = viewModel.toggleFolderFavorite(folder: liveFolder, path: folderPath)
                        }) {
                            Image(systemName: viewModel.isFolderFavorite(folderId: liveFolder.id) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }

                        Menu {
                            Button(action: {
                                HapticManager.lightImpact()
                                uiState.editingElement = EditingInfo(folder: liveFolder, path: folderPath)
                            }) {
                                Label("Editar", systemImage: "pencil")
                            }

                            if !sortedSubfolders.isEmpty {
                                Button(action: {
                                    withAnimation {
                                        uiState.isSelectionMode = true
                                    }
                                }) {
                                    Label("Seleccionar", systemImage: "checkmark.circle")
                                }
                            }

                            if !isInHiddenContext {
                                Button(action: {
                                    withAnimation {
                                        uiState.showingHiddenElements.toggle()
                                        viewModel.setShowingHiddenElements(uiState.showingHiddenElements, for: folderPath)
                                    }
                                }) {
                                    if uiState.showingHiddenElements {
                                        Label("Volver a Elementos", systemImage: "atom")
                                    } else {
                                        Label("Elementos Ocultos", systemImage: "eye.slash")
                                    }
                                }
                            }

                            Divider()

                            Button(action: {
                                uiState.showingInfo = true
                            }) {
                                Label("Info", systemImage: "info.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.blue)
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                    } else {
                        let allSelected = !sortedSubfolders.isEmpty && uiState.selectedItemIds.count == sortedSubfolders.count
                        Button(action: {
                            HapticManager.selection()
                            if allSelected {
                                uiState.selectedItemIds.removeAll()
                            } else {
                                let allIds = sortedSubfolders.map { $0.id }
                                uiState.selectedItemIds = Set(allIds)
                            }
                        }) {
                            Label(
                                allSelected ? "Deseleccionar Todo" : "Seleccionar Todo",
                                systemImage: allSelected ? "checkmark.circle.badge.xmark.fill" : "checkmark.circle.badge.plus"
                            )
                        }
                        .tint(.blue)
                    }
                }
            }
        }
    }
}
