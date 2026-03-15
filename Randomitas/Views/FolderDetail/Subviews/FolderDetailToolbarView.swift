//
//  FolderDetailToolbarView.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

internal import SwiftUI

struct FolderDetailToolbarView: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @ObservedObject var uiState: FolderDetailViewState
    let folderPath: [Int]
    let liveFolder: Folder

    var body: some View {
        let isOnboarding = folderPath.isEmpty && liveFolder.subfolders.isEmpty

        HStack(spacing: 25) {
            if isOnboarding {
                Button(action: { uiState.showFirstElementAlert = true }) {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
            } else {
                SortMenuView(sortType: $uiState.currentSortType)
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .onChange(of: uiState.currentSortType) { viewModel.setSortType($0, for: folderPath.isEmpty ? nil : liveFolder.id) }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }

            if isOnboarding {
                Button(action: { uiState.showFirstElementAlert = true }) {
                    Image(systemName: "rectangle.grid.1x2")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
            } else {
                Menu {
                    Picker("Vista", selection: $uiState.currentViewType) {
                        Text("Lista").tag(RandomitasViewModel.ViewType.list)
                        Text("Cuadrícula").tag(RandomitasViewModel.ViewType.grid)
                        Text("Galería").tag(RandomitasViewModel.ViewType.gallery)
                    }
                    .onChange(of: uiState.currentViewType) { newValue in
                        viewModel.setViewType(newValue, for: folderPath.isEmpty ? nil : liveFolder.id)
                    }
                } label: {
                    Image(systemName: "rectangle.grid.1x2")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
            }

            Button(action: {
                if isOnboarding {
                    uiState.showFirstElementAlert = true
                } else {
                    HapticManager.lightImpact()
                    uiState.showingHistory = true
                }
            }) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }

            if !uiState.showingHiddenElements && !uiState.isSelectionMode {
                Button {
                    if !uiState.longPressDetected {
                        HapticManager.lightImpact()
                        uiState.isBatchAddMode = false
                        uiState.showingNewFolderSheet = true
                    }
                    uiState.longPressDetected = false
                    uiState.isPressedPlusButton = false
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                        .scaleEffect(uiState.isPressedPlusButton ? 0.85 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: uiState.isPressedPlusButton)
                }
                .accessibilityIdentifier("addElementButton")
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !uiState.isPressedPlusButton {
                                uiState.isPressedPlusButton = true
                            }
                        }
                        .onEnded { _ in
                            uiState.isPressedPlusButton = false
                        }
                )
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.4)
                        .onEnded { _ in
                            uiState.longPressDetected = true
                            uiState.isPressedPlusButton = false
                            uiState.isBatchAddMode = true
                            HapticManager.mediumImpact()
                            uiState.showingNewFolderSheet = true
                        }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .zIndex(1)
        .id(uiState.toolbarReady)
    }
}
