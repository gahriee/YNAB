import SwiftUI

struct AddRecurringSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore

    @State private var title: String = ""
    @State private var amount: Double = 0
    @State private var type: TransactionType = .expense
    @State private var categoryId: String? = nil
    @State private var accountId: String? = nil
    @State private var frequency: RecurringFrequency = .monthly
    @State private var startDate: Date = Date()
    
    @State private var isSaving = false
    @State private var errorMessage: String? = nil

    private var isValid: Bool {
        !title.isEmpty && amount > 0 && categoryId != nil && accountId != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title (e.g., Netflix, Salary)", text: $title)
                    AmountTextField(
                        value: $amount,
                        currencySymbol: dataStore.userSettings.currencySymbol
                    )
                }

                Section {
                    Picker("Type", selection: $type) {
                        Text(TransactionType.income.rawValue).tag(TransactionType.income)
                        Text(TransactionType.expense.rawValue).tag(TransactionType.expense)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { _ in
                        categoryId = nil
                    }
                }

                Section {
                    CategoryPicker(
                        categories: dataStore.categories.filter { $0.type.rawValue == type.rawValue },
                        selectedCategoryId: $categoryId
                    )
                    AccountPicker(
                        accounts: dataStore.accounts,
                        selectedAccountId: $accountId
                    )
                }

                Section {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("New Recurring")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRule()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }

    private func saveRule() {
        guard amount > 0,
              !title.isEmpty, let categoryId = categoryId, let accountId = accountId else { return }

        isSaving = true
        errorMessage = nil

        let rule = RecurringRule(
            title: title,
            amount: amount,
            type: type,
            categoryId: categoryId,
            accountId: accountId,
            frequency: frequency,
            startDate: startDate,
            nextDueDate: startDate,
            isActive: true
        )

        Task {
            do {
                try await dataStore.addRecurringRule(rule)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}
