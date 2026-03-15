//
//  DomainErrors.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation

enum RepositoryError: LocalizedError {
    case notFound(String)
    case invalidPath(String)
    case coreData(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let details):
            return "No encontrado: \(details)"
        case .invalidPath(let details):
            return "Path inválido: \(details)"
        case .coreData(let details):
            return "Error de persistencia: \(details)"
        }
    }
}

enum MoveCopyError: LocalizedError {
    case sourceNotFound
    case targetNotFound

    var errorDescription: String? {
        switch self {
        case .sourceNotFound:
            return "No se encontró el elemento a mover/copiar"
        case .targetNotFound:
            return "No se encontró la carpeta destino"
        }
    }
}

enum DomainError: LocalizedError {
    case repository(RepositoryError)
    case moveCopy(MoveCopyError)
    case validation(ValidationError)

    var errorDescription: String? {
        switch self {
        case .repository(let error):
            return error.errorDescription
        case .moveCopy(let error):
            return error.errorDescription
        case .validation(let error):
            return error.errorDescription
        }
    }
}
