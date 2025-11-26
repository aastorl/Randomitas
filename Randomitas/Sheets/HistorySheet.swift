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
                            Text(entry.path)
                                .font(.caption)
                                .foregroundColor(.gray)
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
}
