//
//  BaseViewController.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/29.
//

import UIKit

/// Base view controller with unified "Zen" header styling
/// Inherit from this for consistent navigation bar appearance across tabs
class BaseViewController: UIViewController {
    
    // MARK: - Colors
    
    /// The standard Zen background color (#F7F7F5)
    static let zenBackgroundColor = UIColor(hex: "#F7F7F5") ?? UIColor.systemBackground
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Self.zenBackgroundColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Force re-apply nav bar style every time view appears
        // This fixes the "ghost title" bug where text turns white on tab switches
        forceApplyNavigationBarStyle()
    }
    
    // MARK: - Navigation Bar Configuration
    
    /// Force apply navigation bar style - called every viewWillAppear to prevent ghost titles
    func forceApplyNavigationBarStyle() {
        guard let navigationController = navigationController else { return }
        
        // Preserve existing title - only fallback to tabBarItem if truly empty
        // Note: self.title and navigationItem.title are synced, but check both for safety
        let currentTitle = navigationItem.title ?? self.title
        if currentTitle?.isEmpty ?? true {
            // Try tabBarItem as fallback (works for non-nav-wrapped VCs)
            if let tabTitle = tabBarItem.title, !tabTitle.isEmpty {
                navigationItem.title = tabTitle
            }
        }
        
        // iOS 26: largeTitle is now a SEPARATE property from title
        // Must explicitly set both for large titles to display correctly after tab switches
        if #available(iOS 26.0, *) {
            let titleToUse = navigationItem.title ?? self.title ?? ""
            navigationItem.largeTitle = titleToUse
        }
        
        // Enable large titles
        navigationController.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        // Create unified appearance with explicit colors
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Background: Zen warm white
        appearance.backgroundColor = Self.zenBackgroundColor
        
        // Remove shadow line
        appearance.shadowColor = nil
        appearance.shadowImage = UIImage()
        
        // CRUCIAL: Force black text for large titles
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        // CRUCIAL: Force black text for standard titles
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        // Apply to ALL appearance states (fixes ghost title on transitions)
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        
        // Also set on navigationItem for per-VC override support
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        
        // Safety net: Force tint color for back buttons and interactive elements
        navigationController.navigationBar.tintColor = .label
    }
}
