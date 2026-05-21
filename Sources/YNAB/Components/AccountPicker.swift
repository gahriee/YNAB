import SwiftUI

struct AccountPicker: View {
    let accounts: [Account]
    @Binding var selectedAccountId: String?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(accounts) { account in
                AccountCell(account: account, isSelected: account.id == selectedAccountId)
                    .onTapGesture {
                        selectedAccountId = account.id
                    }
            }
        }
    }
}

struct AccountCell: View {
    let account: Account
    let isSelected: Bool

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
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.blue)
                    .padding(.left, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.secondarySystemGroupedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
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
