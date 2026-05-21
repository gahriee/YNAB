import SwiftUI
import Charts

enum ReportPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct ReportsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedPeriod: ReportPeriod = .month

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(ReportPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        if filteredTransactions.isEmpty {
                            EmptyStateView(
                                icon: "chart.pie.fill",
                                title: "No Data",
                                subtitle: "There are no transactions for this period."
                            )
                            .padding(.top, 40)
                        } else {
                            // 1. Spending by Category (Donut Chart)
                            if !categorySpending.isEmpty {
                                ChartCard(title: "Spending by Category") {
                                    Chart(categorySpending, id: \.categoryId) { item in
                                        SectorMark(
                                            angle: .value("Amount", item.amount),
                                            innerRadius: .ratio(0.6),
                                            angularInset: 1.5
                                        )
                                        .foregroundStyle(colorFromHex(item.color))
                                        .cornerRadius(4)
                                    }
                                    .frame(height: 200)
                                    .chartLegend(.hidden)
                                    
                                    // Custom Legend
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(categorySpending, id: \.categoryId) { item in
                                            HStack {
                                                Circle()
                                                    .fill(colorFromHex(item.color))
                                                    .frame(width: 10, height: 10)
                                                Text(item.name)
                                                    .font(.caption)
                                                Spacer()
                                                Text("\(dataStore.userSettings.currencySymbol)\(item.amount, specifier: "%.2f")")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                            }

                            // 2. Income vs. Expense (Bar Chart)
                            ChartCard(title: "Income vs. Expense") {
                                Chart(incomeExpenseData, id: \.id) { item in
                                    BarMark(
                                        x: .value("Date", item.date, unit: dateUnit),
                                        y: .value("Amount", item.amount)
                                    )
                                    .foregroundStyle(by: .value("Type", item.type.rawValue))
                                    .position(by: .value("Type", item.type.rawValue))
                                }
                                .chartForegroundStyleScale([
                                    TransactionType.income.rawValue: .green,
                                    TransactionType.expense.rawValue: .red
                                ])
                                .frame(height: 200)
                            }

                            // 3. Net Balance Trend (Line Chart)
                            ChartCard(title: "Net Balance Trend") {
                                Chart(netBalanceTrend, id: \.date) { item in
                                    LineMark(
                                        x: .value("Date", item.date, unit: dateUnit),
                                        y: .value("Balance", item.balance)
                                    )
                                    .foregroundStyle(.blue)
                                    
                                    AreaMark(
                                        x: .value("Date", item.date, unit: dateUnit),
                                        y: .value("Balance", item.balance)
                                    )
                                    .foregroundStyle(.blue.opacity(0.1))
                                }
                                .frame(height: 200)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Reports")
        }
    }

    // MARK: - Computed Properties

    private var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return (start, now)
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return (start, now)
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return (start, now)
        }
    }

    private var filteredTransactions: [Transaction] {
        let range = dateRange
        return dataStore.transactions.filter { $0.date >= range.start && $0.date <= range.end }
    }

    // Data for Donut Chart
    private var categorySpending: [(categoryId: String, name: String, color: String, amount: Double)] {
        var grouped: [String: Double] = [:]
        for txn in filteredTransactions where txn.type == .expense {
            grouped[txn.categoryId, default: 0] += txn.amount
        }
        
        return grouped.compactMap { (key, value) in
            guard let category = dataStore.categories.first(where: { $0.id == key }) else { return nil }
            return (categoryId: key, name: category.name, color: category.color, amount: value)
        }.sorted { $0.amount > $1.amount }
    }

    // Data for Bar Chart
    private var dateUnit: Calendar.Component {
        switch selectedPeriod {
        case .week: return .day
        case .month: return .day
        case .year: return .month
        }
    }

    private struct IncomeExpenseItem: Identifiable {
        let id = UUID()
        let date: Date
        let type: TransactionType
        let amount: Double
    }

    private var incomeExpenseData: [IncomeExpenseItem] {
        let calendar = Calendar.current
        var result: [IncomeExpenseItem] = []
        
        // Simplified grouping based on unit (day or month)
        let grouped = Dictionary(grouping: filteredTransactions) { txn -> Date in
            calendar.dateInterval(of: dateUnit, for: txn.date)?.start ?? txn.date
        }
        
        for (date, txns) in grouped {
            let income = txns.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = txns.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            if income > 0 { result.append(IncomeExpenseItem(date: date, type: .income, amount: income)) }
            if expense > 0 { result.append(IncomeExpenseItem(date: date, type: .expense, amount: expense)) }
        }
        
        return result.sorted { $0.date < $1.date }
    }

    // Data for Line Chart
    private struct BalanceTrendItem {
        let date: Date
        let balance: Double
    }

    private var netBalanceTrend: [BalanceTrendItem] {
        let range = dateRange
        let pastTransactions = dataStore.transactions.filter { $0.date < range.start }
        
        var currentBalance = 0.0
        // Calculate balance at start of range
        for txn in pastTransactions {
            if txn.type == .income { currentBalance += txn.amount }
            else if txn.type == .expense { currentBalance -= txn.amount }
            // Ignore transfers as they don't change net worth
        }
        
        var trend: [BalanceTrendItem] = []
        trend.append(BalanceTrendItem(date: range.start, balance: currentBalance))
        
        let txnsInRange = filteredTransactions.sorted { $0.date < $1.date }
        for txn in txnsInRange {
            if txn.type == .income { currentBalance += txn.amount }
            else if txn.type == .expense { currentBalance -= txn.amount }
            trend.append(BalanceTrendItem(date: txn.date, balance: currentBalance))
        }
        
        trend.append(BalanceTrendItem(date: range.end, balance: currentBalance))
        return trend
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

struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
            content
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .padding(.horizontal)
    }
}
