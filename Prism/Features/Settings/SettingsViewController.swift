//
//  SettingsViewController.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit
import CoreData

/// Settings view controller with sectioned layout
final class SettingsViewController: BaseViewController {
    
    // MARK: - Sections
    
    private enum SettingsSection: Int, CaseIterable {
        case accounts
        case merchants
        case about
        
        var title: String? {
            switch self {
            case .accounts: return "My Accounts"
            case .merchants: return "Merchants"
            case .about: return nil // No header for About section
            }
        }
        
        var rowCount: Int {
            switch self {
            case .accounts: return 1 // "View All Accounts"
            case .merchants: return 2 // "All Merchants", "Categories"
            case .about: return 1 // "About Prism"
            }
        }
    }
    
    // MARK: - Properties
    
    private var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        table.backgroundColor = BaseViewController.zenBackgroundColor
        return table
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(tableView)
        tableView.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Helpers
    
    private func accountCount() -> Int {
        let fetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        return (try? context.count(for: fetchRequest)) ?? 0
    }
    
    private func merchantCount() -> Int {
        let fetchRequest: NSFetchRequest<Merchant> = Merchant.fetchRequest()
        return (try? context.count(for: fetchRequest)) ?? 0
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        SettingsSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        SettingsSection(rawValue: section)?.rowCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        SettingsSection(rawValue: section)?.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .white
        
        var config = cell.defaultContentConfiguration()
        config.textProperties.color = .black
        
        guard let section = SettingsSection(rawValue: indexPath.section) else { return cell }
        
        switch section {
        case .accounts:
            config.image = UIImage(systemName: "creditcard.fill")
            config.text = "View All Accounts"
            config.secondaryText = "\(accountCount()) accounts"
            config.imageProperties.tintColor = PrismTheme.Colors.accent
            
        case .merchants:
            if indexPath.row == 0 {
                config.image = UIImage(systemName: "building.2.fill")
                config.text = "All Merchants"
                config.secondaryText = "\(merchantCount()) merchants"
                config.imageProperties.tintColor = PrismTheme.Colors.accent
            } else {
                config.image = UIImage(systemName: "tag.fill")
                config.text = "Categories"
                config.secondaryText = "\(MerchantCategory.allCases.count) categories"
                config.imageProperties.tintColor = PrismTheme.Colors.accent
            }
            
        case .about:
            config.image = UIImage(systemName: "info.circle.fill")
            config.text = "About Prism"
            config.secondaryText = "Version 1.0"
            config.imageProperties.tintColor = PrismTheme.Colors.accent
        }
        
        config.secondaryTextProperties.color = .gray
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // Make section headers visible with dark text
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .darkGray
        header.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let section = SettingsSection(rawValue: indexPath.section) else { return }
        
        switch section {
        case .accounts:
            let accountsVC = AccountsViewController()
            navigationController?.pushViewController(accountsVC, animated: true)
            
        case .merchants:
            if indexPath.row == 0 {
                let merchantsVC = MerchantsViewController()
                navigationController?.pushViewController(merchantsVC, animated: true)
            } else {
                // Categories - just show merchants grouped
                let merchantsVC = MerchantsViewController()
                navigationController?.pushViewController(merchantsVC, animated: true)
            }
            
        case .about:
            showAboutAlert()
        }
    }
    
    private func showAboutAlert() {
        let alert = UIAlertController(
            title: "Prism",
            message: "Version 1.0\n\nA receipt scanning and expense tracking app.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
