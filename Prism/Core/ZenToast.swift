//
//  ZenToast.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/29.
//

import UIKit

/// A capsule-shaped toast notification with "View" action
final class ZenToast: UIView {
    
    // MARK: - Callback
    
    var onViewTapped: (() -> Void)?
    
    // MARK: - UI Components
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()
    
    private let checkmarkIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = .systemGreen
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        return imageView
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Receipt Saved"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .white
        return label
    }()
    
    private lazy var viewButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "View"
        config.baseForegroundColor = PrismTheme.Colors.accent
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.systemFont(ofSize: 15, weight: .bold)
            return attributes
        }
        
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(viewButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Capsule background
        backgroundColor = .label
        layer.cornerRadius = 25
        
        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)
        
        // Content
        addSubview(contentStack)
        contentStack.addArrangedSubview(checkmarkIcon)
        contentStack.addArrangedSubview(messageLabel)
        contentStack.addArrangedSubview(viewButton)
        
        contentStack.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 50),
            
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func viewButtonTapped() {
        onViewTapped?()
    }
    
    // MARK: - Show/Hide Animation
    
    /// Show toast with slide-up animation
    func show(in view: UIView, bottomOffset: CGFloat = 120, duration: TimeInterval = 4.0) {
        self.enableAutoLayout()
        view.addSubview(self)
        
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomOffset)
        ])
        
        // Start off-screen
        transform = CGAffineTransform(translationX: 0, y: 100)
        alpha = 0
        
        // Slide up
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.transform = .identity
            self.alpha = 1
        }
        
        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.hide()
        }
    }
    
    /// Hide toast with slide-down animation
    func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.transform = CGAffineTransform(translationX: 0, y: 100)
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}
