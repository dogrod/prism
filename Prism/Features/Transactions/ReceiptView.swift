//
//  ReceiptView.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/29.
//

import UIKit

/// Skeuomorphic receipt view with jagged bottom edge and thermal printer styling
final class ReceiptView: UIView {
    
    // MARK: - Constants
    
    private enum ReceiptStyle {
        static let inkColor = UIColor(hex: "#2C2C2C") ?? .darkGray
        static let paperColor = UIColor.white
        static let monoFont = UIFont(name: "Menlo-Regular", size: 13) ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
        static let monoBold = UIFont(name: "Menlo-Bold", size: 13) ?? .monospacedSystemFont(ofSize: 13, weight: .bold)
        static let titleFont = UIFont(name: "Menlo-Bold", size: 18) ?? .monospacedSystemFont(ofSize: 18, weight: .bold)
    }
    
    // MARK: - Properties
    
    private var transaction: Transaction?
    
    private let shapeLayer = CAShapeLayer()
    private let shadowLayer = CALayer()
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = ReceiptStyle.paperColor
        return view
    }()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        return stack
    }()
    
    // Header
    private let merchantLabel: UILabel = {
        let label = UILabel()
        label.font = ReceiptStyle.titleFont
        label.textColor = ReceiptStyle.inkColor
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = ReceiptStyle.monoFont
        label.textColor = ReceiptStyle.inkColor.withAlphaComponent(0.7)
        label.textAlignment = .center
        return label
    }()
    
    private let separatorLabel1: UILabel = {
        let label = UILabel()
        label.text = "- - - - - - - - - - - - - - - - - - - -"
        label.font = ReceiptStyle.monoFont
        label.textColor = ReceiptStyle.inkColor.withAlphaComponent(0.5)
        label.textAlignment = .center
        return label
    }()
    
    // Items stack
    private let itemsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()
    
    private let separatorLabel2: UILabel = {
        let label = UILabel()
        label.text = "- - - - - - - - - - - - - - - - - - - -"
        label.font = ReceiptStyle.monoFont
        label.textColor = ReceiptStyle.inkColor.withAlphaComponent(0.5)
        label.textAlignment = .center
        return label
    }()
    
    // Totals
    private let subtotalRow = ReceiptRowView()
    private let taxRow = ReceiptRowView()
    private let tipRow = ReceiptRowView()
    private let totalRow = ReceiptRowView()
    
    private let separatorLabel3: UILabel = {
        let label = UILabel()
        label.text = "================================"
        label.font = ReceiptStyle.monoFont
        label.textColor = ReceiptStyle.inkColor.withAlphaComponent(0.5)
        label.textAlignment = .center
        return label
    }()
    
    // Payment
    private let paymentLabel: UILabel = {
        let label = UILabel()
        label.font = ReceiptStyle.monoFont
        label.textColor = ReceiptStyle.inkColor.withAlphaComponent(0.7)
        label.textAlignment = .center
        return label
    }()
    
    // Barcode
    private let barcodeView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let barcodeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Menlo-Regular", size: 10) ?? .monospacedSystemFont(ofSize: 10, weight: .regular)
        label.textColor = ReceiptStyle.inkColor.withAlphaComponent(0.5)
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateMask()
        drawBarcode()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 15
        layer.shadowOffset = CGSize(width: 0, height: 5)
        
        addSubview(containerView)
        containerView.addSubview(contentStack)
        
        // Build content stack
        contentStack.addArrangedSubview(merchantLabel)
        contentStack.addArrangedSubview(dateLabel)
        contentStack.addArrangedSubview(separatorLabel1)
        contentStack.addArrangedSubview(itemsStack)
        contentStack.addArrangedSubview(separatorLabel2)
        contentStack.addArrangedSubview(subtotalRow)
        contentStack.addArrangedSubview(taxRow)
        contentStack.addArrangedSubview(tipRow)
        contentStack.addArrangedSubview(totalRow)
        contentStack.addArrangedSubview(separatorLabel3)
        contentStack.addArrangedSubview(paymentLabel)
        contentStack.addArrangedSubview(barcodeView)
        contentStack.addArrangedSubview(barcodeLabel)
        
        // Set row styling
        totalRow.setBold(true)
        
        // Constraints
        containerView.enableAutoLayout()
        contentStack.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -32),
            
            barcodeView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func updateMask() {
        let path = ReceiptPath.zigzagPath(for: containerView.bounds, toothWidth: 10, toothHeight: 5)
        shapeLayer.path = path.cgPath
        containerView.layer.mask = shapeLayer
        
        // Update shadow path too
        layer.shadowPath = path.cgPath
    }
    
    // MARK: - Configure
    
    func configure(with transaction: Transaction) {
        self.transaction = transaction
        
        // Header
        merchantLabel.text = (transaction.merchant?.name ?? "RECEIPT").uppercased()
        
        if let date = transaction.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy  HH:mm"
            dateLabel.text = formatter.string(from: date)
        }
        
        // Items
        itemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if let itemsBlob = transaction.itemsBlob,
           let itemsData = itemsBlob.data(using: .utf8),
           let items = try? JSONDecoder().decode([ReceiptJSON.Item].self, from: itemsData) {
            for item in items {
                let row = ReceiptRowView()
                row.configure(left: item.name, right: formatPrice(item.price))
                itemsStack.addArrangedSubview(row)
            }
        } else {
            let row = ReceiptRowView()
            row.configure(left: "Items", right: "N/A")
            itemsStack.addArrangedSubview(row)
        }
        
        // Totals
        let total = transaction.amount?.doubleValue ?? 0
        let tax = transaction.tax?.doubleValue ?? 0
        let tip = transaction.tip?.doubleValue ?? 0
        let subtotal = total - tax - tip
        
        subtotalRow.configure(left: "Subtotal", right: formatPrice(subtotal))
        taxRow.configure(left: "Tax", right: formatPrice(tax))
        
        if tip > 0 {
            tipRow.configure(left: "Tip", right: formatPrice(tip))
            tipRow.isHidden = false
        } else {
            tipRow.isHidden = true
        }
        
        totalRow.configure(left: "TOTAL", right: formatPrice(total))
        
        // Payment
        if let account = transaction.account {
            paymentLabel.text = "Paid with \(account.name ?? "Card")"
        } else {
            paymentLabel.text = "Payment method unknown"
        }
        
        // Barcode label
        barcodeLabel.text = transaction.id?.uuidString.prefix(16).uppercased().description ?? "0000000000000000"
        
        setNeedsLayout()
    }
    
    private func formatPrice(_ price: Double) -> String {
        return String(format: "$%.2f", price)
    }
    
    // MARK: - Barcode Drawing
    
    private func drawBarcode() {
        // Remove existing barcode layers
        barcodeView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let width = barcodeView.bounds.width
        let height = barcodeView.bounds.height
        
        guard width > 0, height > 0 else { return }
        
        // Generate fake barcode pattern
        let barWidth: CGFloat = 2
        let numberOfBars = Int(width / (barWidth * 2))
        
        var currentX: CGFloat = 0
        
        for i in 0..<numberOfBars {
            let isBar = i % 2 == 0 || Int.random(in: 0...2) == 0
            
            if isBar {
                let barLayer = CALayer()
                let barHeight = height * CGFloat.random(in: 0.7...1.0)
                barLayer.frame = CGRect(x: currentX, y: (height - barHeight) / 2, width: barWidth, height: barHeight)
                barLayer.backgroundColor = ReceiptStyle.inkColor.cgColor
                barcodeView.layer.addSublayer(barLayer)
            }
            
            currentX += barWidth * CGFloat.random(in: 1.0...2.0)
            
            if currentX >= width { break }
        }
    }
}

// MARK: - Receipt Row View

final class ReceiptRowView: UIView {
    
    private let leftLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Menlo-Regular", size: 13) ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(hex: "#2C2C2C") ?? .darkGray
        return label
    }()
    
    private let rightLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Menlo-Regular", size: 13) ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(hex: "#2C2C2C") ?? .darkGray
        label.textAlignment = .right
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(leftLabel)
        addSubview(rightLabel)
        
        leftLabel.enableAutoLayout()
        rightLabel.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            leftLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftLabel.topAnchor.constraint(equalTo: topAnchor),
            leftLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            rightLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightLabel.topAnchor.constraint(equalTo: topAnchor),
            rightLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leftLabel.trailingAnchor, constant: 8)
        ])
    }
    
    func configure(left: String, right: String) {
        leftLabel.text = left
        rightLabel.text = right
    }
    
    func setBold(_ bold: Bool) {
        let font = bold 
            ? (UIFont(name: "Menlo-Bold", size: 14) ?? .monospacedSystemFont(ofSize: 14, weight: .bold))
            : (UIFont(name: "Menlo-Regular", size: 13) ?? .monospacedSystemFont(ofSize: 13, weight: .regular))
        leftLabel.font = font
        rightLabel.font = font
    }
}
