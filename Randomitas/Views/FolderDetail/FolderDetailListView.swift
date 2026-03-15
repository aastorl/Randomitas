//
//  FolderDetailListView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 25/11/2025.
//

internal import SwiftUI

struct FolderDetailListView: View {
    @ObservedObject var viewModel: RandomitasViewModel
    // removed @ObservedObject var folder: FolderWrapper - not needed if we rely on sortedSubfolders + path
    let folderPath: [Int]
    let sortedSubfolders: [Folder]
    let sortType: RandomitasViewModel.SortType
    let isInHiddenContext: Bool
    @Binding var showingHiddenAncestorAlert: Bool
    @Binding var hiddenAncestorAlertName: String
    @Binding var showHiddenFavoriteAlert: Bool
    
    
    @Binding var editingElement: EditingInfo?
    
    // Delete policy: immediate delete (consistent across views)
    
    @Binding var imagePickerRequest: ImagePickerRequest?
    @Binding var moveCopyOperation: MoveCopyOperation?
    
    @Binding var isSelectionMode: Bool
    @Binding var navigationPath: NavigationPath
    @Binding var selectedItemIds: Set<UUID>
    var onOpenSearch: (() -> Void)? = nil

    var highlightedItemId: UUID?
    
    @Environment(\.dismiss) var dismiss
    
    private var visibleSubfolders: [Folder] {
        sortedSubfolders
    }
    
    /// Whether to show alphabetical section headers
    private var isAlphabeticalSort: Bool {
        sortType == .nameAsc || sortType == .nameDesc
    }
    
    /// Groups sorted subfolders by their first letter (using sortName logic)
    private var groupedSubfolders: [(letter: String, folders: [Folder])] {
        var groups: [(String, [Folder])] = []
        var currentLetter = ""
        var currentGroup: [Folder] = []
        
        for folder in visibleSubfolders {
            let letter = viewModel.sectionLetter(for: folder)
            if letter != currentLetter {
                if !currentGroup.isEmpty {
                    groups.append((currentLetter, currentGroup))
                }
                currentLetter = letter
                currentGroup = [folder]
            } else {
                currentGroup.append(folder)
            }
        }
        if !currentGroup.isEmpty {
            groups.append((currentLetter, currentGroup))
        }
        return groups
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                List {
                    if !visibleSubfolders.isEmpty {
                        if isAlphabeticalSort {
                            ForEach(groupedSubfolders, id: \.letter) { group in
                                Section {
                                    ForEach(group.folders, id: \.id) { subfolder in
                                        subfolderRow(subfolder)
                                            .id(subfolder.id)
                                    }
                                } header: {
                                    Text(group.letter)
                                        .font(.body.bold())
                                        .foregroundColor(.secondary)
                                        .textCase(nil)
                                }
                            }
                        } else {
                            ForEach(visibleSubfolders, id: \.id) { subfolder in
                                subfolderRow(subfolder)
                                    .id(subfolder.id)
                            }
                        }
                    }
                    
                    if visibleSubfolders.isEmpty {
                        Text("Vacío").foregroundColor(.gray)
                    }
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    await MainActor.run {
                        onOpenSearch?()
                    }
                }
                .onAppear {
                    if let id = highlightedItemId {
                        withAnimation {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
            
        }
    }
    
    // MARK: - Delete Logic
    private func deleteFolder(_ folder: Folder) {
        HapticManager.warning()
        if folderPath.isEmpty {
            viewModel.deleteRootFolder(id: folder.id)
        } else {
            viewModel.deleteSubfolder(id: folder.id, from: folderPath)
        }
    }
    
    @ViewBuilder
    private func subfolderRow(_ subfolder: Folder) -> some View {
        // Calculate index - returns nil if subfolder no longer exists in the live data
        let idx: Int? = {
            if folderPath.isEmpty {
                return viewModel.folders.firstIndex(where: { $0.id == subfolder.id })
            } else {
                if let parent = viewModel.getFolderFromPath(folderPath) {
                    return parent.subfolders.firstIndex(where: { $0.id == subfolder.id })
                } else {
                    return nil
                }
            }
        }()
        
        // Guard against stale data - if element no longer exists, show disabled view
        if let validIdx = idx {
            ZStack(alignment: .leading) {
                NavigationLink(destination: FolderDetailView(
                    folder: subfolder,
                    folderPath: folderPath + [validIdx],
                    viewModel: viewModel,
                    navigationPath: $navigationPath
                )) {
                    EmptyView()
                }
                .opacity(0)
                .disabled(isSelectionMode)
                
                HStack(spacing: 12) {
                    // Selection checkmark (left side)
                    if isSelectionMode {
                        Image(systemName: selectedItemIds.contains(subfolder.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedItemIds.contains(subfolder.id) ? .blue : .gray)
                            .font(.system(size: 22))
                    }
                    
                    Image(systemName: subfolder.isHidden ? "eye.slash" : "atom")
                        .foregroundColor(subfolder.isHidden ? .orange : .blue)
                        .frame(width: 40, height: 40)
                    
                    Text(subfolder.name)
                    
                    Spacer()
                    
                    // Indicador de navegación personalizado
                    if !isSelectionMode {
                        if subfolder.subfolders.isEmpty {
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(.systemGray3))
                                .font(.system(size: 14, weight: .semibold))
                        } else {
                            Image(systemName: "arrow.right")
                                .foregroundColor(Color(.systemGray3))
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isSelectionMode {
                        if selectedItemIds.contains(subfolder.id) {
                            selectedItemIds.remove(subfolder.id)
                        } else {
                            selectedItemIds.insert(subfolder.id)
                        }
                    }
                }
                .allowsHitTesting(isSelectionMode)
            }
            .listRowBackground(
                Color(.systemBackground).opacity(0.7)
            )
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    deleteFolder(subfolder)
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
            .contextMenu {
                Button {
                    showHiddenFavoriteAlert = viewModel.toggleFolderFavorite(folder: subfolder, path: folderPath + [validIdx])
                } label: {
                    Label("Favorito", systemImage: viewModel.isFolderFavorite(folderId: subfolder.id) ? "star.fill" : "star")
                }
                Button {
                    isSelectionMode = true
                    selectedItemIds.insert(subfolder.id)
                } label: {
                    Label("Seleccionar", systemImage: "checkmark.circle")
                }
                Button {
                    editingElement = EditingInfo(folder: subfolder, path: folderPath + [validIdx])
                } label: {
                    Label("Editar", systemImage: "pencil")
                }
                Button {
                    if isInHiddenContext {
                        // Show popup about hidden ancestor
                        if let ancestorName = viewModel.getHiddenAncestorName(at: folderPath + [validIdx]) ?? viewModel.getFolderFromPath(folderPath).flatMap({ $0.isHidden ? $0.name : nil }) {
                            hiddenAncestorAlertName = ancestorName
                            showingHiddenAncestorAlert = true
                        }
                    } else {
                        viewModel.toggleFolderHidden(folder: subfolder, path: folderPath + [validIdx])
                    }
                } label: {
                    if isInHiddenContext {
                        Label("Mostrar", systemImage: "eye")
                    } else {
                        Label(subfolder.isHidden ? "Mostrar" : "Ocultar", systemImage: subfolder.isHidden ? "eye" : "eye.slash")
                    }
                }
                Button(role: .destructive) {
                    deleteFolder(subfolder)
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
        } else {
            // Element no longer exists - show placeholder
            HStack {
                Image(systemName: "eye.slash")
                    .foregroundColor(.orange)
                Text(subfolder.name)
                    .foregroundColor(.gray)
            }
            .opacity(0.5)
            .listRowBackground(Color(.systemBackground).opacity(0.7))
        }
    }
}
