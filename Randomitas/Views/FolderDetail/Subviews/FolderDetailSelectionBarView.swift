//
//  FolderDetailSelectionBarView.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

internal import SwiftUI

struct FolderDetailSelectionBarView: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @ObservedObject var uiState: FolderDetailViewState
    let sortedSubfolders: [Folder]
    let folderPath: [Int]
    let isInHiddenContext: Bool
    let liveFolder: Folder

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if !uiState.selectedItemIds.isEmpty {
                Text("\(uiState.selectedItemIds.count) seleccionado\(uiState.selectedItemIds.count > 1 ? "s" : "")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }

            HStack(spacing: 12) {
                Button(action: {
                    HapticManager.mediumImpact()
                    let selectedFolders = sortedSubfolders.filter { uiState.selectedItemIds.contains($0.id) }
                    guard !selectedFolders.isEmpty else { return }
                    uiState.moveCopyOperation = MoveCopyOperation(items: selectedFolders, sourceContainerPath: folderPath, isCopy: false)
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.turn.up.right")
                            .font(.system(size: 22, weight: .medium))
                        Text("Mover")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(uiState.selectedItemIds.isEmpty ? Color(.systemGray5) : Color.blue.opacity(0.12))
                    .foregroundColor(uiState.selectedItemIds.isEmpty ? .gray : .blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(uiState.selectedItemIds.isEmpty)
                .accessibilityIdentifier("selectionMoveButton")

                Button(action: {
                    HapticManager.mediumImpact()
                    let selectedFolders = sortedSubfolders.filter { uiState.selectedItemIds.contains($0.id) }
                    guard !selectedFolders.isEmpty else { return }
                    uiState.moveCopyOperation = MoveCopyOperation(items: selectedFolders, sourceContainerPath: folderPath, isCopy: true)
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 22, weight: .medium))
                        Text("Copiar")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(uiState.selectedItemIds.isEmpty ? Color(.systemGray5) : Color.blue.opacity(0.12))
                    .foregroundColor(uiState.selectedItemIds.isEmpty ? .gray : .blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(uiState.selectedItemIds.isEmpty)
                .accessibilityIdentifier("selectionCopyButton")

                Button(action: {
                    HapticManager.mediumImpact()
                    guard !uiState.selectedItemIds.isEmpty else { return }

                    if isInHiddenContext {
                        if let ancestorName = viewModel.getHiddenAncestorName(at: folderPath) ?? (liveFolder.isHidden ? liveFolder.name : nil) {
                            uiState.hiddenAncestorAlertName = ancestorName
                            uiState.showingHiddenAncestorAlert = true
                        }
                        return
                    }

                    if folderPath.isEmpty {
                        viewModel.batchToggleHiddenRoot(ids: uiState.selectedItemIds)
                    } else {
                        viewModel.batchToggleHiddenSubfolders(ids: uiState.selectedItemIds, at: folderPath)
                    }

                    uiState.isSelectionMode = false
                    uiState.selectedItemIds.removeAll()
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: (uiState.showingHiddenElements || isInHiddenContext) ? "eye" : "eye.slash")
                            .font(.system(size: 22, weight: .medium))
                        Text((uiState.showingHiddenElements || isInHiddenContext) ? "Mostrar" : "Ocultar")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(uiState.selectedItemIds.isEmpty ? Color(.systemGray5) : Color.orange.opacity(0.12))
                    .foregroundColor(uiState.selectedItemIds.isEmpty ? .gray : .orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(uiState.selectedItemIds.isEmpty)
                .accessibilityIdentifier("selectionHideButton")

                Button(action: {
                    HapticManager.warning()
                    uiState.showingMultiDeleteConfirmation = true
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 22, weight: .medium))
                        Text("Eliminar")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(uiState.selectedItemIds.isEmpty ? Color(.systemGray5) : Color.red.opacity(0.12))
                    .foregroundColor(uiState.selectedItemIds.isEmpty ? .gray : .red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(uiState.selectedItemIds.isEmpty)
                .accessibilityIdentifier("selectionDeleteButton")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: -4)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: -1)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(2)
    }
}
