import SwiftUI

struct BalanceCard: View {
    let totalBalance: Double
    let income: Double
    let expense: Double
    let currencySymbol: String

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Total Balance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(currencySymbol)\(totalBalance, specifier: "%.2f")")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
            }

            HStack(spacing: 0) {
                // Income
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.left.circle.fill")
                            .foregroundStyle(.green)
                        Text("Income")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    Text("\(currencySymbol)\(income, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)

                // Expense
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .foregroundStyle(.red)
                        Text("Expense")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    Text("\(currencySymbol)\(expense, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.secondarySystemGroupedBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}
