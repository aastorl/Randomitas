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
    let isPadLandscape: Bool

    var body: some View {
        Group {
            if isPadLandscape {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        if !uiState.selectedItemIds.isEmpty {
                            Text("^[\(uiState.selectedItemIds.count) seleccionado](inflect: true)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        VStack(spacing: 10) {
                            selectionMoveButton
                            selectionCopyButton
                            selectionHideButton
                            selectionDeleteButton
                        }
                    }
                    .padding(14)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 20)
                .padding(.top, 24)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                VStack(spacing: 0) {
                    Spacer()
                    if !uiState.selectedItemIds.isEmpty {
                        Text("^[\(uiState.selectedItemIds.count) seleccionado](inflect: true)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                    HStack(spacing: 12) {
                        selectionMoveButton
                        selectionCopyButton
                        selectionHideButton
                        selectionDeleteButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                    .background(.thinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: -4)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: -1)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .zIndex(2)
    }

    private var selectionMoveButton: some View {
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
            .frame(width: isPadLandscape ? 140 : nil, height: 60)
            .frame(maxWidth: isPadLandscape ? nil : .infinity)
            .background(uiState.selectedItemIds.isEmpty ? Color(.systemGray5) : Color.blue.opacity(0.12))
            .foregroundColor(uiState.selectedItemIds.isEmpty ? .gray : .blue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(uiState.selectedItemIds.isEmpty)
        .accessibilityIdentifier("selectionMoveButton")
    }

    private var selectionCopyButton: some View {
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
            .frame(width: isPadLandscape ? 140 : nil, height: 60)
            .frame(maxWidth: isPadLandscape ? nil : .infinity)
            .background(uiState.selectedItemIds.isEmpty ? Color(.systemGray5) : Color.blue.opacity(0.12))
            .foregroundColor(uiState.selectedItemIds.isEmpty ? .gray : .blue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(uiState.selectedItemIds.isEmpty)
        .accessibilityIdentifier("selectionCopyButton")
    }

    private var selectionHideButton: some View {
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
            .frame(width: isPadLandscape ? 140 : nil, height: 60)
            .frame(maxWidth: isPadLandscape ? nil : .infinity)
            .background(uiState.selectedItemIds.isEmpty ? Color(.systemGray5) : ((uiState.showingHiddenElements || isInHiddenContext) ? Color.green.opacity(0.12) : Color.orange.opacity(0.12)))
            .foregroundColor(uiState.selectedItemIds.isEmpty ? .gray : ((uiState.showingHiddenElements || isInHiddenContext) ? .green : .orange))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(uiState.selectedItemIds.isEmpty)
        .accessibilityIdentifier("selectionHideButton")
    }

    private var selectionDeleteButton: some View {
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
            .frame(width: isPadLandscape ? 140 : nil, height: 60)
            .frame(maxWidth: isPadLandscape ? nil : .infinity)
            .background(uiState.selectedItemIds.isEmpty ? Color(.systemGray5) : Color.red.opacity(0.12))
            .foregroundColor(uiState.selectedItemIds.isEmpty ? .gray : .red)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(uiState.selectedItemIds.isEmpty)
        .accessibilityIdentifier("selectionDeleteButton")
    }
}
