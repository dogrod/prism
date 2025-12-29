//
//  TransactionsViewController.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit
import CoreData

/// Transactions view controller with NSFetchedResultsController and date grouping
final class TransactionsViewController: BaseViewController {
    
    // MARK: - Properties
    
    private var fetchedResultsController: NSFetchedResultsController<Transaction>!
    
    private var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(TransactionCell.self, forCellReuseIdentifier: TransactionCell.reuseIdentifier)
        table.backgroundColor = PrismTheme.Colors.background
        table.separatorStyle = .singleLine
        table.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
        return table
    }()
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        
        let icon = UIImageView()
        icon.image = UIImage(systemName: "list.bullet.rectangle.portrait")
        icon.tintColor = PrismTheme.Colors.textSecondary
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)
        
        let title = UILabel()
        title.text = "No Transactions"
        title.font = PrismTheme.Fonts.headline
        title.textColor = PrismTheme.Colors.textPrimary
        title.textAlignment = .center
        
        let subtitle = UILabel()
        subtitle.text = "Scan a receipt to add your first transaction"
        subtitle.font = PrismTheme.Fonts.body
        subtitle.textColor = PrismTheme.Colors.textSecondary
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [icon, title, subtitle])
        stack.axis = .vertical
        stack.spacing = PrismTheme.Spacing.md
        stack.alignment = .center
        
        view.addSubview(stack)
        stack.enableAutoLayout()
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
        
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Transactions"
        setupUI()
        setupFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh on appear
        try? fetchedResultsController.performFetch()
        tableView.reloadData()
        updateEmptyState()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = PrismTheme.Colors.background
        
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        
        tableView.enableAutoLayout()
        emptyStateView.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false)
        ]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: "sectionIdentifier",
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            updateEmptyState()
        } catch {
            print("❌ Failed to fetch transactions: \(error)")
        }
    }
    
    private func updateEmptyState() {
        let isEmpty = (fetchedResultsController.fetchedObjects?.isEmpty ?? true)
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    // MARK: - Date Formatting
    
    private func sectionTitle(for sectionIdentifier: String) -> String {
        // sectionIdentifier is in format "yyyy-MM-dd"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: sectionIdentifier) else {
            return sectionIdentifier
        }
        
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy"
            return displayFormatter.string(from: date)
        }
    }
}

// MARK: - Transaction Extension for Section Grouping

extension Transaction {
    
    /// Returns a section identifier string for grouping (yyyy-MM-dd)
    @objc var sectionIdentifier: String {
        guard let date = self.date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - UITableViewDataSource

extension TransactionsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = fetchedResultsController.sections?[section] else { return nil }
        return sectionTitle(for: sectionInfo.name)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionCell.reuseIdentifier, for: indexPath) as! TransactionCell
        let transaction = fetchedResultsController.object(at: indexPath)
        cell.configure(with: transaction)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TransactionsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let transaction = fetchedResultsController.object(at: indexPath)
        let detailVC = TransactionDetailViewController(transaction: transaction)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let transaction = fetchedResultsController.object(at: indexPath)
            context.delete(transaction)
            
            do {
                try context.save()
            } catch {
                print("❌ Failed to delete transaction: \(error)")
            }
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TransactionsViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        tableView.endUpdates()
        updateEmptyState()
    }
    
    func controller(_ controller: NSFetchedResultsController<any NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .update:
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.moveRow(at: indexPath, to: newIndexPath)
            }
        @unknown default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<any NSFetchRequestResult>, didChange sectionInfo: any NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
}

// MARK: - Transaction Cell

final class TransactionCell: UITableViewCell {
    
    static let reuseIdentifier = "TransactionCell"
    
    // MARK: - UI Components
    
    private let merchantIconView: UIView = {
        let view = UIView()
        view.backgroundColor = PrismTheme.Colors.accent.withAlphaComponent(0.1)
        view.layer.cornerRadius = 20
        return view
    }()
    
    private let merchantInitialLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = PrismTheme.Colors.accent
        label.textAlignment = .center
        return label
    }()
    
    private let merchantLabel: UILabel = {
        let label = UILabel()
        label.font = PrismTheme.Fonts.headline
        label.textColor = PrismTheme.Colors.textPrimary
        return label
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = PrismTheme.Fonts.caption
        label.textColor = PrismTheme.Colors.textSecondary
        return label
    }()
    
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = PrismTheme.Colors.textPrimary
        label.textAlignment = .right
        return label
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = PrismTheme.Colors.surface
        accessoryType = .disclosureIndicator
        
        merchantIconView.addSubview(merchantInitialLabel)
        contentView.addSubview(merchantIconView)
        contentView.addSubview(merchantLabel)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(amountLabel)
        
        merchantIconView.enableAutoLayout()
        merchantInitialLabel.enableAutoLayout()
        merchantLabel.enableAutoLayout()
        categoryLabel.enableAutoLayout()
        amountLabel.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            // Icon circle
            merchantIconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            merchantIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            merchantIconView.widthAnchor.constraint(equalToConstant: 40),
            merchantIconView.heightAnchor.constraint(equalToConstant: 40),
            
            // Initial inside circle
            merchantInitialLabel.centerXAnchor.constraint(equalTo: merchantIconView.centerXAnchor),
            merchantInitialLabel.centerYAnchor.constraint(equalTo: merchantIconView.centerYAnchor),
            
            // Merchant name
            merchantLabel.leadingAnchor.constraint(equalTo: merchantIconView.trailingAnchor, constant: 12),
            merchantLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            merchantLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),
            
            // Category
            categoryLabel.leadingAnchor.constraint(equalTo: merchantIconView.trailingAnchor, constant: 12),
            categoryLabel.topAnchor.constraint(equalTo: merchantLabel.bottomAnchor, constant: 2),
            categoryLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            // Amount
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            amountLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            amountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 70)
        ])
    }
    
    // MARK: - Configure
    
    func configure(with transaction: Transaction) {
        let merchantName = transaction.merchant?.name ?? "Unknown"
        merchantLabel.text = merchantName
        merchantInitialLabel.text = String(merchantName.prefix(1)).uppercased()
        
        // Category
        if let merchant = transaction.merchant {
            categoryLabel.text = merchant.category.displayName
            let categoryColor = UIColor(hex: merchant.category.color) ?? PrismTheme.Colors.accent
            merchantIconView.backgroundColor = categoryColor.withAlphaComponent(0.15)
            merchantInitialLabel.textColor = categoryColor
        } else {
            categoryLabel.text = "Uncategorized"
            merchantIconView.backgroundColor = PrismTheme.Colors.textSecondary.withAlphaComponent(0.1)
            merchantInitialLabel.textColor = PrismTheme.Colors.textSecondary
        }
        
        // Amount
        let amount = transaction.amount?.doubleValue ?? 0
        let currency = transaction.currency ?? "CAD"
        amountLabel.text = formatCurrency(amount: amount, currency: currency)
    }
    
    private func formatCurrency(amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }
}
