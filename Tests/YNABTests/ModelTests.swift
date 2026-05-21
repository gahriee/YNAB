import Testing
@testable import YNAB

struct ModelTests {
    
    @Test func testUserSettingsDefaults() {
        let defaults = UserSettings.defaults
        
        #expect(defaults.currency == "PHP")
        #expect(defaults.currencySymbol == "₱")
        #expect(defaults.isPINEnabled == false)
        #expect(defaults.isBiometricEnabled == false)
        #expect(defaults.colorTheme == .system)
        #expect(defaults.notificationsEnabled == true)
        #expect(defaults.pin == nil)
    }
    
    @Test func testEnumRawValues() {
        #expect(TransactionType.income.rawValue == "Income")
        #expect(AccountType.credit.rawValue == "Credit Card")
        #expect(RecurringFrequency.monthly.rawValue == "Monthly")
    }
    
    @Test func testErrorDescriptions() {
        let err1 = YNABError.accountHasTransactions(count: 3)
        #expect(err1.errorDescription == "Cannot delete account with 3 linked transactions. Reassign or delete them first.")
        
        let err2 = YNABError.accountHasTransactions(count: 1)
        #expect(err2.errorDescription == "Cannot delete account with 1 linked transaction. Reassign or delete them first.")
    }
}
