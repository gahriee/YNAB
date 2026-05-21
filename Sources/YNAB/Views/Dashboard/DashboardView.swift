import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddTransaction = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.systemGroupedBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                    BalanceCard(
                        totalBalance: dataStore.totalBalance,
                        income: dataStore.thisMonthIncome,
                        expense: dataStore.thisMonthExpenses,
                        currencySymbol: dataStore.userSettings.currencySymbol
                    )
                    
                    // Budget Alerts
                    let alerts = BudgetService.progress(for: dataStore.budgets, transactions: dataStore.transactions).filter { $0.percentUsed >= 0.75 }
                    if !alerts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Budget Alerts")
                                .font(.title3.bold())
                            
                            ForEach(alerts, id: \.budget.id) { progress in
                                if let category = dataStore.categories.first(where: { $0.id == progress.budget.categoryId }) {
                                    NavigationLink(destination: BudgetListView()) {
                                        HStack {
                                            Image(systemName: category.icon)
                                                .foregroundStyle(progress.isOverBudget ? .red : .orange)
                                            
                                            Text(category.name)
                                                .foregroundStyle(.primary)
                                            
                                            Spacer()
                                            
                                            Text(progress.isOverBudget ? "Over budget!" : "\(Int(progress.percentUsed * 100))% used")
                                                .font(.subheadline.bold())
                                                .foregroundStyle(progress.isOverBudget ? .red : .orange)
                                        }
                                        .padding()
                                        .background(Color.secondarySystemGroupedBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Transactions")
                                .font(.title3.bold())
                            Spacer()
                            NavigationLink("See All", destination: TransactionListView())
                                .font(.subheadline)
                        }
                        
                        if dataStore.recentTransactions.isEmpty {
                            EmptyStateView(
                                icon: "list.bullet.rectangle.fill",
                                title: "No Transactions",
                                subtitle: "Your recent transactions will appear here."
                            )
                        } else {
                            ForEach(dataStore.recentTransactions) { transaction in
                                let category = dataStore.categories.first(where: { $0.id == transaction.categoryId })
                                let account = dataStore.accounts.first(where: { $0.id == transaction.accountId })
                                
                                NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                    TransactionRow(
                                        transaction: transaction,
                                        category: category,
                                        accountName: account?.name ?? "Unknown",
                                        currencySymbol: dataStore.userSettings.currencySymbol
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Divider()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton {
                    showAddTransaction = true
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionSheet()
            }
        }
    }
}
