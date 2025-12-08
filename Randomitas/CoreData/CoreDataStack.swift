//
//  CoreDataStack.swift
//  Randomitas
//
//  Created by Astor Ludueña  on 17/11/2025.
//

import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    let container: NSPersistentContainer
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    init() {
        container = NSPersistentContainer(name: "Randomitas")
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                print("Core Data Error: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Clean database on first launch after restructuring to folders-only
        cleanDatabaseIfNeeded()
    }
    
    private func cleanDatabaseIfNeeded() {
        let hasCleanedKey = "HasCleanedDatabaseForFoldersOnly"
        let userDefaults = UserDefaults.standard
        
        if !userDefaults.bool(forKey: hasCleanedKey) {
            print("🧹 Cleaning database for folders-only restructure...")
            
            let context = container.viewContext
            
            // Delete all entities
            let entityNames = ["FolderEntity", "HistoryEntity", "FolderFavoritesEntity"]
            
            for entityName in entityNames {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try context.execute(deleteRequest)
                    print("✅ Deleted all \(entityName)")
                } catch {
                    print("❌ Error deleting \(entityName): \(error)")
                }
            }
            
            // Save context
            do {
                try context.save()
                userDefaults.set(true, forKey: hasCleanedKey)
                print("✅ Database cleaned successfully")
            } catch {
                print("❌ Error saving after cleanup: \(error)")
            }
        }
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data guardado")
            } catch {
                let error = error as NSError
                print("❌ Error guardando Core Data: \(error)")
            }
        }
    }
    
    func refresh() {
        container.viewContext.reset()
    }
}
