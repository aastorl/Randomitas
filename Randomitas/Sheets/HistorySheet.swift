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
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.history.isEmpty {
                    Text("Sin historial")
                        .foregroundColor(.gray)
                } else {
                    ForEach(viewModel.history.sorted { $0.timestamp > $1.timestamp }) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.itemName)
                                .fontWeight(.semibold)
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
