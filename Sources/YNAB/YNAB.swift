import SwiftUI
import FirebaseCore
@preconcurrency import FirebaseFirestore
@main
struct YNABApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var dataStore = DataStore()
    @State private var isUnlocked = false
    @Environment(\.scenePhase) var scenePhase

    init() {
        FirebaseApp.configure()
        
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber) // 100 MB cache
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            RootView(isUnlocked: $isUnlocked)
                .environmentObject(authService)
                .environmentObject(dataStore)
                .preferredColorScheme(colorScheme(for: dataStore.userSettings.colorTheme))
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                isUnlocked = false
            }
        }
    }
    
    private func colorScheme(for theme: ColorTheme) -> ColorScheme? {
        switch theme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
