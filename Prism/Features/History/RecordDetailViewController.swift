//
//  RecordDetailViewController.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit

final class RecordDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    private let record: ScanHistoryRecord
    
    // MARK: - UI Components
    
    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Image", "Analysis Data"])
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return control
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemBackground
        textView.isEditable = false
        textView.layer.cornerRadius = Constants.UI.cornerRadius
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.isHidden = true
        return textView
    }()
    
    private lazy var metadataLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Initialization
    
    init(record: ScanHistoryRecord) {
        self.record = record
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
        configureContent()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = record.receiptData.merchant_name ?? "Scan Details"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareJSON)
        )
        
        view.addSubview(segmentedControl)
        view.addSubview(scrollView)
        view.addSubview(textView)
        view.addSubview(metadataLabel)
        
        scrollView.addSubview(imageView)
    }
    
    private func setupConstraints() {
        let padding = Constants.UI.defaultPadding
        
        segmentedControl.enableAutoLayout()
        scrollView.enableAutoLayout()
        imageView.enableAutoLayout()
        textView.enableAutoLayout()
        metadataLabel.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            // Segmented Control
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            
            // Metadata Label
            metadataLabel.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            metadataLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            metadataLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            
            // ScrollView (for Image)
            scrollView.topAnchor.constraint(equalTo: metadataLabel.bottomAnchor, constant: padding),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // ImageView inside ScrollView
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            // TextView (hidden by default)
            textView.topAnchor.constraint(equalTo: metadataLabel.bottomAnchor, constant: padding),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding)
        ])
    }
    
    private func configureContent() {
        imageView.image = record.originalImage
        textView.text = record.rawJSONString
        
        // Build metadata string
        var metadata: [String] = []
        metadata.append("Scanned: \(record.formattedDate)")
        if let total = record.receiptData.total {
            let currency = record.receiptData.currency ?? "USD"
            metadata.append("Total: \(currency) \(String(format: "%.2f", total))")
        }
        if let itemCount = record.receiptData.items?.count {
            metadata.append("\(itemCount) items")
        }
        metadataLabel.text = metadata.joined(separator: " • ")
    }
    
    // MARK: - Actions
    
    @objc private func segmentChanged() {
        let showImage = segmentedControl.selectedSegmentIndex == 0
        
        UIView.animate(withDuration: 0.2) {
            self.scrollView.alpha = showImage ? 1 : 0
            self.textView.alpha = showImage ? 0 : 1
        } completion: { _ in
            self.scrollView.isHidden = !showImage
            self.textView.isHidden = showImage
        }
        
        scrollView.isHidden = false
        textView.isHidden = false
    }
    
    @objc private func shareJSON() {
        let activityVC = UIActivityViewController(
            activityItems: [record.rawJSONString],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(activityVC, animated: true)
    }
}

// MARK: - UIScrollViewDelegate (Zoom)

extension RecordDetailViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Center the image when zoomed out
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        imageView.center = CGPoint(
            x: scrollView.contentSize.width / 2 + offsetX,
            y: scrollView.contentSize.height / 2 + offsetY
        )
    }
}
