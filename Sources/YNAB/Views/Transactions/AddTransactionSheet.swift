import SwiftUI

struct AddTransactionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore

    @State private var amount: Double = 0
    @State private var type: TransactionType = .expense
    @State private var categoryId: String?
    @State private var accountId: String?
    @State private var toAccountId: String?
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var isRecurring = false
    @State private var recurringFrequency: RecurringFrequency = .monthly

    var isEditing: Bool = false
    var existingTransaction: Transaction?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AmountTextField(value: $amount, currencySymbol: dataStore.userSettings.currencySymbol)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Details") {
                    if type != .transfer {
                        VStack(alignment: .leading) {
                            Text("Category")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            CategoryPicker(
                                categories: dataStore.categories.filter {
                                    $0.type.rawValue == type.rawValue
                                },
                                selectedCategoryId: $categoryId
                            )
                        }
                        .padding(.vertical, 4)
                    }

                    Picker(type == .transfer ? "From Account" : "Account", selection: $accountId) {
                        Text("Select Account").tag(String?.none)
                        ForEach(dataStore.accounts) { account in
                            Text(account.name).tag(String?.some(account.id!))
                        }
                    }

                    if type == .transfer {
                        Picker("To Account", selection: $toAccountId) {
                            Text("Select Account").tag(String?.none)
                            ForEach(dataStore.accounts.filter { $0.id != accountId }) { account in
                                Text(account.name).tag(String?.some(account.id!))
                            }
                        }
                    }

                    DatePicker("Date", selection: $date)
                }

                Section("Note") {
                    TextField("Optional note", text: $note)
                }

                if !isEditing {
                    Section {
                        Toggle("Make Recurring", isOn: $isRecurring)
                        if isRecurring {
                            Picker("Frequency", selection: $recurringFrequency) {
                                ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                                    Text(freq.rawValue).tag(freq)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Transaction" : "New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if let txn = existingTransaction {
                    amount = txn.amount
                    type = txn.type
                    categoryId = txn.categoryId
                    accountId = txn.accountId
                    toAccountId = txn.toAccountId
                    date = txn.date
                    note = txn.note ?? ""
                    isRecurring = txn.isRecurring
                }
            }
        }
    }

    private var isValid: Bool {
        guard amount > 0 else { return false }
        guard accountId != nil else { return false }
        if type == .transfer {
            guard toAccountId != nil, toAccountId != accountId else { return false }
        } else {
            guard categoryId != nil else { return false }
        }
        return true
    }

    private func save() {
        let newTxn = Transaction(
            id: existingTransaction?.id,
            amount: amount,
            type: type,
            categoryId: categoryId ?? "",
            accountId: accountId ?? "",
            toAccountId: type == .transfer ? toAccountId : nil,
            date: date,
            note: note.isEmpty ? nil : note,
            isRecurring: isRecurring,
            recurringId: existingTransaction?.recurringId
        )

        Task {
            do {
                if isEditing, let oldTxn = existingTransaction {
                    try await dataStore.updateTransaction(old: oldTxn, new: newTxn)
                } else {
                    try await dataStore.addTransaction(newTxn)
                    
                    if isRecurring {
                        let rule = RecurringRule(
                            title: note.isEmpty ? "Recurring \(type.rawValue)" : note,
                            amount: amount,
                            type: type,
                            categoryId: categoryId ?? "",
                            accountId: accountId ?? "",
                            frequency: recurringFrequency,
                            startDate: date,
                            nextDueDate: Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date,
                            isActive: true
                        )
                        try await dataStore.addRecurringRule(rule)
                    }
                }
                dismiss()
            } catch {
                print("Error saving transaction: \(error)")
            }
        }
    }
}
