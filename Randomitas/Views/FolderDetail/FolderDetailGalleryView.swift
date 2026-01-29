//
//  FolderDetailGalleryView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 25/11/2025.
//

internal import SwiftUI

struct FolderDetailGalleryView: View {
    @ObservedObject var viewModel: RandomitasViewModel
    // removed FolderWrapper
    let folderPath: [Int]
    let sortedSubfolders: [Folder]
    
    
    @Binding var editingElement: EditingInfo?
    @Binding var imagePickerRequest: ImagePickerRequest?
    @Binding var moveCopyOperation: MoveCopyOperation?
    
    @Binding var isSelectionMode: Bool
    @Binding var navigationPath: NavigationPath
    @Binding var selectedItemIds: Set<UUID>
    var onOpenSearch: (() -> Void)? = nil

    var highlightedItemId: UUID? // Added
    
    // Delete confirmation
    @State private var folderToDelete: Folder?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    ForEach(sortedSubfolders, id: \.id) { subfolder in
                        galleryFolderCell(subfolder)
                            .id(subfolder.id)
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
        let idx: Int = {
            if folderPath.isEmpty {
                return viewModel.folders.firstIndex(where: { $0.id == subfolder.id }) ?? 0
            } else {
                if let parent = viewModel.getFolderFromPath(folderPath) {
                    return parent.subfolders.firstIndex(where: { $0.id == subfolder.id }) ?? 0
                } else {
                    return 0
                }
            }
        }()
        
        let cellContent = ZStack(alignment: .bottomLeading) {
            if let imageData = subfolder.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()
            } else {
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 300)
                    .overlay(Image(systemName: "atom").font(.system(size: 48)).foregroundColor(.blue))
            }
            
            // Indicador de carpeta oculta (esquina superior derecha)
            if subfolder.isHidden && !isSelectionMode {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "eye.slash")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(12)
            }
            
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear]), startPoint: .bottom, endPoint: .top)
                .frame(height: 100)
            
            HStack {
                Text(subfolder.name)
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
            // Selection mode checkmark overlay
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
                    folder: subfolder,
                    folderPath: folderPath + [idx],
                    viewModel: viewModel,
                    navigationPath: $navigationPath
                )) {
                    cellContent
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .contextMenu {
            Button { viewModel.toggleFolderFavorite(folder: subfolder, path: folderPath + [idx]) } label: {
                Label("Favorito", systemImage: viewModel.isFolderFavorite(folderId: subfolder.id) ? "star.fill" : "star")
            }
            Button {
                isSelectionMode = true
                selectedItemIds.insert(subfolder.id)
            } label: {
                Label("Seleccionar", systemImage: "checkmark.circle")
            }
            Button {
                editingElement = EditingInfo(folder: subfolder, path: folderPath + [idx])
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            Button {
                viewModel.toggleFolderHidden(folder: subfolder, path: folderPath + [idx])
            } label: {
                Label(subfolder.isHidden ? "Mostrar" : "Ocultar", systemImage: subfolder.isHidden ? "eye" : "eye.slash")
            }
            Button(role: .destructive) {
                folderToDelete = subfolder
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
    


}
