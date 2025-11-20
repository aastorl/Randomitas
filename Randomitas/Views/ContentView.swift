//
//  ContentView.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 13/11/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = RandomitasViewModel()
    @State var showingNewFolderSheet = false
    @State var showingResult = false
    @State var selectedResult: (item: Item, path: String)?
    @State var showingFavorites = false
    @State var showingHistory = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    // Header
                    HStack {
                        Menu {
                            Button(action: { /* More options */ }) {
                                Label("Opciones", systemImage: "ellipsis")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        Text("Randomitas")
                            .font(.system(size: 20, weight: .bold))
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: { showingHistory = true }) {
                                Image(systemName: "clock")
                                    .font(.system(size: 18))
                            }
                            
                            Button(action: { showingNewFolderSheet = true }) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 24))
                            }
                        }
                        .foregroundColor(.black)
                    }
                    .padding()
                    
                    // Randomize Button
                    if !viewModel.folders.isEmpty {
                        Button(action: randomize) {
                            HStack {
                                Image(systemName: "shuffle")
                                Text("Randomizar")
                                Text("Elegir entre todos los elementos")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple, .pink]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .padding()
                    }
                    
                    // Content
                    if viewModel.folders.isEmpty {
                        EmptyStateView(showingNewFolderSheet: $showingNewFolderSheet)
                    } else {
                        FoldersListView(viewModel: viewModel)
                    }
                    
                    Spacer()
                }
                
                // Bottom Favorites Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingFavorites = true }) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.yellow)
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                }
            }
            .sheet(isPresented: $showingNewFolderSheet) {
                NewFolderSheet(viewModel: viewModel, isPresented: $showingNewFolderSheet)
            }
            .sheet(isPresented: $showingResult) {
                if let result = selectedResult {
                    ResultSheet(item: result.item, path: result.path, isPresented: $showingResult, viewModel: viewModel, folderPath: [])
                }
            }
            .sheet(isPresented: $showingFavorites) {
                FavoritesSheet(viewModel: viewModel, isPresented: $showingFavorites)
            }
            .sheet(isPresented: $showingHistory) {
                HistorySheet(viewModel: viewModel, isPresented: $showingHistory)
            }
        }
    }
    
    func randomize() {
        viewModel.cleanOldHistory()
        
        if !viewModel.folders.isEmpty {
            let randomIndex = Int.random(in: 0..<viewModel.folders.count)
            selectedResult = viewModel.randomizeFolder(at: [randomIndex])
        }
        
        if selectedResult != nil {
            showingResult = true
        }
    }
}

#Preview {
    ContentView()
}
