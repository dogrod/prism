//
//  Constants.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import Foundation

enum Constants {
    
    // MARK: - API Configuration
    enum API {
        static let openAIBaseURL = "https://api.openai.com/v1"
        static let chatCompletionsEndpoint = "/chat/completions"
        static let defaultModel = "gpt-5-nano"
        
        /// Load API key from Config.plist (if exists)
        static var openAIAPIKey: String {
            guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                  let config = NSDictionary(contentsOfFile: path),
                  let apiKey = config["OPENAI_API_KEY"] as? String else {
                return "YOUR_API_KEY_HERE"
            }
            return apiKey
        }
    }
    
    // MARK: - UI Constants
    enum UI {
        static let defaultPadding: CGFloat = 16
        static let buttonHeight: CGFloat = 50
        static let cornerRadius: CGFloat = 12
    }
    
    // MARK: - Colors
    enum Colors {
        static let primary = "PrimaryColor"
        static let secondary = "SecondaryColor"
        static let background = "BackgroundColor"
    }
}
