//
//  FolderDetailGalleryView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 25/11/2025.
//

internal import SwiftUI

struct FolderDetailGalleryView: View {
    @ObservedObject var viewModel: RandomitasViewModel
    // FolderWrapper eliminado
    let folderPath: [Int]
    let sortedSubfolders: [Folder]
    let sortType: RandomitasViewModel.SortType
    let isInHiddenContext: Bool
    @Binding var showingHiddenAncestorAlert: Bool
    @Binding var hiddenAncestorAlertName: String
    @Binding var showHiddenFavoriteAlert: Bool
    
    
    @Binding var editingElement: EditingInfo?
    @Binding var imagePickerRequest: ImagePickerRequest?
    @Binding var moveCopyOperation: MoveCopyOperation?
    
    @Binding var isSelectionMode: Bool
    @Binding var navigationPath: NavigationPath
    @Binding var selectedItemIds: Set<UUID>
    var onOpenSearch: (() -> Void)? = nil

    var highlightedItemId: UUID? // Añadido
    
    // Confirmación de eliminación
    @State private var folderToDelete: Folder?
    
    /// Indica si se deben mostrar los encabezados de sección alfabéticos
    private var isAlphabeticalSort: Bool {
        sortType == .nameAsc || sortType == .nameDesc
    }
    
    /// Agrupa las subcarpetas ordenadas por su primera letra
    private var groupedSubfolders: [(letter: String, folders: [Folder])] {
        var groups: [(String, [Folder])] = []
        var currentLetter = ""
        var currentGroup: [Folder] = []
        
        for folder in sortedSubfolders {
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
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    if isAlphabeticalSort {
                        ForEach(groupedSubfolders, id: \.letter) { group in
                            // Encabezado de letra de sección
                            Text(group.letter)
                                .font(.title3.bold())
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                            
                            ForEach(group.folders, id: \.id) { subfolder in
                                galleryFolderCell(subfolder)
                                    .id(subfolder.id)
                            }
                        }
                    } else {
                        ForEach(sortedSubfolders, id: \.id) { subfolder in
                            galleryFolderCell(subfolder)
                                .id(subfolder.id)
                        }
                    }
                }
                .padding()
                .padding(.bottom, 80)
            }
            .refreshable {
                await MainActor.run {
                    onOpenSearch?()
                }
            }
            .onAppear {
                if let id = highlightedItemId {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        .alert("¿Eliminar este Elemento?", isPresented: Binding(
            get: { folderToDelete != nil },
            set: { if !$0 { folderToDelete = nil } }
        )) {
            Button("Cancelar", role: .cancel) {
                folderToDelete = nil
            }
            Button("Eliminar", role: .destructive) {
                if let folder = folderToDelete {
                    HapticManager.warning()
                    if folderPath.isEmpty {
                        viewModel.deleteRootFolder(id: folder.id)
                    } else {
                        viewModel.deleteSubfolder(id: folder.id, from: folderPath)
                    }
                    folderToDelete = nil
                }
            }
        } message: {
            if let folder = folderToDelete {
                Text("Se eliminará \"\(folder.name)\" permanentemente.")
            }
        }
    }
    
    @ViewBuilder
    private func galleryFolderCell(_ subfolder: Folder) -> some View {
        // Calcula el índice - retorna nil si la subcarpeta ya no existe en los datos
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
        
        let displayFolder: Folder = {
            if let validIdx = idx, let liveFolder = viewModel.getFolderFromPath(folderPath + [validIdx]) {
                return liveFolder
            }
            return subfolder
        }()

        let cellContent = ZStack(alignment: .bottomLeading) {
            if let imageData = displayFolder.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()
                    .blur(radius: displayFolder.isHidden ? 12 : 0)
                    .overlay(alignment: .center) {
                        if displayFolder.isHidden {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                        }
                    }
            } else {
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 300)
                    .overlay(Image(systemName: displayFolder.isHidden ? "eye.slash" : "atom").font(.system(size: 48)).foregroundColor(displayFolder.isHidden ? .orange : .blue))
            }
            
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear]), startPoint: .bottom, endPoint: .top)
                .frame(height: 100)
            
            HStack {
                Text(displayFolder.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .overlay(
            // Superposición de marca de verificación en modo de selección
            ZStack {
                if isSelectionMode {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: selectedItemIds.contains(subfolder.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedItemIds.contains(subfolder.id) ? .blue : .white)
                                .background(selectedItemIds.contains(subfolder.id) ? Color.white : Color.black.opacity(0.3))
                                .clipShape(Circle())
                                .font(.system(size: 28))
                                .padding(10)
                        }
                        Spacer()
                    }
                }
            }
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        
        // Usar NavigationLink o tap gesture según el modo
        // Mostrar navegación/contexto solo si el índice es válido (el elemento aún existe)
        if let validIdx = idx {
            Group {
                if isSelectionMode {
                    cellContent
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedItemIds.contains(subfolder.id) {
                                selectedItemIds.remove(subfolder.id)
                            } else {
                                selectedItemIds.insert(subfolder.id)
                            }
                        }
                } else {
                    NavigationLink(destination: FolderDetailView(
                        folder: displayFolder,
                        folderPath: folderPath + [validIdx],
                        viewModel: viewModel,
                        navigationPath: $navigationPath
                    )) {
                        cellContent
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .contextMenu {
                Button {
                    showHiddenFavoriteAlert = viewModel.toggleFolderFavorite(folder: displayFolder, path: folderPath + [validIdx])
                } label: {
                    Label("Favorito", systemImage: viewModel.isFolderFavorite(folderId: displayFolder.id) ? "star.fill" : "star")
                }
                Button {
                    isSelectionMode = true
                    selectedItemIds.insert(displayFolder.id)
                } label: {
                    Label("Seleccionar", systemImage: "checkmark.circle")
                }
                Button {
                    editingElement = EditingInfo(folder: displayFolder, path: folderPath + [validIdx])
                } label: {
                    Label("Editar", systemImage: "pencil")
                }
                Button {
                    if isInHiddenContext {
                        if let ancestorName = viewModel.getHiddenAncestorName(at: folderPath + [validIdx]) ?? viewModel.getFolderFromPath(folderPath).flatMap({ $0.isHidden ? $0.name : nil }) {
                            hiddenAncestorAlertName = ancestorName
                            showingHiddenAncestorAlert = true
                        }
                    } else {
                        viewModel.toggleFolderHidden(folder: displayFolder, path: folderPath + [validIdx])
                    }
                } label: {
                    if isInHiddenContext {
                        Label("Mostrar", systemImage: "eye")
                    } else {
                        Label(displayFolder.isHidden ? "Mostrar" : "Ocultar", systemImage: displayFolder.isHidden ? "eye" : "eye.slash")
                    }
                }
                Button(role: .destructive) {
                    folderToDelete = displayFolder
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
        } else {
            // El elemento ya no existe: mostrar contenido sin interacción
            cellContent
                .opacity(0.5)
        }
    }
    


}
