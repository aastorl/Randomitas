//
//  FolderDetailListView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 25/11/2025.
//

internal import SwiftUI

struct FolderDetailListView: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @ObservedObject var folder: FolderWrapper
    let folderPath: [Int]
    let sortedSubfolders: [Folder]
    
    @Binding var editingId: UUID?
    @Binding var editingName: String
    var isEditing: FocusState<Bool>.Binding
    
    @State private var subfolderToDelete: UUID?
    @Binding var imagePickerRequest: ImagePickerRequest?
    @Binding var moveCopyOperation: MoveCopyOperation?
    
    @Binding var isSelectionMode: Bool
    @Binding var navigationPath: NavigationPath
    @Binding var selectedItemIds: Set<UUID>

    var highlightedItemId: UUID?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollViewReader { proxy in
            List(selection: $selectedItemIds) {
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
            .environment(\.editMode, .constant(isSelectionMode ? .active : .inactive))
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
        .alert("¿Seguro quieres eliminar este Elemento?", isPresented: .constant(subfolderToDelete != nil)) {
            Button("Cancelar", role: .cancel) {
                subfolderToDelete = nil
            }
            Button("Eliminar", role: .destructive) {
                if let id = subfolderToDelete {
                    viewModel.deleteSubfolder(id: id, from: folderPath)
                    subfolderToDelete = nil
                }
            }
        }
    }
    
    @ViewBuilder
    private func subfolderRow(_ subfolder: Folder) -> some View {
        let idx = folder.folder.subfolders.firstIndex(where: { $0.id == subfolder.id }) ?? 0
        ZStack(alignment: .leading) {
            NavigationLink(destination: FolderDetailView(
                folder: FolderWrapper(subfolder),
                folderPath: folderPath + [idx],
                viewModel: viewModel,
                navigationPath: $navigationPath
            )) {
                EmptyView()
            }
            .opacity(0)
            .disabled(isSelectionMode)
            
            HStack(spacing: 12) {
                Image(systemName: "atom")
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                
                if editingId == subfolder.id {
                    TextField("Nombre", text: $editingName)
                        .focused(isEditing)
                        .onSubmit {
                            viewModel.renameFolder(id: subfolder.id, newName: editingName)
                            editingId = nil
                        }
                } else {
                    Text(subfolder.name)
                }
                
                // Icono para carpetas ocultas
                if subfolder.isHidden {
                    Image(systemName: "eye.slash")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                
                Spacer()
                
                // Indicador de navegación personalizado
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
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { subfolderToDelete = subfolder.id } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
        .contextMenu {
            Button { viewModel.toggleFolderFavorite(folder: subfolder, path: folderPath + [idx]) } label: {
                Label("Favorito", systemImage: viewModel.isFolderFavorite(folderId: subfolder.id) ? "star.fill" : "star")
            }
            Button {
                editingId = subfolder.id
                editingName = subfolder.name
                isEditing.wrappedValue = true
            } label: {
                Label("Renombrar", systemImage: "pencil")
            }
            Button {
                isSelectionMode = true
                selectedItemIds.insert(subfolder.id)
            } label: {
                Label("Seleccionar", systemImage: "checkmark.circle")
            }
            Button {
                moveCopyOperation = MoveCopyOperation(items: [subfolder], sourceContainerPath: folderPath, isCopy: false)
            } label: {
                Label("Mover", systemImage: "arrow.turn.up.right")
            }
            Button {
                moveCopyOperation = MoveCopyOperation(items: [subfolder], sourceContainerPath: folderPath, isCopy: true)
            } label: {
                Label("Copiar", systemImage: "doc.on.doc")
            }
            Button {
                viewModel.toggleFolderHidden(folder: subfolder, path: folderPath + [idx])
            } label: {
                Label(subfolder.isHidden ? "Mostrar" : "Ocultar", systemImage: subfolder.isHidden ? "eye" : "eye.slash")
            }
            Button(role: .destructive) { viewModel.deleteSubfolder(id: subfolder.id, from: folderPath) } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}
