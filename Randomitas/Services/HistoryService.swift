//
//  HistoryService.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation

/// Reglas de dominio para la retención y persistencia del historial.
@MainActor
final class HistoryService {
    private let store: HistoryStoreProtocol
    private let historyLimit: TimeInterval

    init(store: HistoryStoreProtocol, historyLimit: TimeInterval) {
        self.store = store
        self.historyLimit = historyLimit
    }

    func loadHistory() -> [HistoryEntry] {
        store.loadHistory()
    }

    func saveHistory(_ entry: HistoryEntry) -> [HistoryEntry] {
        store.saveHistory(entry)
        store.deleteHistoryOlderThan(Date().addingTimeInterval(-historyLimit))
        return store.loadHistory()
    }

    func cleanOldHistory() -> [HistoryEntry] {
        store.deleteHistoryOlderThan(Date().addingTimeInterval(-historyLimit))
        return store.loadHistory()
    }

    func removeHistoryEntry(id: UUID) -> [HistoryEntry] {
        store.deleteHistoryEntry(id: id)
        return store.loadHistory()
    }
    
    func clearHistory() -> [HistoryEntry] {
        store.deleteAllHistory()
        return store.loadHistory()
    }
}
