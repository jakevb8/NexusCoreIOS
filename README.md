# NexusCoreIOS

SwiftUI iOS client for [NexusCore](https://github.com/jakevb8/NexusCore) — a multi-tenant Resource Management SaaS. Connects to either the Node.js or .NET backend via a user-selectable toggle.

## Features

- Google Sign-In via Firebase Authentication + GoogleSignIn SDK
- Backend selector: switch between the NexusCoreJS (Node) and NexusCoreDotNet (.NET) APIs
- Asset management: list, search, create, edit, delete, CSV import, sample CSV download
- Team management: invite members by email, copy-link fallback, remove members, change roles
- Reports: utilization rate and assets-by-status breakdown
- Settings: account info, backend picker, sign out
- Full RBAC support (`SUPERADMIN > ORG_MANAGER > ASSET_MANAGER > VIEWER`)

## Tech Stack

| Layer              | Library                                    |
| ------------------ | ------------------------------------------ |
| UI                 | SwiftUI (iOS 16+)                          |
| Navigation         | `NavigationStack` + `NavigationPath`       |
| Auth               | Firebase Auth + GoogleSignIn iOS SDK       |
| HTTP               | `URLSession` with Bearer token interceptor |
| Persistence        | `UserDefaults` (backend preference)        |
| Project generation | xcodegen 2.45.2                            |
| Dependencies       | Swift Package Manager (no CocoaPods)       |

## Getting Started

### Prerequisites

- Xcode 16+
- xcodegen: `brew install xcodegen`
- Firebase CLI: `npm install -g firebase-tools && firebase login`

### Setup

1. **Clone the repo**

   ```bash
   git clone https://github.com/jakevb8/NexusCoreIOS.git
   cd NexusCoreIOS
   ```

2. **Generate the Xcode project**

   ```bash
   xcodegen generate
   ```

3. **Restore `GoogleService-Info.plist`** (gitignored — never commit this file)

   ```bash
   firebase apps:sdkconfig IOS 1:797114794124:ios:2e6c4eebb1fc19f4663ba9 \
     --project nexus-core-rms \
     --out NexusCoreIOS/GoogleService-Info.plist
   ```

4. **Replace placeholders** in `project.yml` with values from `GoogleService-Info.plist`, then re-run `xcodegen generate`:
   - `GIDClientID: PLACEHOLDER_CLIENT_ID` → `CLIENT_ID` value
   - `CFBundleURLSchemes: [PLACEHOLDER_REVERSED_CLIENT_ID]` → `REVERSED_CLIENT_ID` value

5. **Open in Xcode** — SPM will resolve Firebase and GoogleSignIn packages automatically:
   ```bash
   open NexusCoreIOS.xcodeproj
   ```

## Building

Build and run directly from Xcode, or via `xcodebuild`:

```bash
# Build for simulator
xcodebuild -project NexusCoreIOS.xcodeproj \
  -scheme NexusCoreIOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

> **Note:** `project.yml` is the source of truth. Never edit `.xcodeproj` directly — always edit `project.yml` and re-run `xcodegen generate`.

## Firebase / Bundle Details

- **Bundle ID:** `me.jakev.nexuscore`
- **Firebase project:** `nexus-core-rms`
- **Firebase App ID:** `1:797114794124:ios:2e6c4eebb1fc19f4663ba9`

## Related Repos

| Repo                                                            | Description                             |
| --------------------------------------------------------------- | --------------------------------------- |
| [NexusCore](https://github.com/jakevb8/NexusCore)               | Next.js 15 frontend + NestJS REST API   |
| [NexusCoreDotNet](https://github.com/jakevb8/NexusCoreDotNet)   | ASP.NET Core 8 Razor Pages backend      |
| [NexusCoreAndroid](https://github.com/jakevb8/NexusCoreAndroid) | Jetpack Compose Android client          |
| [NexusCoreReact](https://github.com/jakevb8/NexusCoreReact)     | Expo React Native cross-platform client |
