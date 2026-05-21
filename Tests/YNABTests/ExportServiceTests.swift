import Testing
import Foundation
@testable import YNAB

struct ExportServiceTests {
    
    @Test func testCSVGeneration() {
        let date = Date(timeIntervalSince1970: 1716336000) // 2024-05-22 00:00:00 UTC
        
        let tx1 = Transaction(amount: 1500.50, type: .income, categoryId: "c1", accountId: "a1", date: date, note: "Salary", isRecurring: false)
        let tx2 = Transaction(amount: 50.0, type: .expense, categoryId: "c2", accountId: "a1", date: date, note: "Groceries, Milk", isRecurring: false)
        let tx3 = Transaction(amount: 100, type: .transfer, categoryId: "c3", accountId: "a1", toAccountId: "a2", date: date, note: nil, isRecurring: false)
        
        let categories = [
            Category(id: "c1", name: "Salary", icon: "icon", color: "color", type: .income),
            Category(id: "c2", name: "Food", icon: "icon", color: "color", type: .expense),
            Category(id: "c3", name: "Transfer", icon: "icon", color: "color", type: .expense)
        ]
        
        let accounts = [
            Account(id: "a1", name: "Cash", type: .cash, balance: 0, currency: "USD", color: "color", createdAt: date),
            Account(id: "a2", name: "Bank", type: .bank, balance: 0, currency: "USD", color: "color", createdAt: date)
        ]
        
        let csv = ExportService.generateCSV(transactions: [tx1, tx2, tx3], accounts: accounts, categories: categories)
        
        let lines = csv.components(separatedBy: "\n")
        #expect(lines.count == 5) // Header + 3 rows + empty newline at end
        
        #expect(lines[0] == "Date,Type,Category,Account,Amount,Note")
        
        // Income
        #expect(lines[1].contains("Income,Salary,Cash,1500.50,Salary"))
        
        // Expense with comma in note (escaping)
        #expect(lines[2].contains("Expense,Food,Cash,50.00,\"Groceries, Milk\""))
        
        // Transfer
        #expect(lines[3].contains("Transfer,Transfer,Cash -> Bank,100.00,"))
    }
}
