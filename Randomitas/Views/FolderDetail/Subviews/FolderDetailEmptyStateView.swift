//
//  FolderDetailEmptyStateView.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

internal import SwiftUI

struct FolderDetailEmptyStateView: View {
    @ObservedObject var uiState: FolderDetailViewState
    let folderPath: [Int]
    let liveFolder: Folder
    let isInHiddenContext: Bool

    var body: some View {
        if folderPath.isEmpty && !uiState.showingHiddenElements && liveFolder.subfolders.isEmpty {
            WelcomeOnboardingView(mode: .onboarding, onCreateFirstElement: {
                HapticManager.lightImpact()
                uiState.isBatchAddMode = false
                uiState.showingNewFolderSheet = true
            })
        } else if folderPath.isEmpty && !uiState.showingHiddenElements && !liveFolder.subfolders.isEmpty {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "eye.slash")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                VStack(spacing: 8) {
                    Text("Todos los elementos están ocultos")
                        .font(.headline)
                    Text("Accede a los elementos ocultos desde el menú ⋯")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
        } else {
            VStack(spacing: 20) {
                Spacer()

                if isInHiddenContext && !uiState.showingHiddenElements {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    VStack(spacing: 8) {
                        Text("Elemento Oculto")
                            .font(.headline)
                        Text("Los elementos creados aquí no aparecerán al randomizar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Button {
                        if !uiState.longPressDetected {
                            HapticManager.lightImpact()
                            uiState.isBatchAddMode = false
                            uiState.showingNewFolderSheet = true
                        }
                        uiState.longPressDetected = false
                        uiState.isPressedPlusButton = false
                    } label: {
                        VStack {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        .frame(width: 100, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .appGlassEffect()
                        .scaleEffect(uiState.isPressedPlusButton ? 0.9 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: uiState.isPressedPlusButton)
                    }
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
                } else if uiState.showingHiddenElements {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    VStack(spacing: 8) {
                        Text("Sin Elementos Ocultos")
                            .font(.headline)
                        Text("Los elementos ocultos aparecerán aquí")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                } else {
                    Image(systemName: "atom")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    VStack(spacing: 8) {
                        Text("Sin Elementos guardados")
                            .font(.headline)
                        Text("Crea uno nuevo")
                            .font(.subheadline)
                    }

                    Button {
                        if !uiState.longPressDetected {
                            HapticManager.lightImpact()
                            uiState.isBatchAddMode = false
                            uiState.showingNewFolderSheet = true
                        }
                        uiState.longPressDetected = false
                        uiState.isPressedPlusButton = false
                    } label: {
                        VStack {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        .frame(width: 100, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .appGlassEffect()
                        .scaleEffect(uiState.isPressedPlusButton ? 0.9 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: uiState.isPressedPlusButton)
                    }
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

                Spacer()
            }
        }
    }
}
