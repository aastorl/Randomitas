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
    
    let folderToMove: Folder
    let currentPath: [Int]
    let isCopy: Bool
    
    var body: some View {
        NavigationStack {
            MoveCopyListView(
                viewModel: viewModel,
                currentFolder: nil, // Root
                currentPath: [],
                sourcePath: currentPath,
                folderToMove: folderToMove,
                isCopy: isCopy,
                onClose: { isPresented = false }
            )
        }
    }
}

struct MoveCopyListView: View {
    @ObservedObject var viewModel: RandomitasViewModel
    let currentFolder: Folder?
    let currentPath: [Int]
    let sourcePath: [Int]
    let folderToMove: Folder
    let isCopy: Bool
    let onClose: () -> Void
    
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // Helper to get subfolders to display
    var subfolders: [Folder] {
        if let folder = currentFolder {
            return folder.subfolders
        } else {
            return viewModel.folders
        }
    }
    
    var body: some View {
        List {
            if subfolders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Carpeta vacía")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(Array(subfolders.enumerated()), id: \.element.id) { index, folder in
                    // Calculate path for this subfolder
                    let subfolderPath = currentFolder == nil ? [index] : currentPath + [index]
                    
                    NavigationLink(value: MoveCopyDestination(folder: folder, path: subfolderPath)) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            Text(folder.name)
                                .foregroundColor(.primary)
                        }
                    }
                    .disabled(isDisabled(folder: folder, path: subfolderPath))
                }
            }
        }
        .navigationTitle(isCopy ? "Copiar a..." : "Mover a...")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if currentFolder == nil {
                    Button("Cancelar") { onClose() }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isCopy ? "Copiar" : "Mover") {
                    validateAndPerformAction()
                }
                .disabled(isCurrentLocation())
            }
        }
        .navigationDestination(for: MoveCopyDestination.self) { destination in
            MoveCopyListView(
                viewModel: viewModel,
                currentFolder: destination.folder,
                currentPath: destination.path,
                sourcePath: sourcePath,
                folderToMove: folderToMove,
                isCopy: isCopy,
                onClose: onClose
            )
        }
        .alert("Acción no permitida", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Validation Logic
    
    private func isDisabled(folder: Folder, path: [Int]) -> Bool {
        // Prevent navigating into the folder being moved (circular reference)
        if folder.id == folderToMove.id {
            return true
        }
        
        // Prevent navigating into any subfolder of the folder being moved
        if isSubfolderOf(folder: folder, parent: folderToMove) {
            return true
        }
        
        return false
    }
    
    private func isSubfolderOf(folder: Folder, parent: Folder) -> Bool {
        for subfolder in parent.subfolders {
            if subfolder.id == folder.id {
                return true
            }
            if isSubfolderOf(folder: folder, parent: subfolder) {
                return true
            }
        }
        return false
    }
    
    private func isCurrentLocation() -> Bool {
        return currentPath == sourcePath
    }
    
    private func validateAndPerformAction() {
        print("🔍 Validating Move/Copy Action:")
        print("   - folderToMove: \(folderToMove.name)")
        print("   - currentPath: \(currentPath)")
        print("   - sourcePath: \(sourcePath)")
        print("   - isCopy: \(isCopy)")
        
        // Validation: Cannot move/copy to the same location
        if currentPath == sourcePath {
            errorMessage = "No puedes \(isCopy ? "copiar" : "mover") a la misma ubicación."
            showingErrorAlert = true
            print("❌ Validation Failed: Same Location")
            return
        }
        
        // Validation: Cannot move a folder into itself or its subfolders
        if !isCopy {
            if isPathInsideFolder(targetPath: currentPath, folderPath: sourcePath) {
                errorMessage = "No puedes mover una carpeta dentro de sí misma."
                showingErrorAlert = true
                print("❌ Validation Failed: Circular Reference")
                return
            }
        }
        
        // Perform the action
        performAction()
    }
    
    private func isPathInsideFolder(targetPath: [Int], folderPath: [Int]) -> Bool {
        // Check if targetPath starts with folderPath
        guard targetPath.count >= folderPath.count else { return false }
        return Array(targetPath.prefix(folderPath.count)) == folderPath
    }
    
    private func performAction() {
        print("✅ Performing \(isCopy ? "Copy" : "Move") Action")
        
        if isCopy {
            viewModel.copyFolder(id: folderToMove.id, to: currentPath)
        } else {
            viewModel.moveFolder(id: folderToMove.id, to: currentPath)
        }
        
        onClose()
    }
}

struct MoveCopyDestination: Hashable {
    let folder: Folder
    let path: [Int]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(folder.id)
        hasher.combine(path)
    }
    
    static func == (lhs: MoveCopyDestination, rhs: MoveCopyDestination) -> Bool {
        lhs.folder.id == rhs.folder.id && lhs.path == rhs.path
    }
}
