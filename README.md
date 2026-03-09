# Kigali City Services

A Flutter mobile application that provides a directory of services and places of interest across Kigali, Rwanda. Users can sign up, browse listings, add their own places, search and filter by category, view locations on an embedded Google Map, and get turn-by-turn directions — all backed by Firebase Authentication and Firestore in real time.

---

## Table of Contents

1. [Features](#features)
2. [Tech Stack](#tech-stack)
3. [Firebase Setup](#firebase-setup)
4. [Firestore Collections & Schema](#firestore-collections--schema)
5. [State Management Approach](#state-management-approach)
6. [Navigation Structure](#navigation-structure)
7. [Folder Structure](#folder-structure)
8. [How Firestore Data Flows into the UI](#how-firestore-data-flows-into-the-ui)
9. [Running the App](#running-the-app)
10. [Design Summary](#design-summary)
11. [Reflection — Firebase Integration Errors & Resolutions](#reflection--firebase-integration-errors--resolutions)

---

## Features

### Authentication (Requirement 1)
- Sign up with email and password using Firebase Authentication
- Email verification enforced — users cannot access the app until their email is verified
- Log in and log out securely
- On sign-up, a user profile document is immediately written to Firestore under `users/{uid}` containing the user's UID, email, display name, and creation timestamp
- Every listing created by a user is stamped with their UID (`createdBy` field), linking profile to listing

### Location Listings — CRUD (Requirement 2)
Each listing stored in Firestore contains: **Place/Service Name**, **Category**, **Address**, **Contact Number**, **Description**, **Latitude**, **Longitude**, **Created By (UID)**, and **Timestamp**.

- **Create** — any authenticated user can add a new listing via the Add Listing form
- **Read** — all listings are displayed in the Directory tab, updated in real time
- **Update** — users can edit their own listings via the My Listings tab
- **Delete** — users can delete their own listings with a confirmation dialog
- Changes reflect immediately in the UI through Firestore real-time streams managed by `ServicesProvider`

### Directory Search and Filtering (Requirement 3)
- Search bar filters listings by name, description, and address as the user types
- Horizontal category filter chips (Cafés, Pharmacies, Hospitals, Restaurants, Parks, Libraries, Police, Attractions)
- Both search and filter work together and update dynamically from the Firestore-backed provider state

### Detail Page and Google Maps Integration (Requirement 4)
- Tapping any listing navigates to a detail screen showing all stored information
- An embedded **Google Map** (`google_maps_flutter`) displays a marker at the listing's stored latitude/longitude coordinates
- A **Get Directions** button launches Google Maps with turn-by-turn navigation to the listing's coordinates

### State Management — Provider (Requirement 5)
- All state is managed via **Provider** (`ChangeNotifier`)
- A dedicated service layer (`FirestoreService`, `AuthService`) handles all Firebase interactions
- UI widgets never call Firebase directly — they read from providers via `context.watch<T>()` and write via `context.read<T>()`
- `LoadingState` enum (`idle`, `loading`, `success`, `error`) is tracked for every async operation

### Navigation (Requirement 6)
`BottomNavigationBar` with four tabs:
- **Directory** — browse all listings with search and category filter
- **My Listings** — view, edit, and delete the signed-in user's own listings
- **Map View** — full-screen Google Map with markers for all listings
- **Settings** — user profile and notification preferences

### Settings (Requirement 7)
- Displays the authenticated user's display name and email from Firebase Auth
- Toggle for **location-based notifications** (simulated locally)
- Additional toggles for new service alerts and review replies
- Sign out button that clears all Firestore state before returning to the login screen

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.41 / Dart 3 |
| Authentication | Firebase Authentication (Email/Password) |
| Database | Cloud Firestore (real-time snapshots) |
| State Management | Provider (`ChangeNotifier` + `MultiProvider`) |
| Maps | google_maps_flutter + Google Maps SDK |
| Local Storage | SharedPreferences (bookmarks) |
| URL Handling | url_launcher (directions, phone) |

---

## Firebase Setup

### Prerequisites

- Flutter SDK ≥ 3.11
- A Firebase project with **Authentication** (Email/Password) and **Firestore** enabled
- Google Maps API key with **Maps SDK for Android** and **Maps SDK for iOS** enabled in Google Cloud Console

### Steps

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Email/Password** sign-in under Authentication → Sign-in method.
3. Enable **Email Verification** — the app enforces `emailVerified` before granting access.
4. Create a **Firestore database** in production mode.
5. Apply the security rules below.
6. Run `flutterfire configure` inside the `kigali_services/` directory to generate `lib/firebase_options.dart`.
7. Add your Google Maps API key:
   - **Android**: inside `<application>` in `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_API_KEY"/>
     ```
   - **iOS**: in `ios/Runner/AppDelegate.swift`:
     ```swift
     GMSServices.provideAPIKey("YOUR_API_KEY")
     ```
8. Run `flutter pub get` then `flutter run`.

### Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /services/{serviceId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null
        && request.auth.uid == resource.data.createdBy;
    }

    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    match /reviews/{reviewId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```

---

## Firestore Collections & Schema

### `services` — Listings

| Field | Type | Description |
|---|---|---|
| `name` | String | Place or service name |
| `category` | String | Cafés / Pharmacies / Hospitals / Restaurants / Parks / Libraries / Police / Attractions |
| `address` | String | Street address |
| `phone` | String | Contact number |
| `description` | String | Full description of the place |
| `latitude` | Number | Geographic latitude (decimal degrees) |
| `longitude` | Number | Geographic longitude (decimal degrees) |
| `createdBy` | String | Firebase Auth UID of the user who created the listing |
| `timestamp` | Timestamp | Date and time the listing was created |
| `rating` | Number | Computed average rating (recalculated on every review submission) |
| `reviewCount` | Number | Total number of reviews submitted |

### `users` — Profiles

| Field | Type | Description |
|---|---|---|
| `uid` | String | Firebase Auth UID |
| `email` | String | User email address |
| `displayName` | String | User's display name |
| `createdAt` | String | ISO 8601 timestamp of account creation |

### `reviews`

| Field | Type | Description |
|---|---|---|
| `serviceId` | String | ID of the parent `services` document |
| `userId` | String | UID of the reviewer |
| `author` | String | Display name of the reviewer |
| `rating` | Number | Star rating from 1 to 5 |
| `comment` | String | Optional written review text |
| `timestamp` | Timestamp | Date and time of submission |

---

## State Management Approach

The app uses **Provider** (`provider: ^6.1.2`) as its state management solution. Three `ChangeNotifier` classes are registered at the app root via `MultiProvider`:

### `AuthProvider`
- Listens to `AuthService.authStateChanges` (a Firebase `Stream<User?>`)
- Maps the Firebase user to an `AuthStatus` enum: `unknown` → `unauthenticated` / `unverified` / `authenticated`
- Exposes `signUp`, `signIn`, `signOut`, `reloadUser` — all Firestore/Auth calls go through here, never directly from the UI
- Tracks `isLoading` and `errorMessage` for login and signup form feedback

### `ServicesProvider`
- Wraps `FirestoreService` entirely — the only class allowed to access Firestore for listings
- Calls `listenToServices()` and `listenToMyListings(uid)` on sign-in to open persistent `StreamSubscription`s
- Calls `stopListening()` on sign-out to cancel subscriptions and clear cached data
- Exposes `setSearchQuery()` and `setCategory()` which run `_applyFilter()` in-memory against `_allServices`
- Tracks `LoadingState` separately for the directory stream and the My Listings stream
- Exposes `createService`, `updateService`, `deleteService` — all delegate to `FirestoreService`

### `BookmarksProvider`
- Persists a `List<String>` of bookmarked listing IDs to `SharedPreferences`
- Exposes `toggle(id)` and `isBookmarked(id)` — notifies listeners on every change

### Rule Enforced Throughout
UI widgets read state with `context.watch<T>()` for reactive rebuilds and write with `context.read<T>()` for one-shot calls. No widget imports `FirebaseFirestore` or `FirebaseAuth` directly.

---

## Navigation Structure

```
AppRouter  (StatelessWidget — context.watch<AuthProvider>())
├── CircularProgressIndicator   →  AuthStatus.unknown
├── LoginScreen                 →  AuthStatus.unauthenticated
├── _VerifyEmailScreen          →  AuthStatus.unverified
└── MainShell                   →  AuthStatus.authenticated
    └── BottomNavigationBar (IndexedStack)
        ├── [0] HomeScreen          — Directory with search + filter
        ├── [1] CategoryScreen      — My Listings (edit / delete)
        ├── [2] MapScreen           — Full-screen Google Map
        └── [3] SettingsScreen      — Profile + notification toggles

Pushed routes (on top of any tab):
    ServiceDetailScreen   — Embedded Google Map + directions button
    AddEditListingScreen  — Create / edit listing form
    ReviewsScreen         — View reviews + submit rating
    BookmarksScreen       — Saved listings
```

`AppRouter` is the root widget of `MaterialApp.home`. When `AuthProvider` notifies, `AppRouter` rebuilds and switches the entire root — ensuring no protected screens are reachable without authentication.

---

## Folder Structure

```
kigali_services/
└── lib/
    ├── main.dart                         App entry, MultiProvider, AppRouter, MainShell
    ├── firebase_options.dart             Generated by flutterfire configure
    │
    ├── models/
    │   ├── service_model.dart            Listing fields + fromFirestore / toFirestore
    │   ├── user_model.dart               User profile + toFirestore
    │   └── review_model.dart             Review fields + fromFirestore / toFirestore
    │
    ├── services/
    │   ├── auth_service.dart             Firebase Auth wrapper: signUp, signIn, signOut
    │   └── firestore_service.dart        All Firestore reads and writes
    │
    ├── providers/
    │   ├── auth_provider.dart            AuthStatus + loading/error state
    │   ├── services_provider.dart        Listings streams + search/filter + CRUD
    │   └── bookmarks_provider.dart       Local bookmarks via SharedPreferences
    │
    ├── screens/
    │   ├── auth/
    │   │   ├── login_screen.dart
    │   │   └── signup_screen.dart
    │   ├── home/
    │   │   └── home_screen.dart          Directory tab
    │   ├── category/
    │   │   └── category_screen.dart      My Listings tab
    │   ├── listing/
    │   │   └── add_edit_listing_screen.dart
    │   ├── detail/
    │   │   └── service_detail_screen.dart   Google Map embed + directions
    │   ├── map/
    │   │   └── map_screen.dart           Full-screen map tab
    │   ├── reviews/
    │   │   └── reviews_screen.dart
    │   ├── bookmarks/
    │   │   └── bookmarks_screen.dart
    │   └── settings/
    │       └── settings_screen.dart
    │
    └── theme/
        └── app_theme.dart                AppColors + global dark ThemeData
```

---

## How Firestore Data Flows into the UI

### Listings

```
Cloud Firestore  (services collection — real-time snapshot)
        │
        │  QuerySnapshot stream
        ▼
FirestoreService.getServicesStream()
        │  Stream<List<ServiceModel>>
        ▼
ServicesProvider._servicesSub  (StreamSubscription)
        │  updates _allServices → _applyFilter() → notifyListeners()
        ▼
context.watch<ServicesProvider>().services
        │
        ├── HomeScreen      → ListView of all filtered listings
        ├── CategoryScreen  → ListView of the user's own listings
        └── MapScreen       → Set<Marker> on GoogleMap
```

### Authentication

```
Firebase Auth  (authStateChanges stream)
        │
        ▼
AuthService.authStateChanges  →  AuthProvider._onAuthStateChanged()
        │  sets _status + _user → notifyListeners()
        ▼
AppRouter  (context.watch<AuthProvider>())
        │  returns LoginScreen / VerifyEmailScreen / MainShell
```

### CRUD Write Path

```
UI Widget (AddEditListingScreen)
        │  context.read<ServicesProvider>().createService(model)
        ▼
ServicesProvider.createService()
        │  delegates to FirestoreService.createService()
        ▼
FirestoreService  →  _db.collection('services').add(...)
        │
        ▼
Firestore emits new snapshot  →  ServicesProvider stream callback fires
        │  → notifyListeners()
        ▼
HomeScreen / CategoryScreen / MapScreen rebuild automatically
```

---

## Running the App

### Android

1. Connect a device or start an emulator **with Google Play Services** (required for Google Maps).
2. From the `kigali_services/` directory:
   ```bash
   flutter pub get
   flutter run
   ```

### iOS

1. From the `kigali_services/` directory:
   ```bash
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

---

## Design Summary

### Firestore Schema Decision

The `services` collection uses a **flat document structure** — every listing is a single self-contained document. This keeps reads simple (one query fetches everything the Directory needs) and avoids nested sub-collections. The `createdBy` field stores the Firebase Auth UID, serving two purposes: Firestore security rules use it to restrict update/delete to the document's owner, and `ServicesProvider` uses it to filter the My Listings stream with `where('createdBy', isEqualTo: uid)`.

Geographic coordinates are stored as plain numeric fields (`latitude`, `longitude`). On the detail screen and map screen they are passed directly to `google_maps_flutter`'s `LatLng(latitude, longitude)` constructor, keeping the model free of any Flutter/Maps dependency.

### State Management Workflow

On sign-in, `AppRouter` calls `ServicesProvider.listenToServices()` and `ServicesProvider.listenToMyListings(uid)`. Each call opens a persistent `StreamSubscription` on Firestore. Every document change in the `services` collection causes the snapshot to emit, `_allServices` is replaced with the fresh list, `_applyFilter()` re-evaluates the current search query and selected category in memory, and `notifyListeners()` triggers all watching widgets to rebuild. This means the Directory, My Listings, and Map screens all update automatically without any manual refresh — real-time data without polling.

On sign-out, `stopListening()` cancels both subscriptions, nulls the references, and clears all cached lists before `AppRouter` navigates to `LoginScreen`. This prevents stale data from appearing if another user signs in on the same device.

---

## Reflection — Firebase Integration Errors & Resolutions

### Error 1 — Firestore Composite Index Required for My Listings Query

**Problem:** The My Listings stream used `where('createdBy', isEqualTo: uid)` combined with `orderBy('timestamp', descending: true)`. Firestore requires a composite index when filtering and ordering on different fields. At runtime, the query threw a `failed-precondition` error with a URL to auto-create the index. Because the `StreamSubscription` had no error UI, the My Listings tab silently showed an empty list.

**Resolution:** The same `failed-precondition` issue surfaced in the reviews stream (also using `where` + `orderBy`). For reviews, the `orderBy` was removed from the Firestore query and replaced with an in-app `List.sort()` call — eliminating the index requirement entirely. For the My Listings stream the composite index was created via the Firebase Console link. Error handling was also added to the `StreamBuilder` in the reviews screen so future errors surface as visible messages rather than silent empty states.

---

### Error 2 — Google Maps Rendered as a Blank Grey Screen on Android

**Problem:** After integrating `google_maps_flutter`, both the detail screen map and the Map View tab rendered as a solid grey rectangle on Android. There were no exceptions in the console — only a silent rendering failure.

**Resolution:** The `<meta-data>` entry for the Google Maps API key had been placed inside the `<activity>` tag in `AndroidManifest.xml` instead of as a direct child of `<application>`. Moving the entry to the correct level immediately resolved the blank map. It was also confirmed that "Maps SDK for Android" was enabled in Google Cloud Console for the API key, as the key must have the correct API enabled or the SDK silently fails to initialise.

---

### Error 3 — Email Verification Screen Did Not Navigate After Reload

**Problem:** After completing email verification and tapping "I verified — continue" in `SignupScreen`, nothing happened. The screen stayed frozen. `AuthProvider.reloadUser()` was correctly updating `AuthStatus` to `authenticated` and calling `notifyListeners()`, but the UI did not change.

**Resolution:** The root cause was a Navigator stack issue. `SignupScreen` is pushed onto the Navigator as Route 1 on top of `LoginScreen` (Route 0). `AppRouter` (Route 0's widget) was correctly rebuilding to show `MainShell`, but `SignupScreen` remained on top of the stack so the user never saw it. The fix was to capture `Navigator.of(context)` before the `await reloadUser()` call and then call `navigator.popUntil((route) => route.isFirst)` after it completes. This pops `SignupScreen` off the stack and reveals Route 0, which by then is already showing `MainShell`.
