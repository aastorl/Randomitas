//
//  FolderDetailViewState.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation
internal import Combine

final class FolderDetailViewState: ObservableObject {
    @Published var showingNewFolderSheet = false
    @Published var isBatchAddMode = false
    @Published var showingRenameSheet = false
    @Published var renameTarget: (id: UUID, name: String, type: String)? = nil
    @Published var currentViewType: RandomitasViewModel.ViewType = .list
    @Published var currentSortType: RandomitasViewModel.SortType = .nameAsc
    @Published var imagePickerRequest: ImagePickerRequest? = nil
    @Published var showingFavorites = false
    @Published var showingHistory = false
    @Published var showingHiddenFolders = false
    @Published var showingHiddenElements = false
    @Published var moveCopyOperation: MoveCopyOperation? = nil
    @Published var showingHiddenAncestorAlert = false
    @Published var hiddenAncestorAlertName = ""

    @Published var isSelectionMode = false
    @Published var selectedItemIds = Set<UUID>()
    @Published var showingMultiDeleteConfirmation = false

    @Published var pickerID = UUID()
    @Published var showLabel = false
    @Published var longPressDetected = false
    @Published var isPressedPlusButton = false
    @Published var toolbarReady = false

    @Published var editingElement: EditingInfo? = nil

    @Published var isSearching = false
    @Published var searchText = ""

    @Published var selectedFolderResult: (folder: Folder, path: [Int])? = nil
    @Published var showingFolderResult = false
    @Published var navigationHighlightedItemId: UUID? = nil
    @Published var showFirstElementAlert = false
    @Published var showingHiddenRandomizeAlert = false
    @Published var showingEmptyRandomizeAlert = false
    @Published var showingInfo = false

    @Published var showHiddenFavoriteAlert = false

    @Published var errorMessage: String? = nil
    @Published var showingErrorAlert = false
}
