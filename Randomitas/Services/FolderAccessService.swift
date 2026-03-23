//
//  FolderAccessService.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation

/// Funciones de solo lectura para el árbol y búsqueda de imágenes heredadas.
struct FolderAccessService {
    func folder(at path: [Int], in folders: [Folder]) -> Folder? {
        FolderTree.folder(at: path, in: folders)
    }

    func findFolder(at path: [Int], in folders: [Folder]) -> Folder? {
        FolderTree.findFolder(at: path, in: folders)
    }

    func folderPathString(for path: [Int], in folders: [Folder]) -> String {
        FolderTree.folderPathString(for: path, in: folders)
    }

    func reversedPathString(for path: [Int], in folders: [Folder]) -> String {
        FolderTree.reversedPathString(for: path, in: folders)
    }

    func folderHasSubfolders(at path: [Int], in folders: [Folder]) -> Bool {
        guard let folder = folder(at: path, in: folders) else { return false }
        return !folder.subfolders.isEmpty
    }

    func inheritedImageData(for path: [Int], in folders: [Folder]) -> Data? {
        if let folder = folder(at: path, in: folders), let imageData = folder.imageData {
            return imageData
        }

        guard !path.isEmpty else { return nil }

        for endIndex in stride(from: path.count - 1, through: 1, by: -1) {
            let ancestorPath = Array(path.prefix(endIndex))
            if let ancestor = folder(at: ancestorPath, in: folders), let imageData = ancestor.imageData {
                return imageData
            }
        }

        if path.count >= 1 {
            let rootPath = [path[0]]
            if let rootFolder = folder(at: rootPath, in: folders), let imageData = rootFolder.imageData {
                return imageData
            }
        }

        return nil
    }
}
