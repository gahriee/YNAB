import Testing
import Foundation
@testable import YNAB

struct RecurringServiceTests {
    
    @Test func testNextDueDateCalculation() {
        let calendar = Calendar.current
        var components = DateComponents(year: 2024, month: 1, day: 15) // Jan 15, 2024
        let baseDate = calendar.date(from: components)!
        
        let nextDaily = RecurringService.calculateNextDueDate(from: baseDate, frequency: .daily, calendar: calendar)!
        #expect(calendar.component(.day, from: nextDaily) == 16)
        
        let nextWeekly = RecurringService.calculateNextDueDate(from: baseDate, frequency: .weekly, calendar: calendar)!
        #expect(calendar.component(.day, from: nextWeekly) == 22)
        
        let nextMonthly = RecurringService.calculateNextDueDate(from: baseDate, frequency: .monthly, calendar: calendar)!
        #expect(calendar.component(.month, from: nextMonthly) == 2)
        
        let nextYearly = RecurringService.calculateNextDueDate(from: baseDate, frequency: .yearly, calendar: calendar)!
        #expect(calendar.component(.year, from: nextYearly) == 2025)
    }
    
    @Test func testLeapYearCalculation() {
        let calendar = Calendar.current
        var components = DateComponents(year: 2024, month: 2, day: 29) // Feb 29, 2024 (Leap Year)
        let baseDate = calendar.date(from: components)!
        
        let nextYearly = RecurringService.calculateNextDueDate(from: baseDate, frequency: .yearly, calendar: calendar)!
        
        #expect(calendar.component(.year, from: nextYearly) == 2025)
        #expect(calendar.component(.month, from: nextYearly) == 2)
        #expect(calendar.component(.day, from: nextYearly) == 28) // Falls back to 28th
    }
}
