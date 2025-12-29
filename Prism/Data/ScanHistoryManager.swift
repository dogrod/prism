//
//  ScanHistoryManager.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit

// MARK: - Scan Record Model

struct ScanRecord: Identifiable {
    let id: UUID
    let timestamp: Date
    let originalImage: UIImage
    let receiptData: ReceiptJSON
    let rawJSONString: String
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        originalImage: UIImage,
        receiptData: ReceiptJSON,
        rawJSONString: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.originalImage = originalImage
        self.receiptData = receiptData
        self.rawJSONString = rawJSONString
    }
}

// MARK: - Scan History Manager

final class ScanHistoryManager {
    
    // MARK: - Singleton
    
    static let shared = ScanHistoryManager()
    
    private init() {}
    
    // MARK: - Properties
    
    private(set) var records: [ScanRecord] = []
    
    private let maxRecords = 20
    
    // MARK: - Public Methods
    
    /// Add a new scan record to history (prepended to maintain newest-first order)
    func add(record: ScanRecord) {
        print("📚 [ScanHistory] Adding record: \(record.receiptData.merchant_name ?? "Unknown")")
        
        // Prepend new record
        records.insert(record, at: 0)
        
        // Enforce max limit
        if records.count > maxRecords {
            records.removeLast()
            print("📚 [ScanHistory] Removed oldest record (limit: \(maxRecords))")
        }
        
        print("📚 [ScanHistory] Total records: \(records.count)")
    }
    
    /// Clear all history
    func clearAll() {
        records.removeAll()
        print("📚 [ScanHistory] Cleared all records")
    }
    
    /// Get record by ID
    func record(withId id: UUID) -> ScanRecord? {
        return records.first { $0.id == id }
    }
}

// MARK: - Date Formatting Helpers

extension ScanRecord {
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var formattedTotal: String {
        guard let total = receiptData.total else { return "--" }
        let currency = receiptData.currency ?? "USD"
        return String(format: "%@ %.2f", currencySymbol(for: currency), total)
    }
    
    private func currencySymbol(for code: String) -> String {
        switch code.uppercased() {
        case "USD": return "$"
        case "CAD": return "CA$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "CNY": return "¥"
        case "JPY": return "¥"
        default: return code
        }
    }
}
