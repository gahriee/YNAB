import SwiftUI
import CryptoKit

struct PINSetupSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore
    
    @State private var enteredPIN = ""
    @State private var confirmPIN = ""
    @State private var isConfirming = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text(isConfirming ? "Confirm your PIN" : "Enter a 6-digit PIN")
                    .font(.title2)
                    .bold()
                
                HStack(spacing: 15) {
                    let currentPIN = isConfirming ? confirmPIN : enteredPIN
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(index < currentPIN.count ? Color.primary : Color.secondary.opacity(0.3))
                            .frame(width: 20, height: 20)
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(1...9, id: \.self) { number in
                        Button(action: {
                            appendDigit("\(number)")
                        }) {
                            Text("\(number)")
                                .font(.title)
                                .frame(width: 70, height: 70)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(Circle())
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        appendDigit("0")
                    }) {
                        Text("0")
                            .font(.title)
                            .frame(width: 70, height: 70)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Circle())
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        deleteDigit()
                    }) {
                        Image(systemName: "delete.left.fill")
                            .font(.title)
                            .frame(width: 70, height: 70)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .padding(.top, 40)
            .navigationTitle("Setup PIN")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func appendDigit(_ digit: String) {
        if isConfirming {
            if confirmPIN.count < 6 {
                confirmPIN.append(digit)
                if confirmPIN.count == 6 {
                    verifyAndSave()
                }
            }
        } else {
            if enteredPIN.count < 6 {
                enteredPIN.append(digit)
                if enteredPIN.count == 6 {
                    isConfirming = true
                }
            }
        }
    }
    
    private func deleteDigit() {
        if isConfirming {
            if !confirmPIN.isEmpty {
                confirmPIN.removeLast()
            } else {
                isConfirming = false
                errorMessage = ""
            }
        } else {
            if !enteredPIN.isEmpty {
                enteredPIN.removeLast()
                errorMessage = ""
            }
        }
    }
    
    private func verifyAndSave() {
        if enteredPIN == confirmPIN {
            let hashedPIN = hashPIN(enteredPIN)
            
            do {
                if let pinData = hashedPIN.data(using: .utf8) {
                    try KeychainService.save(key: KeychainService.pinHashKey, data: pinData)
                }
                
                var settings = dataStore.userSettings
                settings.isPINEnabled = true
                settings.pin = nil // Do not save in Firestore
                
                Task {
                    do {
                        try await dataStore.updateSettings(settings)
                        dismiss()
                    } catch {
                        errorMessage = "Failed to save settings: \(error.localizedDescription)"
                    }
                }
            } catch {
                errorMessage = "Failed to save PIN securely: \(error.localizedDescription)"
            }
        } else {
            errorMessage = "PINs do not match. Try again."
            enteredPIN = ""
            confirmPIN = ""
            isConfirming = false
        }
    }
    
    private func hashPIN(_ pin: String) -> String {
        let inputData = Data(pin.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
