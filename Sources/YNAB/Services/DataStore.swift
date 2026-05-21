import Foundation
import FirebaseFirestore

/// Central source of truth — aggregates all Firestore listeners and exposes CRUD operations
/// with balance integrity enforcement.
@MainActor
class DataStore: ObservableObject {

    // MARK: - Published Properties

    @Published var accounts: [Account] = []
    @Published var categories: [Category] = []
    @Published var transactions: [Transaction] = []
    @Published var recurringRules: [RecurringRule] = []
    @Published var budgets: [Budget] = []
    @Published var userSettings: UserSettings = .defaults
    @Published var isLoading = true

    // MARK: - Private Properties

    private let firebase = FirebaseService()
    private var listeners: [ListenerRegistration] = []

    private enum Col {
        static let accounts       = "accounts"
        static let categories     = "categories"
        static let transactions   = "transactions"
        static let recurringRules = "recurringRules"
        static let budgets        = "budgets"
        static let settings       = "settings"
    }

    // MARK: - Listener Management

    func startListening() {
        stopListening()

        listeners.append(
            firebase.listen(to: Col.accounts) { [weak self] (items: [Account]) in
                Task { @MainActor in self?.accounts = items }
            }
        )

        listeners.append(
            firebase.listen(to: Col.categories) { [weak self] (items: [Category]) in
                Task { @MainActor in self?.categories = items }
            }
        )

        listeners.append(
            firebase.listen(to: Col.transactions) { [weak self] (items: [Transaction]) in
                Task { @MainActor in
                    self?.transactions = items.sorted { $0.date > $1.date }
                    self?.checkBudgetAlerts()
                }
            }
        )

        listeners.append(
            firebase.listen(to: Col.recurringRules) { [weak self] (items: [RecurringRule]) in
                Task { @MainActor in self?.recurringRules = items }
            }
        )

        listeners.append(
            firebase.listen(to: Col.budgets) { [weak self] (items: [Budget]) in
                Task { @MainActor in 
                    self?.budgets = items 
                    self?.checkBudgetAlerts()
                }
            }
        )

        listeners.append(
            firebase.listenToDocument(in: Col.settings, id: "preferences") { [weak self] (settings: UserSettings?) in
                Task { @MainActor in
                    self?.userSettings = settings ?? .defaults
                    self?.migratePINToKeychainIfNeeded()
                    self?.isLoading = false
                }
            }
        )
    }

    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }

    // MARK: - Accounts

    func addAccount(_ account: Account) async throws {
        try await firebase.add(account, to: Col.accounts)
    }

    func updateAccount(_ account: Account) async throws {
        guard let id = account.id else { return }
        try await firebase.update(account, in: Col.accounts, id: id)
    }

    func deleteAccount(id: String) async throws {
        let linked = transactions.filter { $0.accountId == id || $0.toAccountId == id }
        guard linked.isEmpty else {
            throw YNABError.accountHasTransactions(count: linked.count)
        }
        try await firebase.delete(from: Col.accounts, id: id)
    }

    // MARK: - Categories

    func addCategory(_ category: Category) async throws {
        try await firebase.add(category, to: Col.categories)
    }

    func updateCategory(_ category: Category) async throws {
        guard let id = category.id else { return }
        try await firebase.update(category, in: Col.categories, id: id)
    }

    func deleteCategory(id: String) async throws {
        let linked = transactions.filter { $0.categoryId == id }
        guard linked.isEmpty else {
            throw YNABError.categoryHasTransactions(count: linked.count)
        }
        // Cascade: delete budgets for this category
        for budget in budgets where budget.categoryId == id {
            if let budgetId = budget.id {
                try await firebase.delete(from: Col.budgets, id: budgetId)
            }
        }
        try await firebase.delete(from: Col.categories, id: id)
    }

    // MARK: - Transactions (with balance integrity)

    func addTransaction(_ transaction: Transaction) async throws {
        try await firebase.add(transaction, to: Col.transactions)
        try await applyBalanceEffect(transaction)
    }

    func updateTransaction(old: Transaction, new: Transaction) async throws {
        guard let id = new.id else { return }
        try await reverseBalanceEffect(old)
        try await firebase.update(new, in: Col.transactions, id: id)
        try await applyBalanceEffect(new)
    }

    func deleteTransaction(id: String) async throws {
        guard let transaction = transactions.first(where: { $0.id == id }) else { return }
        try await reverseBalanceEffect(transaction)
        try await firebase.delete(from: Col.transactions, id: id)
    }

    // MARK: - Balance Integrity

    private func applyBalanceEffect(_ txn: Transaction) async throws {
        guard var account = accounts.first(where: { $0.id == txn.accountId }),
              let accountId = account.id else { return }

        switch txn.type {
        case .income:
            account.balance += txn.amount
        case .expense:
            account.balance -= txn.amount
        case .transfer:
            account.balance -= txn.amount
            if let toId = txn.toAccountId,
               var toAccount = accounts.first(where: { $0.id == toId }) {
                toAccount.balance += txn.amount
                try await firebase.update(toAccount, in: Col.accounts, id: toId)
            }
        }
        try await firebase.update(account, in: Col.accounts, id: accountId)
    }

    private func reverseBalanceEffect(_ txn: Transaction) async throws {
        guard var account = accounts.first(where: { $0.id == txn.accountId }),
              let accountId = account.id else { return }

        switch txn.type {
        case .income:
            account.balance -= txn.amount
        case .expense:
            account.balance += txn.amount
        case .transfer:
            account.balance += txn.amount
            if let toId = txn.toAccountId,
               var toAccount = accounts.first(where: { $0.id == toId }) {
                toAccount.balance -= txn.amount
                try await firebase.update(toAccount, in: Col.accounts, id: toId)
            }
        }
        try await firebase.update(account, in: Col.accounts, id: accountId)
    }

    // MARK: - Budgets

    func addBudget(_ budget: Budget) async throws {
        try await firebase.add(budget, to: Col.budgets)
    }

    func updateBudget(_ budget: Budget) async throws {
        guard let id = budget.id else { return }
        try await firebase.update(budget, in: Col.budgets, id: id)
    }

    func deleteBudget(id: String) async throws {
        try await firebase.delete(from: Col.budgets, id: id)
    }

    // MARK: - Recurring Rules

    func addRecurringRule(_ rule: RecurringRule) async throws {
        let ruleId = try await firebase.add(rule, to: Col.recurringRules)
        if userSettings.notificationsEnabled {
            var savedRule = rule
            savedRule.id = ruleId
            NotificationService.scheduleRecurringReminder(rule: savedRule, currencySymbol: userSettings.currencySymbol)
        }
    }

    func updateRecurringRule(_ rule: RecurringRule) async throws {
        guard let id = rule.id else { return }
        try await firebase.update(rule, in: Col.recurringRules, id: id)
    }

    func deleteRecurringRule(id: String) async throws {
        try await firebase.delete(from: Col.recurringRules, id: id)
        NotificationService.cancelRecurringReminder(ruleId: id)
    }

    // MARK: - User Settings

    func updateSettings(_ settings: UserSettings) async throws {
        try firebase.userCollection(Col.settings)
            .document("preferences")
            .setData(from: settings, merge: true)
    }

    // MARK: - Migrations
    
    private func migratePINToKeychainIfNeeded() {
        if let oldPIN = userSettings.pin, !oldPIN.isEmpty {
            do {
                if let pinData = oldPIN.data(using: .utf8) {
                    try KeychainService.save(key: KeychainService.pinHashKey, data: pinData)
                }
                var updatedSettings = userSettings
                updatedSettings.pin = nil
                Task {
                    try? await updateSettings(updatedSettings)
                }
            } catch {
                print("Failed to migrate PIN to Keychain: \(error)")
            }
        }
    }

    // MARK: - Seed Data

    /// Populates default accounts, categories, and settings on first launch.
    func seedDefaultDataIfNeeded() async throws {
        let existing: [Account] = try await firebase.fetch(from: Col.accounts)
        guard existing.isEmpty else { return }

        // Default accounts
        let defaultAccounts = [
            Account(name: "Cash Wallet", type: .cash, balance: 0, currency: "PHP", color: "#4CAF50", createdAt: Date()),
            Account(name: "Bank Account", type: .bank, balance: 0, currency: "PHP", color: "#2196F3", createdAt: Date()),
        ]
        for account in defaultAccounts {
            try await firebase.add(account, to: Col.accounts)
        }

        // Default expense categories
        let expenseCategories = [
            Category(name: "Food", icon: "fork.knife", color: "#FF9800", type: .expense),
            Category(name: "Transport", icon: "bus.fill", color: "#03A9F4", type: .expense),
            Category(name: "Housing", icon: "house.fill", color: "#795548", type: .expense),
            Category(name: "Health", icon: "cross.case.fill", color: "#F44336", type: .expense),
            Category(name: "Entertainment", icon: "gamecontroller.fill", color: "#9C27B0", type: .expense),
            Category(name: "Shopping", icon: "bag.fill", color: "#E91E63", type: .expense),
            Category(name: "Education", icon: "book.fill", color: "#3F51B5", type: .expense),
            Category(name: "Others", icon: "square.grid.2x2.fill", color: "#607D8B", type: .expense),
        ]

        // Default income categories
        let incomeCategories = [
            Category(name: "Salary", icon: "briefcase.fill", color: "#4CAF50", type: .income),
            Category(name: "Freelance", icon: "dollarsign.circle.fill", color: "#8BC34A", type: .income),
            Category(name: "Gift", icon: "gift.fill", color: "#FF5722", type: .income),
            Category(name: "Investment", icon: "chart.line.uptrend.xyaxis", color: "#009688", type: .income),
            Category(name: "Others", icon: "banknote.fill", color: "#CDDC39", type: .income),
        ]

        for category in expenseCategories + incomeCategories {
            try await firebase.add(category, to: Col.categories)
        }

        // Default user settings
        try await updateSettings(.defaults)
    }

    // MARK: - Computed Properties

    private func checkBudgetAlerts() {
        guard userSettings.notificationsEnabled else { return }
        
        let progresses = BudgetService.progress(for: budgets, transactions: transactions)
        for progress in progresses {
            if progress.percentUsed >= 0.75 {
                let categoryName = categories.first(where: { $0.id == progress.budget.categoryId })?.name ?? "Category"
                NotificationService.scheduleBudgetAlert(
                    categoryName: categoryName,
                    percentUsed: progress.percentUsed,
                    remaining: progress.remaining,
                    currencySymbol: userSettings.currencySymbol
                )
            }
        }
    }

    var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }

    var thisMonthIncome: Double {
        let cal = Calendar.current
        let now = Date()
        return transactions
            .filter { $0.type == .income && cal.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    var thisMonthExpenses: Double {
        let cal = Calendar.current
        let now = Date()
        return transactions
            .filter { $0.type == .expense && cal.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    var recentTransactions: [Transaction] {
        Array(transactions.prefix(5))
    }
}
