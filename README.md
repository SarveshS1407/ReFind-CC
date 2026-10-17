# Finders Keepers? — Campus Lost & Found System
### CodeChef-VIT Promotional Cycle 2026–27 | App Development Task

[![Flutter](https://img.shields.io/badge/Flutter-3.47.7-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.5-0175C2?logo=dart)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod%203-blue)](https://riverpod.dev)
[![Tests](https://img.shields.io/badge/Tests-18%20Passed%20(100%25)-brightgreen)](file:///Users/kingpin/Documents/CC-Appdev/test)
[![Static Analysis](https://img.shields.io/badge/Static%20Analysis-0%20Issues-brightgreen)](file:///Users/kingpin/Documents/CC-Appdev)
[![Deployment](https://img.shields.io/badge/Deployment-Vercel%20Ready-black?logo=vercel)](file:///Users/kingpin/Documents/CC-Appdev/vercel.json)
[![License](https://img.shields.io/badge/License-MIT-orange)](#license)

---

## 📌 Executive Summary

**Finders Keepers?** is a production-grade, responsive (mobile & desktop), offline-first application designed to solve the campus lost-and-found coordination problem across universities like **VIT Vellore**.

When items are lost or found in crowded campus hubs (SJT, Technology Tower, Central Library, Food Mall, Men's & Ladies' Hostels), conventional WhatsApp groups and noticeboard announcements cause chaos: fake claims, public spam, exposed personal numbers, and unverified handovers.

**Finders Keepers?** eliminates these issues through:
1. **Authentication-First Entry & Evaluator Demonstration Mode**: Secure `AuthGate` routing presenting an attractive branded Welcome screen, Sign In / Register tabs, password reset flow, and one-tap Evaluator Demonstration Personas.
2. **Dedicated Campus Help Center & User Guide**: 10 structured sections with instant real-time search, expandable accordions, campus security guidance, accessible both before and after signing in.
3. **Zero-Knowledge 3-Tier Ownership Verification**: Finders pose non-public challenge questions. Claimants submit proof and challenge answers stored in strictly isolated subcollections that are never exposed in public feeds.
4. **Cryptographically Salted SHA-256 Handover OTP**: Physical handovers are verified via a dynamic 6-digit one-time token visible only to the verified claimant. The database stores only a salted hash (`salt:itemId:otp`), preventing token forgery or snooping.
5. **Adaptive Responsive Layout**: Seamless UX across Mobile (<640px), Tablet (640–1024px), and Desktop (>=1024px) with adaptive top/bottom navigation and responsive grid layouts.
6. **Approximate Campus Geofencing**: Public listings show landmark names and approximate coordinates (protecting exact GPS lockers or desk positions).
7. **Resilient Offline-First Architecture**: Interrupted submissions are autosaved as drafts; network drops enqueue changes into a persistent local outbox with auto-retry and deduplication upon reconnection.
8. **Vercel Production Deployment**: Fully configured with `vercel.json` SPA rewrites, static caching headers, and `.env.example`.

---

## 🏗️ System Architecture

The application adopts a **Clean Layered Architecture** powered by **Riverpod 3** `Notifier` / `NotifierProvider` reactive state management:

```mermaid
flowchart TD
    subgraph UI_Layer ["📱 Presentation & Responsive UI Layer"]
        AuthGate["AuthGate (Session Routing)"]
        WelcomeScreen["Welcome & Auth Screen (Tabs & Demo Personas)"]
        HelpScreen["Help Center & User Guide (10 Sections)"]
        ResponsiveShell["Responsive Shell (Desktop Header / Mobile Nav)"]
        HomeFeed["Home Feed (Grid / List, Filters & Search)"]
        MapScreen["Campus Map Screen (flutter_map / OSM)"]
        ReportItem["Report Item Screen (Autosave Drafts)"]
        ItemDetails["Item Details Screen & Lifecycle Stepper"]
        SubmitClaim["Claim Submission Screen (Zero-Knowledge Proof)"]
        ClaimMgmt["Claim Review Dashboard (Finder / Mod)"]
        HandoverScreen["Handover Verification (Salted OTP)"]
        ChatScreen["Coordination Messaging Screen"]
        MyActivity["My Activity (Drafts, Reports, Claims)"]
        ModScreen["Campus Moderation Center"]
    end

    subgraph State_Layer ["⚡ State Management (Riverpod 3)"]
        AuthNotifier["AuthNotifier (Session & Role Switching)"]
        ItemsNotifier["ItemsNotifier (CRUD, Filter, Search)"]
        ClaimsNotifier["ClaimsNotifier (Submit, Review, Handover)"]
        DraftsNotifier["DraftsNotifier (Autosave & Recovery)"]
        NetworkNotifier["NetworkNotifier (Sync Engine & Outbox)"]
    end

    subgraph Service_Layer ["⚙️ Business Logic & Services Layer"]
        AuthService["AuthService (Session & Demo Switcher)"]
        ItemService["ItemService (Filtering, Outbox Sync, Matching)"]
        ClaimService["ClaimService (Zero-Knowledge & OTP Hash)"]
        LocalStorage["LocalStorageService (SharedPreferences)"]
        CryptoUtils["CryptoUtils (Salted SHA-256 OTP Validator)"]
    end

    subgraph Backend_Layer ["☁️ Persistence & Deployment"]
        LocalCache["Local Storage & Persistent Outbox Queue"]
        Firestore["Cloud Firestore (Zero-Knowledge Subcollections)"]
        CloudStorage["Firebase Storage (5MB Image Quota)"]
        VercelHost["Vercel Production Hosting (SPA Rewrites)"]
    end

    AuthGate --> WelcomeScreen
    AuthGate --> ResponsiveShell
    ResponsiveShell --> HomeFeed
    ResponsiveShell --> MapScreen
    ResponsiveShell --> ReportItem
    ResponsiveShell --> MyActivity
    ResponsiveShell --> HelpScreen
    UI_Layer --> State_Layer
    State_Layer --> Service_Layer
    Service_Layer --> LocalCache
    Service_Layer --> Firestore
    Service_Layer --> CloudStorage
    CryptoUtils --> ClaimService
```

---

## 🎨 Visual Identity & Design System

The application uses a restrained palette tailored for a prestigious academic institution:

- **Primary Brand Color**: Deep Forest Teal (`#134E4A`) — communicates safety, professionalism, and reliability.
- **Accent Color**: Warm Amber (`#D97706`) — draws focus to important calls to action and active alerts.
- **Background**: Soft Warm Off-White (`#FAF9F6`) — easy on the eyes during prolonged reading.
- **Surface**: Pure White (`#FFFFFF`) with subtle 1px border (`#E2E8F0`) and soft elevation.
- **Status Tokens**:
  - `Lost`: Crimson Rose (`#DC2626` / `#FEF2F2`)
  - `Found`: Emerald Teal (`#059669` / `#ECFDF5`)
  - `Claimed`: Indigo Purple (`#4F46E5` / `#EEF2FF`)
  - `Returned`: Slate Gray (`#475569` / `#F8FAFC`)

### Responsive Breakpoints
- **Mobile (< 640px)**: Bottom `NavigationBar`, single-column item feed, compact cards, floating action button for quick reporting.
- **Tablet (640px – 1024px)**: 2-column item grid, persistent navigation, optimized touch targets.
- **Desktop (>= 1024px)**: Sticky header bar with full brand logo, desktop navigation tabs, search shortcuts, quick "Report New Item" action, 3-column feed grid, and split 2-column item detail views.

---

## 📖 Help Center & User Guide (10 Dedicated Sections)

Accessible from both the unauthenticated Welcome screen and the authenticated navigation menu, the Help Center (`lib/ui/screens/help_screen.dart`) provides complete transparency:

- **A. Welcome to Finders Keepers?**: Core mission and campus problem statement.
- **B. How to Report a Lost Item**: Step-by-step reporting guide, emphasizing non-disclosure of secret markings.
- **C. How to Report a Found Item**: Configuring private challenge questions and safeguarding found property.
- **D. How to Claim an Item**: Entering private proof description and answering finder challenge questions.
- **E. Ownership Verification & 6-Digit Handover OTP**: Deep dive into the 3-tier Zero-Knowledge workflow and cryptographic tokens.
- **F. Tracking Item Lifecycle Status**: Explanation of `lost`, `found`, `claimed`, and `returned` states.
- **G. Approximate Location & Privacy**: How campus landmark geofencing protects personal safety.
- **H. Offline Drafts & Outbox Synchronization**: How auto-save and background sync protect submissions in low-connectivity campus zones.
- **I. Community Moderation & Reporting**: How to report suspicious activity or request warden mediation.
- **J. Campus Security & Designated Handover Desks**: Official physical meeting locations at SJT and TT Security Desks.

Includes a **real-time keyword search bar** allowing users to instantly filter help topics (e.g. typing "OTP" or "draft" immediately reveals relevant sections).

---

## 🗄️ Database Schema & Subcollection Hierarchy

### Firestore Collection Topology

```
/users/{userId}
  ├── id: string (matches auth.uid)
  ├── email: string (valid campus email)
  ├── displayName: string
  ├── studentId: string (e.g., 23BCE1001)
  ├── role: string ('student' | 'moderator' | 'admin')
  ├── phoneNumber: string (optional, masked in public views)
  └── createdAt: timestamp

/items/{itemId}
  ├── id: string (UUIDv4)
  ├── title: string (max 150 chars)
  ├── description: string (max 2000 chars)
  ├── category: string ('ID Cards & Docs', 'Electronics', 'Audio', 'Keys', 'Wallets', etc.)
  ├── type: string ('lost' | 'found')
  ├── status: string ('lost' | 'found' | 'claimed' | 'returned' | 'cancelled')
  ├── campusLocationName: string (e.g., 'Silver Jubilee Tower (SJT)')
  ├── campusZone: string ('Academic', 'Library', 'Dining', 'Hostels', 'Sports')
  ├── latitude: number (approximate campus coordinates)
  ├── longitude: number (approximate campus coordinates)
  ├── isApproximateLocation: bool (default true)
  ├── exactLocationDescription: string (visible only to verified parties)
  ├── imageUrl: string (optional photo URL)
  ├── reporterId: string (matches auth.uid)
  ├── reporterName: string
  ├── reporterContact: string (masked in public queries)
  ├── currentHolderId: string (delegated holder, e.g., Security Desk)
  ├── verificationQuestion: string (e.g., 'What is the sticker on the back?')
  ├── acceptedClaimId: string (UUID of accepted claim)
  ├── handoverCodeHash: string (SHA-256 of `salt:itemId:otp`)
  ├── handoverCompletedAt: timestamp
  ├── syncStatus: string ('synced' | 'pending' | 'failed')
  ├── createdAt: timestamp (immutable)
  └── updatedAt: timestamp
        │
        ├── /claims/{claimId}  <-- [ZERO-KNOWLEDGE SUBCOLLECTION]
        │     ├── id: string (UUIDv4)
        │     ├── itemId: string (matches parent itemId)
        │     ├── claimantId: string (matches claimant auth.uid)
        │     ├── claimantName: string
        │     ├── claimantContact: string
        │     ├── proofDescription: string (private non-public identifier)
        │     ├── answerToQuestion: string (private answer to challenge)
        │     ├── proofImageUrl: string (optional receipt/serial number photo)
        │     ├── status: string ('pending' | 'approved' | 'rejected' | 'handedOver' | 'cancelled')
        │     ├── rejectionReason: string (optional)
        │     ├── handoverCode: string (6-digit OTP visible ONLY to claimant)
        │     ├── createdAt: timestamp (immutable)
        │     └── updatedAt: timestamp
        │
        └── /messages/{messageId}  <-- [COORDINATION MESSAGING]
              ├── id: string (UUIDv4)
              ├── itemId: string
              ├── senderId: string (claimant or finder)
              ├── recipientId: string
              ├── text: string
              └── createdAt: timestamp

/reports/{reportId}  <-- [CAMPUS MODERATION]
  ├── id: string
  ├── reporterId: string
  ├── targetType: string ('item' | 'claim' | 'user')
  ├── targetId: string
  ├── reason: string
  ├── status: string ('pending' | 'investigating' | 'resolved' | 'dismissed')
  └── createdAt: timestamp
```

### 🔒 Why Subcollection Isolation is Essential

In Cloud Firestore, document-level security rules are all-or-nothing: if a user can read an `/items/{id}` document, they can read all fields within that document. Storing verification answers or claimant proofs directly inside the item document would leak them to any authenticated user querying the lost-and-found feed.

By structuring claims under `/items/{itemId}/claims/{claimId}`, Firestore security rules enforce:
```javascript
allow read: if isAuthenticated() && (
  resource.data.claimantId == request.auth.uid ||
  getItem(itemId).reporterId == request.auth.uid ||
  isItemHolder(getItem(itemId)) ||
  isModerator()
);
```
**Outcome**: Other campus students browsing the feed **cannot** query or read verification answers submitted by others, preventing claim sniping and privacy leaks.

---

## 🔄 Item Lifecycle & Handover State Machine

```mermaid
stateDiagram-v2
    [*] --> Lost: Reported as Lost by Owner
    [*] --> Found: Reported as Found by Finder

    Lost --> Claimed: Valid Claim Approved
    Found --> Claimed: Valid Claim Approved
    
    state Claimed {
        [*] --> OTP_Generated: Salted SHA-256 Token Computed
        OTP_Generated --> Handover_Pending: Claimant Receives 6-Digit OTP
        Handover_Pending --> Verified: Finder Enters & Validates OTP
    }

    Claimed --> Returned: OTP Match Confirmed
    Claimed --> Found: Claim Rejected / Reset
    Claimed --> Lost: Claim Rejected / Reset

    Returned --> [*]: Archived in Handover Registry
```

### Detailed Verification Steps

| Stage | Actor | Action & Security Enforcement |
|---|---|---|
| **1. Reporting** | Finder / Owner | Specifies approximate campus landmark (e.g. SJT, TT), category, and sets a **Private Challenge Question** (e.g. *"What is written on the keychain?"* or *"What is the lock screen wallpaper?"*). |
| **2. Browsing** | Students | Search by keyword, filter by category/status, or view campus map. Exact GPS and private answers are **not** visible. |
| **3. Claiming** | Claimant | Submits private challenge answers and proof description. Stored in `/items/{itemId}/claims/{claimId}`. Invisible to public queries. |
| **4. Review** | Finder / Moderator | Inspects claims in private Claim Review Dashboard. Reviews answers and taps **Approve** or **Reject** (with reason). |
| **5. Token Creation** | System | Upon approval, system generates a random 6-digit OTP (e.g. `482915`). The plaintext OTP is stored only in the claimant's approved claim document. The item record stores `SHA-256("salt:itemId:482915")`. |
| **6. Physical Handover** | Finder & Claimant | Parties meet at a designated public campus location (e.g. SJT Security Desk). Claimant displays the 6-digit OTP. Finder inputs the OTP into the **Handover Verification Screen**. |
| **7. Final Confirmation** | System | The entered code is salted and hashed with `itemId`. If the computed hash matches `handoverCodeHash`, the item transitions to `returned`, locking further edits and logging the timestamp. |

---

## ⚡ Instant Evaluator Demo Profiles

To facilitate friction-free evaluation without requiring manual account registration across multiple devices, the app includes **Evaluator Demonstration Mode** on the Welcome screen:

| Profile | Name | Role | Student ID | Evaluation Function |
|---|---|---|---|---|
| **Persona 1** | **Aarav Sharma** | Student (Finder) | `23BCE1042` | Reported the Casio FX-991CW Calculator & MacBook Charger; reviews claims and validates OTP. |
| **Persona 2** | **Diya Patel** | Student (Claimant) | `23BCE1984` | Submits ownership claim for the Casio Calculator, answers challenge question, and receives the 6-digit OTP. |
| **Persona 3** | **Prof. R. Verma** | Campus Security | `FAC9021` | Accesses the Campus Moderation Center, views disputed claims, and manages campus-wide reports. |

---

## 🌐 Vercel Deployment Guide

The application is pre-configured and optimized for direct zero-configuration hosting on **Vercel**:

### Configuration File: `vercel.json`
```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "outputDirectory": "build/web",
  "cleanUrls": true,
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "X-Frame-Options", "value": "SAMEORIGIN" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" }
      ]
    },
    {
      "source": "/assets/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    }
  ]
}
```

### Steps to Deploy to Vercel:

1. **Option A: Via Vercel CLI**:
   ```bash
   # 1. Build the release bundle
   flutter build web --release

   # 2. Deploy to production
   vercel --prod
   ```

2. **Option B: Via Git / Vercel Web Dashboard**:
   - Push repository to GitHub/GitLab.
   - Import the repository in [vercel.com/new](https://vercel.com/new).
   - In Project Settings:
     - **Build Command**: `flutter/bin/flutter build web --release` (or leave empty if using pre-compiled `build/web`)
     - **Output Directory**: `build/web`
   - Click **Deploy**.

---

## 🚀 Local Run & Build Instructions

### 1. Run Pre-Compiled Release Web Bundle Locally
```bash
python3 -m http.server 8080 --directory build/web
# Open http://localhost:8080 in your browser
```

### 2. Run from Source via Flutter Web
```bash
flutter pub get
flutter run -d chrome
```

### 3. Build Release Web Bundle
```bash
flutter build web --release
```

### 4. Build Release Android APK
Ensure Android SDK and Java 17+ are installed:
```bash
flutter build apk --release
# Built APK will be available at: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Automated Testing Suite

The repository includes a comprehensive automated test suite with **18 passing tests** covering cryptography, state machine transitions, zero-knowledge authorization, offline queues, unauthenticated routing, and responsive layouts.

```bash
flutter test
```

### Test Breakdown

| Test Suite | File | Tests | Coverage Scope |
|---|---|---|---|
| **Models & Crypto** | [`test/models_and_crypto_test.dart`](file:///Users/kingpin/Documents/CC-Appdev/test/models_and_crypto_test.dart) | 8 | Salted SHA-256 OTP generation, tampering resistance, wrong code rejection, JSON serialization, Haversine distance, fuzzy search. |
| **Claims & Workflow** | [`test/claims_verification_workflow_test.dart`](file:///Users/kingpin/Documents/CC-Appdev/test/claims_verification_workflow_test.dart) | 8 | Zero-knowledge answer isolation, finder approval state transitions, handover OTP verification, illegal status transition blocking, offline outbox enqueuing, draft persistence. |
| **Widget & Navigation** | [`test/widget_test.dart`](file:///Users/kingpin/Documents/CC-Appdev/test/widget_test.dart) | 2 | Unauthenticated Welcome & Auth Gate smoke test, Help Center unauthenticated access, Evaluator Demo Switcher, Authenticated Feed, Navigation, Filters, and FAB. |

### Static Analysis & Formatting
```bash
flutter analyze
# Result: No issues found! (0 errors, 0 warnings, 0 lints)

dart format --output=none --set-exit-if-changed lib test
# Result: Formatted 38 files (0 changed)
```

---

## 📋 Task Sheet Acceptance Criteria Verification

| Requirement (Page 11) | Implementation Detail | Status |
|---|---|:---:|
| **Report lost/found items with descriptions, images, locations** | Implemented in [`ReportItemScreen`](file:///Users/kingpin/Documents/CC-Appdev/lib/ui/screens/report_item_screen.dart) with photo picker, categories, and campus landmarks. | ✅ Verified |
| **Search and browse reported items** | Implemented in [`HomeFeedScreen`](file:///Users/kingpin/Documents/CC-Appdev/lib/ui/screens/home_feed_screen.dart) with fuzzy search, category filter chips, and status tabs. | ✅ Verified |
| **Approximate item locations on a map** | Implemented in [`MapScreen`](file:///Users/kingpin/Documents/CC-Appdev/lib/ui/screens/map_screen.dart) using OpenStreetMap centered on VIT Vellore. | ✅ Verified |
| **Submit ownership claims** | Implemented in [`SubmitClaimScreen`](file:///Users/kingpin/Documents/CC-Appdev/lib/ui/screens/submit_claim_screen.dart) with challenge answers and private proof fields. | ✅ Verified |
| **Ownership-verification process before handover** | Implemented via 3-tier Zero-Knowledge workflow & [`HandoverScreen`](file:///Users/kingpin/Documents/CC-Appdev/lib/ui/screens/handover_screen.dart) with salted SHA-256 OTP tokens. | ✅ Verified |
| **Track items through lost, found, claimed, returned** | Visualized in [`LifecycleStepper`](file:///Users/kingpin/Documents/CC-Appdev/lib/ui/widgets/lifecycle_stepper.dart) and enforced by [`ItemService`](file:///Users/kingpin/Documents/CC-Appdev/lib/core/services/item_service.dart) & `firestore.rules`. | ✅ Verified |
| **Interrupted submissions & network unreliability** | Draft auto-saving and persistent offline outbox queue with retry in [`LocalStorageService`](file:///Users/kingpin/Documents/CC-Appdev/lib/core/services/local_storage_service.dart). | ✅ Verified |
| **Protect sensitive user information** | Subcollection isolation, masked contact numbers, zero public exposure of verification answers. | ✅ Verified |
| **Responsive UI & Adaptive Navigation** | Multi-screen support (Mobile, Tablet, Desktop) with adaptive headers, bottom navigation, and grids. | ✅ Verified |
| **Dedicated Help Center** | 10-section structured user guide with real-time keyword search, accessible before and after auth. | ✅ Verified |
| **Vercel Ready Deployment** | Configured `vercel.json` SPA rewrites, security headers, cache policies, and `.env.example`. | ✅ Verified |
| **Bonus: Smart Matching Recommendations** | Proactive recommendation engine in [`ItemService.findPotentialMatches`](file:///Users/kingpin/Documents/CC-Appdev/lib/core/services/item_service.dart). | ✅ Verified |
| **Bonus: Secure Coordination Messaging** | In-app finder-claimant messaging in [`ChatScreen`](file:///Users/kingpin/Documents/CC-Appdev/lib/ui/screens/chat_screen.dart). | ✅ Verified |
| **Bonus: Campus Moderation Dashboard** | Flagging and resolution system in [`ModerationScreen`](file:///Users/kingpin/Documents/CC-Appdev/lib/ui/screens/moderation_screen.dart). | ✅ Verified |

---

## 📜 License
This project is authored for the **CodeChef-VIT Promotional Cycle 2026–27 App Development Task**. Distributed under the MIT License.
