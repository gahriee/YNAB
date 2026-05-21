import SwiftUI

struct AddRecurringSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore

    @State private var title: String = ""
    @State private var amount: Double? = nil
    @State private var type: TransactionType = .expense
    @State private var categoryId: String = ""
    @State private var accountId: String = ""
    @State private var frequency: RecurringFrequency = .monthly
    @State private var startDate: Date = Date()
    
    @State private var isSaving = false
    @State private var errorMessage: String? = nil

    private var isValid: Bool {
        !title.isEmpty && (amount ?? 0) > 0 && !categoryId.isEmpty && !accountId.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title (e.g., Netflix, Salary)", text: $title)
                    AmountTextField(
                        amount: $amount,
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
                        categoryId = ""
                    }
                }

                Section {
                    CategoryPicker(
                        selectedCategoryId: $categoryId,
                        type: type == .income ? .income : .expense
                    )
                    AccountPicker(
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
        guard let amount = amount, amount > 0,
              !title.isEmpty, !categoryId.isEmpty, !accountId.isEmpty else { return }

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
