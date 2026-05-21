import SwiftUI

/// Root navigation controller — auth gate → lock gate → MainTabView.
struct RootView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var dataStore: DataStore
    @Binding var isUnlocked: Bool

    var body: some View {
        Group {
            if authService.isAuthenticated {
                if !dataStore.isLoading {
                    if dataStore.userSettings.isPINEnabled && !isUnlocked {
                        LockView(isUnlocked: $isUnlocked)
                    } else {
                        MainTabView()
                    }
                } else {
                    LoadingView()
                }
            } else {
                LoginView()
            }
        }
        .onAppear {
            if authService.isAuthenticated {
                dataStore.startListening()
            }
        }
        .onChange(of: authService.isAuthenticated) { newValue in
            if newValue {
                dataStore.startListening()
            } else {
                dataStore.stopListening()
            }
        }
    }

}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Setting up YNAB...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.systemBackground)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            TransactionListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle.fill")
                }

            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.pie.fill")
                }

            BudgetListView()
                .tabItem {
                    Label("Budgets", systemImage: "target")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .task {
            do {
                try await dataStore.seedDefaultDataIfNeeded()
                try await RecurringService.processDueTransactions(rules: dataStore.recurringRules, dataStore: dataStore)
            } catch {
                print("MainTabView: Initialization failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Placeholder Tab View

struct PlaceholderTabView: View {
    let title: String
    let icon: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundStyle(.tertiary)
                Text("Coming Soon")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.systemGroupedBackground)
            .navigationTitle(title)
        }
    }
}
