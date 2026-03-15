//
//  FolderDetailContentView.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

internal import SwiftUI

struct FolderDetailContentView: View {
    @ObservedObject var viewModel: RandomitasViewModel
    let folderPath: [Int]
    let sortedSubfolders: [Folder]
    let sortType: RandomitasViewModel.SortType
    let viewType: RandomitasViewModel.ViewType
    let isInHiddenContext: Bool
    @Binding var showingHiddenAncestorAlert: Bool
    @Binding var hiddenAncestorAlertName: String
    @Binding var showHiddenFavoriteAlert: Bool
    @Binding var editingElement: EditingInfo?
    @Binding var imagePickerRequest: ImagePickerRequest?
    @Binding var moveCopyOperation: MoveCopyOperation?
    @Binding var isSelectionMode: Bool
    @Binding var selectedItemIds: Set<UUID>
    @Binding var navigationPath: NavigationPath
    let onOpenSearch: () -> Void
    var highlightedItemId: UUID?

    var body: some View {
        switch viewType {
        case .list:
            FolderDetailListView(
                viewModel: viewModel,
                folderPath: folderPath,
                sortedSubfolders: sortedSubfolders,
                sortType: sortType,
                isInHiddenContext: isInHiddenContext,
                showingHiddenAncestorAlert: $showingHiddenAncestorAlert,
                hiddenAncestorAlertName: $hiddenAncestorAlertName,
                showHiddenFavoriteAlert: $showHiddenFavoriteAlert,
                editingElement: $editingElement,
                imagePickerRequest: $imagePickerRequest,
                moveCopyOperation: $moveCopyOperation,
                isSelectionMode: $isSelectionMode,
                navigationPath: $navigationPath,
                selectedItemIds: $selectedItemIds,
                onOpenSearch: onOpenSearch,
                highlightedItemId: highlightedItemId
            )
        case .grid:
            FolderDetailGridView(
                viewModel: viewModel,
                folderPath: folderPath,
                sortedSubfolders: sortedSubfolders,
                sortType: sortType,
                isInHiddenContext: isInHiddenContext,
                showingHiddenAncestorAlert: $showingHiddenAncestorAlert,
                hiddenAncestorAlertName: $hiddenAncestorAlertName,
                showHiddenFavoriteAlert: $showHiddenFavoriteAlert,
                editingElement: $editingElement,
                imagePickerRequest: $imagePickerRequest,
                moveCopyOperation: $moveCopyOperation,
                isSelectionMode: $isSelectionMode,
                navigationPath: $navigationPath,
                selectedItemIds: $selectedItemIds,
                onOpenSearch: onOpenSearch,
                highlightedItemId: highlightedItemId
            )
        case .gallery:
            FolderDetailGalleryView(
                viewModel: viewModel,
                folderPath: folderPath,
                sortedSubfolders: sortedSubfolders,
                sortType: sortType,
                isInHiddenContext: isInHiddenContext,
                showingHiddenAncestorAlert: $showingHiddenAncestorAlert,
                hiddenAncestorAlertName: $hiddenAncestorAlertName,
                showHiddenFavoriteAlert: $showHiddenFavoriteAlert,
                editingElement: $editingElement,
                imagePickerRequest: $imagePickerRequest,
                moveCopyOperation: $moveCopyOperation,
                isSelectionMode: $isSelectionMode,
                navigationPath: $navigationPath,
                selectedItemIds: $selectedItemIds,
                onOpenSearch: onOpenSearch,
                highlightedItemId: highlightedItemId
            )
        }
    }

}
