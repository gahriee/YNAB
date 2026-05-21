import SwiftUI

struct BudgetProgressBar: View {
    let progress: BudgetProgress
    let categoryName: String
    let categoryIcon: String
    let categoryColor: String
    let currencySymbol: String

    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: categoryIcon)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(colorFromHex(categoryColor))
                    .clipShape(Circle())

                Text(categoryName)
                    .font(.headline)

                Spacer()

                Text("\(currencySymbol)\(progress.budget.limit, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.tertiarySystemFill)
                        .frame(height: 12)

                    Capsule()
                        .fill(progressColor)
                        .frame(width: max(0, min(geometry.size.width * CGFloat(animatedProgress), geometry.size.width)), height: 12)
                }
            }
            .frame(height: 12)

            HStack {
                Text("\(currencySymbol)\(progress.spent, specifier: "%.2f") spent")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if progress.isOverBudget {
                    Text("Overspent by \(currencySymbol)\(progress.spent - progress.budget.limit, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fontWeight(.semibold)
                } else {
                    Text("\(currencySymbol)\(progress.remaining, specifier: "%.2f") left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = progress.percentUsed
            }
        }
        .onChange(of: progress.percentUsed) { newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }

    private var progressColor: Color {
        if progress.percentUsed < 0.5 {
            return .green
        } else if progress.percentUsed < 0.75 {
            return .yellow
        } else if progress.percentUsed <= 1.0 {
            return .orange
        } else {
            return .red
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
