#  BookSwap

BookSwap is a Flutter–Firebase mobile app that allows users to **list**, **browse**, and **swap** books seamlessly. The platform encourages community sharing while promoting sustainable reading habits.

---

##  Features

-  Firebase Authentication (Sign Up / Sign In)
-  Cloud Firestore for book listings & swaps
-  Firebase Storage for book cover uploads
-  Real-time updates using Provider
-  Swap requests between users
-  Responsive and modern Flutter UI

---

## Tech Stack

| Layer | Technology |
|-------|-------------|
| Frontend | Flutter (Dart) |
| Backend | Firebase (Auth, Firestore, Storage) |
| State Management | Provider |
| Design Pattern | MVVM + ChangeNotifier |
| IDE | Android Studio |

---

## Project Structure

lib/
│
├── models/
│ └── book.dart
│
├── providers/
│ ├── book_provider.dart
│ ├── notification_provider.dart
│ └── auth_provider.dart
│
├── screens/
│ ├── login.dart
│ ├── signup.dart
│ ├── home/
│ │ ├── browse_listings.dart
│ │ └── post_book_screen.dart
│ └── swap/
│ └── swap_requests.dart
│
├── services/
│ └── firestore_service.dart
│
└── main.dart

yaml
Copy code

---

##  Setup Instructions

1. **Clone this repository**
   ```bash
   git clone https://github.com/<your-username>/bookswap.git
   cd bookswap
Install dependencies

bash
Copy code
flutter pub get
Set up Firebase

Create a new Firebase project.

Add Android/iOS apps and download google-services.json (Android) and/or GoogleService-Info.plist (iOS).

Place them in the appropriate android/app and ios/Runner directories.

Run:

bash
Copy code
flutterfire configure
Run the app

bash
Copy code
flutter run
## Architecture & State Management
The app uses Provider for state management.
Each provider handles a specific concern:

BookProvider: CRUD operations & swap logic.

NotificationProvider: real-time updates for incoming swap requests.

AuthProvider: user session management.