//
//  HistoryListViewController.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit

final class HistoryListViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(HistoryCell.self, forCellReuseIdentifier: HistoryCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        return tableView
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No scan history yet.\nScan a receipt to get started."
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateEmptyState()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Scan History"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissVC)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearHistory)
        )
        navigationItem.rightBarButtonItem?.tintColor = .systemRed
        
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
    }
    
    private func setupConstraints() {
        tableView.enableAutoLayout()
        emptyStateLabel.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func updateEmptyState() {
        let isEmpty = ScanHistoryManager.shared.records.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        navigationItem.rightBarButtonItem?.isEnabled = !isEmpty
    }
    
    // MARK: - Actions
    
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
    
    @objc private func clearHistory() {
        let alert = UIAlertController(
            title: "Clear History",
            message: "Are you sure you want to delete all scan history?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            ScanHistoryManager.shared.clearAll()
            self.tableView.reloadData()
            self.updateEmptyState()
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension HistoryListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ScanHistoryManager.shared.records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HistoryCell.reuseIdentifier, for: indexPath) as? HistoryCell else {
            return UITableViewCell()
        }
        
        let record = ScanHistoryManager.shared.records[indexPath.row]
        cell.configure(with: record)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension HistoryListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let record = ScanHistoryManager.shared.records[indexPath.row]
        let detailVC = RecordDetailViewController(record: record)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - History Cell

final class HistoryCell: UITableViewCell {
    
    static let reuseIdentifier = "HistoryCell"
    
    // MARK: - UI Components
    
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private let merchantLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let totalLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .systemGreen
        label.textAlignment = .right
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        accessoryType = .disclosureIndicator
        
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(stackView)
        contentView.addSubview(totalLabel)
        
        stackView.addArrangedSubview(merchantLabel)
        stackView.addArrangedSubview(dateLabel)
        
        thumbnailImageView.enableAutoLayout()
        stackView.enableAutoLayout()
        totalLabel.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            // Thumbnail
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 56),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 56),
            
            // Stack (merchant + date)
            stackView.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: totalLabel.leadingAnchor, constant: -8),
            
            // Total
            totalLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            totalLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            totalLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 70)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with record: ScanHistoryRecord) {
        thumbnailImageView.image = record.originalImage
        merchantLabel.text = record.receiptData.merchant_name ?? "Unknown Merchant"
        dateLabel.text = record.formattedDate
        totalLabel.text = record.formattedTotal
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        merchantLabel.text = nil
        dateLabel.text = nil
        totalLabel.text = nil
    }
}
