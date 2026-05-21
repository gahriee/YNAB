import SwiftUI

struct ExportSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore
    
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var exportFormat = "CSV"
    
    let formats = ["CSV", "PDF"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section("Format") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(formats, id: \.self) { format in
                            Text(format).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button {
                        export()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Export Transactions")
                                .bold()
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func export() {
        let range = startDate...endDate
        let filteredTransactions = dataStore.transactions.filter { range.contains($0.date) }
        
        let currencySymbol = dataStore.userSettings.currencySymbol
        
        if exportFormat == "CSV" {
            let csvString = ExportService.generateCSV(transactions: filteredTransactions, accounts: dataStore.accounts, categories: dataStore.categories)
            if let data = csvString.data(using: .utf8) {
                ExportService.shareFile(data: data, filename: "YNAB_Export_\(Date().timeIntervalSince1970).csv")
            }
        } else {
            let pdfData = ExportService.generatePDF(transactions: filteredTransactions, accounts: dataStore.accounts, categories: dataStore.categories, currencySymbol: currencySymbol, dateRange: range)
            ExportService.shareFile(data: pdfData, filename: "YNAB_Export_\(Date().timeIntervalSince1970).pdf")
        }
    }
}
