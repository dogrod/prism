//
//  AnalyticsViewController.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit

/// Analytics view controller for displaying spending insights and charts
final class AnalyticsViewController: BaseViewController {
    
    // MARK: - UI Components
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chart.bar.xaxis")
        imageView.tintColor = PrismTheme.Colors.textSecondary
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)
        return imageView
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Spending insights coming soon"
        label.font = PrismTheme.Fonts.body
        label.textColor = PrismTheme.Colors.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [iconImageView, placeholderLabel])
        stack.axis = .vertical
        stack.spacing = PrismTheme.Spacing.md
        stack.alignment = .center
        return stack
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Analytics"
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = PrismTheme.Colors.background
        
        view.addSubview(contentStack)
        contentStack.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
    }
}
