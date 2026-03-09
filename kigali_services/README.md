# Kigali City Services

A Flutter mobile application that serves as a directory for services and places of interest across Kigali, Rwanda. Users can browse, search, and manage listings with real-time Firebase integration.

---

## Table of Contents

1. [Firebase Setup](#firebase-setup)
2. [Firestore Collections](#firestore-collections)
3. [State Management](#state-management)
4. [Navigation Structure](#navigation-structure)
5. [Folder Structure](#folder-structure)
6. [Data Flow](#data-flow)
7. [Design Summary](#design-summary)
8. [Reflection: Integration Errors & Resolutions](#reflection-integration-errors--resolutions)

---

## Firebase Setup

### Prerequisites

- Flutter SDK ≥ 3.11
- A Firebase project with **Authentication** and **Firestore** enabled
- Google Maps API key with Maps SDK for Android and iOS enabled

### Steps

1. **Create a Firebase project** at [firebase.google.com](https://firebase.google.com).
2. **Enable Email/Password** sign-in under Authentication → Sign-in method.
3. **Enable Email Verification** — the app gates access behind `emailVerified`.
4. **Create a Firestore database** in production mode and apply the security rules below.
5. **Run `flutterfire configure`** to generate `lib/firebase_options.dart` for your project.
6. **Add the Google Maps API key**:
   - Android: `android/app/src/main/AndroidManifest.xml` — `com.google.android.geo.API_KEY` meta-data entry.
   - iOS: `ios/Runner/AppDelegate.swift` — `GMSServices.provideAPIKey(...)` call.
7. Run `flutter pub get` then launch with `flutter run`.

### Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Any authenticated user can read listings
    match /services/{serviceId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null
        && request.auth.uid == resource.data.createdBy;
    }

    // User profiles — owner only
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    // Reviews — any authenticated user can read/create
    match /reviews/{reviewId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```

---

## Firestore Collections

### `services` (Listings)

| Field | Type | Description |
|---|---|---|
| `name` | String | Place or service name |
| `category` | String | One of: Cafés, Pharmacies, Hospitals, Restaurants, Parks, Libraries, Police, Attractions |
| `address` | String | Street address |
| `phone` | String | Contact number |
| `description` | String | Full description |
| `latitude` | Number | Geographic latitude |
| `longitude` | Number | Geographic longitude |
| `createdBy` | String | UID of the authenticated user who created the listing |
| `timestamp` | Timestamp | Creation date |
| `rating` | Number | Computed average rating (updated on review submission) |
| `reviewCount` | Number | Total number of reviews |

### `users` (Profiles)

| Field | Type | Description |
|---|---|---|
| `uid` | String | Firebase Auth UID |
| `email` | String | User email |
| `displayName` | String | Display name |
| `createdAt` | String | ISO 8601 account creation timestamp |

### `reviews`

| Field | Type | Description |
|---|---|---|
| `serviceId` | String | References a `services` document |
| `userId` | String | UID of the reviewer |
| `author` | String | Display name of the reviewer |
| `rating` | Number | 1–5 star rating |
| `comment` | String | Optional written review |
| `timestamp` | Timestamp | Submission time |

---

## State Management

The app uses **Provider** (`provider: ^6.1.2`) for all state management. Three `ChangeNotifier` providers are registered at the app root via `MultiProvider`:

| Provider | Responsibility |
|---|---|
| `AuthProvider` | Wraps `AuthService`; exposes `AuthStatus` enum (`unknown`, `unauthenticated`, `unverified`, `authenticated`), loading flag, and error messages |
| `ServicesProvider` | Wraps `FirestoreService`; holds real-time Firestore streams for all listings and the signed-in user's own listings; exposes search/filter logic and CRUD methods |
| `BookmarksProvider` | Persists bookmarked listing IDs to `SharedPreferences`; notifies UI on toggle |

### Key Principle

**UI widgets never call Firebase directly.** All Firestore reads and writes are handled inside `FirestoreService` and `AuthService`, which are called exclusively through their respective Providers. Widgets consume state via `context.watch<T>()` (reactive reads) or `context.read<T>()` (one-shot calls).

### Loading / Error States

`ServicesProvider` uses a `LoadingState` enum (`idle`, `loading`, `success`, `error`) for both the directory stream and the My Listings stream. Every screen that reads listings checks this state and shows a `CircularProgressIndicator` or error text before rendering data.

---

## Navigation Structure

```
AppRouter (StatelessWidget — watches AuthProvider)
├── Loading spinner          (AuthStatus.unknown)
├── LoginScreen              (AuthStatus.unauthenticated)
├── _VerifyEmailScreen       (AuthStatus.unverified)
└── MainShell                (AuthStatus.authenticated)
    └── BottomNavigationBar
        ├── [0] HomeScreen         — Directory: browse, search, filter
        ├── [1] CategoryScreen     — My Listings: user's own listings with edit/delete
        ├── [2] MapScreen          — Google Map showing all listing markers
        └── [3] SettingsScreen     — User profile + notification toggles
```

Navigating to a listing opens `ServiceDetailScreen` (pushed on top of the current tab), which embeds a Google Map and a "Get directions" button that launches Google Maps turn-by-turn navigation.

---

## Folder Structure

```
lib/
├── main.dart                        # App entry, MultiProvider, AppRouter, MainShell
├── firebase_options.dart            # Generated by flutterfire configure
│
├── models/
│   ├── service_model.dart           # Listing data class + Firestore serialisation
│   ├── user_model.dart              # User profile data class
│   └── review_model.dart            # Review data class + Firestore serialisation
│
├── services/
│   ├── auth_service.dart            # Firebase Auth: signUp, signIn, signOut, reload
│   └── firestore_service.dart       # Firestore CRUD + real-time streams for listings/reviews
│
├── providers/
│   ├── auth_provider.dart           # AuthStatus state, wraps AuthService
│   ├── services_provider.dart       # Listings state + search/filter, wraps FirestoreService
│   └── bookmarks_provider.dart      # Local bookmark persistence via SharedPreferences
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   └── home_screen.dart         # Directory tab
│   ├── category/
│   │   └── category_screen.dart     # My Listings tab
│   ├── listing/
│   │   └── add_edit_listing_screen.dart
│   ├── detail/
│   │   └── service_detail_screen.dart  # Google Map + directions
│   ├── map/
│   │   └── map_screen.dart          # Full-screen Google Map tab
│   ├── reviews/
│   │   └── reviews_screen.dart
│   ├── bookmarks/
│   │   └── bookmarks_screen.dart
│   └── settings/
│       └── settings_screen.dart
│
└── theme/
    └── app_theme.dart               # AppColors + global ThemeData
```

---

## Data Flow

```
Firestore
   │  (real-time snapshots)
   ▼
FirestoreService          ← pure data layer, no Flutter imports
   │  (Stream<List<ServiceModel>>)
   ▼
ServicesProvider          ← ChangeNotifier; applies search/filter; exposes CRUD
   │  (context.watch<ServicesProvider>())
   ▼
UI Widgets                ← HomeScreen, CategoryScreen, MapScreen rebuild automatically
```

**Authentication flow:**

```
Firebase Auth
   │  (authStateChanges stream)
   ▼
AuthService.authStateChanges
   │
   ▼
AuthProvider._onAuthStateChanged()
   │  sets AuthStatus + notifyListeners()
   ▼
AppRouter (context.watch<AuthProvider>())
   │  switches between LoginScreen / VerifyEmailScreen / MainShell
```

---

## Design Summary

### Firestore Schema for Listings

The `services` collection is flat — each document is a self-contained listing with all display fields plus `createdBy` (UID) for ownership enforcement. The `createdBy` field is used both for Firestore security rules and for the `My Listings` tab filter (`where('createdBy', isEqualTo: uid)`). Geographic coordinates are stored as numeric `latitude` / `longitude` fields and passed directly to `google_maps_flutter`'s `LatLng` constructor.

### State Management Workflow

On sign-in, `AppRouter` calls `ServicesProvider.listenToServices()` and `ServicesProvider.listenToMyListings(uid)`. These open two persistent `StreamSubscription`s against Firestore. Every time a listing is added, updated, or deleted by any user, the `services` stream emits a new list, `_allServices` is updated, `_applyFilter()` re-runs, and `notifyListeners()` causes every widget watching `ServicesProvider` to rebuild. On sign-out, `stopListening()` cancels both subscriptions and clears all cached data, ensuring no stale state is shown to a subsequent user.

---

## Reflection: Integration Errors & Resolutions

### Error 1 — Missing Firestore Composite Index

**Problem:** When the app first queried `My Listings` using both a `where('createdBy', ...)` clause and `orderBy('timestamp', descending: true)`, Firestore threw a `failed-precondition` error at runtime with a link to create a composite index.

**Resolution:** Opened the link from the error message in the Firebase Console, which auto-populated the index definition (`createdBy` ASC + `timestamp` DESC on the `services` collection). Clicked "Create index" and waited ~2 minutes for it to build. Alternatively, the index can be defined in `firestore.indexes.json` and deployed with `firebase deploy --only firestore:indexes` so it is reproducible across environments.

---

### Error 2 — `PlatformException` on Android: Google Maps Blank Screen

**Problem:** After integrating `google_maps_flutter`, the map widget rendered as a solid grey/blank surface on Android. No crash, no error — just no tiles.

**Resolution:** The API key `<meta-data>` entry had been placed inside the `<activity>` tag instead of directly inside `<application>`. Moving it to be a direct child of `<application>` (at the same level as the `flutterEmbedding` meta-data) resolved the issue immediately. Additionally confirmed that "Maps SDK for Android" was enabled in the Google Cloud Console for the API key.

---

### Error 3 — `StreamSubscription` Leak After Sign-Out

**Problem:** After signing out and signing back in as a different user, the Directory tab briefly showed the previous user's cached listings before re-populating. In some cases, the old Firestore listener was still active and writing into the provider.

**Resolution:** Implemented `ServicesProvider.stopListening()`, which cancels both `_servicesSub` and `_myListingsSub`, nulls the subscriptions, and clears `_allServices` / `_myListings`. This is called from `AppRouter` inside a `WidgetsBinding.addPostFrameCallback` when `AuthStatus.unauthenticated` is detected, guaranteeing a clean slate before the login screen is shown.
