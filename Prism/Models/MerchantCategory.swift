//
//  MerchantCategory.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/29.
//

import Foundation

/// Merchant category enumeration for type-safe categorization
/// Stored as Int16 in Core Data (categoryRaw attribute)
enum MerchantCategory: Int16, CaseIterable, Codable {
    case groceries = 0
    case dining = 1
    case shopping = 2
    case transport = 3
    case utilities = 4
    case entertainment = 5
    case health = 6
    case services = 7
    case other = 8
    
    // MARK: - Display Properties
    
    var displayName: String {
        switch self {
        case .groceries: return "Groceries"
        case .dining: return "Dining"
        case .shopping: return "Shopping"
        case .transport: return "Transport"
        case .utilities: return "Utilities"
        case .entertainment: return "Entertainment"
        case .health: return "Health"
        case .services: return "Services"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .groceries: return "cart.fill"
        case .dining: return "fork.knife"
        case .shopping: return "bag.fill"
        case .transport: return "car.fill"
        case .utilities: return "bolt.fill"
        case .entertainment: return "theatermasks.fill"
        case .health: return "heart.fill"
        case .services: return "wrench.and.screwdriver.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .groceries: return "#4CAF50"
        case .dining: return "#FF9800"
        case .shopping: return "#E91E63"
        case .transport: return "#2196F3"
        case .utilities: return "#9C27B0"
        case .entertainment: return "#F44336"
        case .health: return "#00BCD4"
        case .services: return "#795548"
        case .other: return "#9E9E9E"
        }
    }
    
    // MARK: - Keywords for matching
    
    var keywords: [String] {
        switch self {
        case .groceries:
            return ["supermarket", "grocery", "market", "food", "produce", "t&t", "whole foods", "costco", "walmart", "safeway", "sobeys", "loblaws", "no frills"]
        case .dining:
            return ["restaurant", "cafe", "coffee", "starbucks", "mcdonald", "tim hortons", "subway", "pizza", "sushi", "bar", "pub", "grill", "kitchen", "eatery"]
        case .shopping:
            return ["store", "shop", "mall", "amazon", "best buy", "ikea", "home depot", "canadian tire", "winners", "hudson's bay"]
        case .transport:
            return ["gas", "fuel", "petro", "shell", "esso", "uber", "lyft", "transit", "parking", "toll", "taxi"]
        case .utilities:
            return ["hydro", "electric", "water", "internet", "phone", "mobile", "rogers", "bell", "telus", "shaw"]
        case .entertainment:
            return ["cinema", "movie", "theatre", "concert", "netflix", "spotify", "game", "arcade", "museum", "park"]
        case .health:
            return ["pharmacy", "shoppers drug", "rexall", "hospital", "clinic", "doctor", "dentist", "optometrist", "gym", "fitness"]
        case .services:
            return ["salon", "barber", "laundry", "dry clean", "repair", "auto", "mechanic", "plumber", "electrician"]
        case .other:
            return []
        }
    }
    
    // MARK: - Auto-categorization
    
    /// Attempt to categorize a merchant based on its name
    static func categorize(merchantName: String) -> MerchantCategory {
        let lowercased = merchantName.lowercased()
        
        for category in MerchantCategory.allCases {
            for keyword in category.keywords {
                if lowercased.contains(keyword) {
                    return category
                }
            }
        }
        
        return .other
    }
}

// MARK: - Core Data Extension

extension Merchant {
    
    /// Computed property to get/set category using the enum
    var category: MerchantCategory {
        get {
            MerchantCategory(rawValue: categoryRaw) ?? .other
        }
        set {
            categoryRaw = newValue.rawValue
        }
    }
}
