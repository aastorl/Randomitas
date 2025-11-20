//
//  FoderListView.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import SwiftUI

struct FoldersListView: View {
    @ObservedObject var viewModel: RandomitasViewModel
    
    var body: some View {
        List {
            ForEach(Array(viewModel.folders.enumerated()), id: \.element.id) { idx, folder in
                NavigationLink(destination: FolderDetailView(
                    folder: FolderWrapper(folder),
                    folderPath: [idx],
                    viewModel: viewModel
                )) {
                    HStack {
                        // Mostrar imagen si existe, sino mostrar ícono
                        if let imageData = folder.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                                .cornerRadius(4)
                        } else {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                        }
                        Text(folder.name)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive, action: { viewModel.deleteRootFolder(id: folder.id) }) {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }
        }
    }
}
