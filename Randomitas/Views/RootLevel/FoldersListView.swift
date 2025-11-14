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
                    folder: folder,
                    folderPath: [idx],
                    viewModel: viewModel
                )) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
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
