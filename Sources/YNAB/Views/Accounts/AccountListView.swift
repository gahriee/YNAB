import SwiftUI

struct AccountListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddAccount = false
    @State private var errorMsg: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            List {
                if dataStore.accounts.isEmpty {
                    EmptyStateView(
                        icon: "building.columns.fill",
                        title: "No Accounts",
                        subtitle: "Add your first account to get started."
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(dataStore.accounts) { account in
                        NavigationLink(destination: AccountTransactionListView(account: account)) {
                            AccountListRow(account: account)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(account: account)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
#if os(iOS)
            .listStyle(.insetGrouped)
#endif
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddAccount = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddAccount) {
                AddAccountSheet()
            }
            .alert("Cannot Delete", isPresented: $showError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMsg ?? "")
            })
        }
    }
    
    private func delete(account: Account) {
        Task {
            if let id = account.id {
                do {
                    try await dataStore.deleteAccount(id: id)
                } catch {
                    errorMsg = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct AccountListRow: View {
    let account: Account
    
    var body: some View {
        HStack {
            Image(systemName: iconFor(type: account.type))
                .font(.title2)
                .foregroundStyle(colorFromHex(account.color))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.body)
                Text(account.type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(account.currency)\(account.balance, specifier: "%.2f")")
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
    
    private func iconFor(type: AccountType) -> String {
        switch type {
        case .cash: return "banknote.fill"
        case .bank: return "building.columns.fill"
        case .credit: return "creditcard.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        }
    }
    
    private func colorFromHex(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}

struct AccountTransactionListView: View {
    let account: Account
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        let accountTransactions = dataStore.transactions.filter {
            $0.accountId == account.id || $0.toAccountId == account.id
        }
        
        List {
            if accountTransactions.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.rectangle.fill",
                    title: "No Transactions",
                    subtitle: "No transactions found for this account."
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(accountTransactions) { transaction in
                    let category = dataStore.categories.first(where: { $0.id == transaction.categoryId })
                    NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                        TransactionRow(
                            transaction: transaction,
                            category: category,
                            accountName: account.name,
                            currencySymbol: dataStore.userSettings.currencySymbol
                        )
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(account.name)
    }
}
