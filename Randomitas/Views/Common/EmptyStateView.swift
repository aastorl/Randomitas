//
//  EmptyStateView.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

internal import SwiftUI

struct EmptyStateView: View {
    @Binding var showingNewFolderSheet: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 64))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                Text("Comienza creando un Elemento")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("Los items solo pueden existir dentro de carpetas") // Depreacated
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Button(action: { showingNewFolderSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "bookmark.slash")
                    Text("Nuevo Elemento")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
}
