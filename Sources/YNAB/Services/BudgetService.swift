import Foundation

struct BudgetService {
    static func progress(for budgets: [Budget], transactions: [Transaction]) -> [BudgetProgress] {
        let calendar = Calendar.current
        let now = Date()

        return budgets.map { budget in
            let startDate: Date
            let endDate: Date

            switch budget.period {
            case .weekly:
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
                startDate = calendar.date(from: components) ?? now
                endDate = calendar.date(byAdding: .day, value: 7, to: startDate) ?? now
            case .monthly:
                let components = calendar.dateComponents([.year, .month], from: now)
                startDate = calendar.date(from: components) ?? now
                endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? now
            }

            let spent = transactions
                .filter { $0.type == .expense && $0.categoryId == budget.categoryId && $0.date >= startDate && $0.date < endDate }
                .reduce(0) { $0 + $1.amount }

            let remaining = max(0, budget.limit - spent)
            let percentUsed = budget.limit > 0 ? spent / budget.limit : 0
            let isOverBudget = spent >= budget.limit

            return BudgetProgress(
                budget: budget,
                spent: spent,
                remaining: remaining,
                percentUsed: percentUsed,
                isOverBudget: isOverBudget
            )
        }.sorted { (a, b) -> Bool in
            if a.isOverBudget && !b.isOverBudget { return true }
            if !a.isOverBudget && b.isOverBudget { return false }
            return a.percentUsed > b.percentUsed
        }
    }
}
