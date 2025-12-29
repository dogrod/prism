//
//  TransactionRepository.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import Foundation
import CoreData

// MARK: - Transaction Entity (Placeholder for future Core Data model)

struct TransactionEntity {
    let id: UUID
    let date: Date
    let amount: Double
    let category: String
    let classification: String // "Need" or "Want"
    let merchantName: String?
}

// MARK: - Transaction Repository Protocol

protocol TransactionRepositoryProtocol {
    func fetchAll() async throws -> [TransactionEntity]
    func save(transaction: TransactionEntity) async throws
    func delete(id: UUID) async throws
}

// MARK: - Transaction Repository Implementation (Placeholder)

final class TransactionRepository: TransactionRepositoryProtocol {
    
    private let databaseService: DatabaseServiceProtocol
    
    init(databaseService: DatabaseServiceProtocol = DatabaseService.shared) {
        self.databaseService = databaseService
    }
    
    func fetchAll() async throws -> [TransactionEntity] {
        // TODO: Implement Core Data fetch when entity is created
        return []
    }
    
    func save(transaction: TransactionEntity) async throws {
        // TODO: Implement Core Data save when entity is created
    }
    
    func delete(id: UUID) async throws {
        // TODO: Implement Core Data delete when entity is created
    }
}
