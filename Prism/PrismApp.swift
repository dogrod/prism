//
//  PrismApp.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import SwiftUI
import CoreData

@main
struct PrismApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
