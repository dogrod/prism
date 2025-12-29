//
//  TransactionDetailViewController.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/29.
//

import UIKit
import CoreData

/// Transaction detail view showing skeuomorphic receipt
final class TransactionDetailViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let transaction: Transaction
    private var isRegenerating = false
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()
    
    private let receiptView = ReceiptView()
    
    private lazy var loadingOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.startAnimating()
        view.addSubview(spinner)
        
        let label = UILabel()
        label.text = "Regenerating..."
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .white
        view.addSubview(label)
        
        spinner.enableAutoLayout()
        label.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 12),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        return view
    }()
    
    // MARK: - Init
    
    init(transaction: Transaction) {
        self.transaction = transaction
        super.init(nibName: nil, bundle: nil)
        
        // Set title at init-time to prevent lazy title animation delay
        self.title = "Ticket"
        // Disable large title mode immediately
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        configureReceipt()
    }
    
    // MARK: - Setup
    
    private func setupNavigation() {
        // Title already set in init for immediate display
        navigationItem.largeTitleDisplayMode = .never
        
        // Configure nav bar to match gray background
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemGray6
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        
        // Create menu for right bar button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            menu: createOptionsMenu()
        )
    }
    
    private func createOptionsMenu() -> UIMenu {
        // Check if regeneration is available (has image)
        let canRegenerate = transaction.scanRecord?.imagePath != nil
        
        let regenerateAction = UIAction(
            title: "Regenerate info...",
            image: UIImage(systemName: "sparkles"),
            attributes: canRegenerate ? [] : .disabled
        ) { [weak self] _ in
            self?.showModelPicker()
        }
        
        let editAction = UIAction(
            title: "Edit",
            image: UIImage(systemName: "pencil")
        ) { [weak self] _ in
            self?.showEditAlert()
        }
        
        let deleteAction = UIAction(
            title: "Delete",
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.confirmDelete()
        }
        
        return UIMenu(children: [regenerateAction, editAction, deleteAction])
    }
    
    private func setupUI() {
        // Darker background to make receipt pop
        view.backgroundColor = .systemGray6
        
        view.addSubview(scrollView)
        scrollView.addSubview(receiptView)
        view.addSubview(loadingOverlay)
        
        scrollView.enableAutoLayout()
        receiptView.enableAutoLayout()
        loadingOverlay.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            receiptView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            receiptView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            receiptView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            receiptView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            receiptView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48),
            
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureReceipt() {
        receiptView.configure(with: transaction)
    }
    
    // MARK: - Loading Overlay
    
    private func showLoading() {
        UIView.animate(withDuration: 0.3) {
            self.loadingOverlay.alpha = 1
        }
    }
    
    private func hideLoading() {
        UIView.animate(withDuration: 0.3) {
            self.loadingOverlay.alpha = 0
        }
    }
    
    // MARK: - Actions
    
    private func showModelPicker() {
        let alert = UIAlertController(
            title: "Regenerate with Model",
            message: "Choose a model to re-analyze this receipt",
            preferredStyle: .actionSheet
        )
        
        for model in AIModel.allCases {
            alert.addAction(UIAlertAction(title: model.name, style: .default) { [weak self] _ in
                self?.regenerate(with: model)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func regenerate(with model: AIModel) {
        guard !isRegenerating else { return }
        isRegenerating = true
        showLoading()
        
        Task {
            do {
                let _ = try await ScanProcessor.shared.regenerateTransaction(transaction, using: model)
                
                await MainActor.run {
                    hideLoading()
                    isRegenerating = false
                    configureReceipt()
                    
                    // Show success feedback
                    let toast = ZenToast()
                    toast.onViewTapped = nil
                    toast.show(in: view, duration: 2.0)
                }
            } catch {
                await MainActor.run {
                    hideLoading()
                    isRegenerating = false
                    showError(error)
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Regeneration Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showEditAlert() {
        let alert = UIAlertController(
            title: "Edit Transaction",
            message: "Edit functionality coming soon",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func confirmDelete() {
        let alert = UIAlertController(
            title: "Delete Transaction",
            message: "Are you sure you want to delete this transaction?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteTransaction()
        })
        
        present(alert, animated: true)
    }
    
    private func deleteTransaction() {
        let context = PersistenceController.shared.container.viewContext
        context.delete(transaction)
        
        do {
            try context.save()
            navigationController?.popViewController(animated: true)
        } catch {
            showError(error)
        }
    }
}
