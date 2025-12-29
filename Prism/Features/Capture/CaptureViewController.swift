//
//  CaptureViewController.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit
import Combine

final class CaptureViewController: UIViewController {
    
    // MARK: - Dependencies
    
    private let viewModel: CaptureViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    
    private lazy var ambientGradientView: UIView = {
        let view = UIView()
        view.alpha = 0.6
        return view
    }()
    
    private let ambientGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            PrismTheme.Colors.cyan.withAlphaComponent(0.4).cgColor,
            PrismTheme.Colors.purple.withAlphaComponent(0.2).cgColor,
            UIColor.clear.cgColor
        ]
        layer.locations = [0, 0.5, 1]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }()
    
    // Custom Navigation Bar
    private lazy var customNavBar: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        return stack
    }()
    
    private lazy var logoLabel: UILabel = {
        let label = UILabel()
        let text = "PRISM"
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.kern, value: 4.0, range: NSRange(location: 0, length: text.count))
        label.attributedText = attributedString
        label.font = PrismTheme.Fonts.logo
        label.textColor = PrismTheme.Colors.textPrimary
        return label
    }()
    
    private lazy var modelSelectorButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = ModelManager.shared.currentModel.shortName
        config.image = UIImage(systemName: "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 6
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        config.baseForegroundColor = PrismTheme.Colors.textPrimary
        config.baseBackgroundColor = PrismTheme.Colors.surfaceLight
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 12)
        
        let button = UIButton(configuration: config)
        button.showsMenuAsPrimaryAction = true
        button.menu = createModelMenu()
        return button
    }()
    
    private lazy var historyButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "clock.arrow.circlepath")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        config.baseForegroundColor = PrismTheme.Colors.textSecondary
        
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(historyButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // Scanner Portal
    private lazy var portalView: PortalView = {
        let view = PortalView()
        return view
    }()
    
    private lazy var receiptImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.image = UIImage(systemName: "viewfinder")
        imageView.tintColor = PrismTheme.Colors.textMuted
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .ultraLight)
        return imageView
    }()
    
    private lazy var portalHintLabel: UILabel = {
        let label = UILabel()
        label.text = "TAP TO SCAN"
        label.font = PrismTheme.Fonts.caption
        label.textColor = PrismTheme.Colors.textMuted
        label.textAlignment = .center
        
        let attributedString = NSMutableAttributedString(string: "TAP TO SCAN")
        attributedString.addAttribute(.kern, value: 2.0, range: NSRange(location: 0, length: 11))
        label.attributedText = attributedString
        return label
    }()
    
    // Status
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = PrismTheme.Fonts.body
        label.textAlignment = .center
        label.textColor = PrismTheme.Colors.textSecondary
        label.text = "Ready to scan"
        return label
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = PrismTheme.Colors.cyan
        return indicator
    }()
    
    // Action Button
    private lazy var scanButton: GradientButton = {
        let button = GradientButton()
        
        let title = "SCAN RECEIPT"
        let attributedString = NSMutableAttributedString(string: title)
        attributedString.addAttribute(.kern, value: 2.0, range: NSRange(location: 0, length: title.count))
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16, weight: .bold), range: NSRange(location: 0, length: title.count))
        attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: title.count))
        
        button.setAttributedTitle(attributedString, for: .normal)
        button.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var resetButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Reset"
        config.image = UIImage(systemName: "arrow.counterclockwise")
        config.imagePadding = 6
        config.baseForegroundColor = PrismTheme.Colors.textSecondary
        
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    // Result Card
    private lazy var resultCard: GlassView = {
        let view = GlassView()
        view.alpha = 0
        view.transform = CGAffineTransform(translationX: 0, y: 50)
        return view
    }()
    
    private lazy var resultTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "ANALYSIS RESULT"
        label.font = PrismTheme.Fonts.caption
        label.textColor = PrismTheme.Colors.cyan
        
        let attributedString = NSMutableAttributedString(string: "ANALYSIS RESULT")
        attributedString.addAttribute(.kern, value: 1.5, range: NSRange(location: 0, length: 15))
        label.attributedText = attributedString
        return label
    }()
    
    private lazy var resultTextView: UITextView = {
        let textView = UITextView()
        textView.font = PrismTheme.Fonts.mono
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.textColor = PrismTheme.Colors.neonGreen
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        return textView
    }()
    
    // MARK: - Initialization
    
    init(viewModel: CaptureViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
        setupGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ambientGradientLayer.frame = CGRect(x: -100, y: -100, width: 400, height: 400)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = PrismTheme.Colors.background
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Ambient glow
        ambientGradientView.layer.addSublayer(ambientGradientLayer)
        view.addSubview(ambientGradientView)
        
        // Custom nav bar
        customNavBar.addArrangedSubview(logoLabel)
        customNavBar.addArrangedSubview(modelSelectorButton)
        customNavBar.addArrangedSubview(historyButton)
        view.addSubview(customNavBar)
        
        // Portal
        portalView.addSubview(receiptImageView)
        portalView.addSubview(portalHintLabel)
        view.addSubview(portalView)
        
        // Status area
        view.addSubview(statusLabel)
        view.addSubview(activityIndicator)
        
        // Action buttons
        view.addSubview(scanButton)
        view.addSubview(resetButton)
        
        // Result card
        resultCard.addSubview(resultTitleLabel)
        resultCard.addSubview(resultTextView)
        view.addSubview(resultCard)
    }
    
    private func setupConstraints() {
        let padding = PrismTheme.Spacing.md
        let safeArea = view.safeAreaLayoutGuide
        
        ambientGradientView.enableAutoLayout()
        customNavBar.enableAutoLayout()
        portalView.enableAutoLayout()
        receiptImageView.enableAutoLayout()
        portalHintLabel.enableAutoLayout()
        statusLabel.enableAutoLayout()
        activityIndicator.enableAutoLayout()
        scanButton.enableAutoLayout()
        resetButton.enableAutoLayout()
        resultCard.enableAutoLayout()
        resultTitleLabel.enableAutoLayout()
        resultTextView.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            // Ambient gradient
            ambientGradientView.topAnchor.constraint(equalTo: view.topAnchor),
            ambientGradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ambientGradientView.widthAnchor.constraint(equalToConstant: 400),
            ambientGradientView.heightAnchor.constraint(equalToConstant: 400),
            
            // Custom nav bar
            customNavBar.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: padding),
            customNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            customNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            customNavBar.heightAnchor.constraint(equalToConstant: 44),
            
            // Portal
            portalView.topAnchor.constraint(equalTo: customNavBar.bottomAnchor, constant: PrismTheme.Spacing.lg),
            portalView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            portalView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            portalView.heightAnchor.constraint(equalToConstant: 280),
            
            // Image inside portal
            receiptImageView.topAnchor.constraint(equalTo: portalView.topAnchor, constant: 12),
            receiptImageView.leadingAnchor.constraint(equalTo: portalView.leadingAnchor, constant: 12),
            receiptImageView.trailingAnchor.constraint(equalTo: portalView.trailingAnchor, constant: -12),
            receiptImageView.bottomAnchor.constraint(equalTo: portalHintLabel.topAnchor, constant: -8),
            
            // Portal hint
            portalHintLabel.bottomAnchor.constraint(equalTo: portalView.bottomAnchor, constant: -16),
            portalHintLabel.centerXAnchor.constraint(equalTo: portalView.centerXAnchor),
            
            // Status
            statusLabel.topAnchor.constraint(equalTo: portalView.bottomAnchor, constant: PrismTheme.Spacing.lg),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            
            // Activity indicator
            activityIndicator.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),
            
            // Scan button
            scanButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: PrismTheme.Spacing.lg),
            scanButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            scanButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            scanButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Reset button
            resetButton.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: PrismTheme.Spacing.sm),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Result card
            resultCard.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: PrismTheme.Spacing.md),
            resultCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            resultCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            resultCard.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -padding),
            
            // Result title
            resultTitleLabel.topAnchor.constraint(equalTo: resultCard.topAnchor, constant: 16),
            resultTitleLabel.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 16),
            
            // Result text
            resultTextView.topAnchor.constraint(equalTo: resultTitleLabel.bottomAnchor, constant: 8),
            resultTextView.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 8),
            resultTextView.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -8),
            resultTextView.bottomAnchor.constraint(equalTo: resultCard.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupBindings() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
        
        viewModel.$selectedImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                if let image = image {
                    self?.receiptImageView.image = image
                    self?.receiptImageView.contentMode = .scaleAspectFit
                    self?.portalHintLabel.isHidden = true
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(portalTapped))
        portalView.addGestureRecognizer(tapGesture)
        portalView.isUserInteractionEnabled = true
    }
    
    // MARK: - Model Menu
    
    private func createModelMenu() -> UIMenu {
        let actions = AIModel.allCases.map { model in
            UIAction(
                title: model.displayName,
                subtitle: model.description,
                state: model == ModelManager.shared.currentModel ? .on : .off
            ) { [weak self] _ in
                ModelManager.shared.currentModel = model
                self?.updateModelButton()
            }
        }
        
        return UIMenu(title: "Select Model", children: actions)
    }
    
    private func updateModelButton() {
        modelSelectorButton.configuration?.title = ModelManager.shared.currentModel.shortName
        modelSelectorButton.menu = createModelMenu()
    }
    
    // MARK: - State Handling
    
    private func handleStateChange(_ state: CaptureState) {
        switch state {
        case .idle:
            activityIndicator.stopAnimating()
            scanButton.isEnabled = true
            resetButton.isHidden = true
            portalView.isAnimating = false
            statusLabel.text = "Ready to scan"
            statusLabel.textColor = PrismTheme.Colors.textSecondary
            
            receiptImageView.image = UIImage(systemName: "viewfinder")
            receiptImageView.tintColor = PrismTheme.Colors.textMuted
            receiptImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .ultraLight)
            portalHintLabel.isHidden = false
            
            hideResultCard()
            
        case .scanning:
            activityIndicator.startAnimating()
            scanButton.isEnabled = false
            portalView.isAnimating = true
            statusLabel.text = "Scanning receipt..."
            statusLabel.textColor = PrismTheme.Colors.cyan
            hideResultCard()
            
        case .analyzing:
            statusLabel.text = "Analyzing with AI..."
            statusLabel.textColor = PrismTheme.Colors.purple
            
        case .success:
            activityIndicator.stopAnimating()
            scanButton.isEnabled = true
            resetButton.isHidden = false
            portalView.isAnimating = false
            statusLabel.text = "Analysis complete"
            statusLabel.textColor = PrismTheme.Colors.success
            
            resultTextView.text = viewModel.resultJSON
            showResultCard()
            
        case .error(let message):
            activityIndicator.stopAnimating()
            scanButton.isEnabled = true
            resetButton.isHidden = false
            portalView.isAnimating = false
            statusLabel.text = message
            statusLabel.textColor = PrismTheme.Colors.error
            hideResultCard()
        }
    }
    
    private func showResultCard() {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.resultCard.alpha = 1
            self.resultCard.transform = .identity
        }
    }
    
    private func hideResultCard() {
        UIView.animate(withDuration: 0.3) {
            self.resultCard.alpha = 0
            self.resultCard.transform = CGAffineTransform(translationX: 0, y: 50)
        }
    }
    
    // MARK: - Actions
    
    @objc private func scanButtonTapped() {
        presentImagePicker()
    }
    
    @objc private func portalTapped() {
        presentImagePicker()
    }
    
    @objc private func resetButtonTapped() {
        viewModel.reset()
    }
    
    @objc private func historyButtonTapped() {
        let historyVC = HistoryListViewController()
        let navController = UINavigationController(rootViewController: historyVC)
        navController.modalPresentationStyle = .pageSheet
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
    
    private func presentImagePicker() {
        let alertController = UIAlertController(
            title: "Select Image Source",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                self?.showImagePicker(sourceType: .camera)
            })
        }
        
        alertController.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.showImagePicker(sourceType: .photoLibrary)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = scanButton
            popover.sourceRect = scanButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    private func showImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension CaptureViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else { return }
        viewModel.processImage(image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
