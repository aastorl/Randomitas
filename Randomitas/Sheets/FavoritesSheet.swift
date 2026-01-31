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
    
    private var validFavorites: [(FolderReference, [Int])] {
        viewModel.folderFavorites.filter { fav in
            if let folder = viewModel.getFolderFromPath(fav.1) {
                return folder.id == fav.0.id
            }
            return false
        }
    }
    
    private var sortedFavorites: [(FolderReference, [Int])] {
        let folders = validFavorites.compactMap { fav -> (FolderReference, [Int], Folder)? in
            guard let folder = viewModel.getFolderFromPath(fav.1) else { return nil }
            return (fav.0, fav.1, folder)
        }
        
        let sorted: [(FolderReference, [Int], Folder)]
        switch sortType {
        case .nameAsc:
            sorted = folders.sorted { $0.0.name.localizedCaseInsensitiveCompare($1.0.name) == .orderedAscending }
        case .nameDesc:
            sorted = folders.sorted { $0.0.name.localizedCaseInsensitiveCompare($1.0.name) == .orderedDescending }
        case .dateNewest:
            sorted = folders.sorted { ($0.2.createdAt ?? Date.distantPast) > ($1.2.createdAt ?? Date.distantPast) }
        case .dateOldest:
            sorted = folders.sorted { ($0.2.createdAt ?? Date.distantPast) < ($1.2.createdAt ?? Date.distantPast) }
        }
        
        return sorted.map { ($0.0, $0.1) }
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
                        Section(header: Text("")) {
                            ForEach(sortedFavorites, id: \.0.id) { fav in
                                let pathString = viewModel.getReversedPathString(for: fav.1)
                                let inheritedImage = viewModel.getInheritedImageData(for: fav.1)
                                
                                SheetRowView(
                                    name: fav.0.name,
                                    imageData: inheritedImage,
                                    onTap: {
                                        highlightedItemId = fav.0.id
                                        navigateToFullPath(fav.1)
                                        isPresented = false
                                    },
                                    onLongPress: {
                                        HapticManager.lightImpact()
                                        showingPathPopup = (name: fav.0.name, path: pathString)
                                    }
                                )
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowBackground(Color(.systemBackground).opacity(0.7))
                            }
                            .onDelete { indices in
                                let currentSorted = sortedFavorites
                                let idsToRemove = indices.map { currentSorted[$0].0.id }
                                let realIndices = IndexSet(viewModel.folderFavorites.enumerated()
                                    .filter { idsToRemove.contains($0.element.0.id) }
                                    .map { $0.offset })
                                viewModel.removeFolderFavorites(at: realIndices)
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
                    Text("< \(popup.path)")
                }
            }
        }
    }
}

// MARK: - Empty State View for Sheets

struct SheetEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
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

// MARK: - Reusable Row View with Gradient Blur Background

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
            .onLongPressGesture(minimumDuration: 0.5) {
                onLongPress()
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
    }
}
