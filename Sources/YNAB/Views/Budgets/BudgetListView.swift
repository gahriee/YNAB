import SwiftUI

struct BudgetListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddBudget = false

    private var budgetProgresses: [BudgetProgress] {
        BudgetService.progress(for: dataStore.budgets, transactions: dataStore.transactions)
    }

    private var totalBudgeted: Double {
        dataStore.budgets.reduce(0) { $0 + $1.limit }
    }

    private var totalSpent: Double {
        budgetProgresses.reduce(0) { $0 + $1.spent }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.systemGroupedBackground.ignoresSafeArea()

                if dataStore.budgets.isEmpty {
                    EmptyStateView(
                        icon: "target",
                        title: "No Budgets",
                        subtitle: "Create budgets to track your spending limits."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Summary Card
                            VStack(spacing: 8) {
                                Text("Total Budgeted")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(dataStore.userSettings.currencySymbol)\(totalBudgeted, specifier: "%.2f")")
                                    .font(.title2.bold())
                                
                                Divider().padding(.vertical, 4)

                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Spent")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("\(dataStore.userSettings.currencySymbol)\(totalSpent, specifier: "%.2f")")
                                            .font(.headline)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("Remaining")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("\(dataStore.userSettings.currencySymbol)\(max(0, totalBudgeted - totalSpent), specifier: "%.2f")")
                                            .font(.headline)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.secondarySystemGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                            .padding(.horizontal)

                            // List of Budgets
                            LazyVStack(spacing: 16) {
                                ForEach(budgetProgresses, id: \.budget.id) { progress in
                                    if let category = dataStore.categories.first(where: { $0.id == progress.budget.categoryId }) {
                                        BudgetProgressBar(
                                            progress: progress,
                                            categoryName: category.name,
                                            categoryIcon: category.icon,
                                            categoryColor: category.color,
                                            currencySymbol: dataStore.userSettings.currencySymbol
                                        )
                                        .padding(.horizontal)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                if let id = progress.budget.id {
                                                    deleteBudget(id: id)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Budgets")
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton {
                    showAddBudget = true
                }
            }
            .sheet(isPresented: $showAddBudget) {
                AddBudgetSheet()
            }
        }
    }

    private func deleteBudget(id: String) {
        Task {
            do {
                try await dataStore.deleteBudget(id: id)
            } catch {
                print("Failed to delete budget: \(error.localizedDescription)")
            }
        }
    }
}
