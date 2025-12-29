//
//  ScanProcessor.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/29.
//

import Foundation
import CoreData
import UIKit

// MARK: - Scan Processor Result

enum ScanProcessorResult {
    case success(Transaction)
    case duplicateDetected(existing: Transaction)
    case error(Error)
}

// MARK: - Scan Processor Error

enum ScanProcessorError: LocalizedError {
    case invalidData(String)
    case saveFailed(Error)
    case imageSaveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .imageSaveFailed:
            return "Failed to save receipt image"
        }
    }
}

// MARK: - Scan Processor

/// Processes scanned receipts and creates Transaction records
final class ScanProcessor {
    
    // MARK: - Singleton
    
    static let shared = ScanProcessor()
    
    private init() {}
    
    // MARK: - Dependencies
    
    private var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    
    // MARK: - Main Pipeline
    
    /// Process a scanned receipt and create a Transaction
    /// - Parameters:
    ///   - receipt: The parsed ReceiptJSON from OCR/LLM
    ///   - rawJSON: The raw JSON string for audit trail
    ///   - image: The original scanned image
    /// - Returns: ScanProcessorResult indicating success, duplicate, or error
    func process(
        receipt: ReceiptJSON,
        rawJSON: String,
        image: UIImage
    ) async -> ScanProcessorResult {
        do {
            print("📋 [ScanProcessor] Starting pipeline...")
            
            // Step A: Account Resolution
            let account = try resolveAccount(from: receipt)
            print("✅ [ScanProcessor] Account resolved: \(account.name ?? "Unknown")")
            
            // Step B: Merchant Resolution
            let merchant = try resolveMerchant(from: receipt)
            print("✅ [ScanProcessor] Merchant resolved: \(merchant.name ?? "Unknown") [\(merchant.category.displayName)]")
            
            // Parse date and amount
            guard let date = parseDate(from: receipt),
                  let amount = receipt.total else {
                throw ScanProcessorError.invalidData("Missing date or amount")
            }
            
            // Step C: Duplicate Detection
            if let existingTransaction = findDuplicate(merchant: merchant, date: date, amount: amount) {
                print("⚠️ [ScanProcessor] Duplicate detected!")
                return .duplicateDetected(existing: existingTransaction)
            }
            
            // Step D: Save Transaction
            let transaction = try saveTransaction(
                receipt: receipt,
                account: account,
                merchant: merchant,
                date: date,
                rawJSON: rawJSON,
                image: image
            )
            
            print("✅ [ScanProcessor] Transaction saved: \(transaction.id?.uuidString ?? "Unknown")")
            return .success(transaction)
            
        } catch {
            print("❌ [ScanProcessor] Error: \(error)")
            return .error(error)
        }
    }
    
    // MARK: - Step A: Account Resolution
    
    private func resolveAccount(from receipt: ReceiptJSON) throws -> Account {
        let provider = receipt.payment?.type ?? "Unknown"
        let last4 = receipt.payment?.last4 ?? "0000"
        
        // Query for existing account
        let fetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "provider ==[c] %@ AND lastFourDigits == %@",
            provider, last4
        )
        fetchRequest.fetchLimit = 1
        
        if let existingAccount = try context.fetch(fetchRequest).first {
            return existingAccount
        }
        
        // Create new account
        let newAccount = Account(context: context)
        newAccount.id = UUID()
        newAccount.provider = provider
        newAccount.lastFourDigits = last4
        newAccount.name = "\(provider) ****\(last4)"
        
        print("🆕 [ScanProcessor] Created new account: \(newAccount.name ?? "")")
        return newAccount
    }
    
    // MARK: - Step B: Merchant Resolution
    
    private func resolveMerchant(from receipt: ReceiptJSON) throws -> Merchant {
        let merchantName = receipt.merchant_name ?? "Unknown Merchant"
        
        // Query for existing merchant by normalized name
        let fetchRequest: NSFetchRequest<Merchant> = Merchant.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@", merchantName)
        fetchRequest.fetchLimit = 1
        
        if let existingMerchant = try context.fetch(fetchRequest).first {
            return existingMerchant
        }
        
        // Create new merchant with auto-categorization
        let newMerchant = Merchant(context: context)
        newMerchant.id = UUID()
        newMerchant.name = merchantName
        newMerchant.rawName = merchantName
        newMerchant.address = receipt.merchant_address
        
        // Auto-categorize based on name and items
        let topItems = receipt.items?.prefix(3).map { $0.name } ?? []
        newMerchant.category = classifyMerchant(name: merchantName, topItems: Array(topItems))
        
        print("🆕 [ScanProcessor] Created new merchant: \(merchantName) -> \(newMerchant.category.displayName)")
        return newMerchant
    }
    
    /// Classify merchant using keywords (could be enhanced with LLM call)
    private func classifyMerchant(name: String, topItems: [String]) -> MerchantCategory {
        // First try name-based classification
        let category = MerchantCategory.categorize(merchantName: name)
        if category != .other {
            return category
        }
        
        // Try item-based classification
        for item in topItems {
            let itemCategory = MerchantCategory.categorize(merchantName: item)
            if itemCategory != .other {
                return itemCategory
            }
        }
        
        return .other
    }
    
    // MARK: - Step C: Duplicate Detection
    
    private func findDuplicate(merchant: Merchant, date: Date, amount: Double) -> Transaction? {
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        // Match on same day (ignoring time)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        fetchRequest.predicate = NSPredicate(
            format: "merchant == %@ AND date >= %@ AND date < %@ AND amount == %@",
            merchant,
            startOfDay as NSDate,
            endOfDay as NSDate,
            NSDecimalNumber(value: amount)
        )
        fetchRequest.fetchLimit = 1
        
        return try? context.fetch(fetchRequest).first
    }
    
    // MARK: - Step D: Save Transaction
    
    private func saveTransaction(
        receipt: ReceiptJSON,
        account: Account,
        merchant: Merchant,
        date: Date,
        rawJSON: String,
        image: UIImage
    ) throws -> Transaction {
        // Save image to documents directory
        let imagePath = try saveImage(image)
        
        // Create ScanRecord
        let scanRecord = ScanRecord(context: context)
        scanRecord.id = UUID()
        scanRecord.rawJSON = rawJSON
        scanRecord.imagePath = imagePath
        scanRecord.createdAt = Date()
        
        // Create Transaction
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.date = date
        transaction.amount = NSDecimalNumber(value: receipt.total ?? 0)
        transaction.tax = receipt.tax.map { NSDecimalNumber(value: $0) }
        transaction.tip = receipt.tip.map { NSDecimalNumber(value: $0) }
        transaction.currency = receipt.currency ?? "CAD"
        transaction.isVerified = true
        
        // Serialize items as JSON blob
        if let items = receipt.items {
            let encoder = JSONEncoder()
            if let itemsData = try? encoder.encode(items),
               let itemsString = String(data: itemsData, encoding: .utf8) {
                transaction.itemsBlob = itemsString
            }
        }
        
        // Link relationships
        transaction.account = account
        transaction.merchant = merchant
        transaction.scanRecord = scanRecord
        
        // Save context
        do {
            try context.save()
        } catch {
            throw ScanProcessorError.saveFailed(error)
        }
        
        return transaction
    }
    
    // MARK: - Helpers
    
    private func parseDate(from receipt: ReceiptJSON) -> Date? {
        guard let dateString = receipt.date else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            // Add time if available
            if let timeString = receipt.time {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                if let time = timeFormatter.date(from: timeString) {
                    let calendar = Calendar.current
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                    return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                        minute: timeComponents.minute ?? 0,
                                        second: 0,
                                        of: date)
                }
            }
            return date
        }
        
        return nil
    }
    
    private func saveImage(_ image: UIImage) throws -> String {
        let fileName = UUID().uuidString + ".heic"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent("receipts", isDirectory: true)
        
        // Create receipts directory if needed
        try? FileManager.default.createDirectory(at: imagePath, withIntermediateDirectories: true)
        
        let filePath = imagePath.appendingPathComponent(fileName)
        
        // Try HEIC first (better compression), fall back to JPEG
        var data: Data?
        if let cgImage = image.cgImage {
            let heicData = NSMutableData()
            if let destination = CGImageDestinationCreateWithData(heicData, "public.heic" as CFString, 1, nil) {
                let options: [CFString: Any] = [
                    kCGImageDestinationLossyCompressionQuality: 0.5
                ]
                CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
                if CGImageDestinationFinalize(destination) {
                    data = heicData as Data
                }
            }
        }
        
        // Fallback to JPEG if HEIC fails
        if data == nil {
            data = image.jpegData(compressionQuality: 0.5)
        }
        
        guard let imageData = data else {
            throw ScanProcessorError.imageSaveFailed
        }
        
        try imageData.write(to: filePath)
        return filePath.path
    }
    
    // MARK: - Force Add Duplicate
    
    /// Add a transaction even if it's a duplicate
    func forceAddDuplicate(
        receipt: ReceiptJSON,
        rawJSON: String,
        image: UIImage
    ) async -> ScanProcessorResult {
        do {
            let account = try resolveAccount(from: receipt)
            let merchant = try resolveMerchant(from: receipt)
            
            guard let date = parseDate(from: receipt) else {
                throw ScanProcessorError.invalidData("Missing date")
            }
            
            let transaction = try saveTransaction(
                receipt: receipt,
                account: account,
                merchant: merchant,
                date: date,
                rawJSON: rawJSON,
                image: image
            )
            
            return .success(transaction)
        } catch {
            return .error(error)
        }
    }
    
    // MARK: - Regenerate Transaction
    
    /// Regenerate a transaction by re-analyzing its original image with a new model
    /// - Parameters:
    ///   - transaction: The existing transaction to update
    ///   - model: The LLM model to use for analysis
    /// - Returns: Updated transaction or error
    func regenerateTransaction(
        _ transaction: Transaction,
        using model: AIModel
    ) async throws -> Transaction {
        print("🔄 [ScanProcessor] Regenerating transaction with model: \(model.name)")
        
        // Get the original image from ScanRecord
        guard let scanRecord = transaction.scanRecord,
              let imagePath = scanRecord.imagePath else {
            throw ScanProcessorError.invalidData("No original image available")
        }
        
        // Load the image
        guard let image = UIImage(contentsOfFile: imagePath) else {
            throw ScanProcessorError.invalidData("Could not load image from path")
        }
        
        // Run OCR
        let ocrService = VisionOCRService()
        let recognizedText = try await ocrService.recognizeText(image: image)
        
        // Run LLM with specified model
        let llmService = OpenAILLMService()
        
        // Temporarily switch model
        let originalModel = ModelManager.shared.currentModel
        ModelManager.shared.currentModel = model
        
        let receipt = try await llmService.extractReceiptData(from: recognizedText)
        
        // Restore original model
        ModelManager.shared.currentModel = originalModel
        
        // Update the transaction
        try await updateTransaction(transaction, with: receipt)
        
        print("✅ [ScanProcessor] Transaction regenerated successfully")
        return transaction
    }
    
    /// Update an existing transaction with new receipt data
    private func updateTransaction(_ transaction: Transaction, with receipt: ReceiptJSON) async throws {
        // Resolve new merchant if changed
        let merchant = try resolveMerchant(from: receipt)
        let account = try resolveAccount(from: receipt)
        
        // Update transaction fields
        if let date = parseDate(from: receipt) {
            transaction.date = date
        }
        
        transaction.amount = NSDecimalNumber(value: receipt.total ?? 0)
        transaction.tax = receipt.tax.map { NSDecimalNumber(value: $0) }
        transaction.tip = receipt.tip.map { NSDecimalNumber(value: $0) }
        transaction.currency = receipt.currency ?? "CAD"
        
        // Update items blob
        if let items = receipt.items {
            let encoder = JSONEncoder()
            if let itemsData = try? encoder.encode(items),
               let itemsString = String(data: itemsData, encoding: .utf8) {
                transaction.itemsBlob = itemsString
            }
        }
        
        // Update relationships
        transaction.merchant = merchant
        transaction.account = account
        
        // Update scan record raw JSON
        if let scanRecord = transaction.scanRecord {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            if let data = try? encoder.encode(receipt),
               let jsonString = String(data: data, encoding: .utf8) {
                scanRecord.rawJSON = jsonString
            }
        }
        
        // Save
        try context.save()
    }
}
