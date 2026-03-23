//
//  FolderDetailSearchResultsView.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

internal import SwiftUI

struct FolderDetailSearchResultsView: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @ObservedObject var uiState: FolderDetailViewState
    let navigateToFullPath: ([Int]) -> Void
    var isSearchFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(spacing: 0) {
            Color(.systemBackground)
                .frame(height: 1)
                .ignoresSafeArea()

            List {
                let results = viewModel.search(query: uiState.searchText)
                    .sorted { viewModel.sortName(for: $0.0.name).localizedStandardCompare(viewModel.sortName(for: $1.0.name)) == .orderedAscending }
                if !results.isEmpty {
                    let grouped = groupSearchResults(results)
                    ForEach(grouped, id: \.letter) { group in
                        Section {
                            ForEach(group.items, id: \.0.id) { folder, path, parentName in
                                Button(action: {
                                    uiState.navigationHighlightedItemId = folder.id
                                    navigateToFullPath(path)
                                    uiState.isSearching = false
                                    uiState.searchText = ""
                                    isSearchFocused.wrappedValue = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(folder.name)
                                                .foregroundColor(.primary)
                                            HStack(spacing: 4) {
                                                Text(verbatim: "< \(parentName)")
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        } header: {
                            Text(group.letter)
                                .font(.title3.bold())
                                .foregroundColor(.secondary)
                                .textCase(nil)
                        }
                    }
                } else {
                    Text("No se encontraron Elementos")
                        .foregroundColor(.gray)
                }
            }
            .listStyle(.plain)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .padding(.bottom, 80)
        .zIndex(1)
        .transition(.opacity)
    }

    private func groupSearchResults(_ results: [(Folder, [Int], String)]) -> [(letter: String, items: [(Folder, [Int], String)])] {
        var groups: [(String, [(Folder, [Int], String)])] = []
        var currentLetter = ""
        var currentGroup: [(Folder, [Int], String)] = []

        for item in results {
            let letter = viewModel.sectionLetter(for: item.0)
            if letter != currentLetter {
                if !currentGroup.isEmpty {
                    groups.append((currentLetter, currentGroup))
                }
                currentLetter = letter
                currentGroup = [item]
            } else {
                currentGroup.append(item)
            }
        }
        if !currentGroup.isEmpty {
            groups.append((currentLetter, currentGroup))
        }
        return groups
    }
}
