//
//  FolderDetailGalleryView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 25/11/2025.
//

internal import SwiftUI

struct FolderDetailGalleryView: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @ObservedObject var folder: FolderWrapper
    let folderPath: [Int]
    let sortedSubfolders: [Folder]
    
    @Binding var editingId: UUID?
    @Binding var editingName: String
    var isEditing: FocusState<Bool>.Binding
    @Binding var imagePickerRequest: ImagePickerRequest?
    
    @Binding var moveCopyOperation: MoveCopyOperation?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                ForEach(sortedSubfolders, id: \.id) { subfolder in
                    galleryFolderCell(subfolder)
                }

            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func galleryFolderCell(_ subfolder: Folder) -> some View {
        let idx = folder.folder.subfolders.firstIndex(where: { $0.id == subfolder.id }) ?? 0
        NavigationLink(destination: FolderDetailView(folder: FolderWrapper(subfolder), folderPath: folderPath + [idx], viewModel: viewModel)) {
            ZStack(alignment: .bottomLeading) {
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
                        .overlay(Image(systemName: "folder.fill").font(.system(size: 48)).foregroundColor(.blue))
                }
                
                // Indicador de carpeta oculta (esquina superior derecha)
                if subfolder.isHidden {
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
                    if editingId == subfolder.id {
                        TextField("Nombre", text: $editingName)
                            .focused(isEditing)
                            .onSubmit {
                                viewModel.renameFolder(id: subfolder.id, newName: editingName)
                                editingId = nil
                            }
                            .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(.white)
                    } else {
                        Text(subfolder.name)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
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
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
                moveCopyOperation = MoveCopyOperation(folder: subfolder, sourcePath: folderPath + [idx], isCopy: false)
            } label: {
                Label("Mover", systemImage: "arrow.turn.up.right")
            }
            Button {
                moveCopyOperation = MoveCopyOperation(folder: subfolder, sourcePath: folderPath + [idx], isCopy: true)
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
