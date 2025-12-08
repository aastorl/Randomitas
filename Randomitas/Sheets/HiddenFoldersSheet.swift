//
//  HiddenFoldersSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña on 05/12/2025.
//

internal import SwiftUI

struct HiddenDestination: Identifiable, Hashable {
    let id = UUID()
    let path: [Int]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: HiddenDestination, rhs: HiddenDestination) -> Bool {
        lhs.id == rhs.id
    }
}

struct HiddenFoldersSheet: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @Binding var isPresented: Bool
    @State var selectedDestination: HiddenDestination?
    @State private var hiddenFolders: [(folder: Folder, path: [Int])] = []
    
    var body: some View {
        NavigationStack {
            List {
                if !hiddenFolders.isEmpty {
                    Section(header: Text("Carpetas Ocultas")) {
                        ForEach(Array(hiddenFolders.enumerated()), id: \.element.folder.id) { index, item in
                            NavigationLink(value: HiddenDestination(path: item.path)) {
                                HStack {
                                    Image(systemName: "eye.slash")
                                        .foregroundColor(.gray)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.folder.name)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .onDelete { indices in
                            viewModel.removeHiddenFolders(at: indices, from: hiddenFolders)
                            hiddenFolders = viewModel.getHiddenFolders()
                        }
                    }
                }
                
                if hiddenFolders.isEmpty {
                    Text("Sin carpetas ocultas")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Carpetas Ocultas")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HiddenDestination.self) { destination in
                if let folderView = buildFolderViewFromPath(destination.path) {
                    folderView
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                hiddenFolders = viewModel.getHiddenFolders()
            }
        }
    }
    
    private func buildFolderViewFromPath(_ path: [Int]) -> FolderDetailView? {
        guard !path.isEmpty else { return nil }
        
        var currentFolder = viewModel.folders[path[0]]
        for i in 1..<path.count {
            guard i < path.count, path[i] < currentFolder.subfolders.count else { return nil }
            currentFolder = currentFolder.subfolders[path[i]]
        }
        
        return FolderDetailView(
            folder: FolderWrapper(currentFolder),
            folderPath: path,
            viewModel: viewModel
        )
    }
}
