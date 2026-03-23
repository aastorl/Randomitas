//
//  CoreDataStack.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 17/11/2025.
//

import CoreData
import os

@MainActor
class CoreDataStack {
    static let shared = CoreDataStack()
    static func makeInMemory() -> CoreDataStack {
        CoreDataStack(inMemory: true)
    }
    
    let container: NSPersistentContainer
    private let logger = Logger(subsystem: "Randomitas", category: "CoreDataStack")
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Randomitas")
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                self.logger.error("Core Data Error: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Limpiar base de datos en el primer inicio tras reestructurar para usar solo carpetas
        if !inMemory {
            cleanDatabaseIfNeeded()
        }
    }
    
    private func cleanDatabaseIfNeeded() {
        let hasCleanedKey = "HasCleanedDatabaseForFoldersOnly"
        let userDefaults = UserDefaults.standard
        
        if !userDefaults.bool(forKey: hasCleanedKey) {
            logger.info("Cleaning database for folders-only restructure...")
            
            let context = container.viewContext
            
            // Eliminar todas las entidades
            let entityNames = ["FolderEntity", "HistoryEntity", "FolderFavoritesEntity"]
            
            for entityName in entityNames {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try context.execute(deleteRequest)
                    logger.info("Deleted all \(entityName, privacy: .public)")
                } catch {
                    logger.error("Error deleting \(entityName, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
            }
            
            // Guardar contexto
            do {
                try context.save()
                userDefaults.set(true, forKey: hasCleanedKey)
                logger.info("Database cleaned successfully")
            } catch {
                logger.error("Error saving after cleanup: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                logger.info("Core Data guardado")
            } catch {
                let error = error as NSError
                logger.error("Error guardando Core Data: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    func refresh() {
        container.viewContext.reset()
    }
}
