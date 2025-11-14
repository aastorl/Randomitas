//
//  EmptyStateView.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import SwiftUI

struct EmptyStateView: View {
    @Binding var showingNewFolderSheet: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Comienza creando una carpeta")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("Los items solo pueden existir dentro de carpetas")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Button(action: { showingNewFolderSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                    Text("Nueva Carpeta")
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
