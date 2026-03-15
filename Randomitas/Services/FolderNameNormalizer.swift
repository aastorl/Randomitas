//
//  FolderNameNormalizer.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation

struct FolderNameNormalizer {
    static func normalize(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("the ") {
            return String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }

    /// Returns the uppercase first letter of the normalized sort name for section headers
    static func sectionLetter(for folder: Folder) -> String {
        let normalized = normalize(folder.name)
        guard let first = normalized.first else { return "#" }
        let upper = String(first).uppercased()
        return first.isLetter ? upper : "#"
    }
}
