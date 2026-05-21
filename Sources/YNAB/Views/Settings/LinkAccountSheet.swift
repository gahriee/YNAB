import SwiftUI

struct LinkAccountSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isSuccess {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Account Linked Successfully!")
                            .font(.title2)
                            .bold()
                        
                        Text("Your data is now safely backed up to this email.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Done") {
                            dismiss()
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                } else {
                    Text("Secure your data by linking your guest account to an email address.")
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                        .foregroundColor(.secondary)
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        Task {
                            await linkAccount()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Link Account")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Link Email")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !isSuccess {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func linkAccount() async {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters long."
            return
        }
        
        isLoading = true
        errorMessage = ""
        do {
            try await authService.linkEmail(email: email, password: password)
            isSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
