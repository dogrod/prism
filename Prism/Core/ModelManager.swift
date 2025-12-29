//
//  ModelManager.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import Foundation

// MARK: - AI Model Enum

enum AIModel: String, CaseIterable {
    case gpt5Nano = "gpt-5-nano"
    case gpt5Mini = "gpt-5-mini"
    case gpt4oMini = "gpt-4o-mini"
    
    var displayName: String {
        switch self {
        case .gpt5Nano: return "GPT-5 Nano"
        case .gpt5Mini: return "GPT-5 Mini"
        case .gpt4oMini: return "GPT-4o Mini"
        }
    }
    
    var shortName: String {
        switch self {
        case .gpt5Nano: return "Nano ⚡"
        case .gpt5Mini: return "Mini ⚖️"
        case .gpt4oMini: return "4o Mini"
        }
    }
    
    var description: String {
        switch self {
        case .gpt5Nano: return "Fastest response time"
        case .gpt5Mini: return "Balanced speed & accuracy"
        case .gpt4oMini: return "Legacy model"
        }
    }
    
    /// GPT-5 series models don't support temperature parameter
    var supportsTemperature: Bool {
        switch self {
        case .gpt5Nano, .gpt5Mini: return false
        case .gpt4oMini: return true
        }
    }
}

// MARK: - Model Manager Singleton

final class ModelManager {
    
    // MARK: - Singleton
    
    static let shared = ModelManager()
    
    private init() {
        // Load saved model on init
        if let savedRawValue = UserDefaults.standard.string(forKey: Keys.selectedModel),
           let savedModel = AIModel(rawValue: savedRawValue) {
            _currentModel = savedModel
        }
    }
    
    // MARK: - Keys
    
    private enum Keys {
        static let selectedModel = "prism.selectedAIModel"
    }
    
    // MARK: - Properties
    
    private var _currentModel: AIModel = .gpt5Nano
    
    var currentModel: AIModel {
        get { _currentModel }
        set {
            _currentModel = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.selectedModel)
            print("🤖 [ModelManager] Switched to: \(newValue.displayName)")
            
            // Post notification for UI updates
            NotificationCenter.default.post(
                name: .modelDidChange,
                object: nil,
                userInfo: ["model": newValue]
            )
        }
    }
    
    // MARK: - Convenience
    
    var modelIdentifier: String {
        return currentModel.rawValue
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let modelDidChange = Notification.Name("prism.modelDidChange")
}
