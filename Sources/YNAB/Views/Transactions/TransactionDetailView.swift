import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var showEditSheet = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    let category = dataStore.categories.first(where: { $0.id == transaction.categoryId })
                    
                    ZStack {
                        Circle()
                            .fill(colorFromHex(category?.color ?? "#888888").opacity(0.2))
                            .frame(width: 80, height: 80)
                        Image(systemName: category?.icon ?? "questionmark")
                            .font(.system(size: 40))
                            .foregroundStyle(colorFromHex(category?.color ?? "#888888"))
                    }
                    
                    Text("\(amountPrefix)\(dataStore.userSettings.currencySymbol)\(abs(transaction.amount), specifier: "%.2f")")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(amountColor)
                    
                    Text(category?.name ?? "Transfer")
                        .font(.title3)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .listRowBackground(Color.clear)
            }
            
            Section("Details") {
                DetailRow(title: "Type", value: transaction.type.rawValue)
                
                let account = dataStore.accounts.first(where: { $0.id == transaction.accountId })
                DetailRow(title: transaction.type == .transfer ? "From" : "Account", value: account?.name ?? "Unknown")
                
                if transaction.type == .transfer {
                    let toAccount = dataStore.accounts.first(where: { $0.id == transaction.toAccountId })
                    DetailRow(title: "To", value: toAccount?.name ?? "Unknown")
                }
                
                DetailRow(title: "Date", value: transaction.date.formatted(date: .long, time: .shortened))
                
                if let note = transaction.note, !note.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Note")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(note)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    Task {
                        if let id = transaction.id {
                            try? await dataStore.deleteTransaction(id: id)
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Transaction")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Transaction Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddTransactionSheet(isEditing: true, existingTransaction: transaction)
        }
    }
    
    private var amountPrefix: String {
        switch transaction.type {
        case .income: return "+"
        case .expense: return "-"
        case .transfer: return ""
        }
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income: return .green
        case .expense: return .primary
        case .transfer: return .blue
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

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
