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
    
    let foldersToMove: [Folder]
    let sourceContainerPath: [Int]
    let isCopy: Bool
    var onSuccess: (() -> Void)? = nil
    
    // State for Tree View
    @State private var expandedFolderIds: Set<UUID> = []
    @State private var isRootExpanded: Bool = true
    @State private var selectedTargetFolder: Folder? = nil
    @State private var isRootSelected: Bool = false
    
    // Alerts
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingReplaceAlert = false
    
    // New Element Sheet
    @State private var showingNewFolderSheet = false
    @State private var conflictingFolders: [Folder] = []
    
    // MEMORIA TEMPORAL: Solo recuerda si fue hace menos de 2 minutos
    @AppStorage("lastMoveCopyTargetPath") private var lastTargetPathString: String = ""
    @AppStorage("lastMoveCopyWasRoot") private var lastWasRoot: Bool = false
    @AppStorage("lastMoveCopyTimestamp") private var lastTimestamp: Double = 0
    
    private let memoryDuration: TimeInterval = 120 // 2 minutos
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header informativo
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: isCopy ? "doc.on.doc.fill" : "arrow.turn.up.right")
                            .font(.system(size: 28))
                            .foregroundColor(isCopy ? .green : .blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(foldersToMove.count) elemento\(foldersToMove.count > 1 ? "s" : "")")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Selecciona el destino")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                }
                
                Divider()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        // Root Node as part of tree
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                // Chevron for Root
                                Image(systemName: "chevron.right")
                                    .rotationEffect(isRootExpanded ? .degrees(90) : .zero)
                                    .foregroundColor(.gray)
                                    .onTapGesture {
                                        withAnimation {
                                            isRootExpanded.toggle()
                                        }
                                    }
                                    .frame(width: 30, height: 30)
                                    .contentShape(Rectangle())
                                
                                // Root Icon & Name
                                Button(action: {
                                    selectRoot()
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "house.fill")
                                            .font(.title3)
                                            .foregroundColor(.orange)
                                        Text("Randomitas")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if isRootSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isRootSelected ? Color.blue.opacity(0.1) : Color.clear)
                            )
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                            
                            // Children of Root
                            if isRootExpanded {
                                LazyVStack(alignment: .leading, spacing: 0) {
                                    ForEach(viewModel.folders) { folder in
                                        FolderTreeNode(
                                            folder: folder,
                                            level: 1,
                                            expandedIds: $expandedFolderIds,
                                            selectedFolder: $selectedTargetFolder,
                                            isRootSelected: $isRootSelected,
                                            foldersToMove: foldersToMove,
                                            fullPath: [viewModel.folders.firstIndex(where: { $0.id == folder.id }) ?? 0]
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }
                
                // Action Bar - Refinada
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 0) {
                        // Cancelar (izquierda)
                        Button(action: { isPresented = false }) {
                            Text("Cancelar")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        
                        // Divider vertical
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(width: 1)
                            .padding(.vertical, 8)
                        
                        // + (centro)
                        Button(action: { showingNewFolderSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(isRootSelected || selectedTargetFolder != nil ? .blue : Color(.systemGray3))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .disabled(!isRootSelected && selectedTargetFolder == nil)
                        
                        // Divider vertical
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(width: 1)
                            .padding(.vertical, 8)
                        
                        // Acción (derecha)
                        Button(action: validateAndPerformAction) {
                            Text(isCopy ? "Copiar" : "Mover")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isActionDisabled ? Color(.systemGray3) : (isCopy ? .green : .blue))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .disabled(isActionDisabled)
                    }
                    .frame(height: 50)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle(isCopy ? "Copiar a..." : "Mover a...")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 🆕 Decidir si cargar memoria o empezar en Root
                if isRecentSession() {
                    loadLastTargetLocation()
                } else {
                    // Si pasó mucho tiempo, limpiar y empezar en Root
                    clearMemory()
                    expandCurrentPath()
                }
            }
            .alert("Acción no permitida", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("¿Reemplazar elementos existentes?", isPresented: $showingReplaceAlert) {
                Button("Cancelar", role: .cancel) {
                    conflictingFolders = []
                }
                Button("Reemplazar", role: .destructive) {
                    replaceAndPerformAction()
                }
            } message: {
                if conflictingFolders.count == 1 {
                    Text("Ya existe un Elemento llamado \"\(conflictingFolders.first?.name ?? "")\". ¿Quieres reemplazarlo?")
                } else {
                    Text("Ya existen \(conflictingFolders.count) Elementos con los mismos nombres. ¿Quieres reemplazarlos?")
                }
            }
            .sheet(isPresented: $showingNewFolderSheet) {
                NewFolderSheet(
                    viewModel: viewModel,
                    folderPath: calculateNewFolderPath(),
                    isPresented: $showingNewFolderSheet
                )
            }
        }
    }
    
    private var isActionDisabled: Bool {
        if selectedTargetFolder == nil && !isRootSelected { return true }
        
        if let targetId = selectedTargetFolder?.id {
            if foldersToMove.contains(where: { $0.id == targetId }) {
                return true
            }
        }
        return false
    }
    
    // MARK: - Logic
    
    private func selectRoot() {
        HapticManager.selection()
        if isRootSelected {
            isRootSelected = false
        } else {
            selectedTargetFolder = nil
            isRootSelected = true
        }
    }
    
    // 🆕 VERIFICAR SI ES UNA SESIÓN RECIENTE (< 2 minutos)
    private func isRecentSession() -> Bool {
        let now = Date().timeIntervalSince1970
        let elapsed = now - lastTimestamp
        return elapsed < memoryDuration && lastTimestamp > 0
    }
    
    // 🆕 LIMPIAR MEMORIA
    private func clearMemory() {
        lastTargetPathString = ""
        lastWasRoot = false
        lastTimestamp = 0
    }
    
    // 🆕 CARGAR ÚLTIMA UBICACIÓN GUARDADA
    private func loadLastTargetLocation() {
        if lastWasRoot {
            selectRoot()
            return
        }
        
        if !lastTargetPathString.isEmpty {
            let pathComponents = lastTargetPathString.split(separator: ",").compactMap { Int($0) }
            if let folder = viewModel.getFolderFromPath(pathComponents) {
                selectedTargetFolder = folder
                isRootSelected = false
                
                // Expandir el path hacia esa carpeta
                var tempIds: Set<UUID> = []
                var currentLevelFolders = viewModel.folders
                
                for pathIndex in pathComponents {
                    if pathIndex < currentLevelFolders.count {
                        let folder = currentLevelFolders[pathIndex]
                        tempIds.insert(folder.id)
                        currentLevelFolders = folder.subfolders
                    }
                }
                expandedFolderIds = tempIds
            } else {
                // Si la carpeta ya no existe, empezar en Root
                expandCurrentPath()
            }
        }
    }
    
    // 🆕 GUARDAR UBICACIÓN Y TIMESTAMP
    private func saveLastTargetLocation(targetPath: [Int]) {
        if isRootSelected {
            lastWasRoot = true
            lastTargetPathString = ""
        } else {
            lastWasRoot = false
            lastTargetPathString = targetPath.map { String($0) }.joined(separator: ",")
        }
        lastTimestamp = Date().timeIntervalSince1970
    }
    
    private func expandCurrentPath() {
        if sourceContainerPath.isEmpty {
            selectRoot()
        } else {
            if let currentFolder = viewModel.getFolderFromPath(sourceContainerPath) {
                selectedTargetFolder = currentFolder
                isRootSelected = false
            } else {
                selectRoot()
            }
        }
        
        var tempIds: Set<UUID> = []
        var currentLevelFolders = viewModel.folders
        
        for (index, pathIndex) in sourceContainerPath.enumerated() {
            if pathIndex < currentLevelFolders.count {
                let folder = currentLevelFolders[pathIndex]
                tempIds.insert(folder.id)
                currentLevelFolders = folder.subfolders
            } else {
                break
            }
        }
        
        expandedFolderIds = tempIds.union(expandedFolderIds)
    }
    
    private func validateAndPerformAction() {
        let targetPath = calculatePath(for: selectedTargetFolder)
        
        // Check 1: Same location
        if targetPath == sourceContainerPath {
             errorMessage = "No puedes \(isCopy ? "copiar" : "mover") a la misma ubicación."
             showingErrorAlert = true
             return
        }
        
        // Check 2: Moving into itself (Circular)
        if !isCopy {
             if let selectedId = selectedTargetFolder?.id {
                 if foldersToMove.contains(where: { $0.id == selectedId || isSubfolderOf(folder: selectedTargetFolder!, parent: $0) }) {
                     errorMessage = "No puedes mover un Elemento dentro de sí mismo."
                     showingErrorAlert = true
                     return
                 }
             }
        }
        
        checkForConflictsAndPerform(targetPath: targetPath)
    }
    
    private func calculatePath(for folder: Folder?) -> [Int] {
        guard let folder = folder else { return [] }
        return findPath(for: folder.id, in: viewModel.folders) ?? []
    }
    
    // Calcula el path para NewFolderSheet
    // Retorna nil si debe crear en root, o el path completo si es subcarpeta
    private func calculateNewFolderPath() -> [Int]? {
        // Si root está seleccionado, crear en nivel raíz
        if isRootSelected {
            return nil
        }
        
        // Si hay una carpeta seleccionada, calcular su path
        guard let folder = selectedTargetFolder else {
            return nil
        }
        
        // Buscar el path de la carpeta seleccionada
        if let path = findPath(for: folder.id, in: viewModel.folders), !path.isEmpty {
            return path
        }
        
        // Si no se encuentra el path, crear en root como fallback
        return nil
    }
    
    private func findPath(for id: UUID, in folders: [Folder]) -> [Int]? {
        for (index, folder) in folders.enumerated() {
            if folder.id == id {
                return [index]
            }
            if let subPath = findPath(for: id, in: folder.subfolders) {
                return [index] + subPath
            }
        }
        return nil
    }
    
    private func isSubfolderOf(folder: Folder, parent: Folder) -> Bool {
        for sub in parent.subfolders {
            if sub.id == folder.id { return true }
            if isSubfolderOf(folder: folder, parent: sub) { return true }
        }
        return false
    }
    
    private func checkForConflictsAndPerform(targetPath: [Int]) {
        let destinationSubfolders: [Folder]
        if let targetFolder = selectedTargetFolder {
            destinationSubfolders = targetFolder.subfolders
        } else {
            destinationSubfolders = viewModel.folders
        }
        
        conflictingFolders = destinationSubfolders.filter { dest in
            foldersToMove.contains { $0.name == dest.name }
        }
        
        if !conflictingFolders.isEmpty {
             showingReplaceAlert = true
             return
        }
        
        performAction(targetPath: targetPath)
    }
    
    private func replaceAndPerformAction() {
        let targetPath = calculatePath(for: selectedTargetFolder)
        
        for conflict in conflictingFolders {
            if selectedTargetFolder == nil {
                viewModel.deleteRootFolder(id: conflict.id)
            } else {
                viewModel.deleteSubfolder(id: conflict.id, from: targetPath)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            performAction(targetPath: targetPath)
        }
    }
    
    private func performAction(targetPath: [Int]) {
        // 🆕 GUARDAR ubicación y timestamp
        saveLastTargetLocation(targetPath: targetPath)
        
        // Usar el ID del destino en vez del path para evitar problemas con índices que cambian
        let targetFolderId: UUID? = isRootSelected ? nil : selectedTargetFolder?.id
        
        for folder in foldersToMove {
            if isCopy {
                viewModel.copyFolderById(id: folder.id, toFolderId: targetFolderId)
            } else {
                viewModel.moveFolderById(id: folder.id, toFolderId: targetFolderId)
            }
        }
        HapticManager.success()
        onSuccess?()
        isPresented = false
    }
}

struct FolderTreeNode: View {
    let folder: Folder
    let level: Int
    @Binding var expandedIds: Set<UUID>
    @Binding var selectedFolder: Folder?
    @Binding var isRootSelected: Bool
    let foldersToMove: [Folder]
    let fullPath: [Int]
    
    private var isExpanded: Binding<Bool> {
        Binding(
            get: { expandedIds.contains(folder.id) },
            set: { isExpanded in
                if isExpanded { expandedIds.insert(folder.id) }
                else { expandedIds.remove(folder.id) }
            }
        )
    }
    
    private var isSelected: Bool {
        selectedFolder?.id == folder.id
    }
    
    private var isDisabled: Bool {
        foldersToMove.contains(where: { $0.id == folder.id })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                ForEach(0..<level, id: \.self) { _ in
                    Spacer().frame(width: 24)
                }
                
                if !folder.subfolders.isEmpty {
                    Image(systemName: "chevron.right")
                        .rotationEffect(isExpanded.wrappedValue ? .degrees(90) : .zero)
                        .foregroundColor(.gray)
                        .onTapGesture {
                            withAnimation {
                                isExpanded.wrappedValue.toggle()
                            }
                        }
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                } else {
                     Spacer().frame(width: 30)
                }
                
                Button(action: {
                    selectThis()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "atom")
                            .font(.body)
                            .foregroundColor(isDisabled ? .gray : .blue)
                        Text(folder.name)
                            .font(.body)
                            .foregroundColor(isDisabled ? .gray : .primary)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .disabled(isDisabled)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            
            if isExpanded.wrappedValue {
                ForEach(Array(folder.subfolders.enumerated()), id: \.element.id) { index, subfolder in
                    FolderTreeNode(
                        folder: subfolder,
                        level: level + 1,
                        expandedIds: $expandedIds,
                        selectedFolder: $selectedFolder,
                        isRootSelected: $isRootSelected,
                        foldersToMove: foldersToMove,
                        fullPath: fullPath + [index]
                    )
                }
            }
        }
    }
    
    private func selectThis() {
        if !isDisabled {
            HapticManager.selection()
            if selectedFolder?.id == folder.id {
                selectedFolder = nil
            } else {
                selectedFolder = folder
                isRootSelected = false
            }
        }
    }
}
