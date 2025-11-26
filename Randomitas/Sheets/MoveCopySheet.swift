//
//  MoveCopySheet.swift
//  Randomitas
//
//  Created by Astor Ludueña on 25/11/2025.
//

internal import SwiftUI

struct MoveCopySheet: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @Binding var isPresented: Bool
    
    let itemToMove: Item?
    let folderToMove: Folder?
    let currentPath: [Int] // Path of the item/folder being moved
    let isCopy: Bool
    
    @State private var selectedDestinationPath: [Int]?
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Destino")) {
                    // Root option (only if moving a folder to root, or item to root if we supported items at root, but items must be in folders? No, items are in folders. Root folders are at root.)
                    // Actually, items MUST be in a folder. Folders CAN be at root.
                    // So if moving a folder, we can move to Root (path []).
                    // If moving an item, we MUST select a folder.
                    
                    if folderToMove != nil {
                        Button(action: { selectedDestinationPath = [] }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                Text("Raíz")
                                Spacer()
                                if selectedDestinationPath == [] {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .disabled(isCurrentLocation([]))
                    }
                    
                    ForEach(Array(viewModel.folders.enumerated()), id: \.element.id) { index, folder in
                        FolderHierarchyRow(
                            folder: folder,
                            path: [index],
                            selectedPath: $selectedDestinationPath,
                            disabledPath: getDisabledPath(),
                            movingItem: itemToMove != nil
                        )
                    }
                }
            }
            .navigationTitle(isCopy ? "Copiar a..." : "Mover a...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isCopy ? "Copiar" : "Mover") {
                        performAction()
                    }
                    .disabled(selectedDestinationPath == nil)
                }
            }
        }
    }
    
    private func isCurrentLocation(_ path: [Int]) -> Bool {
        // If moving an item, current location is the folder it's in (currentPath).
        // If moving a folder, current location is its parent folder.
        // But wait, folderToMove's path is passed as currentPath.
        // If folderToMove is at root, currentPath is [index]. Parent is [].
        
        // Actually, let's simplify.
        // If moving item: destination cannot be the same folder it's currently in.
        // If moving folder: destination cannot be itself or any of its children.
        
        if let _ = itemToMove {
            return path == currentPath
        }
        
        if let _ = folderToMove {
            // If moving folder, currentPath is the path TO the folder.
            // e.g. Root > A > B. Path to B is [0, 0].
            // Parent is [0].
            // We can't move B to [0] (it's already there).
            
            // Logic:
            // 1. Destination cannot be the parent of the folder (no-op).
            // 2. Destination cannot be the folder itself (no-op).
            // 3. Destination cannot be a child of the folder (circular).
            
            // Check 3: Is destination a child of folderToMove?
            // If destination starts with currentPath, it's a child (or self).
            if path.starts(with: currentPath) {
                return true
            }
            
            // Check 1: Is destination the parent?
            // Parent path is currentPath.dropLast().
            if path == Array(currentPath.dropLast()) {
                return true
            }
        }
        
        return false
    }
    
    private func getDisabledPath() -> [Int]? {
        // If moving a folder, we disable the folder itself and its children.
        // So we pass the path of the folder being moved.
        if let _ = folderToMove {
            return currentPath
        }
        return nil
    }
    
    private func performAction() {
        guard let destination = selectedDestinationPath else { return }
        
        if let item = itemToMove {
            if isCopy {
                viewModel.copyItem(id: item.id, to: destination)
            } else {
                viewModel.moveItem(id: item.id, to: destination)
            }
        } else if let folder = folderToMove {
            if isCopy {
                viewModel.copyFolder(id: folder.id, to: destination)
            } else {
                viewModel.moveFolder(id: folder.id, to: destination)
            }
        }
        
        isPresented = false
    }
}

struct FolderHierarchyRow: View {
    let folder: Folder
    let path: [Int]
    @Binding var selectedPath: [Int]?
    let disabledPath: [Int]?
    let movingItem: Bool
    
    @State private var isExpanded: Bool = false
    
    var isDisabled: Bool {
        // If this folder is the one being moved (or a child of it), it's disabled.
        if let disabled = disabledPath {
            if path.starts(with: disabled) { return true }
        }
        
        if movingItem {
            // Cannot move item to a folder that has subfolders
            if !folder.subfolders.isEmpty { return true }
        } else {
            // Cannot move folder to a folder that has items
            if !folder.items.isEmpty { return true }
        }
        
        return false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if !folder.subfolders.isEmpty {
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                    }
                } else {
                    Spacer().frame(width: 20)
                }
                
                Button(action: { selectedPath = path }) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(isDisabled ? .gray : .blue)
                        Text(folder.name)
                            .foregroundColor(isDisabled ? .gray : .primary)
                        Spacer()
                        if selectedPath == path {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .disabled(isDisabled)
            }
            .padding(.vertical, 4)
            
            if isExpanded {
                ForEach(Array(folder.subfolders.enumerated()), id: \.element.id) { index, subfolder in
                    FolderHierarchyRow(
                        folder: subfolder,
                        path: path + [index],
                        selectedPath: $selectedPath,
                        disabledPath: disabledPath,
                        movingItem: movingItem
                    )
                    .padding(.leading, 20)
                }
            }
        }
    }
}
