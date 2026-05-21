import Foundation

struct RecurringService {
    @MainActor
    static func processDueTransactions(rules: [RecurringRule], dataStore: DataStore) async throws {
        let now = Date()
        let calendar = Calendar.current
        
        for var rule in rules where rule.isActive {
            var hasUpdates = false
            
            while rule.nextDueDate <= now {
                let transaction = Transaction(
                    amount: rule.amount,
                    type: rule.type,
                    categoryId: rule.categoryId,
                    accountId: rule.accountId,
                    toAccountId: nil,
                    date: rule.nextDueDate,
                    note: "\(rule.title) (Auto)",
                    isRecurring: true,
                    recurringId: rule.id
                )
                
                try await dataStore.addTransaction(transaction)
                
                guard let nextDate = calculateNextDueDate(from: rule.nextDueDate, frequency: rule.frequency, calendar: calendar) else {
                    break
                }
                
                rule.nextDueDate = nextDate
                hasUpdates = true
            }
            
            if hasUpdates {
                try await dataStore.updateRecurringRule(rule)
            }
        }
    }
    
    static func calculateNextDueDate(from date: Date, frequency: RecurringFrequency, calendar: Calendar = .current) -> Date? {
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }
}
