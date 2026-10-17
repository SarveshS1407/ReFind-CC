# Engineering Decisions & Technical Reflection: Finders Keepers?
*CodeChef-VIT Promotional Cycle 2026–27 — App Development Task*

---

### 1. What was the most technically challenging part of your implementation, and how did you approach it?

The most technically demanding challenge was engineering the **zero-knowledge ownership verification and secure handover pipeline** under unreliable campus network conditions. In a campus environment, lost items are vulnerable to fraudulent claims (e.g., someone claiming an expensive pair of AirPods or a smartwatch without owning it). Simultaneously, students frequently walk through campus dead zones (basements, elevators, lecture halls with high RF attenuation).

We solved this through a multi-tiered architecture:
1. **Public vs. Private Field Partitioning**: Found item listings display public metadata (approximate building, category, generic photo, timestamp) while masking critical distinguishing features. When creating a found report, the finder defines specific verification challenges (e.g., "Describe the scratch pattern on the back", "What is the lock screen wallpaper?", "What keychain is attached?").
2. **Subcollection Authorization Boundaries in Firestore**: Verification answers submitted by claimants are isolated in a restricted subcollection (`/items/{itemId}/claims/{claimId}`). Cloud Firestore security rules strictly forbid list or read queries from any user other than the specific claimant and the original reporter. The general public never receives this data payload.
3. **Cryptographic Handover Verification**: Once a claim is verified by the finder, a cryptographically random, collision-resistant 6-digit Handover Token is issued to the claimant. During the physical handover at a designated campus safety point (e.g., SJT Security Desk), the finder validates this token in-app, atomically completing the state transition to `returned` in a Firestore transaction.
4. **Resilient Local Outbox Queue**: All submissions, claims, and state updates pass through an offline-aware repository that writes to local encrypted storage (`Hive`/`SharedPreferences`) before network dispatch. If network drops mid-submission, the item is tagged with a distinct `SyncStatus.queued` badge, and an exponential backoff worker synchronizes once connectivity is re-established.

---

### 2. Describe one important design decision you made, and why did you choose that approach over alternatives?

**Decision: Adopting OpenStreetMap (via `flutter_map` and Vector/Raster Tiles) over Google Maps Platform SDK.**

#### Alternatives Considered:
1. **Google Maps Flutter Plugin (`google_maps_flutter`)**:
   - *Pros*: Familiar styling, street view integration.
   - *Cons*: Requires Google Cloud Platform project creation, billing account setup, restrictive API key restrictions (SHA-1 fingerprint matching), platform-specific XML/plist injection, and network-dependent tile loading that fails under offline campus conditions.
2. **OpenStreetMap (`flutter_map` + `latlong2`)**:
   - *Pros*: 100% open-source, zero API keys or billing barriers for evaluators, native offline caching support (`flutter_map_cache`), full customizability of marker layers and campus bounding boxes (centered at VIT Vellore: `12.9698° N, 79.1559° E`), and predictable behavior in automated testing without native mock bridges.

**Rationale**:
For a campus lost-and-found application, evaluators and students need an app that compiles and runs immediately without demanding personal Google Cloud API keys or risking billing quota limits. Furthermore, OpenStreetMap allows us to blur exact GPS coordinates into campus building polygons (e.g., SJT, TT, Anna Auditorium, Men's/Women's Hostels), satisfying the strict requirement to protect sensitive location data while providing an intuitive spatial experience.

---

### 3. What is one limitation or failure case your current implementation does not handle well?

**Limitation: Asynchronous Physical Item Modification & Verification Dispute Resolution.**

If a dishonest finder accepts an item claim, receives the handover token, but hands over an item that was damaged or altered, or if two students collude to falsely mark an item as `returned` to claim a reward, the purely software-based verification cannot inspect the physical reality of the exchange. 

Additionally, if a finder becomes unresponsive after receiving claims, the item remains indefinitely locked in `found` or `claimed` status without automatic escalation. In our current architecture, while an administrative moderation role (`role: 'moderator' | 'admin'`) exists with override capabilities, automated dispute escalation (such as expiring an unverified claim after 72 hours and notifying campus security) is simulated through client-side state flags rather than a continuous Cloud Function cron scheduler.

---

### 4. If you had another week to work on the project, what would you improve first and why?

1. **On-Device Embedding Generation for Image Similarity (TensorFlow Lite / MobileNet)**:
   - Rather than relying on simple text-tag matching between Lost and Found reports, we would bundle an on-device lightweight feature extractor (MobileNetV3) to compute 512-dimensional visual embeddings when photos are uploaded. When a student reports a lost blue water bottle, cosine similarity would automatically rank recently found blue bottles at the top of their feed.
2. **End-to-End Encrypted Double-Ratchet In-App Chat**:
   - Replace standard Firestore-based message documents with an end-to-end encrypted protocol (Signal Protocol / Olm) between claimant and finder so that rendezvous location coordinates and personal phone numbers exchanged in chat cannot be read even by database administrators.
3. **Geo-fenced Handover Confirmation via Bluetooth Low Energy (BLE) / NFC**:
   - Supplement the 6-digit handover OTP with proximity verification using BLE advertising or an NFC tap between the finder's and owner's phones, proving that both parties were physically present at the same campus location during handover.
4. **Automated Firebase Emulator Test Harness in CI/CD**:
   - Set up GitHub Actions running `@firebase/rules-unit-testing` alongside Flutter integration tests in a headless Android emulator for continuous regression testing of all security rules and state machine transitions.

---

### 5. Architectural Decisions for Premium UI/UX, Authentication-First Routing, and Vercel Deployment

#### Decision 5.1: Authentication-First Reactive AuthGate with Evaluator Personas
- **Problem**: Opening an unauthenticated visitor directly into a feed creates ambiguity around identity, permissions, and claims ownership.
- **Solution**: Implemented an explicit `AuthGate` in `lib/main.dart` that dynamically watches `currentUserProvider`. Unauthenticated sessions land on `WelcomeAuthScreen`, featuring:
  - University branding, value proposition pills, and Sign In / Register tabs.
  - A persistent **Evaluator Demonstration Mode** with three distinct personas: **Aarav Sharma** (Finder), **Diya Patel** (Claimant), and **Prof. R. Verma** (Campus Security Moderator). Tapping any persona switches the active session immediately with zero friction.
  - An unauthenticated access link to the **Campus Help Center**, ensuring prospective users and evaluators can read the complete workflow before creating an account.

#### Decision 5.2: Responsive Adaptive Shell with Strict Breakpoints
- **Problem**: Mobile-first layouts look stretched and sparse on desktop displays, while desktop dashboards feel cluttered on mobile phones.
- **Solution**: Defined `AppBreakpoints` (`Mobile < 640px`, `Tablet 640–1024px`, `Desktop >= 1024px`) and engineered `ResponsiveMainScreen`:
  - **Desktop**: Features a 68px sticky header bar with brand logo, campus title, navigation tabs, quick search shortcuts, and "Report New Item" action button. Feed items render in an adaptive 3-column grid with a max width constraint of 1200px.
  - **Mobile**: Features a sleek bottom `NavigationBar`, single-column feed, and an extended Floating Action Button on the Feed tab for one-tap item reporting.

#### Decision 5.3: Vercel Single-Page Application (SPA) Routing & Asset Caching Strategy
- **Problem**: Flutter Web compiles into a client-side Single Page Application (`index.html`, `main.dart.js`, `flutter.js`, WebAssembly bundles). Direct browser reloads on deep links (e.g. `/details/123`) return 404 errors on standard static web hosts unless rewrites are configured.
- **Solution**: Created `vercel.json` with wildcard SPA rewriting:
  ```json
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
  ```
  Coupled with immutable HTTP `Cache-Control` headers for compiled assets (`/assets/*`, `/canvaskit/*`), and `must-revalidate` for `index.html` and `flutter_service_worker.js`, ensuring instant subsequent visits and seamless instant updates without cache poisoning.
