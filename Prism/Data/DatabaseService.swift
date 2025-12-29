//
//  DatabaseService.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import Foundation
import CoreData

// MARK: - Database Service Protocol

protocol DatabaseServiceProtocol {
    var viewContext: NSManagedObjectContext { get }
    func saveContext() throws
}

// MARK: - Database Service Implementation

final class DatabaseService: DatabaseServiceProtocol {
    
    private let persistenceController: PersistenceController
    
    static let shared = DatabaseService()
    
    var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    func saveContext() throws {
        let context = viewContext
        if context.hasChanges {
            try context.save()
        }
    }
}
