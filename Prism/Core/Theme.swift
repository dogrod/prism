//
//  Theme.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit

// MARK: - Prism Theme

enum PrismTheme {
    
    // MARK: - Colors
    
    enum Colors {
        // Base
        static let background = UIColor(hex: "#121212")
        static let surface = UIColor(hex: "#1E1E1E")
        static let surfaceLight = UIColor(hex: "#2A2A2A")
        
        // Accent
        static let cyan = UIColor(hex: "#00D4FF")
        static let purple = UIColor(hex: "#A855F7")
        static let neonGreen = UIColor(hex: "#00FF88")
        static let electricBlue = UIColor(hex: "#0066FF")
        
        // Text
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(white: 0.7, alpha: 1.0)
        static let textMuted = UIColor(white: 0.5, alpha: 1.0)
        
        // Semantic
        static let success = UIColor(hex: "#00FF88")
        static let error = UIColor(hex: "#FF4757")
        static let warning = UIColor(hex: "#FFA502")
        
        // Border
        static let borderLight = UIColor.white.withAlphaComponent(0.15)
        static let borderMedium = UIColor.white.withAlphaComponent(0.25)
        
        // Gradients
        static let gradientCyan = [cyan.cgColor, electricBlue.cgColor]
        static let gradientPurple = [purple.cgColor, cyan.cgColor]
    }
    
    // MARK: - Fonts
    
    enum Fonts {
        static let title = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let headline = UIFont.systemFont(ofSize: 18, weight: .semibold)
        static let body = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let caption = UIFont.systemFont(ofSize: 13, weight: .medium)
        static let mono = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        
        static let logo: UIFont = {
            let font = UIFont.systemFont(ofSize: 22, weight: .bold)
            return font
        }()
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    
    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 28
    }
}

// MARK: - UIColor Hex Extension

extension UIColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - Gradient Layer Factory

extension CAGradientLayer {
    static func prismGradient(colors: [CGColor], horizontal: Bool = true) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = colors
        if horizontal {
            layer.startPoint = CGPoint(x: 0, y: 0.5)
            layer.endPoint = CGPoint(x: 1, y: 0.5)
        } else {
            layer.startPoint = CGPoint(x: 0.5, y: 0)
            layer.endPoint = CGPoint(x: 0.5, y: 1)
        }
        return layer
    }
}

// MARK: - Glassmorphism View

class GlassView: UIView {
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor(white: 0.1, alpha: 0.6)
        layer.cornerRadius = PrismTheme.Radius.large
        layer.borderWidth = 1
        layer.borderColor = PrismTheme.Colors.borderLight.cgColor
        clipsToBounds = true
        
        insertSubview(blurView, at: 0)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - Gradient Button

class GradientButton: UIButton {
    
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }
    
    private func setupGradient() {
        gradientLayer.colors = PrismTheme.Colors.gradientCyan
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = PrismTheme.Radius.pill
        layer.insertSublayer(gradientLayer, at: 0)
        
        // Shadow
        layer.shadowColor = PrismTheme.Colors.electricBlue.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.shadowOpacity = 0.4
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    func setGradientColors(_ colors: [CGColor]) {
        gradientLayer.colors = colors
    }
}

// MARK: - Pulsing Border View

class PortalView: UIView {
    
    private let borderLayer = CAShapeLayer()
    private var pulseAnimation: CABasicAnimation?
    
    var isAnimating: Bool = false {
        didSet {
            if isAnimating {
                startPulse()
            } else {
                stopPulse()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = PrismTheme.Colors.surface
        layer.cornerRadius = PrismTheme.Radius.xl
        clipsToBounds = false
        
        // Border
        layer.borderWidth = 1
        layer.borderColor = PrismTheme.Colors.borderMedium.cgColor
        
        // Glow shadow
        layer.shadowColor = PrismTheme.Colors.cyan.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = 15
        layer.shadowOpacity = 0.3
    }
    
    private func startPulse() {
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = 0.3
        animation.toValue = 0.7
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "pulse")
        
        let borderAnimation = CABasicAnimation(keyPath: "borderColor")
        borderAnimation.fromValue = PrismTheme.Colors.borderMedium.cgColor
        borderAnimation.toValue = PrismTheme.Colors.cyan.cgColor
        borderAnimation.duration = 0.8
        borderAnimation.autoreverses = true
        borderAnimation.repeatCount = .infinity
        layer.add(borderAnimation, forKey: "borderPulse")
    }
    
    private func stopPulse() {
        layer.removeAnimation(forKey: "pulse")
        layer.removeAnimation(forKey: "borderPulse")
        layer.shadowOpacity = 0.3
        layer.borderColor = PrismTheme.Colors.borderMedium.cgColor
    }
}
