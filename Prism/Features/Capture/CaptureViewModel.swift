//
//  CaptureViewModel.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit
import Combine

// MARK: - Capture State

enum CaptureState: Equatable {
    case idle
    case scanning
    case analyzing
    case success(ReceiptJSON)
    case error(String)
    
    static func == (lhs: CaptureState, rhs: CaptureState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.scanning, .scanning), (.analyzing, .analyzing):
            return true
        case (.success(let lhsReceipt), .success(let rhsReceipt)):
            return lhsReceipt == rhsReceipt
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - Capture ViewModel

@MainActor
final class CaptureViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var state: CaptureState = .idle
    @Published private(set) var selectedImage: UIImage?
    @Published private(set) var ocrText: String?
    
    /// Published when a transaction is successfully saved - used for toast navigation
    @Published private(set) var savedTransaction: Transaction?
    
    // MARK: - Dependencies
    
    private let ocrService: OCRServiceProtocol
    private let llmService: LLMServiceProtocol
    
    // MARK: - Initialization
    
    init(ocrService: OCRServiceProtocol, llmService: LLMServiceProtocol) {
        self.ocrService = ocrService
        self.llmService = llmService
    }
    
    // MARK: - Public Methods
    
    func processImage(_ image: UIImage) {
        print("📸 [CaptureVM] Starting image processing...")
        print("📸 [CaptureVM] Image size: \(image.size)")
        selectedImage = image
        state = .scanning
        
        Task {
            await performScanAndAnalyze(image)
        }
    }
    
    func reset() {
        state = .idle
        selectedImage = nil
        ocrText = nil
    }
    
    // MARK: - Private Methods
    
    private func performScanAndAnalyze(_ image: UIImage) async {
        // Step 1: OCR
        print("🔍 [CaptureVM] Step 1: Starting OCR...")
        do {
            let recognizedText = try await ocrService.recognizeText(image: image)
            ocrText = recognizedText
            print("✅ [CaptureVM] OCR Success! Recognized \(recognizedText.count) characters")
            print("📝 [CaptureVM] OCR Text Preview: \(String(recognizedText.prefix(200)))...")
            
            // Step 2: LLM Analysis
            print("🤖 [CaptureVM] Step 2: Starting LLM analysis...")
            state = .analyzing
            
            let receiptData = try await llmService.extractReceiptData(from: recognizedText)
            print("✅ [CaptureVM] LLM Success! Parsed receipt with \(receiptData.items?.count ?? 0) items")
            
            // Save to scan history
            saveToHistory(image: image, receiptData: receiptData)
            
            state = .success(receiptData)
            
        } catch let error as OCRError {
            print("❌ [CaptureVM] OCR Error: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        } catch let error as LLMError {
            print("❌ [CaptureVM] LLM Error: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        } catch let error as ReceiptError {
            print("❌ [CaptureVM] Receipt Error: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        } catch {
            print("❌ [CaptureVM] Unexpected Error: \(error.localizedDescription)")
            state = .error("An unexpected error occurred: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Computed Properties
    
    var stateDescription: String {
        switch state {
        case .idle:
            return "Tap 'Scan Receipt' to begin"
        case .scanning:
            return "Scanning receipt..."
        case .analyzing:
            return "Analyzing with AI..."
        case .success:
            return "Analysis complete!"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var resultJSON: String? {
        guard case .success(let receipt) = state else { return nil }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let data = try? encoder.encode(receipt),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return jsonString
    }
    
    // MARK: - History Management
    
    private func saveToHistory(image: UIImage, receiptData: ReceiptJSON) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let rawJSON: String
        if let data = try? encoder.encode(receiptData),
           let jsonString = String(data: data, encoding: .utf8) {
            rawJSON = jsonString
        } else {
            rawJSON = "Failed to encode JSON"
        }
        
        // Save to legacy in-memory history
        let record = ScanHistoryRecord(
            originalImage: image,
            receiptData: receiptData,
            rawJSONString: rawJSON
        )
        ScanHistoryManager.shared.add(record: record)
        
        // Save to Core Data via ScanProcessor
        Task {
            let result = await ScanProcessor.shared.process(
                receipt: receiptData,
                rawJSON: rawJSON,
                image: image
            )
            
            switch result {
            case .success(let transaction):
                print("✅ [CaptureVM] Transaction saved: \(transaction.id?.uuidString ?? "Unknown")")
                print("   Merchant: \(transaction.merchant?.name ?? "Unknown")")
                print("   Account: \(transaction.account?.name ?? "Unknown")")
                print("   Amount: \(transaction.amount ?? 0) \(transaction.currency ?? "CAD")")
                
                // Check if it's a potential duplicate
                if transaction.duplicateOfTransactionID != nil {
                    print("⚠️ [CaptureVM] Transaction marked as potential duplicate")
                }
                
                // Publish for toast navigation
                await MainActor.run {
                    self.savedTransaction = transaction
                }
                
            case .error(let error):
                print("❌ [CaptureVM] Failed to save transaction: \(error.localizedDescription)")
            }
        }
    }
    
    /// Clear the saved transaction after handling
    func clearSavedTransaction() {
        savedTransaction = nil
    }
}
