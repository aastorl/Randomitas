//
//  FolderDetailBottomBarView.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

internal import SwiftUI

struct FolderDetailBottomBarView: View {
    @ObservedObject var uiState: FolderDetailViewState
    let isInHiddenContext: Bool
    let randomizeAction: () -> Void
    var isSearchFocused: FocusState<Bool>.Binding
    let isPadLandscape: Bool

    var body: some View {
        VStack {
            Spacer()
            if uiState.isSearching {
                searchBar
                    .padding(.leading, isPadLandscape ? 88 : 0)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                bottomActionBar
                    .padding(.leading, isPadLandscape ? 88 : 0)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Buscar Elementos", text: $uiState.searchText)
                    .focused(isSearchFocused)
                    .submitLabel(.search)

                if !uiState.searchText.isEmpty {
                    Button(action: { uiState.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)

            Button("Cancelar") {
                withAnimation(.spring()) {
                    uiState.isSearching = false
                    uiState.searchText = ""
                    isSearchFocused.wrappedValue = false
                }
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
    }

    private var bottomActionBar: some View {
        ZStack {
            HStack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)

                Spacer()

                Capsule()
                    .fill(Color.clear)
                    .frame(width: 110, height: 56)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)

                Spacer()

                Circle()
                    .fill(Color.clear)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .allowsHitTesting(false)

            HStack {
                hiddenButton
                Spacer()
                randomizeButton
                Spacer()
                favoritesButton
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 0)
        .padding(.top, 20)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.05), location: 0.3),
                    .init(color: .black.opacity(0.15), location: 0.6),
                    .init(color: .black.opacity(0.35), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .padding(.top, -40)
            .padding(.bottom, -100)
            .allowsHitTesting(false)
        )
    }

    private var hiddenButton: some View {
        Button(action: { HapticManager.lightImpact(); uiState.showingHiddenFolders = true }) {
            Image(systemName: "eye.slash")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.orange)
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .appGlassEffect()
        }
        .contentShape(Circle())
        .accessibilityIdentifier("hiddenFoldersButton")
    }

    private var randomizeButton: some View {
        Group {
            if isInHiddenContext {
                Button(action: {
                    HapticManager.warning()
                    uiState.showingHiddenRandomizeAlert = true
                }) {
                    Image("ShuffleIcon")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 45, height: 45)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 95, height: 56)
                        .clipShape(Capsule())
                        .appGlassEffect()
                }
                .contentShape(Capsule())
                .accessibilityIdentifier("randomizeButtonDisabled")
            } else {
                Button(action: randomizeAction) {
                    Image("ShuffleIcon")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 45, height: 45)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 95, height: 56)
                        .clipShape(Capsule())
                        .appGlassEffect()
                }
                .contentShape(Capsule())
                .accessibilityIdentifier("randomizeButton")
            }
        }
    }

    private var favoritesButton: some View {
        Button(action: { HapticManager.lightImpact(); uiState.showingFavorites = true }) {
            Image(systemName: "star")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.yellow)
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .appGlassEffect()
        }
        .contentShape(Circle())
        .accessibilityIdentifier("favoritesButton")
    }
}
