import Foundation
import UIKit
import PDFKit

@MainActor
struct ExportService {
    
    // MARK: - CSV Export
    
    static func generateCSV(transactions: [Transaction], accounts: [Account], categories: [Category]) -> String {
        var csvString = "Date,Type,Category,Account,Amount,Note\n"
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        for transaction in transactions {
            let date = dateFormatter.string(from: transaction.date)
            let type = transaction.type.rawValue
            
            let categoryName = categories.first(where: { $0.id == transaction.categoryId })?.name ?? "Unknown"
            
            let accountName = accounts.first(where: { $0.id == transaction.accountId })?.name ?? "Unknown"
            var accountStr = accountName
            if transaction.type == .transfer, let toId = transaction.toAccountId {
                let toAccountName = accounts.first(where: { $0.id == toId })?.name ?? "Unknown"
                accountStr = "\(accountName) -> \(toAccountName)"
            }
            
            let amount = String(format: "%.2f", transaction.amount)
            
            // Escape note for CSV (quotes and commas)
            let rawNote = transaction.note ?? ""
            let escapedNote = rawNote.contains(",") || rawNote.contains("\"") ? "\"\(rawNote.replacingOccurrences(of: "\"", with: "\"\""))\"" : rawNote
            
            let row = "\(date),\(type),\(categoryName),\(accountStr),\(amount),\(escapedNote)\n"
            csvString.append(row)
        }
        
        return csvString
    }
    
    // MARK: - PDF Export
    
    static func generatePDF(transactions: [Transaction], accounts: [Account], categories: [Category], currencySymbol: String, dateRange: ClosedRange<Date>?) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "YNAB App",
            kCGPDFContextAuthor: "YNAB User"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            let titleBottom = drawTitle(pageRect: pageRect, dateRange: dateRange)
            var currentY = titleBottom + 20
            
            currentY = drawTotals(transactions: transactions, currencySymbol: currencySymbol, currentY: currentY)
            currentY += 20
            
            let headers = ["Date", "Type", "Category", "Account", "Amount"]
            let columnWidths: [CGFloat] = [100, 80, 120, 150, 100]
            
            currentY = drawTableHeader(headers: headers, columnWidths: columnWidths, currentY: currentY, pageRect: pageRect)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            
            for (index, transaction) in transactions.enumerated() {
                if currentY > pageHeight - 50 {
                    context.beginPage()
                    currentY = 40
                    currentY = drawTableHeader(headers: headers, columnWidths: columnWidths, currentY: currentY, pageRect: pageRect)
                }
                
                let dateStr = dateFormatter.string(from: transaction.date)
                let typeStr = transaction.type.rawValue
                let categoryName = categories.first(where: { $0.id == transaction.categoryId })?.name ?? "Unknown"
                let accountName = accounts.first(where: { $0.id == transaction.accountId })?.name ?? "Unknown"
                
                var amountPrefix = ""
                if transaction.type == .income { amountPrefix = "+" }
                else if transaction.type == .expense { amountPrefix = "-" }
                
                let amountStr = "\(amountPrefix)\(currencySymbol)\(String(format: "%.2f", transaction.amount))"
                
                let rowData = [dateStr, typeStr, categoryName, accountName, amountStr]
                
                let isAlternate = index % 2 == 1
                currentY = drawTableRow(rowData: rowData, columnWidths: columnWidths, currentY: currentY, pageRect: pageRect, isAlternate: isAlternate)
            }
        }
        
        return data
    }
    
    // MARK: - PDF Helpers
    
    private static func drawTitle(pageRect: CGRect, dateRange: ClosedRange<Date>?) -> CGFloat {
        let titleFont = UIFont.boldSystemFont(ofSize: 24.0)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont
        ]
        let titleString = "Transaction Report"
        let titleSize = titleString.size(withAttributes: titleAttributes)
        let titleRect = CGRect(x: (pageRect.width - titleSize.width) / 2.0, y: 36, width: titleSize.width, height: titleSize.height)
        titleString.draw(in: titleRect, withAttributes: titleAttributes)
        
        var bottom = titleRect.maxY
        
        if let range = dateRange {
            let subtitleFont = UIFont.systemFont(ofSize: 14.0)
            let subtitleAttributes: [NSAttributedString.Key: Any] = [.font: subtitleFont, .foregroundColor: UIColor.darkGray]
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let subtitleString = "\(formatter.string(from: range.lowerBound)) - \(formatter.string(from: range.upperBound))"
            let subtitleSize = subtitleString.size(withAttributes: subtitleAttributes)
            let subtitleRect = CGRect(x: (pageRect.width - subtitleSize.width) / 2.0, y: titleRect.maxY + 8, width: subtitleSize.width, height: subtitleSize.height)
            subtitleString.draw(in: subtitleRect, withAttributes: subtitleAttributes)
            bottom = subtitleRect.maxY
        }
        
        return bottom
    }
    
    private static func drawTotals(transactions: [Transaction], currencySymbol: String, currentY: CGFloat) -> CGFloat {
        let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        
        let textFont = UIFont.systemFont(ofSize: 14.0)
        let attributes: [NSAttributedString.Key: Any] = [.font: textFont]
        
        let incomeString = "Total Income: \(currencySymbol)\(String(format: "%.2f", income))"
        let expenseString = "Total Expense: \(currencySymbol)\(String(format: "%.2f", expense))"
        
        incomeString.draw(at: CGPoint(x: 40, y: currentY), withAttributes: attributes)
        expenseString.draw(at: CGPoint(x: 300, y: currentY), withAttributes: attributes)
        
        return currentY + 20
    }
    
    private static func drawTableHeader(headers: [String], columnWidths: [CGFloat], currentY: CGFloat, pageRect: CGRect) -> CGFloat {
        let headerFont = UIFont.boldSystemFont(ofSize: 12.0)
        let attributes: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.white]
        
        let headerRect = CGRect(x: 40, y: currentY, width: pageRect.width - 80, height: 24)
        let path = UIBezierPath(rect: headerRect)
        UIColor.darkGray.setFill()
        path.fill()
        
        var currentX: CGFloat = 44
        for (index, header) in headers.enumerated() {
            let rect = CGRect(x: currentX, y: currentY + 4, width: columnWidths[index] - 8, height: 16)
            header.draw(in: rect, withAttributes: attributes)
            currentX += columnWidths[index]
        }
        
        return currentY + 24
    }
    
    private static func drawTableRow(rowData: [String], columnWidths: [CGFloat], currentY: CGFloat, pageRect: CGRect, isAlternate: Bool) -> CGFloat {
        let textFont = UIFont.systemFont(ofSize: 10.0)
        let attributes: [NSAttributedString.Key: Any] = [.font: textFont]
        
        let rowHeight: CGFloat = 20
        
        if isAlternate {
            let rowRect = CGRect(x: 40, y: currentY, width: pageRect.width - 80, height: rowHeight)
            let path = UIBezierPath(rect: rowRect)
            UIColor(white: 0.95, alpha: 1.0).setFill()
            path.fill()
        }
        
        var currentX: CGFloat = 44
        for (index, text) in rowData.enumerated() {
            let rect = CGRect(x: currentX, y: currentY + 4, width: columnWidths[index] - 8, height: rowHeight - 4)
            text.draw(in: rect, withAttributes: attributes)
            currentX += columnWidths[index]
        }
        
        return currentY + rowHeight
    }
    
    // MARK: - Share Activity
    
    static func shareFile(data: Data, filename: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            // iPad popover support
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true, completion: nil)
        } catch {
            print("Failed to save or share file: \(error.localizedDescription)")
        }
    }
}
