import SwiftUI

struct CategoryPicker: View {
    let categories: [Category]
    @Binding var selectedCategoryId: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(categories) { category in
                    CategoryCell(category: category, isSelected: category.id == selectedCategoryId)
                        .onTapGesture {
                            selectedCategoryId = category.id
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryCell: View {
    let category: Category
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isSelected ? colorFromHex(category.color) : colorFromHex(category.color).opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : colorFromHex(category.color))
            }
            
            Text(category.name)
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .secondary)
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
