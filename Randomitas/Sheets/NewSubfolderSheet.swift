//
//  NewSubfolderSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import SwiftUI

struct NewSubfolderSheet: View {
    @ObservedObject var viewModel: RandomitasViewModel
    let folderPath: [Int]
    @Binding var isPresented: Bool
    @State var name: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Nombre de la subcarpeta", text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Spacer()
                
                Button(action: {
                    viewModel.addSubfolder(name: name.isEmpty ? "Sin nombre" : name, to: folderPath)
                    isPresented = false
                }) {
                    Text("Crear")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Nueva Subcarpeta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { isPresented = false }
                }
            }
        }
    }
}
