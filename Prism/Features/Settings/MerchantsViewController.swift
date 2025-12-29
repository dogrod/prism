//
//  MerchantsViewController.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/29.
//

import UIKit
import CoreData

/// Displays merchants grouped by category with ability to change category
final class MerchantsViewController: UIViewController {
    
    // MARK: - Properties
    
    private var merchantsByCategory: [MerchantCategory: [Merchant]] = [:]
    private var sortedCategories: [MerchantCategory] = []
    
    private var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(MerchantCell.self, forCellReuseIdentifier: MerchantCell.reuseIdentifier)
        table.backgroundColor = PrismTheme.Colors.background
        return table
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No merchants yet.\nMerchants are created automatically when you scan receipts."
        label.font = PrismTheme.Fonts.body
        label.textColor = PrismTheme.Colors.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchMerchants()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = PrismTheme.Colors.background
        title = "Merchants"
        
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        
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
    
    // MARK: - Data
    
    private func fetchMerchants() {
        let fetchRequest: NSFetchRequest<Merchant> = Merchant.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "categoryRaw", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        do {
            let merchants = try context.fetch(fetchRequest)
            groupMerchants(merchants)
            tableView.reloadData()
            
            let isEmpty = merchantsByCategory.isEmpty
            emptyStateLabel.isHidden = !isEmpty
            tableView.isHidden = isEmpty
        } catch {
            print("❌ Failed to fetch merchants: \(error)")
        }
    }
    
    private func groupMerchants(_ merchants: [Merchant]) {
        merchantsByCategory = [:]
        
        for merchant in merchants {
            let category = merchant.category
            if merchantsByCategory[category] == nil {
                merchantsByCategory[category] = []
            }
            merchantsByCategory[category]?.append(merchant)
        }
        
        // Sort categories by raw value
        sortedCategories = merchantsByCategory.keys.sorted { $0.rawValue < $1.rawValue }
    }
    
    // MARK: - Category Change
    
    private func showCategoryPicker(for merchant: Merchant, at indexPath: IndexPath) {
        let alert = UIAlertController(title: "Change Category", message: merchant.name, preferredStyle: .actionSheet)
        
        for category in MerchantCategory.allCases {
            let action = UIAlertAction(title: category.displayName, style: .default) { [weak self] _ in
                self?.updateMerchantCategory(merchant, to: category)
            }
            
            // Checkmark current category
            if category == merchant.category {
                action.setValue(true, forKey: "checked")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController,
           let cell = tableView.cellForRow(at: indexPath) {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func updateMerchantCategory(_ merchant: Merchant, to category: MerchantCategory) {
        merchant.category = category
        
        do {
            try context.save()
            fetchMerchants()
        } catch {
            print("❌ Failed to update category: \(error)")
        }
    }
}

// MARK: - UITableViewDataSource

extension MerchantsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        sortedCategories.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let category = sortedCategories[section]
        return merchantsByCategory[category]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sortedCategories[section].displayName
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MerchantCell.reuseIdentifier, for: indexPath) as! MerchantCell
        
        let category = sortedCategories[indexPath.section]
        if let merchant = merchantsByCategory[category]?[indexPath.row] {
            cell.configure(with: merchant)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MerchantsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let category = sortedCategories[indexPath.section]
        if let merchant = merchantsByCategory[category]?[indexPath.row] {
            showCategoryPicker(for: merchant, at: indexPath)
        }
    }
}

// MARK: - Merchant Cell

final class MerchantCell: UITableViewCell {
    
    static let reuseIdentifier = "MerchantCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        backgroundColor = PrismTheme.Colors.surface
        accessoryType = .disclosureIndicator
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with merchant: Merchant) {
        textLabel?.text = merchant.name
        textLabel?.font = PrismTheme.Fonts.headline
        textLabel?.textColor = PrismTheme.Colors.textPrimary
        
        let transactionCount = merchant.transactions?.count ?? 0
        detailTextLabel?.text = "\(transactionCount) transaction\(transactionCount == 1 ? "" : "s")"
        detailTextLabel?.font = PrismTheme.Fonts.caption
        detailTextLabel?.textColor = PrismTheme.Colors.textSecondary
        
        imageView?.image = UIImage(systemName: merchant.category.iconName)
        imageView?.tintColor = UIColor(hex: merchant.category.color)
    }
}
