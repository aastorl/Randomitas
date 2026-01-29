//
//  ContentView.swift
//  Randomitas
//
//  Created by Astor Ludueña on 13/11/2025.
//

internal import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RandomitasViewModel()
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            FolderDetailView(
                folder: viewModel.rootFolder, // Virtual Root Folder
                folderPath: [], // Root Path
                viewModel: viewModel,
                navigationPath: $navigationPath
            )
        }
    }
}
