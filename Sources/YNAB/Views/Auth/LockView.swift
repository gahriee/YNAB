import SwiftUI
import CryptoKit
import LocalAuthentication

struct LockView: View {
    @Binding var isUnlocked: Bool
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var authService: AuthService
    
    @State private var enteredPIN = ""
    @State private var errorMessage = ""
    
    @State private var wrongAttempts = 0
    @State private var cooldownRemaining = 0
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundColor(.accentColor)
                .padding(.top, 50)
            
            Text("Enter PIN")
                .font(.title2)
                .bold()
            
            HStack(spacing: 15) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index < enteredPIN.count ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 20, height: 20)
                }
            }
            
            if cooldownRemaining > 0 {
                Text("Try again in \(cooldownRemaining) seconds")
                    .foregroundColor(.red)
                    .font(.subheadline)
            } else if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
            } else {
                Text(" ") // Placeholder for spacing
                    .font(.subheadline)
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
                    .disabled(cooldownRemaining > 0)
                }
                
                if dataStore.userSettings.isBiometricEnabled {
                    Button(action: {
                        authenticateWithBiometrics()
                    }) {
                        Image(systemName: "faceid")
                            .font(.title)
                            .frame(width: 70, height: 70)
                            .foregroundColor(.primary)
                    }
                    .disabled(cooldownRemaining > 0)
                } else {
                    Spacer()
                }
                
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
                .disabled(cooldownRemaining > 0)
                
                Button(action: {
                    deleteDigit()
                }) {
                    Image(systemName: "delete.left.fill")
                        .font(.title)
                        .frame(width: 70, height: 70)
                        .foregroundColor(.primary)
                }
                .disabled(cooldownRemaining > 0 || enteredPIN.isEmpty)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .onAppear {
            if dataStore.userSettings.isBiometricEnabled {
                authenticateWithBiometrics()
            }
        }
    }
    
    private func appendDigit(_ digit: String) {
        guard cooldownRemaining == 0, enteredPIN.count < 6 else { return }
        
        enteredPIN.append(digit)
        if enteredPIN.count == 6 {
            verifyPIN()
        }
    }
    
    private func deleteDigit() {
        guard cooldownRemaining == 0, !enteredPIN.isEmpty else { return }
        enteredPIN.removeLast()
        errorMessage = ""
    }
    
    private func verifyPIN() {
        let hashedInput = hashPIN(enteredPIN)
        
        var isMatch = false
        if let storedData = try? KeychainService.load(key: KeychainService.pinHashKey),
           let storedHash = String(data: storedData, encoding: .utf8) {
            isMatch = (hashedInput == storedHash)
        } else if let legacyPin = dataStore.userSettings.pin {
            isMatch = (hashedInput == legacyPin)
        }
        
        if isMatch {
            withAnimation {
                isUnlocked = true
                wrongAttempts = 0
            }
        } else {
            enteredPIN = ""
            wrongAttempts += 1
            
            if wrongAttempts >= 10 {
                // Max attempts reached, sign out as danger step
                do {
                    try authService.signOut()
                } catch {
                    print("Failed to sign out after 10 attempts: \(error.localizedDescription)")
                }
            } else if wrongAttempts >= 3 {
                startCooldown()
            } else {
                errorMessage = "Incorrect PIN. \(10 - wrongAttempts) attempts remaining."
            }
        }
    }
    
    private func startCooldown() {
        cooldownRemaining = 30
        errorMessage = "Too many failed attempts."
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if cooldownRemaining > 0 {
                cooldownRemaining -= 1
            } else {
                timer?.invalidate()
                errorMessage = ""
                // Reset wrong attempts slightly to allow trying again without immediate cooldown
                wrongAttempts = 0
            }
        }
    }
    
    private func hashPIN(_ pin: String) -> String {
        let inputData = Data(pin.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock YNAB"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        withAnimation {
                            isUnlocked = true
                            wrongAttempts = 0
                        }
                    } else {
                        errorMessage = "Biometric authentication failed."
                    }
                }
            }
        } else {
            errorMessage = "Biometrics not available."
        }
    }
}
