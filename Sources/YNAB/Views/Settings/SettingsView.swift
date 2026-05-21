import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var authService: AuthService
    
    @State private var showExportSheet = false
    @State private var showPINSetup = false
    @State private var showLinkAccountSheet = false
    @State private var showDeleteAccountConfirmation = false
    
    let currencies = ["PHP": "₱", "USD": "$", "EUR": "€", "GBP": "£", "JPY": "¥"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Manage") {
                    NavigationLink(destination: AccountListView()) {
                        Label("Accounts", systemImage: "building.columns.fill")
                    }
                    NavigationLink(destination: CategoryListView()) {
                        Label("Categories", systemImage: "tag.fill")
                    }
                    NavigationLink(destination: RecurringListView()) {
                        Label("Recurring", systemImage: "arrow.trianglehead.2.counterclockwise")
                    }
                }
                
                Section("Preferences") {
                    Picker("Currency", selection: Binding(
                        get: { dataStore.userSettings.currency },
                        set: { newCurrency in
                            var settings = dataStore.userSettings
                            settings.currency = newCurrency
                            settings.currencySymbol = currencies[newCurrency] ?? "$"
                            Task { try? await dataStore.updateSettings(settings) }
                        }
                    )) {
                        ForEach(currencies.keys.sorted(), id: \.self) { key in
                            Text("\(key) (\(currencies[key] ?? ""))").tag(key)
                        }
                    }
                    
                    Picker("Theme", selection: Binding(
                        get: { dataStore.userSettings.colorTheme },
                        set: { newTheme in
                            var settings = dataStore.userSettings
                            settings.colorTheme = newTheme
                            Task { try? await dataStore.updateSettings(settings) }
                        }
                    )) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                }
                
                Section("Security") {
                    Toggle("Enable PIN", isOn: Binding(
                        get: { dataStore.userSettings.isPINEnabled },
                        set: { newValue in
                            if newValue {
                                showPINSetup = true
                            } else {
                                var settings = dataStore.userSettings
                                settings.isPINEnabled = false
                                settings.pin = nil
                                settings.isBiometricEnabled = false // disable biometric if PIN is disabled
                                Task { try? await dataStore.updateSettings(settings) }
                            }
                        }
                    ))
                    
                    if dataStore.userSettings.isPINEnabled {
                        Toggle("Enable Face ID / Touch ID", isOn: Binding(
                            get: { dataStore.userSettings.isBiometricEnabled },
                            set: { newValue in
                                var settings = dataStore.userSettings
                                settings.isBiometricEnabled = newValue
                                Task { try? await dataStore.updateSettings(settings) }
                            }
                        ))
                    }
                }
                
                Section("Notifications") {
                    Toggle("Budget & Recurring Alerts", isOn: Binding(
                        get: { dataStore.userSettings.notificationsEnabled },
                        set: { newValue in
                            var settings = dataStore.userSettings
                            settings.notificationsEnabled = newValue
                            Task {
                                if newValue {
                                    let granted = await NotificationService.requestPermission()
                                    settings.notificationsEnabled = granted
                                } else {
                                    NotificationService.cancelAll()
                                }
                                try? await dataStore.updateSettings(settings)
                            }
                        }
                    ))
                }
                
                Section("Export") {
                    Button(action: { showExportSheet = true }) {
                        Label("Export Transactions", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section("Account") {
                    if authService.isAnonymous {
                        HStack {
                            Text("Guest User")
                            Spacer()
                            Text("Not Backed Up").foregroundColor(.red).font(.caption)
                        }
                        
                        Button("Link Email Account") {
                            showLinkAccountSheet = true
                        }
                        
                        #if os(iOS)
                        Button("Link Google Account") {
                            Task {
                                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                      let window = windowScene.windows.first,
                                      let rootVC = window.rootViewController else { return }
                                try? await authService.linkGoogle(presenting: rootVC)
                            }
                        }
                        #endif
                    } else {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(authService.user?.email ?? "Linked").foregroundColor(.secondary)
                        }
                    }
                    
                    Button("Sign Out") {
                        try? authService.signOut()
                    }
                    
                    Button("Delete Account", role: .destructive) {
                        showDeleteAccountConfirmation = true
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showExportSheet) {
                ExportSheet()
            }
            .sheet(isPresented: $showPINSetup) {
                PINSetupSheet()
            }
            .sheet(isPresented: $showLinkAccountSheet) {
                LinkAccountSheet()
            }
            .alert("Delete Account", isPresented: $showDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        try? await authService.deleteAccount()
                    }
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
        }
    }
}
