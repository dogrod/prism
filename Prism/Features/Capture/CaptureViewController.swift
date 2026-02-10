//
//  CaptureViewController.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit
import Combine
import AVFoundation
import PhotosUI

// MARK: - Capture UI State

enum CaptureUIState {
    case idle
    case processing
    case success(Transaction)
    case failure(String)
}

// MARK: - Capture View Controller

final class CaptureViewController: UIViewController {
    
    // MARK: - Dependencies
    
    private let viewModel: CaptureViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Camera Properties
    
    private let captureSession = AVCaptureSession()
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "com.prism.camera.session")
    private var cameraPermissionGranted = false
    
    // MARK: - UI State
    
    private var uiState: CaptureUIState = .idle {
        didSet { updateUIState(animated: true) }
    }
    
    // MARK: - Constraint References (for animation)
    
    private var galleryButtonWidthConstraint: NSLayoutConstraint?
    private var shutterButtonLeadingToGalleryConstraint: NSLayoutConstraint?
    private var shutterButtonLeadingToViewConstraint: NSLayoutConstraint?
    
    // MARK: - UI Components - Header
    
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
        config.baseBackgroundColor = PrismTheme.Colors.surfaceElevated
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
    
    // MARK: - UI Components - Viewfinder
    
    private lazy var viewfinderCard: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var cameraPreviewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    // Corner brackets
    private lazy var topLeftBracket = createCornerBracket(corners: [.topLeft])
    private lazy var topRightBracket = createCornerBracket(corners: [.topRight])
    private lazy var bottomLeftBracket = createCornerBracket(corners: [.bottomLeft])
    private lazy var bottomRightBracket = createCornerBracket(corners: [.bottomRight])
    
    // Permission fallback UI
    private lazy var permissionView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.isHidden = true
        
        let lockIcon = UIImageView(image: UIImage(systemName: "lock.fill"))
        lockIcon.tintColor = .systemGray
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)
        
        let button = UIButton(type: .system)
        button.setTitle("Tap to Allow Camera", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        button.addTarget(self, action: #selector(requestCameraPermission), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [lockIcon, button])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        
        view.addSubview(stack)
        stack.enableAutoLayout()
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }()
    
    // Captured image view - shows the actual image being processed (WYSIWYG)
    private lazy var capturedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
    }()
    
    // White processing overlay - indicates scanning in progress
    private lazy var processingOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.alpha = 0
        return view
    }()
    
    // Frozen frame overlay (legacy - kept for camera preview snapshot)
    private lazy var frozenFrameView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        return imageView
    }()
    
    // Error overlay
    private lazy var errorOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.isHidden = true
        
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)
        
        let label = UILabel()
        label.text = "Scan Failed"
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        
        view.addSubview(stack)
        stack.enableAutoLayout()
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }()
    
    // MARK: - UI Components - Action Bar
    
    private lazy var actionBar: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var galleryButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 16
        button.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        button.tintColor = .black
        button.imageView?.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        button.addTarget(self, action: #selector(galleryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var shutterButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.label
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(shutterButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var shutterLabel: UILabel = {
        let label = UILabel()
        label.text = "SCAN RECEIPT"
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        return label
    }()
    
    private lazy var shutterSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    private lazy var shutterIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var shutterStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [shutterSpinner, shutterIcon, shutterLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        return stack
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
        checkCameraPermission()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraPreviewView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCameraSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCameraSession()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = PrismTheme.Colors.background
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Header
        customNavBar.addArrangedSubview(logoLabel)
        customNavBar.addArrangedSubview(modelSelectorButton)
        customNavBar.addArrangedSubview(historyButton)
        view.addSubview(customNavBar)
        
        // Viewfinder
        viewfinderCard.addSubview(cameraPreviewView)
        viewfinderCard.addSubview(frozenFrameView)
        viewfinderCard.addSubview(capturedImageView)  // WYSIWYG layer
        viewfinderCard.addSubview(processingOverlay)  // White overlay for processing
        viewfinderCard.addSubview(permissionView)
        viewfinderCard.addSubview(errorOverlay)
        viewfinderCard.addSubview(topLeftBracket)
        viewfinderCard.addSubview(topRightBracket)
        viewfinderCard.addSubview(bottomLeftBracket)
        viewfinderCard.addSubview(bottomRightBracket)
        view.addSubview(viewfinderCard)
        
        // Action Bar
        shutterButton.addSubview(shutterStack)
        actionBar.addSubview(galleryButton)
        actionBar.addSubview(shutterButton)
        view.addSubview(actionBar)
    }
    
    private func setupConstraints() {
        let padding: CGFloat = 16
        let safeArea = view.safeAreaLayoutGuide
        let tabBarOffset: CGFloat = 100  // Account for floating tab bar
        
        customNavBar.enableAutoLayout()
        viewfinderCard.enableAutoLayout()
        cameraPreviewView.enableAutoLayout()
        frozenFrameView.enableAutoLayout()
        capturedImageView.enableAutoLayout()
        processingOverlay.enableAutoLayout()
        permissionView.enableAutoLayout()
        errorOverlay.enableAutoLayout()
        topLeftBracket.enableAutoLayout()
        topRightBracket.enableAutoLayout()
        bottomLeftBracket.enableAutoLayout()
        bottomRightBracket.enableAutoLayout()
        actionBar.enableAutoLayout()
        galleryButton.enableAutoLayout()
        shutterButton.enableAutoLayout()
        shutterStack.enableAutoLayout()
        
        // Gallery button width constraint (for hiding animation)
        galleryButtonWidthConstraint = galleryButton.widthAnchor.constraint(equalToConstant: 56)
        
        // Shutter button constraints for morphing
        shutterButtonLeadingToGalleryConstraint = shutterButton.leadingAnchor.constraint(equalTo: galleryButton.trailingAnchor, constant: 12)
        shutterButtonLeadingToViewConstraint = shutterButton.leadingAnchor.constraint(equalTo: actionBar.leadingAnchor)
        shutterButtonLeadingToViewConstraint?.isActive = false
        
        let bracketSize: CGFloat = 40
        let bracketInset: CGFloat = 16
        
        NSLayoutConstraint.activate([
            // Header
            customNavBar.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: padding),
            customNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            customNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            customNavBar.heightAnchor.constraint(equalToConstant: 44),
            
            // Viewfinder Card
            viewfinderCard.topAnchor.constraint(equalTo: customNavBar.bottomAnchor, constant: padding),
            viewfinderCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            viewfinderCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            viewfinderCard.bottomAnchor.constraint(equalTo: actionBar.topAnchor, constant: -padding),
            
            // Camera preview fills viewfinder
            cameraPreviewView.topAnchor.constraint(equalTo: viewfinderCard.topAnchor),
            cameraPreviewView.leadingAnchor.constraint(equalTo: viewfinderCard.leadingAnchor),
            cameraPreviewView.trailingAnchor.constraint(equalTo: viewfinderCard.trailingAnchor),
            cameraPreviewView.bottomAnchor.constraint(equalTo: viewfinderCard.bottomAnchor),
            
            // Frozen frame overlay (legacy)
            frozenFrameView.topAnchor.constraint(equalTo: viewfinderCard.topAnchor),
            frozenFrameView.leadingAnchor.constraint(equalTo: viewfinderCard.leadingAnchor),
            frozenFrameView.trailingAnchor.constraint(equalTo: viewfinderCard.trailingAnchor),
            frozenFrameView.bottomAnchor.constraint(equalTo: viewfinderCard.bottomAnchor),
            
            // Captured image view (WYSIWYG)
            capturedImageView.topAnchor.constraint(equalTo: viewfinderCard.topAnchor),
            capturedImageView.leadingAnchor.constraint(equalTo: viewfinderCard.leadingAnchor),
            capturedImageView.trailingAnchor.constraint(equalTo: viewfinderCard.trailingAnchor),
            capturedImageView.bottomAnchor.constraint(equalTo: viewfinderCard.bottomAnchor),
            
            // Processing overlay (white)
            processingOverlay.topAnchor.constraint(equalTo: viewfinderCard.topAnchor),
            processingOverlay.leadingAnchor.constraint(equalTo: viewfinderCard.leadingAnchor),
            processingOverlay.trailingAnchor.constraint(equalTo: viewfinderCard.trailingAnchor),
            processingOverlay.bottomAnchor.constraint(equalTo: viewfinderCard.bottomAnchor),
            
            // Permission view
            permissionView.topAnchor.constraint(equalTo: viewfinderCard.topAnchor),
            permissionView.leadingAnchor.constraint(equalTo: viewfinderCard.leadingAnchor),
            permissionView.trailingAnchor.constraint(equalTo: viewfinderCard.trailingAnchor),
            permissionView.bottomAnchor.constraint(equalTo: viewfinderCard.bottomAnchor),
            
            // Error overlay
            errorOverlay.topAnchor.constraint(equalTo: viewfinderCard.topAnchor),
            errorOverlay.leadingAnchor.constraint(equalTo: viewfinderCard.leadingAnchor),
            errorOverlay.trailingAnchor.constraint(equalTo: viewfinderCard.trailingAnchor),
            errorOverlay.bottomAnchor.constraint(equalTo: viewfinderCard.bottomAnchor),
            
            // Corner brackets
            topLeftBracket.topAnchor.constraint(equalTo: viewfinderCard.topAnchor, constant: bracketInset),
            topLeftBracket.leadingAnchor.constraint(equalTo: viewfinderCard.leadingAnchor, constant: bracketInset),
            topLeftBracket.widthAnchor.constraint(equalToConstant: bracketSize),
            topLeftBracket.heightAnchor.constraint(equalToConstant: bracketSize),
            
            topRightBracket.topAnchor.constraint(equalTo: viewfinderCard.topAnchor, constant: bracketInset),
            topRightBracket.trailingAnchor.constraint(equalTo: viewfinderCard.trailingAnchor, constant: -bracketInset),
            topRightBracket.widthAnchor.constraint(equalToConstant: bracketSize),
            topRightBracket.heightAnchor.constraint(equalToConstant: bracketSize),
            
            bottomLeftBracket.bottomAnchor.constraint(equalTo: viewfinderCard.bottomAnchor, constant: -bracketInset),
            bottomLeftBracket.leadingAnchor.constraint(equalTo: viewfinderCard.leadingAnchor, constant: bracketInset),
            bottomLeftBracket.widthAnchor.constraint(equalToConstant: bracketSize),
            bottomLeftBracket.heightAnchor.constraint(equalToConstant: bracketSize),
            
            bottomRightBracket.bottomAnchor.constraint(equalTo: viewfinderCard.bottomAnchor, constant: -bracketInset),
            bottomRightBracket.trailingAnchor.constraint(equalTo: viewfinderCard.trailingAnchor, constant: -bracketInset),
            bottomRightBracket.widthAnchor.constraint(equalToConstant: bracketSize),
            bottomRightBracket.heightAnchor.constraint(equalToConstant: bracketSize),
            
            // Action Bar
            actionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            actionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            actionBar.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -tabBarOffset + 60),
            actionBar.heightAnchor.constraint(equalToConstant: 56),
            
            // Gallery Button
            galleryButton.leadingAnchor.constraint(equalTo: actionBar.leadingAnchor),
            galleryButton.topAnchor.constraint(equalTo: actionBar.topAnchor),
            galleryButton.bottomAnchor.constraint(equalTo: actionBar.bottomAnchor),
            galleryButtonWidthConstraint!,
            
            // Shutter Button
            shutterButtonLeadingToGalleryConstraint!,
            shutterButton.trailingAnchor.constraint(equalTo: actionBar.trailingAnchor),
            shutterButton.topAnchor.constraint(equalTo: actionBar.topAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: actionBar.bottomAnchor),
            
            // Shutter stack centered
            shutterStack.centerXAnchor.constraint(equalTo: shutterButton.centerXAnchor),
            shutterStack.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleViewModelState(state)
            }
            .store(in: &cancellables)
        
        viewModel.$savedTransaction
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] transaction in
                self?.uiState = .success(transaction)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Camera Setup
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
            setupCamera()
        case .notDetermined:
            permissionView.isHidden = false
        case .denied, .restricted:
            permissionView.isHidden = false
        @unknown default:
            permissionView.isHidden = false
        }
    }
    
    @objc private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.cameraPermissionGranted = true
                    self?.permissionView.isHidden = true
                    self?.setupCamera()
                    self?.startCameraSession()
                } else {
                    // Open settings
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            }
        }
    }
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo
            
            // Add video input
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  self.captureSession.canAddInput(input) else {
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addInput(input)
            
            // Add photo output
            let output = AVCapturePhotoOutput()
            guard self.captureSession.canAddOutput(output) else {
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addOutput(output)
            self.photoOutput = output
            
            self.captureSession.commitConfiguration()
            
            // Setup preview layer on main thread
            DispatchQueue.main.async {
                let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.frame = self.cameraPreviewView.bounds
                self.cameraPreviewView.layer.addSublayer(previewLayer)
                self.previewLayer = previewLayer
                
                self.permissionView.isHidden = true
            }
        }
    }
    
    private func startCameraSession() {
        guard cameraPermissionGranted else { return }
        sessionQueue.async { [weak self] in
            if self?.captureSession.isRunning == false {
                self?.captureSession.startRunning()
            }
        }
    }
    
    private func stopCameraSession() {
        sessionQueue.async { [weak self] in
            if self?.captureSession.isRunning == true {
                self?.captureSession.stopRunning()
            }
        }
    }
    
    // MARK: - State Management
    
    private func handleViewModelState(_ state: CaptureState) {
        switch state {
        case .idle:
            // Only reset to idle if we're not showing success
            if case .success = uiState { return }
            uiState = .idle
        case .scanning, .analyzing:
            uiState = .processing
        case .success:
            // Wait for savedTransaction binding to trigger success
            break
        case .error(let message):
            uiState = .failure(message)
        }
    }
    
    private func updateUIState(animated: Bool) {
        let duration: TimeInterval = animated ? 0.3 : 0
        
        switch uiState {
        case .idle:
            // Gallery visible, Shutter normal
            UIView.animate(withDuration: duration) {
                self.galleryButton.alpha = 1
                self.galleryButton.isHidden = false
                self.galleryButtonWidthConstraint?.constant = 56
                self.shutterButtonLeadingToGalleryConstraint?.isActive = true
                self.shutterButtonLeadingToViewConstraint?.isActive = false
                
                self.shutterButton.backgroundColor = UIColor.label
                self.shutterLabel.text = "SCAN RECEIPT"
                self.shutterSpinner.stopAnimating()
                self.shutterIcon.isHidden = true
                self.shutterLabel.isHidden = false
                self.shutterButton.isEnabled = true
                
                // Hide all overlays
                self.frozenFrameView.isHidden = true
                self.capturedImageView.isHidden = true
                self.processingOverlay.alpha = 0
                self.errorOverlay.isHidden = true
                
                self.view.layoutIfNeeded()
            }
            
            // Restart camera
            startCameraSession()
            
        case .processing:
            // DON'T freeze camera here - wait until photo is captured
            // The camera is frozen in the photo capture delegate callback
            
            UIView.animate(withDuration: duration) {
                self.galleryButton.alpha = 0
                self.galleryButtonWidthConstraint?.constant = 0
                self.shutterButtonLeadingToGalleryConstraint?.isActive = false
                self.shutterButtonLeadingToViewConstraint?.isActive = true
                
                self.shutterButton.backgroundColor = UIColor(hex: "#9B9A97")  // Stone Grey
                self.shutterLabel.text = "SCAN IN PROCESS..."
                self.shutterSpinner.startAnimating()
                self.shutterIcon.isHidden = true
                self.shutterLabel.isHidden = false
                self.shutterButton.isEnabled = false
                
                // Animate white overlay to 0.4 alpha (processing indicator)
                self.processingOverlay.alpha = 0.4
                self.errorOverlay.isHidden = true
                
                self.view.layoutIfNeeded()
            } completion: { _ in
                self.galleryButton.isHidden = true
            }
            
        case .success(let transaction):
            // Spring animation to success - fade out processing overlay
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5
            ) {
                self.shutterButton.backgroundColor = UIColor(hex: "#4A6C45")  // Matcha Green
                self.shutterLabel.text = "TRANSACTION ADDED"
                self.shutterSpinner.stopAnimating()
                self.shutterIcon.image = UIImage(systemName: "checkmark.circle.fill")
                self.shutterIcon.isHidden = false
                self.shutterButton.isEnabled = false
                
                // Fade out processing overlay
                self.processingOverlay.alpha = 0
            }
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Show toast and revert after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.showSavedToast(for: transaction)
                self?.viewModel.clearSavedTransaction()
                self?.viewModel.reset()
                self?.uiState = .idle
            }
            
        case .failure(let message):
            // Stop spinner immediately (outside animation block)
            shutterSpinner.stopAnimating()
            
            // Show error overlay, fade out processing overlay
            UIView.animate(withDuration: duration) {
                self.errorOverlay.isHidden = false
                self.processingOverlay.alpha = 0
                
                // Keep captured image visible behind error overlay
                // (so user sees what they captured)
                
                // Show gallery button
                self.galleryButton.alpha = 1
                self.galleryButton.isHidden = false
                self.galleryButtonWidthConstraint?.constant = 56
                self.shutterButtonLeadingToGalleryConstraint?.isActive = true
                self.shutterButtonLeadingToViewConstraint?.isActive = false
                
                self.shutterButton.backgroundColor = UIColor.label
                self.shutterLabel.text = "RETRY"
                self.shutterIcon.isHidden = true
                self.shutterLabel.isHidden = false
                self.shutterButton.isEnabled = true
                
                self.view.layoutIfNeeded()
            }
            
            // Update error message in overlay
            if let label = errorOverlay.subviews.first?.subviews.compactMap({ $0 as? UILabel }).first {
                label.text = message
            }
        }
    }
    
    private func freezeCamera() {
        // Capture current frame from preview
        guard let connection = photoOutput?.connection(with: .video),
              connection.isEnabled else {
            frozenFrameView.isHidden = false
            frozenFrameView.backgroundColor = .black
            return
        }
        
        // Stop camera and show frozen frame
        stopCameraSession()
        
        // Create snapshot of preview
        if let previewLayer = previewLayer {
            UIGraphicsBeginImageContextWithOptions(cameraPreviewView.bounds.size, false, 0)
            if let context = UIGraphicsGetCurrentContext() {
                previewLayer.render(in: context)
                let snapshot = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                frozenFrameView.image = snapshot
            }
        }
        
        frozenFrameView.isHidden = false
    }
    
    // MARK: - Corner Bracket Helper
    
    private func createCornerBracket(corners: UIRectCorner) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 4
        shapeLayer.lineCap = .round
        
        // Draw L shape based on corner
        let path = UIBezierPath()
        let size: CGFloat = 40
        let length: CGFloat = 20
        
        if corners.contains(.topLeft) {
            path.move(to: CGPoint(x: 0, y: length))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: length, y: 0))
        } else if corners.contains(.topRight) {
            path.move(to: CGPoint(x: size - length, y: 0))
            path.addLine(to: CGPoint(x: size, y: 0))
            path.addLine(to: CGPoint(x: size, y: length))
        } else if corners.contains(.bottomLeft) {
            path.move(to: CGPoint(x: 0, y: size - length))
            path.addLine(to: CGPoint(x: 0, y: size))
            path.addLine(to: CGPoint(x: length, y: size))
        } else if corners.contains(.bottomRight) {
            path.move(to: CGPoint(x: size, y: size - length))
            path.addLine(to: CGPoint(x: size, y: size))
            path.addLine(to: CGPoint(x: size - length, y: size))
        }
        
        shapeLayer.path = path.cgPath
        view.layer.addSublayer(shapeLayer)
        
        return view
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
    
    // MARK: - Toast
    
    private var currentToast: ZenToast?
    
    private func showSavedToast(for transaction: Transaction) {
        currentToast?.removeFromSuperview()
        
        let toast = ZenToast()
        currentToast = toast
        
        toast.onViewTapped = { [weak self] in
            self?.navigateToTransaction(transaction)
        }
        
        toast.show(in: view, bottomOffset: 140, duration: 4.0)
    }
    
    private func navigateToTransaction(_ transaction: Transaction) {
        currentToast?.hide()
        
        dismiss(animated: true) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let tabBarController = window.rootViewController as? UITabBarController else {
                return
            }
            
            tabBarController.selectedIndex = 0
            
            if let navController = tabBarController.viewControllers?.first as? UINavigationController {
                let detailVC = TransactionDetailViewController(transaction: transaction)
                navController.pushViewController(detailVC, animated: true)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func shutterButtonTapped() {
        print("👆 [CaptureVC] shutterButtonTapped, current state: \(uiState)")
        
        switch uiState {
        case .idle:
            // Normal capture
            capturePhoto()
            
        case .failure:
            // RETRY: Reset to idle first, then user can capture again
            print("🔄 [CaptureVC] RETRY tapped, resetting to idle")
            uiState = .idle
            
        case .processing, .success:
            // Do nothing during processing or success animation
            break
        }
    }
    
    @objc private func galleryButtonTapped() {
        print("📷 [CaptureVC] galleryButtonTapped")
        
        // If in failure state, reset first
        if case .failure = uiState {
            uiState = .idle
        }
        
        presentPhotoPicker()
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
    
    // MARK: - Photo Capture
    
    private func capturePhoto() {
        print("📸 [CaptureVC] capturePhoto() called")
        
        guard let photoOutput = photoOutput else {
            print("⚠️ [CaptureVC] No photoOutput available, opening gallery instead")
            // No camera, open gallery instead
            presentPhotoPicker()
            return
        }
        
        print("📸 [CaptureVC] Initiating photo capture...")
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        // First transition to processing state (UI feedback)
        uiState = .processing
        
        // Then capture photo - delegate callback will handle the rest
        photoOutput.capturePhoto(with: settings, delegate: self)
        print("📸 [CaptureVC] Photo capture initiated, waiting for delegate...")
    }
    
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CaptureViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("📸 [CaptureVC] Photo delegate callback received")
        
        if let error = error {
            print("❌ [CaptureVC] Photo capture error: \(error)")
            uiState = .failure("Failed to capture photo")
            return
        }
        
        print("📸 [CaptureVC] Photo captured successfully, processing...")
        
        // Now freeze the camera since we have the photo
        freezeCamera()
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ [CaptureVC] Failed to get image data from photo")
            uiState = .failure("Failed to process photo")
            return
        }
        
        // WYSIWYG: Show the actual captured image
        capturedImageView.image = image
        capturedImageView.isHidden = false
        
        print("📸 [CaptureVC] Image created: \(image.size), sending to viewModel...")
        
        // Process the image
        viewModel.processImage(image)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension CaptureViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            return
        }
        
        uiState = .processing
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            DispatchQueue.main.async {
                if let image = image as? UIImage {
                    // WYSIWYG: Show the actual selected image
                    self?.capturedImageView.image = image
                    self?.capturedImageView.isHidden = false
                    
                    self?.viewModel.processImage(image)
                } else {
                    self?.uiState = .failure("Failed to load image")
                }
            }
        }
    }
}
