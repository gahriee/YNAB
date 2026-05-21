import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddTransaction = false
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all

    enum FilterType: String, CaseIterable {
        case all = "All"
        case income = "Income"
        case expense = "Expense"
        case transfer = "Transfer"
    }

    var filteredTransactions: [Transaction] {
        var result = dataStore.transactions

        // Apply type filter
        switch selectedFilter {
        case .all: break
        case .income: result = result.filter { $0.type == .income }
        case .expense: result = result.filter { $0.type == .expense }
        case .transfer: result = result.filter { $0.type == .transfer }
        }

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { txn in
                if let note = txn.note, note.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                let amountString = String(format: "%.2f", txn.amount)
                if amountString.contains(searchText) {
                    return true
                }
                if let cat = dataStore.categories.first(where: { $0.id == txn.categoryId }),
                   cat.name.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                return false
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(FilterType.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding()
                }
                
                List {
                    if filteredTransactions.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Results",
                            subtitle: "No transactions match your current filters."
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(filteredTransactions) { transaction in
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(transaction: transaction)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search by note, amount, or category")
            }
            .navigationTitle("Transactions")
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

    private func delete(transaction: Transaction) {
        Task {
            if let id = transaction.id {
                do {
                    try await dataStore.deleteTransaction(id: id)
                } catch {
                    print("Error deleting transaction: \(error)")
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
