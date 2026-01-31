//
//  HistorySheet.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

internal import SwiftUI

struct HistorySheet: View {
    @ObservedObject var viewModel: RandomitasViewModel
    @Binding var isPresented: Bool
    var navigateToFullPath: (([Int]) -> Void)? = nil
    @Binding var highlightedItemId: UUID?
    
    @State private var showingPathPopup: (name: String, path: String, timestamp: Date)? = nil
    
    private var validHistory: [HistoryEntry] {
        viewModel.history
            .sorted { $0.timestamp > $1.timestamp }
            .filter { entry in
                if let folder = viewModel.getFolderFromPath(entry.folderPath) {
                    return folder.id == entry.itemId
                }
                return false
            }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if validHistory.isEmpty {
                    // Empty State
                    SheetEmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "Sin Historial",
                        subtitle: "Los resultados aleatorios de las últimas 24 horas aparecerán aquí"
                    )
                } else {
                    List {
                        ForEach(validHistory) { entry in
                            let pathString = reversePathString(entry.path, itemName: entry.itemName)
                            let inheritedImage = viewModel.getInheritedImageData(for: entry.folderPath)
                            
                            SheetRowView(
                                name: entry.itemName,
                                imageData: inheritedImage,
                                onTap: {
                                    if let navigate = navigateToFullPath {
                                        highlightedItemId = entry.itemId
                                        navigate(entry.folderPath)
                                        isPresented = false
                                    }
                                },
                                onLongPress: {
                                    HapticManager.lightImpact()
                                    showingPathPopup = (name: entry.itemName, path: pathString, timestamp: entry.timestamp)
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(Color(.systemBackground).opacity(0.7))
                        }
                        .onDelete { indices in
                            let validEntries = validHistory
                            for index in indices {
                                if index < validEntries.count {
                                    viewModel.removeHistoryEntry(id: validEntries[index].id)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 0)
                }
            }
            .navigationTitle("Historial (24hs)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { isPresented = false }
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
                    Text("< \(popup.path)\n\n\(popup.timestamp.formatted(date: .abbreviated, time: .shortened))")
                }
            }
        }
    }

    private func reversePathString(_ path: String, itemName: String) -> String {
        var components = path.components(separatedBy: " > ")
        
        if let last = components.last, last == itemName {
            components.removeLast()
        }
        
        if components.isEmpty {
            return "Randomitas"
        }
        
        return components.reversed().joined(separator: " < ")
    }
}
