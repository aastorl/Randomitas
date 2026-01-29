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
    
    // Computed property - filtra historial de elementos que aún existen
    private var validHistory: [HistoryEntry] {
        viewModel.history
            .sorted { $0.timestamp > $1.timestamp }
            .filter { entry in
                // Verificar que el folder aún existe
                if let folder = viewModel.getFolderFromPath(entry.folderPath) {
                    return folder.id == entry.itemId
                }
                return false
            }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if validHistory.isEmpty {
                    Text("Sin historial")
                        .foregroundColor(.gray)
                } else {
                    ForEach(validHistory) { entry in
                        Button(action: {
                            // Navigate to the item directly
                            if let navigate = navigateToFullPath {
                                highlightedItemId = entry.itemId
                                navigate(entry.folderPath)
                                isPresented = false
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.itemName)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                let reversed = reversePathString(entry.path, itemName: entry.itemName)
                                if !reversed.isEmpty {
                                    HStack(spacing: 4) {
                                        Text("< \(reversed)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                Text(entry.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete { indices in
                        // Mapear índices de validHistory a history real
                        let validEntries = validHistory
                        for index in indices {
                            if index < validEntries.count {
                                viewModel.removeHistoryEntry(id: validEntries[index].id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Historial (24hs)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { isPresented = false }
                }
            }
        }
    }

    private func reversePathString(_ path: String, itemName: String) -> String {
        var components = path.components(separatedBy: " > ")
        
        // Remove item name if it's at the end (to get parent path)
        if let last = components.last, last == itemName {
            components.removeLast()
        }
        
        if components.isEmpty {
            return "Randomitas"
        }
        
        return components.reversed().joined(separator: " < ")
    }
}

