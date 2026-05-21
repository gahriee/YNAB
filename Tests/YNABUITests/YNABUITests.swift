import XCTest

final class YNABUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLoginFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for login screen to appear
        let emailTextField = app.textFields["Email"]
        XCTAssertTrue(emailTextField.waitForExistence(timeout: 5.0), "Login screen should appear")

        let passwordTextField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordTextField.exists)

        // Test Guest Login (simulated)
        let guestButton = app.buttons["Continue as Guest"]
        if guestButton.exists {
            guestButton.tap()
            
            // Should transition to MainTabView containing Dashboard
            let dashboardTab = app.tabBars.buttons["Dashboard"]
            XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5.0), "Dashboard should appear after guest login")
        }
    }
    
    func testNavigationTabs() throws {
        let app = XCUIApplication()
        app.launch()
        
        let guestButton = app.buttons["Continue as Guest"]
        if guestButton.waitForExistence(timeout: 2.0) {
            guestButton.tap()
        }
        
        let tabBars = app.tabBars
        let transactionsTab = tabBars.buttons["Transactions"]
        XCTAssertTrue(transactionsTab.waitForExistence(timeout: 5.0))
        transactionsTab.tap()
        
        let reportsTab = tabBars.buttons["Reports"]
        XCTAssertTrue(reportsTab.exists)
        reportsTab.tap()
        
        let settingsTab = tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists)
        settingsTab.tap()
    }
}
