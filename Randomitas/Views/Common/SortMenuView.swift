//
//  SortMenuView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 21/11/2025.
//

internal import SwiftUI

struct SortMenuView: View {
    @Binding var sortType: RandomitasViewModel.SortType
    
    var body: some View {
        Menu {
            Section("Ordenar por nombre") {
                Button(action: { sortType = .nameAsc }) {
                    Label("A - Z", systemImage: sortType == .nameAsc ? "checkmark" : "")
                }
                Button(action: { sortType = .nameDesc }) {
                    Label("Z - A", systemImage: sortType == .nameDesc ? "checkmark" : "")
                }
            }
            
            Section("Ordenar por fecha") {
                Button(action: { sortType = .dateNewest }) {
                    Label("Más reciente", systemImage: sortType == .dateNewest ? "checkmark" : "")
                }
                Button(action: { sortType = .dateOldest }) {
                    Label("Más antiguo", systemImage: sortType == .dateOldest ? "checkmark" : "")
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}
