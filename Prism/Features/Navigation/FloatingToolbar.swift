//
//  FloatingToolbar.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit

/// Tab identifier for navigation
enum TabIdentifier: String, CaseIterable {
    case transactions = "transactions"
    case analytics = "analytics"
    case settings = "settings"
    case capture = "capture"
    
    var symbolName: String {
        switch self {
        case .transactions: return "list.bullet.rectangle.portrait"
        case .analytics: return "chart.bar.xaxis"
        case .settings: return "gearshape"
        case .capture: return "camera.viewfinder"
        }
    }
    
    var title: String {
        switch self {
        case .transactions: return "Transactions"
        case .analytics: return "Analytics"
        case .settings: return "Settings"
        case .capture: return "Capture"
        }
    }
}

/// Minimalist floating toolbar - "Floating Card" aesthetic
/// Paper-like, clean, with subtle shadow
final class FloatingToolbar: UIView {
    
    // MARK: - Constants
    
    private enum Constants {
        static let barHeight: CGFloat = 56
        static let cornerRadius: CGFloat = 24
        static let bottomOffset: CGFloat = 16
        static let horizontalPadding: CGFloat = 20
        static let iconSize: CGFloat = 22
        static let buttonSize: CGFloat = 44
        static let borderWidth: CGFloat = 1
    }
    
    // MARK: - Properties
    
    var onTabSelected: ((TabIdentifier) -> Void)?
    
    private(set) var selectedTab: TabIdentifier = .transactions {
        didSet {
            updateSelection()
        }
    }
    
    private var tabButtons: [TabIdentifier: UIButton] = [:]
    
    // MARK: - UI Components
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        return view
    }()
    
    private let leftStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.distribution = .equalSpacing
        return stack
    }()
    
    private lazy var captureButton: UIButton = {
        let button = createTabButton(for: .capture)
        return button
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .clear
        
        // Add background with corner radius
        addSubview(backgroundView)
        backgroundView.layer.cornerRadius = Constants.cornerRadius
        backgroundView.clipsToBounds = true
        
        // 1px solid border - crisp paper card edge
        layer.cornerRadius = Constants.cornerRadius
        layer.borderWidth = Constants.borderWidth
        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
        
        // Soft, physical floating shadow
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.05
        
        // Create main tab buttons
        let mainTabs: [TabIdentifier] = [.transactions, .analytics, .settings]
        for tab in mainTabs {
            let button = createTabButton(for: tab)
            tabButtons[tab] = button
            leftStack.addArrangedSubview(button)
        }
        
        tabButtons[.capture] = captureButton
        
        // Add to view
        addSubview(leftStack)
        addSubview(captureButton)
        
        setupConstraints()
        updateSelection()
    }
    
    private func setupConstraints() {
        backgroundView.enableAutoLayout()
        leftStack.enableAutoLayout()
        captureButton.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            // Background fills entire view
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Left stack
            leftStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalPadding),
            leftStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Capture button on far right
            captureButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.horizontalPadding),
            captureButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize),
            captureButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize)
        ])
    }
    
    private func createTabButton(for tab: TabIdentifier) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: tab.symbolName)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: Constants.iconSize,
            weight: .medium
        )
        // Default to inactive grey
        config.baseForegroundColor = .secondaryLabel
        
        let button = UIButton(configuration: config)
        button.tag = TabIdentifier.allCases.firstIndex(of: tab) ?? 0
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        
        button.setSize(width: Constants.buttonSize, height: Constants.buttonSize)
        
        return button
    }
    
    // MARK: - Actions
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        guard let tab = TabIdentifier.allCases[safe: sender.tag] else { return }
        selectedTab = tab
        onTabSelected?(tab)
    }
    
    // MARK: - Selection State
    
    private func updateSelection() {
        for (tab, button) in tabButtons {
            let isSelected = (tab == selectedTab)
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                // Clean monochrome state change - no glows
                button.configuration?.baseForegroundColor = isSelected
                    ? .label                    // Dark charcoal/black
                    : .secondaryLabel           // Light grey
            }
        }
    }
    
    // MARK: - Public API
    
    func selectTab(_ tab: TabIdentifier) {
        guard tab != selectedTab else { return }
        selectedTab = tab
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: Constants.cornerRadius).cgPath
    }
    
    // MARK: - Static Factory
    
    static var preferredHeight: CGFloat { Constants.barHeight }
    static var preferredBottomOffset: CGFloat { Constants.bottomOffset }
}

// MARK: - Safe Array Subscript

private extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Legacy alias for compatibility

typealias LiquidGlassBar = FloatingToolbar
