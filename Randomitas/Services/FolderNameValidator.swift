//
//  FolderNameValidator.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation

enum ValidationError: LocalizedError {
    case emptyName
    case duplicateName

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Nombre requerido"
        case .duplicateName:
            return "Nombre duplicado"
        }
    }
}

struct FolderNameValidator {
    func validate(_ name: String, siblings: [Folder]) -> Result<String, ValidationError> {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyName) }

        let normalized = trimmed.lowercased()
        let hasDuplicate = siblings.contains { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized }
        if hasDuplicate {
            return .failure(.duplicateName)
        }

        return .success(trimmed)
    }
}
