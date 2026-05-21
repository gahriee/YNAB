import SwiftUI

struct CategoryListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddCategory = false
    @State private var errorMsg: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.systemGroupedBackground.ignoresSafeArea()
                
                if dataStore.categories.isEmpty {
                    EmptyStateView(
                        icon: "tag.fill",
                        title: "No Categories",
                        subtitle: "Add your first category to start organizing."
                    )
                } else {
                    List {

                    Section("Expenses") {
                        ForEach(dataStore.categories.filter { $0.type == .expense }) { category in
                            CategoryListRow(category: category)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        delete(category: category)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    
                    Section("Income") {
                        ForEach(dataStore.categories.filter { $0.type == .income }) { category in
                            CategoryListRow(category: category)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        delete(category: category)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    }
#if os(iOS)
                    .listStyle(.insetGrouped)
#endif
                }
            }
#if os(iOS)
            .background(Color.systemGroupedBackground)
#endif
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddCategory = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet()
            }
            .alert("Cannot Delete", isPresented: $showError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMsg ?? "")
            })
        }
    }
    
    private func delete(category: Category) {
        Task {
            if let id = category.id {
                do {
                    try await dataStore.deleteCategory(id: id)
                } catch {
                    errorMsg = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct CategoryListRow: View {
    let category: Category
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(colorFromHex(category.color).opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: category.icon)
                    .foregroundStyle(colorFromHex(category.color))
            }
            
            Text(category.name)
                .font(.body)
                .padding(.leading, 8)
        }
        .padding(.vertical, 4)
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
