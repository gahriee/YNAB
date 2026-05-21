import SwiftUI

struct AddBudgetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore

    @State private var limit: Double = 0
    @State private var categoryId: String = ""
    @State private var period: BudgetPeriod = .monthly
    
    @State private var isSaving = false
    @State private var errorMessage: String? = nil

    private var availableCategories: [Category] {
        // Filter out categories that already have a budget
        let budgetedCategoryIds = Set(dataStore.budgets.map { $0.categoryId })
        return dataStore.categories.filter { $0.type == .expense && !budgetedCategoryIds.contains($0.id ?? "") }
    }

    private var isValid: Bool {
        !categoryId.isEmpty && limit > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AmountTextField(
                        value: $limit,
                        currencySymbol: dataStore.userSettings.currencySymbol
                    )
                }

                Section {
                    Picker("Category", selection: $categoryId) {
                        Text("Select Category").tag("")
                        ForEach(availableCategories) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.name)
                            }
                            .tag(category.id ?? "")
                        }
                    }
                    
                    if availableCategories.isEmpty {
                        Text("All expense categories already have a budget.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Picker("Period", selection: $period) {
                        ForEach(BudgetPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("New Budget")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBudget()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }

    private func saveBudget() {
        guard limit > 0, !categoryId.isEmpty else { return }

        isSaving = true
        errorMessage = nil

        let budget = Budget(
            categoryId: categoryId,
            limit: limit,
            period: period,
            createdAt: Date()
        )

        Task {
            do {
                try await dataStore.addBudget(budget)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}
