//
//  FavoritesSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

internal import SwiftUI

struct FavoritesSheet: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @Binding var isPresented: Bool
    var navigateToFullPath: ([Int]) -> Void
    @Binding var highlightedItemId: UUID?
    @Binding var currentPath: [Int]
    
    @State private var sortType: RandomitasViewModel.SortType = .nameAsc
    @State private var showingPathPopup: (name: String, path: String)? = nil
    
    private var validFavorites: [(ref: FolderReference, path: [Int], folder: Folder)] {
        viewModel.folderFavorites.compactMap { favRef in
            guard let path = viewModel.findPathById(favRef.id),
                  let folder = viewModel.getFolderFromPath(path),
                  folder.id == favRef.id else {
                return nil
            }
            return (ref: favRef, path: path, folder: folder)
        }
    }
    
    private var sortedFavorites: [(ref: FolderReference, path: [Int], folder: Folder)] {
        let sorted: [(ref: FolderReference, path: [Int], folder: Folder)]
        switch sortType {
        case .nameAsc:
            sorted = validFavorites.sorted { viewModel.sortName(for: $0.folder.name).localizedStandardCompare(viewModel.sortName(for: $1.folder.name)) == .orderedAscending }
        case .nameDesc:
            sorted = validFavorites.sorted { viewModel.sortName(for: $0.folder.name).localizedStandardCompare(viewModel.sortName(for: $1.folder.name)) == .orderedDescending }
        case .dateNewest:
            sorted = validFavorites.sorted { $0.folder.createdAt > $1.folder.createdAt }
        case .dateOldest:
            sorted = validFavorites.sorted { $0.folder.createdAt < $1.folder.createdAt }
        }
        
        return sorted
    }
    
    private var isAlphabeticalSort: Bool {
        sortType == .nameAsc || sortType == .nameDesc
    }
    
    private var groupedFavorites: [(letter: String, items: [(ref: FolderReference, path: [Int], folder: Folder)])] {
        var groups: [(String, [(ref: FolderReference, path: [Int], folder: Folder)])] = []
        var currentLetter = ""
        var currentGroup: [(ref: FolderReference, path: [Int], folder: Folder)] = []
        
        for fav in sortedFavorites {
            let normalized = viewModel.sortName(for: fav.folder.name)
            let first = normalized.first.map { $0.isLetter ? String($0).uppercased() : "#" } ?? "#"
            if first != currentLetter {
                if !currentGroup.isEmpty {
                    groups.append((currentLetter, currentGroup))
                }
                currentLetter = first
                currentGroup = [fav]
            } else {
                currentGroup.append(fav)
            }
        }
        if !currentGroup.isEmpty {
            groups.append((currentLetter, currentGroup))
        }
        return groups
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if sortedFavorites.isEmpty {
                    SheetEmptyStateView(
                        icon: "star.slash",
                        title: "Sin Favoritos",
                        subtitle: "Los elementos marcados como favoritos aparecerán aquí"
                    )
                } else {
                    List {
                        if isAlphabeticalSort {
                            ForEach(groupedFavorites, id: \.letter) { group in
                                Section {
                                    ForEach(group.items, id: \.ref.id) { fav in
                                        let pathString = viewModel.getReversedPathString(for: fav.path)
                                        let inheritedImage = viewModel.getInheritedImageData(for: fav.path)
                                        
                                        SheetRowView(
                                            name: fav.folder.name,
                                            imageData: inheritedImage,
                                            onTap: {
                                                highlightedItemId = fav.ref.id
                                                navigateToFullPath(fav.path)
                                                isPresented = false
                                            },
                                            onLongPress: {
                                                HapticManager.lightImpact()
                                                showingPathPopup = (name: fav.folder.name, path: pathString)
                                            }
                                        )
                                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                        .listRowBackground(Color(.systemBackground).opacity(0.7))
                                    }
                                    .onDelete { indices in
                                        let itemsInGroup = group.items
                                        let idsToRemove = indices.map { itemsInGroup[$0].ref.id }
                                        let realIndices = IndexSet(viewModel.folderFavorites.enumerated()
                                            .filter { idsToRemove.contains($0.element.id) }
                                            .map { $0.offset })
                                        viewModel.removeFolderFavorites(at: realIndices)
                                    }
                                } header: {
                                    Text(group.letter)
                                        .font(.title3.bold())
                                        .foregroundColor(.secondary)
                                        .textCase(nil)
                                }
                            }
                        } else {
                            Section(header: Text("")) {
                                ForEach(sortedFavorites, id: \.ref.id) { fav in
                                    let pathString = viewModel.getReversedPathString(for: fav.path)
                                    let inheritedImage = viewModel.getInheritedImageData(for: fav.path)
                                    
                                    SheetRowView(
                                        name: fav.folder.name,
                                        imageData: inheritedImage,
                                        onTap: {
                                            highlightedItemId = fav.ref.id
                                            navigateToFullPath(fav.path)
                                            isPresented = false
                                        },
                                        onLongPress: {
                                            HapticManager.lightImpact()
                                            showingPathPopup = (name: fav.folder.name, path: pathString)
                                        }
                                    )
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                    .listRowBackground(Color(.systemBackground).opacity(0.7))
                                }
                                .onDelete { indices in
                                    let currentSorted = sortedFavorites
                                    let idsToRemove = indices.map { currentSorted[$0].ref.id }
                                    let realIndices = IndexSet(viewModel.folderFavorites.enumerated()
                                        .filter { idsToRemove.contains($0.element.id) }
                                        .map { $0.offset })
                                    viewModel.removeFolderFavorites(at: realIndices)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 0)
                }
            }
            .navigationTitle("Favoritos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !sortedFavorites.isEmpty {
                        Menu {
                            Section("Nombre") {
                                Button(action: { sortType = .nameAsc }) {
                                    HStack {
                                        Text("A → Z")
                                        if sortType == .nameAsc {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                Button(action: { sortType = .nameDesc }) {
                                    HStack {
                                        Text("Z → A")
                                        if sortType == .nameDesc {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            Section("Fecha") {
                                Button(action: { sortType = .dateNewest }) {
                                    HStack {
                                        Text("Más reciente")
                                        if sortType == .dateNewest {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                Button(action: { sortType = .dateOldest }) {
                                    HStack {
                                        Text("Más antiguo")
                                        if sortType == .dateOldest {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        isPresented = false
                    }
                }
            }
            .alert(showingPathPopup?.name ?? "", isPresented: Binding(
                get: { showingPathPopup != nil },
                set: { if !$0 { showingPathPopup = nil } }
            )) {
                Button("OK", role: .cancel) {
                    showingPathPopup = nil
                }
            } message: {
                if let popup = showingPathPopup {
                    Text(verbatim: "< \(popup.path)")
                }
            }
        }
    }
}

// MARK: - Estado Vacío para Sheets

struct SheetEmptyStateView: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Fila Reutilizable con Fondo de Desenfoque Gradual

struct SheetRowView: View {
    let name: String
    let imageData: Data?
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    GeometryReader { geometry in
                        ZStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .blur(radius: 15)
                                .clipped()
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                                .mask(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .clear, location: 0.0),
                                            .init(color: .clear, location: 0.5),
                                            .init(color: .white, location: 0.8),
                                            .init(color: .white, location: 1.0)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: (colorScheme == .dark ? Color.black : Color.white).opacity(0.7), location: 0.0),
                                    .init(color: (colorScheme == .dark ? Color.black : Color.white).opacity(0.5), location: 0.35),
                                    .init(color: (colorScheme == .dark ? Color.black : Color.white).opacity(0.2), location: 0.5),
                                    .init(color: .clear, location: 0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                }
                
                HStack {
                    Text(name)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.leading, 16)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(imageData != nil ? .white : .gray)
                        .shadow(color: imageData != nil ? .black.opacity(0.8) : .clear, radius: 3)
                        .padding(.trailing, 16)
                }
            }
            .frame(height: 65)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .onLongPressGesture(minimumDuration: 0.3) {
                onLongPress()
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
    }
}
