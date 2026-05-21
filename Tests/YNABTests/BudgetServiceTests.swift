import Testing
import Foundation
@testable import YNAB

struct BudgetServiceTests {
    
    @Test func testProgressCalculationsMonthly() {
        let now = Date()
        let budget = Budget(categoryId: "cat1", limit: 1000, period: .monthly, createdAt: now)
        
        let tx1 = Transaction(amount: 400, type: .expense, categoryId: "cat1", accountId: "acc1", date: now, isRecurring: false)
        let tx2 = Transaction(amount: 300, type: .expense, categoryId: "cat1", accountId: "acc1", date: now, isRecurring: false)
        
        // Income should be ignored
        let tx3 = Transaction(amount: 500, type: .income, categoryId: "cat1", accountId: "acc1", date: now, isRecurring: false)
        
        let progresses = BudgetService.progress(for: [budget], transactions: [tx1, tx2, tx3])
        
        #expect(progresses.count == 1)
        let p = progresses[0]
        #expect(p.spent == 700)
        #expect(p.remaining == 300)
        #expect(p.percentUsed == 0.7)
        #expect(p.isOverBudget == false)
    }
    
    @Test func testProgressCalculationsOverBudget() {
        let now = Date()
        let budget = Budget(categoryId: "cat1", limit: 500, period: .weekly, createdAt: now)
        
        let tx1 = Transaction(amount: 600, type: .expense, categoryId: "cat1", accountId: "acc1", date: now, isRecurring: false)
        
        let progresses = BudgetService.progress(for: [budget], transactions: [tx1])
        
        #expect(progresses.count == 1)
        let p = progresses[0]
        #expect(p.spent == 600)
        #expect(p.remaining == 0)
        #expect(p.percentUsed == 1.2)
        #expect(p.isOverBudget == true)
    }
    
    @Test func testSortingOverBudgetFirst() {
        let now = Date()
        let b1 = Budget(categoryId: "cat1", limit: 100, period: .monthly, createdAt: now)
        let b2 = Budget(categoryId: "cat2", limit: 100, period: .monthly, createdAt: now)
        
        let tx1 = Transaction(amount: 50, type: .expense, categoryId: "cat1", accountId: "acc1", date: now, isRecurring: false) // 50%
        let tx2 = Transaction(amount: 150, type: .expense, categoryId: "cat2", accountId: "acc1", date: now, isRecurring: false) // 150%
        
        let progresses = BudgetService.progress(for: [b1, b2], transactions: [tx1, tx2])
        
        #expect(progresses.count == 2)
        #expect(progresses[0].budget.categoryId == "cat2") // Over budget sorted first
        #expect(progresses[1].budget.categoryId == "cat1")
    }
}
