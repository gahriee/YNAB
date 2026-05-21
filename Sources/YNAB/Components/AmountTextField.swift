import SwiftUI

struct AmountTextField: View {
    @Binding var value: Double
    let currencySymbol: String
    
    @State private var textValue: String = ""

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(currencySymbol)
                .font(.title)
                .foregroundStyle(.secondary)
            
            TextField("0.00", text: $textValue)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .keyboardType(.decimalPad)
                .onChange(of: textValue) { _, newValue in
                    let filtered = newValue.filter { "0123456789.".contains($0) }
                    let components = filtered.components(separatedBy: ".")
                    
                    var finalString = filtered
                    if components.count > 2 {
                        finalString = components[0] + "." + components.dropFirst().joined()
                    }
                    
                    if finalString != newValue {
                        textValue = finalString
                    }
                    
                    if let doubleValue = Double(finalString) {
                        value = doubleValue
                    } else if finalString.isEmpty {
                        value = 0
                    }
                }
                .onAppear {
                    if value > 0 {
                        textValue = String(format: "%.2f", value)
                    }
                }
        }
    }
}
