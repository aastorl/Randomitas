//
//  RenameSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña on 21/11/2025.
//

internal import SwiftUI

struct RenameSheet: View {
    let itemId: UUID
    let currentName: String
    let onRename: (String) -> Void
    @Binding var isPresented: Bool
    @State var newName: String = ""
    @FocusState var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Nuevo nombre", text: $newName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isFocused)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { isPresented = false }) {
                        Text("Cancelar")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        if !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                            onRename(newName)
                            isPresented = false
                        }
                    }) {
                        Text("Guardar")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .navigationTitle("Renombrar")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            newName = currentName
            isFocused = true
        }
    }
}
