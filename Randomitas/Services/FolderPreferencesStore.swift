//
//  FolderPreferencesStore.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation
import os

final class FolderPreferencesStore: PreferencesStoreProtocol {
    private let userDefaults: UserDefaults
    private let logger = Logger(subsystem: "Randomitas", category: "FolderPreferencesStore")

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func getSortType(for folderId: UUID?) -> RandomitasViewModel.SortType {
        let key = "sort_\(folderId?.uuidString ?? "root")"
        if let saved = userDefaults.string(forKey: key), let sortType = RandomitasViewModel.SortType(rawValue: saved) {
            return sortType
        }
        return .nameAsc
    }

    func setSortType(_ sortType: RandomitasViewModel.SortType, for folderId: UUID?) {
        let key = "sort_\(folderId?.uuidString ?? "root")"
        userDefaults.set(sortType.rawValue, forKey: key)
        logger.info("Ordenamiento guardado para carpeta: \(sortType.rawValue, privacy: .public)")
    }

    func getViewType(for folderId: UUID?) -> RandomitasViewModel.ViewType {
        let key = "view_\(folderId?.uuidString ?? "root")"
        if let saved = userDefaults.string(forKey: key), let viewType = RandomitasViewModel.ViewType(rawValue: saved) {
            return viewType
        }
        return .list
    }

    func setViewType(_ viewType: RandomitasViewModel.ViewType, for folderId: UUID?) {
        let key = "view_\(folderId?.uuidString ?? "root")"
        userDefaults.set(viewType.rawValue, forKey: key)
        logger.info("Vista guardada para carpeta: \(viewType.rawValue, privacy: .public)")
    }
}
