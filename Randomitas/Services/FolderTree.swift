//
//  FolderTree.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation

struct FolderTree {
    static let rootName = "Randomitas"

    static func folder(at path: [Int], in folders: [Folder]) -> Folder? {
        guard !path.isEmpty, path[0] < folders.count else { return nil }
        var current = folders[path[0]]
        for i in 1..<path.count {
            guard path[i] < current.subfolders.count else { return nil }
            current = current.subfolders[path[i]]
        }
        return current
    }

    static func findFolder(at path: [Int], in folders: [Folder]) -> Folder? {
        return folder(at: path, in: folders)
    }

    static func findPathById(_ id: UUID, in folders: [Folder]) -> [Int]? {
        for (index, folder) in folders.enumerated() {
            if folder.id == id {
                return [index]
            }
            if let subPath = findPathByIdRecursive(id, in: folder, currentPath: [index]) {
                return subPath
            }
        }
        return nil
    }

    private static func findPathByIdRecursive(_ id: UUID, in folder: Folder, currentPath: [Int]) -> [Int]? {
        for (index, subfolder) in folder.subfolders.enumerated() {
            let path = currentPath + [index]
            if subfolder.id == id {
                return path
            }
            if let found = findPathByIdRecursive(id, in: subfolder, currentPath: path) {
                return found
            }
        }
        return nil
    }

    static func isFolderHiddenRecursive(folders: [Folder], targetId: UUID) -> Bool {
        for folder in folders {
            if folder.id == targetId {
                return folder.isHidden
            }
            if isFolderHiddenRecursive(folders: folder.subfolders, targetId: targetId) {
                return true
            }
        }
        return false
    }

    static func collectHiddenFolders(from folders: [Folder]) -> [(folder: Folder, path: [Int])] {
        var hiddenFolders: [(Folder, [Int])] = []
        for (index, folder) in folders.enumerated() {
            collectHiddenFolders(from: folder, currentPath: [index], into: &hiddenFolders)
        }
        return hiddenFolders
    }

    private static func collectHiddenFolders(from folder: Folder, currentPath: [Int], into result: inout [(Folder, [Int])]) {
        if folder.isHidden {
            result.append((folder, currentPath))
            return
        }
        for (index, subfolder) in folder.subfolders.enumerated() {
            collectHiddenFolders(from: subfolder, currentPath: currentPath + [index], into: &result)
        }
    }

    static func collectAllFolders(from folders: [Folder], currentPath: [Int], into result: inout [(folder: Folder, path: [Int])]) {
        for (index, folder) in folders.enumerated() {
            let folderPath = currentPath + [index]
            result.append((folder, folderPath))
            if !folder.subfolders.isEmpty {
                collectAllFolders(from: folder.subfolders, currentPath: folderPath, into: &result)
            }
        }
    }

    static func folderPathString(for path: [Int], in folders: [Folder]) -> String {
        var names: [String] = []
        var currentList = folders
        for index in path {
            if index < currentList.count {
                let folder = currentList[index]
                names.append(folder.name)
                currentList = folder.subfolders
            } else {
                break
            }
        }
        return names.joined(separator: " > ")
    }

    static func reversedPathString(for path: [Int], in folders: [Folder]) -> String {
        var names = [rootName]
        var currentLevelFolders = folders
        let parentPath = path.dropLast()

        for index in parentPath {
            if index < currentLevelFolders.count {
                let folder = currentLevelFolders[index]
                names.append(folder.name)
                currentLevelFolders = folder.subfolders
            } else {
                break
            }
        }

        return names.reversed().joined(separator: " < ")
    }

    static func search(query: String, in folders: [Folder]) -> [(Folder, [Int], String)] {
        guard !query.isEmpty else { return [] }
        var foundFolders: [(Folder, [Int], String)] = []

        func searchRecursive(folders: [Folder], currentPath: [Int], parentNames: [String]) {
            for (index, folder) in folders.enumerated() {
                let newPath = currentPath + [index]

                if folder.name.lowercased().hasPrefix(query.lowercased()) {
                    let pathString = parentNames.reversed().joined(separator: " < ")
                    foundFolders.append((folder, newPath, pathString))
                }

                var newParentNames = parentNames
                newParentNames.append(folder.name)
                searchRecursive(folders: folder.subfolders, currentPath: newPath, parentNames: newParentNames)
            }
        }

        searchRecursive(folders: folders, currentPath: [], parentNames: [rootName])
        return foundFolders
    }
}
