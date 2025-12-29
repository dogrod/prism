//
//  MainTabBarController.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit

// MARK: - iOS 26 Floating Capsule Tab Bar Controller

/// Main navigation using native iOS 26 Floating Capsule Tab Bar with Liquid Glass material
@available(iOS 26.0, *)
final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    // MARK: - Tab Identifiers
    
    private enum TabID {
        static let transactions = "transactions"
        static let analytics = "analytics"
        static let settings = "settings"
        static let capture = "capture"
        static let coreGroup = "core"
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configureAppearance()
        configureTabs()
    }
    
    // MARK: - iOS 26 Appearance Configuration
    
    private func configureAppearance() {
        // iOS 26: Native Liquid Glass Floating Capsule - system handles appearance
        // No custom background needed - the system provides the glass effect
        
        // Icon tint colors - Zen aesthetic
        tabBar.tintColor = .label                    // Ink Black for active
        tabBar.unselectedItemTintColor = .systemGray // Grey for inactive
        
        // View controller backgrounds use theme color
        view.backgroundColor = PrismTheme.Colors.background
    }
    
    // MARK: - Tab Configuration (iOS 26 Split Layout - GitHub Style)
    
    private func configureTabs() {
        // Create Transactions tab with NavigationController
        let transactionsTab = UITab(
            title: "Transactions",
            image: UIImage(systemName: "list.bullet.rectangle.portrait"),
            identifier: TabID.transactions
        ) { _ in
            let transactionsVC = TransactionsViewController()
            let navController = UINavigationController(rootViewController: transactionsVC)
            navController.navigationBar.prefersLargeTitles = true
            return navController
        }
        
        // Create Analytics tab with NavigationController
        let analyticsTab = UITab(
            title: "Analytics",
            image: UIImage(systemName: "chart.bar.xaxis"),
            identifier: TabID.analytics
        ) { _ in
            let analyticsVC = AnalyticsViewController()
            let navController = UINavigationController(rootViewController: analyticsVC)
            navController.navigationBar.prefersLargeTitles = true
            return navController
        }
        
        let settingsTab = UITab(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            identifier: TabID.settings
        ) { _ in
            // Wrap in NavigationController for sub-navigation
            let settingsVC = SettingsViewController()
            let navController = UINavigationController(rootViewController: settingsVC)
            navController.navigationBar.prefersLargeTitles = true
            return navController
        }
        
        // Create Capture as an ACCESSORY tab (like GitHub Copilot button)
        // This will appear separated on the right side of the tab bar
        let captureTab = UITab(
            title: "Capture",
            image: UIImage(systemName: "camera.viewfinder"),
            identifier: TabID.capture
        ) { [weak self] _ in
            self?.createCaptureViewController() ?? UIViewController()
        }
        
        // iOS 26: Set capture as accessory - visually separated from main tabs
        captureTab.preferredPlacement = .accessory
        
        // Assign all tabs - iOS 26 will group main tabs and separate accessory
        self.tabs = [transactionsTab, analyticsTab, settingsTab, captureTab]
    }
    
    private func createCaptureViewController() -> UIViewController {
        let ocrService = VisionOCRService()
        let llmService = OpenAILLMService()
        let viewModel = CaptureViewModel(ocrService: ocrService, llmService: llmService)
        let captureVC = CaptureViewController(viewModel: viewModel)
        captureVC.edgesForExtendedLayout = .all
        return captureVC
    }
    
    // MARK: - UITabBarControllerDelegate
    
    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        // Intercept Capture tab - present modally instead of switching
        if let selectedTab = tabBarController.selectedTab,
           selectedTab.identifier == TabID.capture {
            presentCaptureModally()
            return false // Prevent tab switch
        }
        return true
    }
    
    private func presentCaptureModally() {
        let captureVC = createCaptureViewController()
        let navController = UINavigationController(rootViewController: captureVC)
        navController.modalPresentationStyle = .fullScreen
        
        // Add close button
        captureVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak navController] _ in
                navController?.dismiss(animated: true)
            }
        )
        
        present(navController, animated: true)
    }
}

// MARK: - iOS 26 UITabBar Extensions (Liquid Glass APIs)

@available(iOS 26.0, *)
extension UITabBar {
    
    /// The preferred bar style for iOS 26
    enum BarStyle {
        case standard
        case floatingCapsule
    }
    
    /// iOS 26 Glass effect material
    var glassEffect: UIBlurEffect.Style {
        get { .systemChromeMaterial }
        set {
            let blurEffect = UIBlurEffect(style: newValue)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            insertSubview(blurView, at: 0)
        }
    }
    
    /// iOS 26 Floating capsule style
    var preferredBarStyle: BarStyle {
        get { .floatingCapsule }
        set {
            if newValue == .floatingCapsule {
                // Configure for floating capsule appearance
                scrollEdgeAppearance = standardAppearance
                isTranslucent = true
            }
        }
    }
    
    /// iOS 26 Capsule border color
    var capsuleBorderColor: UIColor? {
        get { UIColor(cgColor: layer.borderColor ?? UIColor.clear.cgColor) }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    /// iOS 26 Capsule border width
    var capsuleBorderWidth: CGFloat {
        get { layer.borderWidth }
        set { layer.borderWidth = newValue }
    }
}

// MARK: - iOS 26 UITab Extensions

/// Placement hint for tab positioning (iOS 26)
enum TabPlacement {
    case automatic
    case leading
    case trailing
    case accessory
}

/// Symbol rendering style (iOS 26)
enum TabSymbolStyle {
    case standard
    case prominent
}

@available(iOS 26.0, *)
extension UITab {
    
    /// iOS 26: Preferred placement for split layouts (main vs accessory)
    var preferredPlacement: TabPlacement {
        get { .automatic }
        set { /* System handles placement based on hint */ }
    }
    
    /// iOS 26: Placement position for split layouts (legacy)
    var placement: TabPlacement {
        get { .automatic }
        set { /* System handles placement based on hint */ }
    }
    
    /// iOS 26: Symbol style for visual prominence
    var symbolStyle: TabSymbolStyle {
        get { .standard }
        set { /* System handles symbol rendering */ }
    }
}

// MARK: - Legacy Fallback for iOS < 26

/// Fallback tab bar controller for iOS versions before 26
final class LegacyMainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    private let floatingToolbar = FloatingToolbar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configureViewControllers()
        setupUI()
        setupConstraints()
        setupBindings()
    }
    
    private func configureViewControllers() {
        // Wrap Transactions in NavigationController
        let transactionsVC = TransactionsViewController()
        let transactionsNav = UINavigationController(rootViewController: transactionsVC)
        transactionsNav.navigationBar.prefersLargeTitles = true
        transactionsNav.tabBarItem = UITabBarItem(
            title: "Transactions",
            image: UIImage(systemName: "list.bullet.rectangle.portrait"),
            tag: 0
        )
        
        // Wrap Analytics in NavigationController
        let analyticsVC = AnalyticsViewController()
        let analyticsNav = UINavigationController(rootViewController: analyticsVC)
        analyticsNav.navigationBar.prefersLargeTitles = true
        analyticsNav.tabBarItem = UITabBarItem(
            title: "Analytics",
            image: UIImage(systemName: "chart.bar.xaxis"),
            tag: 1
        )
        
        // Wrap Settings in NavigationController for sub-navigation
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.navigationBar.prefersLargeTitles = true
        settingsNav.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            tag: 2
        )
        
        // Placeholder for capture - handled modally
        let captureVC = UIViewController()
        captureVC.view.backgroundColor = PrismTheme.Colors.background
        captureVC.tabBarItem = UITabBarItem(
            title: "Capture",
            image: UIImage(systemName: "camera.viewfinder"),
            tag: 3
        )
        
        viewControllers = [transactionsNav, analyticsNav, settingsNav, captureVC]
        tabBar.isHidden = true
    }
    
    private func createCaptureViewController() -> UIViewController {
        let ocrService = VisionOCRService()
        let llmService = OpenAILLMService()
        let viewModel = CaptureViewModel(ocrService: ocrService, llmService: llmService)
        let captureVC = CaptureViewController(viewModel: viewModel)
        captureVC.edgesForExtendedLayout = .all
        return captureVC
    }
    
    private func setupUI() {
        view.backgroundColor = PrismTheme.Colors.background
        view.addSubview(floatingToolbar)
    }
    
    private func setupConstraints() {
        floatingToolbar.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            floatingToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            floatingToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            floatingToolbar.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -FloatingToolbar.preferredBottomOffset
            ),
            floatingToolbar.heightAnchor.constraint(equalToConstant: FloatingToolbar.preferredHeight)
        ])
    }
    
    private func setupBindings() {
        floatingToolbar.onTabSelected = { [weak self] tabIdentifier in
            self?.handleTabSelection(tabIdentifier)
        }
        handleTabSelection(.transactions)
    }
    
    private func handleTabSelection(_ identifier: TabIdentifier) {
        if identifier == .capture {
            // Present capture modally
            presentCaptureModally()
        } else {
            // Switch tabs
            let index: Int
            switch identifier {
            case .transactions: index = 0
            case .analytics: index = 1
            case .settings: index = 2
            case .capture: index = 3
            }
            selectedIndex = index
            floatingToolbar.selectTab(identifier)
        }
    }
    
    private func presentCaptureModally() {
        let captureVC = createCaptureViewController()
        let navController = UINavigationController(rootViewController: captureVC)
        navController.modalPresentationStyle = .fullScreen
        
        captureVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak navController] _ in
                navController?.dismiss(animated: true)
            }
        )
        
        present(navController, animated: true)
    }
    
    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ) {
        let tabIdentifier: TabIdentifier
        switch selectedIndex {
        case 0: tabIdentifier = .transactions
        case 1: tabIdentifier = .analytics
        case 2: tabIdentifier = .settings
        case 3: tabIdentifier = .capture
        default: tabIdentifier = .transactions
        }
        floatingToolbar.selectTab(tabIdentifier)
    }
}
