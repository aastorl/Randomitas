//
//  RandomizerService.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation

struct RandomizerService {
    func randomizeCurrentScreen(
        at path: [Int],
        folders: [Folder],
        findFolder: ([Int]) -> Folder?,
        isHidden: ([Int]) -> Bool,
        pathString: ([Int]) -> String,
        saveHistory: (HistoryEntry) -> Void
    ) -> (folder: Folder, path: [Int])? {
        let foldersToRandomize: [Folder]

        if path.isEmpty {
            foldersToRandomize = folders
        } else {
            guard let parentFolder = findFolder(path) else { return nil }
            foldersToRandomize = parentFolder.subfolders
        }

        var visibleFolders: [Folder] = []
        for (index, folder) in foldersToRandomize.enumerated() {
            let folderPath = path + [index]
            if !isHidden(folderPath) {
                visibleFolders.append(folder)
            }
        }

        guard !visibleFolders.isEmpty else { return nil }

        let randomIndex = Int.random(in: 0..<visibleFolders.count)
        let selectedFolder = visibleFolders[randomIndex]

        guard let originalIndex = foldersToRandomize.firstIndex(where: { $0.id == selectedFolder.id }) else { return nil }
        let resultPath = path + [originalIndex]

        let pathValue = pathString(Array(resultPath.dropLast()))
        let entry = HistoryEntry(itemId: selectedFolder.id, itemName: selectedFolder.name, path: pathValue, folderPath: resultPath)
        saveHistory(entry)

        return (selectedFolder, resultPath)
    }

    func randomizeWithChildren(
        at path: [Int],
        folders: [Folder],
        findFolder: ([Int]) -> Folder?,
        isHidden: ([Int]) -> Bool,
        pathString: ([Int]) -> String,
        saveHistory: (HistoryEntry) -> Void
    ) -> (folder: Folder, path: [Int])? {
        var allFolders: [(folder: Folder, path: [Int])] = []

        if path.isEmpty {
            FolderTree.collectAllFolders(from: folders, currentPath: [], into: &allFolders)
        } else {
            guard let parentFolder = findFolder(path) else { return nil }
            FolderTree.collectAllFolders(from: parentFolder.subfolders, currentPath: path, into: &allFolders)
        }

        allFolders = allFolders.filter { !isHidden($0.path) }

        guard !allFolders.isEmpty else { return nil }

        let randomIndex = Int.random(in: 0..<allFolders.count)
        let selected = allFolders[randomIndex]

        let pathValue = pathString(Array(selected.path.dropLast()))
        let entry = HistoryEntry(itemId: selected.folder.id, itemName: selected.folder.name, path: pathValue, folderPath: selected.path)
        saveHistory(entry)

        return selected
    }
}
