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
    
    
    @Binding var editingElement: EditingInfo?
    
    // Undo delete state
    @State private var deletedFolder: Folder?
    @State private var showUndoSnackbar = false
    @State private var undoTimer: Timer?
    
    @Binding var imagePickerRequest: ImagePickerRequest?
    @Binding var moveCopyOperation: MoveCopyOperation?
    
    @Binding var isSelectionMode: Bool
    @Binding var navigationPath: NavigationPath
    @Binding var selectedItemIds: Set<UUID>
    var onOpenSearch: (() -> Void)? = nil

    var highlightedItemId: UUID?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                if !sortedSubfolders.isEmpty {
                    ForEach(sortedSubfolders, id: \.id) { subfolder in
                        subfolderRow(subfolder)
                            .id(subfolder.id)
                    }
                }
                
                if sortedSubfolders.isEmpty {
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
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 80)
        }
        .overlay(alignment: .bottom) {
            // Undo Snackbar
            if showUndoSnackbar, let folder = deletedFolder {
                HStack {
                    Text("\"\(folder.name)\" eliminado")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                    
                    Button("Deshacer") {
                        undoDelete()
                    }
                    .foregroundColor(.yellow)
                    .font(.system(size: 14, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.85))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showUndoSnackbar)
    }
    
    // MARK: - Undo Logic
    
    private func deleteWithUndo(_ folder: Folder) {
        // Cancel any existing timer
        undoTimer?.invalidate()
        
        // Store the folder for potential undo
        deletedFolder = folder
        
        // Delete immediately
        HapticManager.warning()
        if folderPath.isEmpty {
            viewModel.deleteRootFolder(id: folder.id)
        } else {
            viewModel.deleteSubfolder(id: folder.id, from: folderPath)
        }
        
        // Show snackbar
        withAnimation {
            showUndoSnackbar = true
        }
        
        // Start timer to hide snackbar after 4 seconds
        undoTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation {
                showUndoSnackbar = false
                deletedFolder = nil
            }
        }
    }
    
    private func undoDelete() {
        guard let folder = deletedFolder else { return }
        
        // Cancel timer
        undoTimer?.invalidate()
        
        // Re-add the folder
        if folderPath.isEmpty {
            viewModel.addRootFolder(name: folder.name, isFavorite: false, imageData: folder.imageData)
        } else {
            viewModel.addSubfolder(name: folder.name, to: folderPath, isFavorite: false, imageData: folder.imageData)
        }
        
        HapticManager.success()
        
        // Hide snackbar
        withAnimation {
            showUndoSnackbar = false
            deletedFolder = nil
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
                    
                    Image(systemName: "atom")
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                    
                    Text(subfolder.name)
                    
                    // Icono para carpetas ocultas
                    if subfolder.isHidden {
                        Image(systemName: "eye.slash")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                    
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
                    deleteWithUndo(subfolder)
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
            .contextMenu {
                Button { viewModel.toggleFolderFavorite(folder: subfolder, path: folderPath + [validIdx]) } label: {
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
                    viewModel.toggleFolderHidden(folder: subfolder, path: folderPath + [validIdx])
                } label: {
                    Label(subfolder.isHidden ? "Mostrar" : "Ocultar", systemImage: subfolder.isHidden ? "eye" : "eye.slash")
                }
                Button(role: .destructive) {
                    deleteWithUndo(subfolder)
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
        } else {
            // Element no longer exists - show placeholder
            HStack {
                Image(systemName: "atom")
                    .foregroundColor(.gray)
                Text(subfolder.name)
                    .foregroundColor(.gray)
            }
            .opacity(0.5)
            .listRowBackground(Color(.systemBackground).opacity(0.7))
        }
    }
}
