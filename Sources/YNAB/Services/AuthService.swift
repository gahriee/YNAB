import Foundation
@preconcurrency import FirebaseAuth
@preconcurrency import GoogleSignIn

/// Manages Firebase Authentication state — anonymous sign-in with future upgrade path.
@MainActor
class AuthService: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isAuthenticated = false

    private var authStateListener: AuthStateDidChangeListenerHandle?

    // MARK: - Lifecycle

    init() {
        setupAuthStateListener()
    }

    // MARK: - Auth State

    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
    }

    var uid: String? {
        user?.uid
    }
    
    var isAnonymous: Bool {
        user?.isAnonymous ?? true
    }

    // MARK: - Sign In

    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        self.user = result.user
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        self.user = result.user
    }
    
    func signUpWithEmail(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        self.user = result.user
    }
    
    #if os(iOS)
    func signInWithGoogle(presenting: UIViewController) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
        guard let idToken = result.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: result.user.accessToken.tokenString)
        let authResult = try await Auth.auth().signIn(with: credential)
        self.user = authResult.user
    }
    #endif

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func linkEmail(email: String, password: String) async throws {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await Auth.auth().currentUser?.link(with: credential)
    }
    
    #if os(iOS)
    func linkGoogle(presenting: UIViewController) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
        guard let idToken = result.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: result.user.accessToken.tokenString)
        try await Auth.auth().currentUser?.link(with: credential)
    }
    #endif
    
    func deleteAccount() async throws {
        try await Auth.auth().currentUser?.delete()
        self.user = nil
    }
}
