# YNAB (You Need A Budget) — Project Status

> **Last Updated:** 2026-05-21 (Phase 5 Advanced)

---

## Overview

YNAB is an iOS personal finance tracker built with **Swift 6**, **SwiftUI**, and the **MVVM** pattern. The project has completed all 5 phases, concluding with **Phase 5 — Advanced**. The app now features robust Google and Email authentication, Keychain-secured PIN storage, Firestore offline persistence, and comprehensive Unit and UI testing.

---

## Module Progress

| # | Module | Status | Notes |
|---|--------|--------|-------|
| 1 | **Auth** | 🟢 Complete | Email & Google Sign-in, Guest linking, PIN lock screen |
| 2 | **Dashboard** | 🟢 Complete | Balance summary, recent transactions, quick-add FAB |
| 3 | **Transactions** | 🟢 Complete | Full ledger — add, edit, delete income & expenses |
| 4 | **Budgets** | 🟢 Complete | Monthly spending limits per category |
| 5 | **Categories** | 🟢 Complete | Custom income / expense categories with icons |
| 6 | **Accounts** | 🟢 Complete | Wallets (cash, bank, card) with individual balances |
| 7 | **Reports** | 🟢 Complete | Charts via Swift Charts |
| 8 | **Recurring** | 🟢 Complete | Scheduled repeating transactions |
| 9 | **Export** | 🟢 Complete | CSV / PDF export |
| 10 | **Settings** | 🟢 Complete | Currency, theme, notifications, data reset |

---

## Layer Progress

| Layer | Status | Details |
|-------|--------|---------|
| **Project Skeleton** | 🟢 Complete | `Package.swift` configured, Swift 6, executable target + test target |
| **Architecture Doc** | 🟢 Complete | Full module plan, data models, navigation, screen specs documented |
| **XcodeGen Config** | 🟢 Complete | `project.yml` updated with Firebase SPM deps + correct source paths |
| **Firebase Setup** | 🟢 Complete | `GoogleService-Info.plist` integrated |
| **Data Models** | 🟢 Complete | `Codable` structs with `@DocumentID` — `Account`, `Category`, `Transaction`, `RecurringRule`, `Budget`, `UserSettings` + all enums |
| **Firebase Auth** | 🟢 Complete | `AuthService` — anonymous sign-in + auth state listener + future email linking |
| **Firestore Persistence** | 🟢 Complete | `FirebaseService` — generic CRUD, real-time listeners, document-level listeners |
| **Services** | 🟢 Complete | `DataStore` complete — `RecurringService`, `BudgetService` complete — `ExportService`, `NotificationService` pending |
| **Views** | 🟢 Complete | Dashboard, Transactions, Accounts, Categories, Reports, Budgets, Recurring complete. Settings pending. |
| **Components** | 🟢 Complete | `FloatingActionButton`, `BalanceCard`, `TransactionRow`, `BudgetProgressBar` etc. |
| **Navigation** | 🟢 Complete | Tab-based `MainTabView` with auth gate and lock gate |
| **Notifications** | 🟢 Complete | Budget alerts, recurring reminders |
| **Firestore Security Rules** | 🟢 Complete | Per-user data scoping rules |
| **Keychain** | 🟢 Complete | PIN hash stored securely in Keychain |
| **Seed Data** | 🟢 Complete | Default accounts & categories seeded on first launch (written to Firestore) |
| **Unit Tests** | 🟢 Complete | `YNABTests` with `BudgetService`, `RecurringService`, `ExportService` tests |
| **UI Tests** | 🟢 Complete | `YNABUITests` with navigation and login flow tests |

---

## Current File Structure

```
YNAB/
├── .gitignore
├── Package.swift                      ← Swift 6, iOS 17+, Firebase SPM deps
├── project.yml                        ← XcodeGen config (sources → Sources/YNAB)
├── FinanceTracker_Architecture.md     ← Full architecture document (YNAB-branded)
├── README.md
├── project-status.md
├── Sources/
│   └── YNAB/
│       ├── YNAB.swift                 ← @main SwiftUI App entry point
│       ├── App/
│       │   └── RootView.swift         ← Auth gate → MainTabView (placeholder tabs)
│       ├── Components/
│       │   └── BudgetProgressBar.swift
│       ├── Models/
│       │   └── Models.swift           ← All data models + enums + errors
│       ├── Views/
│       │   ├── Budgets/
│       │   │   ├── BudgetListView.swift
│       │   │   └── AddBudgetSheet.swift
│       │   ├── Reports/
│       │   │   └── ReportsView.swift
│       │   ├── Recurring/
│       │   │   ├── RecurringListView.swift
│       │   │   └── AddRecurringSheet.swift
│       │   └── ...
│       └── Services/
│           ├── AuthService.swift      ← Firebase Auth (anonymous + email link)
│           ├── FirebaseService.swift  ← Generic Firestore CRUD + listeners
│           ├── DataStore.swift        ← Central ObservableObject store
│           ├── BudgetService.swift
│           ├── RecurringService.swift
│           └── KeychainService.swift  ← Secure storage access
└── Tests/
    ├── YNABTests/                     ← Unit test target (Swift Testing)
    └── YNABUITests/                   ← UI test target (XCTest)
```

---

## Recommended Next Steps

### Phase 1 — Foundation (Priority: High)
1. [x] Create `project.yml` for XcodeGen (with Firebase SPM dependencies)
2. [x] Set up Firebase project + download `GoogleService-Info.plist`
3. [x] Define all Codable data models in `Models/Models.swift` (with `@DocumentID`)
4. [x] Implement `AuthService` (anonymous sign-in + auth state listener)
5. [x] Implement `FirebaseService` (generic Firestore CRUD + real-time listeners)
6. [x] Create `DataStore` as the single source of truth (`ObservableObject` + Firestore listeners)
7. [x] Implement `YNABApp.swift` with `FirebaseApp.configure()`

### Phase 2 — Core Views (Priority: High)
8. [x] Build `RootView` with auth gate logic and lock gate
9. [x] Build `LoginView` and `SignUpView` (Email & Google sign-in)
10. [x] Build `MainTabView` with 5 tabs (Dashboard, Transactions, Settings wired)
11. [x] Implement `DashboardView` with balance card & recent transactions
12. [x] Implement `TransactionListView` + `AddTransactionSheet` + `TransactionDetailView`
13. [x] Implement `AccountListView` + `AddAccountSheet`
14. [x] Implement `CategoryListView` + `AddCategorySheet`

### Phase 3 — Budget & Reports (Priority: Medium)
15. [x] Implement `BudgetListView` + `AddBudgetSheet`
16. [x] Implement `BudgetService` for progress calculations
17. [x] Implement `ReportsView` with Swift Charts
18. [x] Implement `RecurringListView` + `RecurringService`

### Phase 4 — Polish (Priority: Medium)
19. [x] Implement `SettingsView`
20. [x] Implement `ExportService` (CSV + PDF)
21. [x] Implement `NotificationService`
22. [x] Implement `LockView` (PIN + biometric)
23. [x] Add default seed data on first launch (write to Firestore)
24. [x] Deploy Firestore security rules

### Phase 5 — Advanced (Priority: Low)
25. [x] Email / Google Sign-In (upgrade from anonymous auth)
26. [x] Keychain storage for PIN hash
27. [x] Firestore offline persistence configuration
28. [x] Unit test coverage for services
29. [x] UI test coverage for critical flows

---

## Legend

| Icon | Meaning |
|------|---------|
| 🟢 | Complete |
| 🟡 | In Progress |
| 🔴 | Not Started |
