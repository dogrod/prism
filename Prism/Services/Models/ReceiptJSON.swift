//
//  ReceiptJSON.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import Foundation

// MARK: - Receipt JSON Response Model

struct ReceiptJSON: Codable, Equatable {
    let merchant_name: String?
    let merchant_address: String?
    let date: String? // Format: YYYY-MM-DD
    let time: String? // Format: HH:mm
    let currency: String? // ISO Code (e.g., "CAD", "USD")
    let total: Double?
    let tax: Double?
    let payment: PaymentInfo?
    let items: [Item]?
    
    // MARK: - Payment Info
    
    struct PaymentInfo: Codable, Equatable {
        let type: String? // e.g., "Visa", "MasterCard", "Cash", "Debit"
        let last4: String? // e.g., "4021"
    }
    
    // MARK: - Item
    
    struct Item: Codable, Equatable {
        let name: String
        let price: Double
        let category: String // Dynamic category from the provided list
        let quantity: Int?
    }
}

// MARK: - OpenAI API Response Models

struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// MARK: - OpenAI Request Models

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double? // Optional: GPT-5 series doesn't support temperature
    let responseFormat: ResponseFormat?
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case responseFormat = "response_format"
    }
    
    struct ResponseFormat: Codable {
        let type: String
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}
