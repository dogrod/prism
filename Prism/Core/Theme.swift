//
//  Theme.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit

// MARK: - Prism Theme: "Digital Zen"
// Japanese Minimalist / Notion-inspired aesthetic
// Keywords: Zen, Paper-like, Matte, High Contrast, Typography-driven, Clean

enum PrismTheme {
    
    // MARK: - Colors (Monochromatic "Notion" Palette)
    
    enum Colors {
        // Background - Off-White / Warm Paper
        static let background = UIColor(hex: "#F7F7F5")
        static let backgroundPure = UIColor.white
        
        // Surface - Cards/Toolbar
        static let surface = UIColor.white
        static let surfaceElevated = UIColor.white.withAlphaComponent(0.98)
        
        // Text - Ink & Stone
        static let textPrimary = UIColor(hex: "#37352F")      // Notion Ink Black
        static let textSecondary = UIColor(hex: "#9B9A97")    // Stone Grey
        static let textMuted = UIColor(hex: "#B4B4B4")
        
        // Accent - Solid Charcoal (Monochrome focus)
        static let accent = UIColor(hex: "#2F2F2F")
        static let accentSubtle = UIColor(hex: "#787774")
        
        // Semantic
        static let success = UIColor(hex: "#2E7D32")          // Muted Green
        static let error = UIColor(hex: "#C62828")            // Muted Red
        static let warning = UIColor(hex: "#EF6C00")          // Muted Orange
        
        // Border - Crisp thin lines
        static let border = UIColor(hex: "#E0E0E0")
        static let borderLight = UIColor.lightGray.withAlphaComponent(0.2)
        static let borderMedium = UIColor.lightGray.withAlphaComponent(0.3)
        
        // Icon states
        static let iconActive = UIColor.label
        static let iconInactive = UIColor.secondaryLabel
    }
    
    // MARK: - Fonts (SF Pro + NY Serif for titles)
    
    enum Fonts {
        // Editorial titles using New York Serif
        static let largeTitle: UIFont = {
            if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
                .withDesign(.serif) {
                return UIFont(descriptor: descriptor, size: 34)
            }
            return UIFont.systemFont(ofSize: 34, weight: .bold)
        }()
        
        static let title: UIFont = {
            if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title1)
                .withDesign(.serif) {
                return UIFont(descriptor: descriptor, size: 28)
            }
            return UIFont.systemFont(ofSize: 28, weight: .bold)
        }()
        
        // UI elements use SF Pro
        static let headline = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let body = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let callout = UIFont.systemFont(ofSize: 15, weight: .regular)
        static let caption = UIFont.systemFont(ofSize: 13, weight: .regular)
        static let captionMedium = UIFont.systemFont(ofSize: 13, weight: .medium)
        static let mono = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        
        static let logo: UIFont = {
            if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
                .withDesign(.serif) {
                return UIFont(descriptor: descriptor, size: 20)
            }
            return UIFont.systemFont(ofSize: 20, weight: .semibold)
        }()
    }
    
    // MARK: - Spacing (Generous "Zen" whitespace)
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let section: CGFloat = 64        // Large section breaks
    }
    
    // MARK: - Corner Radius
    
    enum Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
        static let xl: CGFloat = 18
        static let pill: CGFloat = 24
    }
    
    // MARK: - Shadows (Soft, diffused, physical)
    
    enum Shadow {
        static func floating(for layer: CALayer) {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.shadowRadius = 10
            layer.shadowOpacity = 0.05
        }
        
        static func card(for layer: CALayer) {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 1)
            layer.shadowRadius = 4
            layer.shadowOpacity = 0.04
        }
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

// MARK: - Minimalist Card View

class CardView: UIView {
    
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
        layer.cornerRadius = PrismTheme.Radius.large
        layer.borderWidth = 1
        layer.borderColor = PrismTheme.Colors.border.cgColor
        
        // Subtle shadow
        PrismTheme.Shadow.card(for: layer)
        clipsToBounds = false
    }
}

// MARK: - Primary Button (Minimal)

class PrimaryButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        backgroundColor = PrismTheme.Colors.textPrimary
        setTitleColor(.white, for: .normal)
        titleLabel?.font = PrismTheme.Fonts.headline
        layer.cornerRadius = PrismTheme.Radius.medium
        
        // Subtle shadow
        PrismTheme.Shadow.floating(for: layer)
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.alpha = self.isHighlighted ? 0.8 : 1.0
                self.transform = self.isHighlighted 
                    ? CGAffineTransform(scaleX: 0.98, y: 0.98) 
                    : .identity
            }
        }
    }
}

// MARK: - Content Card View (for results/data display)

class ContentCardView: UIView {
    
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
        layer.cornerRadius = PrismTheme.Radius.large
        layer.borderWidth = 1
        layer.borderColor = PrismTheme.Colors.border.cgColor
        clipsToBounds = true
    }
}

// MARK: - Scan Portal View (Minimal version)

class PortalView: UIView {
    
    var isAnimating: Bool = false {
        didSet {
            if isAnimating {
                startIndicator()
            } else {
                stopIndicator()
            }
        }
    }
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = PrismTheme.Colors.textSecondary
        indicator.hidesWhenStopped = true
        return indicator
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
        backgroundColor = PrismTheme.Colors.surface
        layer.cornerRadius = PrismTheme.Radius.xl
        layer.borderWidth = 1
        layer.borderColor = PrismTheme.Colors.border.cgColor
        
        // Soft shadow
        PrismTheme.Shadow.card(for: layer)
        clipsToBounds = false
        
        addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func startIndicator() {
        activityIndicator.startAnimating()
        UIView.animate(withDuration: 0.3) {
            self.layer.borderColor = PrismTheme.Colors.textSecondary.cgColor
        }
    }
    
    private func stopIndicator() {
        activityIndicator.stopAnimating()
        UIView.animate(withDuration: 0.3) {
            self.layer.borderColor = PrismTheme.Colors.border.cgColor
        }
    }
}

// MARK: - Legacy compatibility aliases

typealias GlassView = ContentCardView
typealias GradientButton = PrimaryButton
