import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    let category: Category?
    let accountName: String
    let currencySymbol: String

    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(colorFromHex(category?.color ?? "#888888").opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: category?.icon ?? "questionmark")
                    .font(.title3)
                    .foregroundStyle(colorFromHex(category?.color ?? "#888888"))
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(category?.name ?? "Unknown")
                    .font(.headline)
                
                HStack {
                    Text(accountName)
                    Text("•")
                    Text(transaction.date.formatted(date: .omitted, time: .shortened))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Amount
            Text("\(amountPrefix)\(currencySymbol)\(abs(transaction.amount), specifier: "%.2f")")
                .font(.headline)
                .foregroundStyle(amountColor)
        }
        .padding(.vertical, 8)
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
        case .expense: return .red
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
