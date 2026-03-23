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

    /// Devuelve la primera letra en mayúscula del nombre normalizado para los encabezados de sección
    static func sectionLetter(for folder: Folder) -> String {
        let normalized = normalize(folder.name)
        guard let first = normalized.first else { return "#" }
        let upper = String(first).uppercased()
        return first.isLetter ? upper : "#"
    }
}
