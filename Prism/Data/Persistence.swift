//
//  Persistence.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample account
        let account = Account(context: viewContext)
        account.id = UUID()
        account.name = "Visa ****4242"
        account.provider = "Visa"
        account.lastFourDigits = "4242"
        
        // Create sample merchant
        let merchant = Merchant(context: viewContext)
        merchant.id = UUID()
        merchant.name = "Sample Store"
        merchant.categoryRaw = MerchantCategory.shopping.rawValue
        
        // Create sample transaction
        let transaction = Transaction(context: viewContext)
        transaction.id = UUID()
        transaction.date = Date()
        transaction.amount = NSDecimalNumber(value: 25.99)
        transaction.currency = "CAD"
        transaction.account = account
        transaction.merchant = merchant
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Prism")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
