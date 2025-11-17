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
