import SwiftUI

struct RecurringListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddRule = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if dataStore.recurringRules.isEmpty {
                    EmptyStateView(
                        icon: "arrow.trianglehead.2.counterclockwise",
                        title: "No Recurring Transactions",
                        subtitle: "Set up automatic transactions for subscriptions or salary."
                    )
                } else {
                    List {
                        ForEach(dataStore.recurringRules) { rule in
                            RecurringRuleRow(rule: rule, currencySymbol: dataStore.userSettings.currencySymbol) {
                                toggleRule(rule)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let id = rule.id {
                                        deleteRule(id: id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recurring")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddRule = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddRule) {
                AddRecurringSheet()
            }
        }
    }

    private func toggleRule(_ rule: RecurringRule) {
        var updatedRule = rule
        updatedRule.isActive.toggle()
        Task {
            do {
                try await dataStore.updateRecurringRule(updatedRule)
            } catch {
                print("Failed to update rule: \(error.localizedDescription)")
            }
        }
    }

    private func deleteRule(id: String) {
        Task {
            do {
                try await dataStore.deleteRecurringRule(id: id)
            } catch {
                print("Failed to delete rule: \(error.localizedDescription)")
            }
        }
    }
}

struct RecurringRuleRow: View {
    let rule: RecurringRule
    let currencySymbol: String
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.title)
                    .font(.headline)
                
                Text("\(rule.frequency.rawValue) · \(rule.type.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Next: \(rule.nextDueDate, style: .date)")
                    .font(.caption2)
                    .foregroundStyle(rule.isActive ? .blue : .secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text("\(currencySymbol)\(rule.amount, specifier: "%.2f")")
                    .font(.subheadline.bold())
                    .foregroundStyle(rule.type == .income ? .green : .primary)
                
                Toggle("", isOn: Binding(
                    get: { rule.isActive },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
        }
        .padding(.vertical, 4)
        .opacity(rule.isActive ? 1.0 : 0.6)
    }
}
