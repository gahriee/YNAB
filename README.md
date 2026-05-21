# 💰 YNAB — You Need A Budget

A personal finance tracker for **iOS** built with **Swift**, **SwiftUI**, and **Firebase**.

Take control of your money — track income, expenses, budgets, and recurring transactions all in one beautifully designed app.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📊 **Dashboard** | At-a-glance balance summary, recent transactions, and budget alerts |
| 💸 **Transactions** | Full ledger — add, edit, and delete income, expenses, and transfers |
| 🎯 **Budgets** | Set monthly or weekly spending limits per category with progress tracking |
| 🏦 **Accounts** | Manage wallets (cash, bank, credit card, investment) with individual balances |
| 🏷️ **Categories** | Custom income and expense categories with SF Symbol icons |
| 📈 **Reports** | Visual charts — spending breakdown, income vs. expense trends, net worth |
| 🔁 **Recurring** | Schedule repeating transactions (subscriptions, salary, bills) |
| 📤 **Export** | Export transaction history as CSV or PDF |
| 🔒 **Security** | PIN code and Face ID / Touch ID lock screen |
| 🌙 **Themes** | System, Light, and Dark mode support |

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Language** | Swift 6 |
| **UI** | SwiftUI |
| **Architecture** | MVVM |
| **Backend** | Firebase (Firestore + Auth) |
| **Charts** | Swift Charts |
| **Cloud Sync** | Firestore real-time listeners |
| **Security** | Keychain + LocalAuthentication |
| **Notifications** | UserNotifications |
| **Build System** | XcodeGen |
| **Min Deployment** | iOS 17.0 |

---

## 📁 Project Structure

```
YNAB/
├── App/                        # Entry point (FirebaseApp.configure) & root navigation
├── Models/                     # Codable data models & enums
├── Services/                   # Firebase CRUD, Auth, DataStore, Budget, Export, etc.
├── Views/                      # Feature-based view modules
│   ├── Auth/                   #   Login (Firebase Auth) + PIN / biometric lock
│   ├── Dashboard/              #   Home screen
│   ├── Transactions/           #   Ledger & add/edit
│   ├── Budgets/                #   Budget management
│   ├── Categories/             #   Category management
│   ├── Accounts/               #   Account management
│   ├── Reports/                #   Charts & analytics
│   ├── Recurring/              #   Scheduled transactions
│   └── Settings/               #   App preferences
├── Components/                 # Shared reusable UI components
└── GoogleService-Info.plist    # Firebase project configuration
```

---

## 🚀 Getting Started

### Prerequisites

- **macOS 14+** (Sonoma or later)
- **Xcode 16+**
- **Swift 6.0+**
- **XcodeGen** — to generate the `.xcodeproj` from the `project.yml`

### Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-username/YNAB.git
   cd YNAB
   ```

2. **Set up Firebase**

   - Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project (or use an existing one)
   - Add an iOS app with bundle ID `com.ynab.app`
   - Download `GoogleService-Info.plist` and place it in the `YNAB/` directory
   - Enable **Authentication** → Sign-in method → Anonymous (and optionally Email/Password)
   - Enable **Cloud Firestore** and start in **test mode** (update security rules for production)

3. **Install XcodeGen** (if not already installed)

   ```bash
   # Via Homebrew (recommended)
   brew install xcodegen

   # Or via Mint
   mint install yonaskolb/XcodeGen
   ```

4. **Generate the Xcode project**

   ```bash
   xcodegen generate
   ```

   This reads the `project.yml` file and generates `YNAB.xcodeproj` with Firebase dependencies resolved via SPM.

5. **Open in Xcode**

   ```bash
   open YNAB.xcodeproj
   ```

6. **Build & Run**

   Select an iOS 17+ simulator and press **⌘R**.

> **Note:** The `YNAB.xcodeproj` directory is git-ignored. Every developer runs `xcodegen generate` after cloning to create their local project file. This avoids `.xcodeproj` merge conflicts entirely. Firebase SPM packages are resolved automatically on first open.

---

## 🏗 XcodeGen

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from a declarative **YAML** configuration (`project.yml`).

### Why XcodeGen?

- **No merge conflicts** — `.xcodeproj` is generated, not committed
- **Readable config** — YAML is human-friendly and easy to review
- **Reproducible builds** — every developer generates the same project
- **Easy CI/CD** — just run `xcodegen generate` before building

### Key Commands

| Command | Description |
|---------|-------------|
| `xcodegen generate` | Generate `YNAB.xcodeproj` from `project.yml` |
| `xcodegen dump` | Validate and dump the resolved project spec |
| `xcodegen generate --use-cache` | Skip regeneration if `project.yml` hasn't changed |

### project.yml Overview

```yaml
name: YNAB
options:
  bundleIdPrefix: com.ynab
  deploymentTarget:
    iOS: "17.0"

packages:
  Firebase:
    url: https://github.com/firebase/firebase-ios-sdk
    majorVersion: "11.0.0"

targets:
  YNAB:
    type: application
    platform: iOS
    sources: [YNAB]
    dependencies:
      - package: Firebase
        product: FirebaseAuth
      - package: Firebase
        product: FirebaseFirestore
  YNABTests:
    type: bundle.unit-test
    platform: iOS
    sources: [YNABTests]
    dependencies:
      - target: YNAB
```

For the full configuration, see [`project.yml`](project.yml) or the [Architecture Document](FinanceTracker_Architecture.md#14-build-system--xcodegen).

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [Architecture](FinanceTracker_Architecture.md) | Full software architecture — modules, data models, navigation, screen specs, persistence strategy |
| [Project Status](project-status.md) | Current implementation progress and phased roadmap |

---

## 📝 License

This project is for personal/educational use.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Run `xcodegen generate` to regenerate the project
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request
