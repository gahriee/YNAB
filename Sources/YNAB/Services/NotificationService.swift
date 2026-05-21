import Foundation
import UserNotifications

struct NotificationService {
    
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Failed to request notification permission: \(error.localizedDescription)")
            return false
        }
    }
    
    static func scheduleBudgetAlert(categoryName: String, percentUsed: Double, remaining: Double, currencySymbol: String) {
        let content = UNMutableNotificationContent()
        
        if percentUsed >= 1.0 {
            content.title = "Budget Exceeded 🚨"
            content.body = "You've exceeded your \(categoryName) budget by \(currencySymbol)\(String(format: "%.2f", abs(remaining)))"
        } else if percentUsed >= 0.75 {
            content.title = "Budget Alert ⚠️"
            content.body = "You've used \(Int(percentUsed * 100))% of your \(categoryName) budget."
        } else {
            return // No alert needed
        }
        
        content.sound = .default
        
        // Use categoryName as identifier to avoid spamming the same alert
        let identifier = "budget_alert_\(categoryName)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil) // trigger nil delivers immediately
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule budget alert: \(error.localizedDescription)")
            }
        }
    }
    
    static func scheduleRecurringReminder(rule: RecurringRule, currencySymbol: String) {
        guard rule.isActive, let ruleId = rule.id else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Recurring Reminder 📅"
        content.body = "\(rule.title) of \(currencySymbol)\(String(format: "%.2f", rule.amount)) is due today."
        content.sound = .default
        
        // Schedule for 9:00 AM on the next due date
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: rule.nextDueDate)
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "recurring_\(ruleId)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule recurring reminder: \(error.localizedDescription)")
            }
        }
    }
    
    static func cancelRecurringReminder(ruleId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["recurring_\(ruleId)"])
    }
    
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
