//
//  AccountsViewController.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/29.
//

import UIKit
import CoreData

/// Displays and manages payment accounts
final class AccountsViewController: UIViewController {
    
    // MARK: - Properties
    
    private var accounts: [Account] = []
    
    private var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(AccountCell.self, forCellReuseIdentifier: AccountCell.reuseIdentifier)
        table.backgroundColor = PrismTheme.Colors.background
        return table
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No accounts yet.\nAccounts are created automatically when you scan receipts."
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
        setupNavigation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchAccounts()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = PrismTheme.Colors.background
        title = "Accounts"
        
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
    
    private func setupNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: UIAction { [weak self] _ in
                self?.showAddAccountAlert()
            }
        )
    }
    
    // MARK: - Data
    
    private func fetchAccounts() {
        let fetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            accounts = try context.fetch(fetchRequest)
            tableView.reloadData()
            emptyStateLabel.isHidden = !accounts.isEmpty
            tableView.isHidden = accounts.isEmpty
        } catch {
            print("❌ Failed to fetch accounts: \(error)")
        }
    }
    
    // MARK: - Actions
    
    private func showAddAccountAlert() {
        let alert = UIAlertController(title: "Add Account", message: "Enter account details", preferredStyle: .alert)
        
        alert.addTextField { field in
            field.placeholder = "Provider (e.g., Visa, Amex)"
            field.autocapitalizationType = .words
        }
        
        alert.addTextField { field in
            field.placeholder = "Last 4 digits"
            field.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let provider = alert.textFields?[0].text, !provider.isEmpty,
                  let last4 = alert.textFields?[1].text, last4.count == 4 else { return }
            
            self.addAccount(provider: provider, last4: last4)
        })
        
        present(alert, animated: true)
    }
    
    private func addAccount(provider: String, last4: String) {
        let account = Account(context: context)
        account.id = UUID()
        account.provider = provider
        account.lastFourDigits = last4
        account.name = "\(provider) ****\(last4)"
        
        do {
            try context.save()
            fetchAccounts()
        } catch {
            print("❌ Failed to save account: \(error)")
        }
    }
}

// MARK: - UITableViewDataSource

extension AccountsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountCell.reuseIdentifier, for: indexPath) as! AccountCell
        cell.configure(with: accounts[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AccountsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let account = accounts[indexPath.row]
            context.delete(account)
            
            do {
                try context.save()
                fetchAccounts()
            } catch {
                print("❌ Failed to delete account: \(error)")
            }
        }
    }
}

// MARK: - Account Cell

final class AccountCell: UITableViewCell {
    
    static let reuseIdentifier = "AccountCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        backgroundColor = PrismTheme.Colors.surface
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with account: Account) {
        textLabel?.text = account.name
        textLabel?.font = PrismTheme.Fonts.headline
        textLabel?.textColor = PrismTheme.Colors.textPrimary
        
        let transactionCount = account.transactions?.count ?? 0
        detailTextLabel?.text = "\(account.provider ?? "") • \(transactionCount) transaction\(transactionCount == 1 ? "" : "s")"
        detailTextLabel?.font = PrismTheme.Fonts.caption
        detailTextLabel?.textColor = PrismTheme.Colors.textSecondary
        
        imageView?.image = UIImage(systemName: "creditcard.fill")
        imageView?.tintColor = PrismTheme.Colors.accent
    }
}
