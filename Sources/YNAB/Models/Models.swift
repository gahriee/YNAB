import Foundation
import FirebaseFirestore

// MARK: - Enums

enum TransactionType: String, Codable, CaseIterable {
    case income   = "Income"
    case expense  = "Expense"
    case transfer = "Transfer"
}

enum AccountType: String, Codable, CaseIterable {
    case cash       = "Cash"
    case bank       = "Bank"
    case credit     = "Credit Card"
    case investment = "Investment"
}

enum CategoryType: String, Codable, CaseIterable {
    case income  = "Income"
    case expense = "Expense"
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case daily   = "Daily"
    case weekly  = "Weekly"
    case monthly = "Monthly"
    case yearly  = "Yearly"
}

enum BudgetPeriod: String, Codable, CaseIterable {
    case weekly  = "Weekly"
    case monthly = "Monthly"
}

enum ColorTheme: String, Codable, CaseIterable {
    case system = "System"
    case light  = "Light"
    case dark   = "Dark"
}

// MARK: - Account

struct Account: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var type: AccountType
    var balance: Double
    var currency: String
    var color: String
    var createdAt: Date
}

// MARK: - Category

struct Category: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var icon: String
    var color: String
    var type: CategoryType
}

// MARK: - Transaction

struct Transaction: Codable, Identifiable {
    @DocumentID var id: String?
    var amount: Double
    var type: TransactionType
    var categoryId: String
    var accountId: String
    var toAccountId: String?
    var date: Date
    var note: String?
    var isRecurring: Bool
    var recurringId: String?
}

// MARK: - RecurringRule

struct RecurringRule: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var amount: Double
    var type: TransactionType
    var categoryId: String
    var accountId: String
    var frequency: RecurringFrequency
    var startDate: Date
    var nextDueDate: Date
    var isActive: Bool
}

// MARK: - Budget

struct Budget: Codable, Identifiable {
    @DocumentID var id: String?
    var categoryId: String
    var limit: Double
    var period: BudgetPeriod
    var createdAt: Date
}

// MARK: - BudgetProgress (computed locally, not persisted)

struct BudgetProgress {
    var budget: Budget
    var spent: Double
    var remaining: Double
    var percentUsed: Double
    var isOverBudget: Bool
}

// MARK: - UserSettings

struct UserSettings: Codable {
    var currency: String
    var currencySymbol: String
    var isPINEnabled: Bool
    var pin: String? // DEPRECATED: Stored in Keychain now. This remains for migration purposes.
    var isBiometricEnabled: Bool
    var colorTheme: ColorTheme
    var notificationsEnabled: Bool

    static var defaults: UserSettings {
        UserSettings(
            currency: "PHP",
            currencySymbol: "₱",
            isPINEnabled: false,
            pin: nil,
            isBiometricEnabled: false,
            colorTheme: .system,
            notificationsEnabled: true
        )
    }
}

// MARK: - Errors

enum YNABError: LocalizedError {
    case accountHasTransactions(count: Int)
    case categoryHasTransactions(count: Int)
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .accountHasTransactions(let count):
            return "Cannot delete account with \(count) linked transaction\(count == 1 ? "" : "s"). Reassign or delete them first."
        case .categoryHasTransactions(let count):
            return "Cannot delete category with \(count) linked transaction\(count == 1 ? "" : "s"). Reassign them first."
        case .notAuthenticated:
            return "User is not authenticated. Please sign in first."
        }
    }
}
