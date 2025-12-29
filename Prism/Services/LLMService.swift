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
        You are an expert Receipt Parser & Financial Analyst API.

        **Objective:**
        Extract structured data from the provided raw OCR text of a receipt.
        Output the result in STRICT JSON format matching the schema defined below.

        **Allowed Categories:** \(categoriesString)

        **Instructions:**

        1. **Merchant Details:**
           - Extract the `merchant_name`.
           - Extract the full `merchant_address` if visible.

        2. **Date & Time:**
           - Format `date` as `YYYY-MM-DD`. If the year is missing, assume the current year.
           - Format `time` as `HH:mm` (24-hour format).

        3. **Currency Logic:**
           - Infer the `currency` ISO code (e.g., "CAD", "USD", "CNY", "EUR") based on:
               - Currency symbols ($, £, €).
               - The country/region found in the address or phone number area code.
           - If the currency cannot be determined with certainty, return null.

        4. **Financials:**
           - Extract `total` amount and `tax` amount.
           - Extract `payment` information:
               - `type`: "Visa", "Amex", "Debit", "Cash", etc.
               - `last4`: The last 4 digits of the card number.

        5. **Line Items & Categorization:**
           - Extract individual items into the `items` array.
           - For each item, assign a `category` ONLY from the Allowed Categories list.
           - If an item does not fit any provided category, use "Uncategorized".
           - Do not list "Total" or "Tax" as items.

        **JSON Schema:**
        {
          "merchant_name": "String or null",
          "merchant_address": "String or null",
          "date": "YYYY-MM-DD or null",
          "time": "HH:mm or null",
          "currency": "String (ISO) or null",
          "total": Number or null,
          "tax": Number or null,
          "tip": Number or null,
          "payment": {
            "type": "String or null",
            "last4": "String or null"
          },
          "items": [
            {
              "name": "String",
              "price": Number,
              "quantity": Integer (default 1),
              "category": "String (Must match Allowed Categories)"
            }
          ]
        }

        Return ONLY the raw JSON object. Do not wrap in markdown blocks. Do not add conversational text.
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
            print("✅ [LLMService] Successfully decoded ReceiptJSON with \(receiptJSON.items?.count ?? 0) items")
            return receiptJSON
        } catch {
            print("❌ [LLMService] Failed to decode ReceiptJSON: \(error)")
            print("❌ [LLMService] Content was: \(content)")
            throw LLMError.decodingError(error)
        }
    }
}
