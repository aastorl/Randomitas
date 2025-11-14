//
//  ResultSheet.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 14/11/2025.
//

import SwiftUI

struct ResultSheet: View {
    let item: Item
    let path: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button("Cerrar") { isPresented = false }
                Spacer()
            }
            .padding()
            
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.purple)
                
                Text(item.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(path)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}
