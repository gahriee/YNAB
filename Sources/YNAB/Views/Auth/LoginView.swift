import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isShowingSignUp = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                Text("YNAB")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                TextField("Email", text: $email)
#if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
#endif
                    .padding()
                    .background(Color.secondarySystemGroupedBackground)
                    .cornerRadius(10)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.secondarySystemGroupedBackground)
                    .cornerRadius(10)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    Task {
                        await signIn()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                NavigationLink(destination: SignUpView(), isActive: $isShowingSignUp) {
                    Text("Don't have an account? Sign Up")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                
                Divider()
                    .padding(.vertical, 10)
                
                #if os(iOS)
                Button(action: {
                    Task {
                        await signInWithGoogle()
                    }
                }) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                        Text("Sign in with Google")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                }
                #endif
                
                Button(action: {
                    Task {
                        await signInAnonymously()
                    }
                }) {
                    Text("Continue as Guest")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private func signIn() async {
        isLoading = true
        errorMessage = ""
        do {
            try await authService.signInWithEmail(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    #if os(iOS)
    private func signInWithGoogle() async {
        isLoading = true
        errorMessage = ""
        do {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootVC = window.rootViewController else { return }
            
            try await authService.signInWithGoogle(presenting: rootVC)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    #endif
    
    private func signInAnonymously() async {
        isLoading = true
        errorMessage = ""
        do {
            try await authService.signInAnonymously()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
