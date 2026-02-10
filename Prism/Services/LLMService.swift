//
//  LLMService.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import Foundation

// MARK: - LLM Service Protocol

protocol LLMServiceProtocol {
    func extractReceiptData(from ocrText: String) async throws -> ReceiptJSON
}

// MARK: - LLM Error

enum LLMError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case apiError(String)
    case noContent
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        case .noContent:
            return "No content in response"
        }
    }
}

// MARK: - OpenAI LLM Service Implementation

final class OpenAILLMService: LLMServiceProtocol {
    
    private let session: URLSession
    private let apiKey: String
    private let model: String
    
    init(
        session: URLSession = .shared,
        apiKey: String = Constants.API.openAIAPIKey,
        model: String = Constants.API.defaultModel
    ) {
        self.session = session
        self.apiKey = apiKey
        self.model = model
    }
    
    func extractReceiptData(from ocrText: String) async throws -> ReceiptJSON {
        // Use ModelManager for dynamic model selection
        let selectedModel = ModelManager.shared.modelIdentifier
        
        print("🤖 [LLMService] Starting extraction...")
        print("🤖 [LLMService] Using model: \(selectedModel)")
        print("🤖 [LLMService] API Key: \(apiKey.prefix(10))...\(apiKey.suffix(4)) (length: \(apiKey.count))")
        
        let urlString = Constants.API.openAIBaseURL + Constants.API.chatCompletionsEndpoint
        print("🤖 [LLMService] URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw LLMError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create prompt with dynamic categories
        let userCategories = ["Groceries (Need)", "Dining (Want)", "Transport (Need)", "Entertainment (Want)", "Shopping (Want)", "Utilities (Need)", "Healthcare (Need)", "Uncategorized"]
        let categoriesString = userCategories.joined(separator: ", ")
        
        let systemPrompt = """
        Role: Receipt Parser AI.
        Task: Analyze the OCR text to extract transaction details.

        **Step 1: MVR (Minimum Viable Receipt) Validation**
        Analyze the input text/image. To be considered a valid receipt, it MUST contain:
        1. A discernible **Total Amount** (Price).
        2. AND at least one of: A **Merchant Name** OR a **Date**.
        If these conditions are NOT met, set `"is_valid": false` and stop extraction.

        **Step 2: Data Extraction (Only if Valid)**
        If the input is a valid receipt, extract the following details:

        1. **Merchant Details:**
        - `merchant_name`: Normalize the name (e.g., "T&T Supermarket #002" -> "T&T Supermarket").
        - `merchant_address`: Full address if visible.

        2. **Date & Time:**
        - `date`: Format as `YYYY-MM-DD`. If year is missing, assume current year (\(Calendar.current.component(.year, from: Date()))).
        - `time`: Format as `HH:mm` (24-hour).

        3. **Currency Logic:**
        - Infer ISO code (e.g., "CAD", "USD") based on symbols ($, £) or address/phone locale.
        - Default to "CAD" if ambiguous but looks like North America.

        4. **Financials:**
        - `total`: Final amount paid.
        - `tax`: Total tax amount.
        - `tip`: Tip amount if present.
        - `payment`: Extract type (Visa/Amex/Debit/Cash) and `last4` digits.

        5. **Line Items & Categorization:**
        - Extract items into the `items` array.
        - Assign `category` ONLY from the **Allowed Categories** list above.
        - If unsure, use "Other". Do not use "Uncategorized".
        - Do not list "Total", "Subtotal", or "Tax" as items.

        **Step 3: JSON Output**
        Return a JSON object.

        **JSON Schema for Valid Receipt (Strict Output):**

        {
          "is_valid": true,
          "merchant_name": "String (Normalized) or null",
          "merchant_address": "String or null",
          "date": "YYYY-MM-DD or null",
          "time": "HH:mm or null",
          "currency": "String (e.g. CAD, USD, EUR) or null",
          "total": Number,
          "tax": Number or null,
          "tip": Number or null,
          "payment": {
            "type": "String (e.g. Visa, MasterCard, Cash) or null",
            "last4": "String or null"
          },
          "items": [
            {
              "name": "String",
              "price": Number,
              "quantity": Integer (default 1),
              "category": "String (from: \(categoriesString))"
            }
          ]
        }

        **JSON Schema for Invalid Receipt (Strict Output):**
        {
          "is_valid": false,
          "error_reason": "Brief explanation (e.g. 'No total amount found', 'Not a receipt')"
        }

        CRITICAL: Return ONLY raw JSON. No markdown formatting. No conversational text.
        """
        
        let userPrompt = "Parse this receipt:\n\n\(ocrText)"
        
        // Only include temperature for models that support it
        let temperature: Double? = ModelManager.shared.currentModel.supportsTemperature ? 0.1 : nil
        
        let openAIRequest = OpenAIRequest(
            model: selectedModel,
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: userPrompt)
            ],
            temperature: temperature,
            responseFormat: OpenAIRequest.ResponseFormat(type: "json_object")
        )
        
        // Encode request body
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(openAIRequest)
        
        // Perform request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw LLMError.networkError(error)
        }
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "No body"
            print("❌ [LLMService] API Error Status: \(httpResponse.statusCode)")
            print("❌ [LLMService] Error Body: \(errorBody)")
            throw LLMError.apiError("Status \(httpResponse.statusCode): \(errorBody)")
        }
        
        print("✅ [LLMService] API Response OK (Status: \(httpResponse.statusCode))")
        
        // Log raw response for debugging
        let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode as string"
        print("📦 [LLMService] Raw API Response:")
        print(rawResponse)
        
        // Decode response
        let decoder = JSONDecoder()
        let openAIResponse: OpenAIResponse
        do {
            openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)
            print("✅ [LLMService] Successfully decoded OpenAI response")
        } catch {
            print("❌ [LLMService] Failed to decode OpenAI response: \(error)")
            throw LLMError.decodingError(error)
        }
        
        // Extract content from response
        guard let content = openAIResponse.choices.first?.message.content else {
            print("❌ [LLMService] No content in response choices")
            throw LLMError.noContent
        }
        
        print("📄 [LLMService] LLM Content:")
        print(content)
        
        // Parse the JSON content into ReceiptJSON
        guard let contentData = content.data(using: .utf8) else {
            throw LLMError.decodingError(NSError(domain: "LLMService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert content to data"]))
        }
        
        do {
            let receiptJSON = try decoder.decode(ReceiptJSON.self, from: contentData)
            
            // MVR Validation: Check if is_valid is explicitly false
            if receiptJSON.is_valid == false {
                let errorReason = receiptJSON.error_reason ?? "Not a valid receipt"
                print("❌ [LLMService] MVR Validation Failed: \(errorReason)")
                throw ReceiptError.notAReceipt(errorReason)
            }
            
            // Legacy fallback: If is_valid is missing (nil), check for total
            if receiptJSON.is_valid == nil && receiptJSON.total == nil {
                print("❌ [LLMService] Legacy validation failed: Missing total amount")
                throw ReceiptError.missingTotal
            }
            
            print("✅ [LLMService] Successfully decoded ReceiptJSON with \(receiptJSON.items?.count ?? 0) items")
            return receiptJSON
        } catch let error as ReceiptError {
            // Re-throw ReceiptErrors directly
            throw error
        } catch {
            print("❌ [LLMService] Failed to decode ReceiptJSON: \(error)")
            print("❌ [LLMService] Content was: \(content)")
            throw LLMError.decodingError(error)
        }
    }
}
