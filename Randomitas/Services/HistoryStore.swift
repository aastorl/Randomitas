//
//  HistoryStore.swift
//  Randomitas
//
//  Created by Codex on 13/03/2026.
//

import Foundation
import CoreData
import os

/// Almacén de Core Data para el historial. Devuelve las entradas más recientes primero.
@MainActor
final class HistoryStore: HistoryStoreProtocol {
    private let coreDataStack: CoreDataStack
    private let logger = Logger(subsystem: "Randomitas", category: "HistoryStore")

    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    func loadHistory() -> [HistoryEntry] {
        let request = NSFetchRequest<HistoryEntity>(entityName: "HistoryEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        do {
            let entities = try coreDataStack.context.fetch(request)
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let name = entity.itemName,
                      let path = entity.path,
                      let ts = entity.timestamp else { return nil }
                let itemId = entity.itemId ?? UUID()
                let folderPathData = entity.folderPath
                let folderPath: [Int] = folderPathData.flatMap { try? JSONDecoder().decode([Int].self, from: $0) } ?? []
                return HistoryEntry(id: id, itemId: itemId, itemName: name, path: path, folderPath: folderPath, timestamp: ts)
            }
        } catch {
            logger.error("Error: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func saveHistory(_ entry: HistoryEntry) {
        let hist = NSEntityDescription.insertNewObject(forEntityName: "HistoryEntity", into: coreDataStack.context) as! HistoryEntity
        hist.id = entry.id
        hist.itemId = entry.itemId
        hist.itemName = entry.itemName
        hist.path = entry.path
        hist.folderPath = try? JSONEncoder().encode(entry.folderPath)
        hist.timestamp = entry.timestamp
        coreDataStack.save()
    }

    func deleteHistoryOlderThan(_ cutoff: Date) {
        let request = NSFetchRequest<HistoryEntity>(entityName: "HistoryEntity")
        request.predicate = NSPredicate(format: "timestamp < %@", cutoff as NSDate)
        do {
            let old = try coreDataStack.context.fetch(request)
            old.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
        } catch {
            logger.error("Error: \(error.localizedDescription, privacy: .public)")
        }
    }

    func deleteHistoryEntry(id: UUID) {
        let request = NSFetchRequest<HistoryEntity>(entityName: "HistoryEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let entity = try coreDataStack.context.fetch(request).first {
                coreDataStack.context.delete(entity)
                coreDataStack.save()
            }
        } catch {
            logger.error("Error: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func deleteAllHistory() {
        let request = NSFetchRequest<HistoryEntity>(entityName: "HistoryEntity")
        do {
            let entities = try coreDataStack.context.fetch(request)
            entities.forEach { coreDataStack.context.delete($0) }
            coreDataStack.save()
        } catch {
            logger.error("Error: \(error.localizedDescription, privacy: .public)")
        }
    }
}
