# ChestSense 🫁

<div align="center">

**AI-Powered Chest X-Ray Analysis Platform**

A comprehensive Flutter application for chest X-ray analysis with role-based access for patients and doctors, featuring real-time diagnosis, secure authentication, and professional medical workflows.

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28?logo=firebase)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart)](https://dart.dev)

[Features](#-features) • [Getting Started](#-getting-started) • [Installation](#-installation) • [Configuration](#%EF%B8%8F-configuration) • [Troubleshooting](#-troubleshooting)

</div>

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Features](#-features)
- [Technology Stack](#-technology-stack)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#%EF%B8%8F-configuration)
- [Running the Project](#-running-the-project)
- [Project Structure](#-project-structure)
- [Authentication Flow](#-authentication-flow)
- [Firestore Database Schema](#-firestore-database-schema)
- [Security Rules](#-security-rules)
- [Troubleshooting](#-troubleshooting)
- [Known Issues](#%EF%B8%8F-known-issues)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Project Overview

**ChestSense** is a mobile and web application designed to revolutionize chest X-ray analysis through AI-powered diagnostics. The platform serves two primary user roles:

### **For Patients** 👤
- Upload and analyze chest X-ray images
- View detailed analysis results and health insights
- Manage personal health records securely
- Track historical X-ray analyses
- Update profile information including age, gender, and medical history

### **For Doctors** 👨‍⚕️
- Practice with sample X-ray scans
- Review patient analyses (with proper authorization)
- Manage professional profile including specialization and license information
- Access comprehensive analysis history
- Provide expert consultation

### **Core Capabilities**
- ✅ **Dual Role System**: Separate interfaces for patients and doctors
- ✅ **Secure Authentication**: Firebase Authentication with Google Sign-In
- ✅ **Real-time Database**: Cloud Firestore for instant data synchronization
- ✅ **Image Processing**: Advanced X-ray image analysis
- ✅ **Responsive Design**: Works on Android, iOS, and Web
- ✅ **Password Reset**: Magic link-based secure password recovery
- ✅ **Profile Management**: Dynamic, role-based profile editing

---

## ✨ Features

### 🔐 Authentication & Security
- **Email/Password Authentication** with Firebase Auth
- **Google Sign-In** integration for quick access
- **Magic Link Password Reset** - No OTP needed, fully integrated with Firebase
- **Role-based Access Control** (RBAC) through Firestore security rules
- **Session Management** with persistent login state

### 🩺 X-Ray Analysis (Patient Features)
- **Image Upload** from camera or gallery
- **AI-Powered Analysis** with detailed results
- **Analysis History** with timestamp tracking
- **Result Interpretation** with clear explanations
- **Profile Management** with age, gender, and medical info

### 👨‍⚕️ Doctor Dashboard
- **Practice Mode** for sample X-ray analysis
- **Patient Record Access** (authorized)
- **Professional Profile** with specialization details
- **License Verification** tracking
- **Analysis Archive** for reference

### 🎨 User Experience
- **Modern Dark Theme** with professional medical aesthetics
- **Smooth Animations** and transitions
- **Responsive Layouts** for all screen sizes
- **Intuitive Navigation** with bottom navigation bar
- **Real-time Updates** via Provider state management

---

## 🛠 Technology Stack

### **Frontend Framework**
- **Flutter 3.11+** - Cross-platform UI framework
- **Dart 3.11+** - Programming language

### **Backend & Services**
- **Firebase Authentication** - User authentication and authorization
- **Cloud Firestore** - NoSQL real-time database
- **Firebase Storage** - Image and file storage (ready for integration)

### **State Management**
- **Provider 6.1+** - Dependency injection and state management

### **Key Packages**
| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^3.1.0 | Firebase initialization |
| `firebase_auth` | ^5.1.1 | Authentication services |
| `cloud_firestore` | ^5.1.0 | Database operations |
| `provider` | ^6.1.2 | State management |
| `google_sign_in` | ^6.2.1 | Google OAuth integration |
| `image_picker` | ^1.1.2 | Camera/gallery access |
| `permission_handler` | ^12.0.1 | Runtime permissions |
| `http` | ^1.2.2 | API requests |
| `image` | ^4.1.7 | Image processing |

---

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

### **Required Software**

1. **Flutter SDK** (3.11 or higher)
   - Download: [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
   - Verify installation: `flutter doctor`

2. **Dart SDK** (Included with Flutter)
   - Version: 3.11 or higher
   - Verify: `dart --version`

3. **IDE** (Choose one)
   - **VS Code** with Flutter extension (Recommended)
   - **Android Studio** with Flutter plugin
   - **IntelliJ IDEA** with Flutter plugin

4. **Platform-Specific Requirements**

   **For Android Development:**
   - Android Studio (latest version)
   - Android SDK (API level 21+)
   - Java JDK 11 or higher
   - Android device or emulator

   **For iOS Development (macOS only):**
   - Xcode 14+
   - CocoaPods
   - iOS Simulator or physical device

   **For Web Development:**
   - Chrome browser

5. **Firebase CLI** (Optional, for deployments)
   ```bash
   npm install -g firebase-tools
   ```

6. **Git** (for version control)
   - Download: [https://git-scm.com/downloads](https://git-scm.com/downloads)

### **Verify Installation**

Run the following command to check your Flutter environment:

```bash
flutter doctor -v
```

Expected output should show:
- ✅ Flutter (3.11+)
- ✅ Dart SDK
- ✅ At least one platform (Android/iOS/Web) configured
- ✅ IDE with Flutter plugin

---

## 🚀 Installation

### **Step 1: Clone the Repository**

```bash
git clone https://github.com/yourusername/chestsense.git
cd chestsense
```

### **Step 2: Install Dependencies**

```bash
flutter pub get
```

This will download all required packages listed in `pubspec.yaml`.

### **Step 3: Verify Flutter Setup**

```bash
flutter doctor
```

Fix any issues reported before proceeding.

---

## ⚙️ Configuration

### **Firebase Setup**

ChestSense requires Firebase for authentication and database services. Follow these steps:

#### **1. Create Firebase Project**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `ChestSense` (or your preferred name)
4. Disable Google Analytics (optional)
5. Click **"Create project"**

#### **2. Enable Firebase Services**

**Authentication:**
1. Navigate to **Build** → **Authentication**
2. Click **"Get started"**
3. Enable **Email/Password** provider
4. Enable **Google** provider
   - Enter support email
   - Download `OAuth 2.0 Client ID` if needed

**Firestore Database:**
1. Navigate to **Build** → **Firestore Database**
2. Click **"Create database"**
3. Choose **"Start in test mode"** (we'll deploy security rules later)
4. Select a location (choose closest to your users)
5. Click **"Enable"**

#### **3. Register Your Apps**

**For Android:**

1. In Firebase Console, click **⚙️** → **Project settings**
2. Under "Your apps", click **Android** icon
3. Fill in:
   - **Package name**: `com.yourcompany.chestsense` (must match `android/app/build.gradle`)
   - **App nickname**: ChestSense Android
   - **Debug signing certificate** (optional for development)
4. Download `google-services.json`
5. Place it in `android/app/` directory

**For iOS (macOS only):**

1. Click **iOS** icon in Firebase Console
2. Fill in:
   - **Bundle ID**: `com.yourcompany.chestsense` (must match Xcode project)
   - **App nickname**: ChestSense iOS
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory
5. Open `ios/Runner.xcworkspace` in Xcode
6. Drag `GoogleService-Info.plist` into the Runner folder in Xcode

**For Web:**

1. Click **Web** icon in Firebase Console
2. Enter **App nickname**: ChestSense Web
3. Copy the Firebase configuration
4. Update `web/index.html` with Firebase config (if not already present)

#### **4. Deploy Firestore Security Rules**

**Important:** The project includes production-ready security rules.

```bash
# Authenticate with Firebase
firebase login

# Initialize Firebase (if not already done)
firebase init

# Select:
# - Firestore
# - Use existing project: chestsense-d7abc (or your project ID)

# Deploy security rules
firebase deploy --only firestore:rules
```

**Security Rules Overview:**
- ✅ Users can only read/write their own data
- ✅ Doctors can read all patient records (with proper authentication)
- ✅ Role-based access control enforced at database level
- ✅ No unauthenticated access (except password reset)

#### **5. Update Configuration Files**

The app is already configured with Firebase options. Ensure your configuration files match your Firebase project:

**Check:** `lib/firebase_options.dart`
- Should contain your Firebase project configuration
- Auto-generated by FlutterFire CLI

**If missing, regenerate:**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

### **Environment Variables**

No environment variables are required for local development. All configuration is handled through Firebase config files.

### **Google Sign-In Configuration**

**Android:**
- SHA-1 fingerprint already configured in Firebase
- Ensure `google-services.json` is in place
- No additional steps needed

**iOS:**
- Ensure `GoogleService-Info.plist` is in Xcode project
- URL schemes automatically configured

**Web:**
- Google Sign-In works out of the box with Firebase config

---

## 🏃 Running the Project

### **Run on Android**

```bash
# List available devices
flutter devices

# Run on connected Android device
flutter run -d android

# Run on specific device
flutter run -d <device-id>
```

**First time setup:**
- Enable Developer Options on your Android device
- Enable USB Debugging
- Connect device via USB
- Accept debugging permission popup

### **Run on iOS** (macOS only)

```bash
# Open iOS Simulator
open -a Simulator

# Run on iOS Simulator
flutter run -d ios

# Run on physical iPhone
flutter run -d <device-name>
```

**First time setup:**
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select your development team in **Signing & Capabilities**
3. Connect iPhone and trust computer
4. Run from terminal

### **Run on Web (Chrome)**

```bash
flutter run -d chrome
```

**Hot Reload:**
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Press `q` to quit

### **Build for Production**

**Android APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Android App Bundle (for Play Store):**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**iOS (macOS only):**
```bash
flutter build ios --release
# Then open Xcode and archive
```

**Web:**
```bash
flutter build web --release
# Output: build/web/
```

---

## 📁 Project Structure

```
chestsense/
├── android/                    # Android-specific configuration
│   ├── app/
│   │   ├── google-services.json   # Firebase config (Android)
│   │   └── build.gradle.kts       # App-level build config
│   └── build.gradle.kts           # Project-level build config
│
├── ios/                        # iOS-specific configuration
│   ├── Runner/
│   │   ├── GoogleService-Info.plist  # Firebase config (iOS)
│   │   └── Info.plist               # iOS app info
│   └── Runner.xcworkspace           # Xcode workspace
│
├── lib/                        # Main application code
│   ├── main.dart                    # App entry point
│   ├── firebase_options.dart        # Firebase configuration
│   │
│   ├── models/                      # Data models
│   │   ├── user_model.dart          # User entity
│   │   ├── patient_model.dart       # Patient-specific data
│   │   ├── doctor_model.dart        # Doctor-specific data
│   │   └── analysis_model.dart      # X-ray analysis results
│   │
│   ├── screens/                     # UI screens
│   │   ├── auth/                    # Authentication screens
│   │   │   ├── login_screen.dart        # Login with magic link reset
│   │   │   ├── patient_signup_screen.dart
│   │   │   └── doctor_signup_screen.dart
│   │   │
│   │   ├── home/                    # Home/Dashboard screens
│   │   │   ├── patient_home_screen.dart
│   │   │   └── doctor_home_screen.dart
│   │   │
│   │   └── shared/                  # Shared screens
│   │       └── profile_screen.dart      # Dynamic profile editor
│   │
│   ├── services/                    # Business logic & Firebase services
│   │   ├── firebase_auth_service.dart   # Authentication operations
│   │   └── firebase_db_service.dart     # Firestore CRUD operations
│   │
│   └── theme/                       # App styling & theme
│       └── app_theme.dart               # Colors, text styles, spacing
│
├── functions/                  # Firebase Cloud Functions (optional)
│   ├── main.py                      # Python Cloud Functions
│   └── requirements.txt             # Python dependencies
│
├── test-images/                # Sample X-ray images for testing
│
├── firestore.rules             # Firestore security rules
├── firestore.indexes.json      # Firestore indexes configuration
├── firebase.json               # Firebase project config
├── pubspec.yaml                # Flutter dependencies
└── README.md                   # This file
```

### **Key Files Explained**

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, initializes Firebase and Provider |
| `lib/firebase_options.dart` | Auto-generated Firebase configuration |
| `lib/services/firebase_auth_service.dart` | Handles login, signup, password reset |
| `lib/services/firebase_db_service.dart` | Firestore database operations |
| `lib/theme/app_theme.dart` | Centralized theme (colors, typography) |
| `firestore.rules` | Database security rules (deployed to Firebase) |
| `pubspec.yaml` | Package dependencies and assets |

---

## 🔐 Authentication Flow

### **User Registration**

1. **Patient Signup:**
   - User provides: Email, Password, Full Name, Age, Gender
   - System creates:
     - Firebase Auth account
     - User document in `users` collection (role: patient)
     - Patient profile in `patients` collection

2. **Doctor Signup:**
   - User provides: Email, Password, Full Name, Specialization, License Number
   - System creates:
     - Firebase Auth account
     - User document in `users` collection (role: doctor)
     - Doctor profile in `doctors` collection

### **Login Process**

1. User enters email and password
2. Firebase authenticates credentials
3. App fetches user role from Firestore
4. Redirects to role-specific dashboard:
   - **Patient** → `PatientHomeScreen`
   - **Doctor** → `DoctorHomeScreen`

### **Password Reset (Magic Link)**

1. User clicks "Forgot Password?" on login screen
2. Enters email address
3. Firebase sends password reset email with secure link
4. User clicks link in email
5. Firebase presents password reset page
6. User sets new password
7. Redirect to app and login with new credentials

**Advantages of Magic Link:**
- ✅ **No Cloud Functions needed** - Works on free tier
- ✅ **More secure** - Links expire automatically
- ✅ **Better UX** - Single click, no typing codes
- ✅ **Industry standard** - Used by Google, GitHub, etc.

---

## 🗄 Firestore Database Schema

### **Collections Structure**

```
firestore
│
├── users/                      # All users (patients + doctors)
│   └── {userId}
│       ├── email: string
│       ├── fullName: string
│       ├── role: "patient" | "doctor"
│       └── createdAt: timestamp
│
├── patients/                   # Patient-specific data
│   └── {userId}
│       ├── age: number
│       ├── gender: "Male" | "Female" | "Other"
│       ├── createdAt: timestamp
│       └── analyses/           # Sub-collection
│           └── {analysisId}
│               ├── imageUrl: string
│               ├── result: string
│               ├── confidence: number
│               └── timestamp: timestamp
│
├── doctors/                    # Doctor-specific data
│   └── {userId}
│       ├── specialization: string
│       ├── licenseNumber: string
│       └── createdAt: timestamp
│
├── analyses/                   # Shared analyses (for queries)
│   └── {analysisId}
│       ├── userId: string
│       ├── patientId: string
│       ├── result: string
│       └── timestamp: timestamp
│
└── doctorAnalyses/            # Doctor practice scans
    └── {analysisId}
        ├── doctorUid: string
        ├── imageUrl: string
        ├── result: string
        └── timestamp: timestamp
```

### **Security Rules Summary**

- ✅ Users can **only read/write their own data**
- ✅ Doctors can **read all patient records** (for consultation)
- ✅ Patients **cannot access doctor-only collections**
- ✅ No **unauthenticated access** to any protected data
- ✅ **Role-based permissions** enforced at database level

---

## 🛡 Security Rules

The project includes production-ready Firestore security rules in `firestore.rules`.

### **Key Security Features**

1. **Authentication Required**: All operations require valid Firebase auth token
2. **Owner-based Access**: Users can only modify their own documents
3. **Role-based Read Access**: Doctors can read patient data, patients cannot read doctor data
4. **No Deletion**: Profile deletion is disabled to maintain data integrity
5. **Validated Writes**: Data must match expected schema

### **Deploy Security Rules**

```bash
firebase deploy --only firestore:rules
```

### **Test Security Rules** (Optional)

```bash
firebase emulators:start --only firestore
```

---

## 🔧 Troubleshooting

### **Common Issues & Solutions**

#### **1. Firebase Configuration Errors**

**Error:**
```
[core/no-app] No Firebase App '[DEFAULT]' has been created
```

**Solution:**
- Ensure `google-services.json` (Android) is in `android/app/`
- Ensure `GoogleService-Info.plist` (iOS) is in `ios/Runner/`
- Run `flutterfire configure` to regenerate config
- Clean and rebuild: `flutter clean && flutter pub get`

---

#### **2. Google Sign-In Not Working**

**Error:**
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10:, null, null)
```

**Solution (Android):**
1. Add SHA-1 fingerprint to Firebase Console
   ```bash
   # Get SHA-1
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
2. Add fingerprint to Firebase: **Project Settings** → **Your Apps** → **Android** → **Add Fingerprint**
3. Download new `google-services.json`
4. Replace old file and rebuild

**Solution (iOS):**
- Ensure `GoogleService-Info.plist` is added to Xcode project (not just folder)
- Check URL schemes in `Info.plist`
- Rebuild: `flutter clean && cd ios && pod install && cd ..`

---

#### **3. Firestore Permission Denied**

**Error:**
```
[cloud_firestore/permission-denied] Missing or insufficient permissions
```

**Solution:**
1. Check if user is authenticated: `FirebaseAuth.instance.currentUser != null`
2. Verify security rules are deployed:
   ```bash
   firebase deploy --only firestore:rules
   ```
3. Ensure user role matches required permissions
4. Check Firestore Rules in Firebase Console → **Build** → **Firestore Database** → **Rules**

---

#### **4. Build Failures**

**Error (Android):**
```
Execution failed for task ':app:processDebugGoogleServices'
```

**Solution:**
- Ensure `google-services.json` is in correct location: `android/app/`
- Verify package name matches in:
  - `android/app/build.gradle` → `applicationId`
  - `google-services.json` → `package_name`
- Clean build: `flutter clean && cd android && ./gradlew clean && cd ..`

**Error (iOS):**
```
CocoaPods not installed or not in valid state
```

**Solution:**
```bash
# Install CocoaPods
sudo gem install cocoapods

# Install pods
cd ios
pod install
cd ..

# Rebuild
flutter run -d ios
```

---

#### **5. Image Picker Not Working**

**Error:**
```
PlatformException(photo_access_denied, ...)
```

**Solution (Android):**
- Add permissions to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
  ```

**Solution (iOS):**
- Add keys to `ios/Runner/Info.plist`:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>We need camera access to capture X-ray images</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>We need photo library access to select X-ray images</string>
  ```

---

#### **6. Flutter Doctor Issues**

**Error:**
```
[✗] Android toolchain - develop for Android devices
```

**Solution:**
1. Install Android Studio
2. Install Android SDK via SDK Manager
3. Accept licenses: `flutter doctor --android-licenses`
4. Run `flutter doctor` again

---

#### **7. Dependencies Not Installing**

**Error:**
```
Because chestsense depends on package_name ^x.x.x which doesn't exist, version solving failed
```

**Solution:**
```bash
# Clear pub cache
flutter pub cache repair

# Remove lock file
rm pubspec.lock

# Reinstall
flutter pub get

# If still failing, check pubspec.yaml for typos
```

---

#### **8. Hot Reload Not Working**

**Symptoms:**
- Changes not reflecting in app
- Need to restart every time

**Solution:**
- Use `R` (capital R) for hot restart instead of `r`
- Some changes require full restart (e.g., main.dart, Provider changes)
- Ensure you're editing correct file (check file path)
- Try: `flutter clean && flutter pub get && flutter run`

---

#### **9. Web Build Errors**

**Error:**
```
Failed to load Firebase config
```

**Solution:**
- Check `web/index.html` has correct Firebase config
- Ensure `firebase.js` scripts are loaded before app initialization
- Clear browser cache and rebuild:
  ```bash
  flutter clean
  flutter build web --release
  ```

---

### **Getting Help**

If you encounter issues not listed here:

1. **Check Flutter Logs:**
   ```bash
   flutter run --verbose
   ```

2. **Check Firebase Console:**
   - Authentication logs
   - Firestore usage metrics
   - Error reporting

3. **Search GitHub Issues:**
   - [Flutter Issues](https://github.com/flutter/flutter/issues)
   - [FlutterFire Issues](https://github.com/firebase/flutterfire/issues)

4. **Community Support:**
   - [Stack Overflow - Flutter Tag](https://stackoverflow.com/questions/tagged/flutter)
   - [Flutter Discord](https://discord.gg/flutter)
   - [r/FlutterDev](https://www.reddit.com/r/FlutterDev/)

---

## ⚠️ Known Issues

### **Current Limitations**

1. **Cloud Functions Not Deployed** (free tier limitation)
   - Email notifications not implemented
   - Scheduled cleanup jobs not active
   - Solution: Upgrade to Blaze plan for Cloud Functions

2. **AI Model Not Integrated**
   - X-ray analysis currently returns mock data
   - TODO: Integrate TensorFlow Lite or cloud ML API

3. **Firebase Storage Not Configured**
   - Images currently stored as base64 in Firestore (not recommended for production)
   - TODO: Migrate to Firebase Storage for image hosting

4. **No Offline Support**
   - App requires internet connection
   - TODO: Enable Firestore offline persistence

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

### **Development Workflow**

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes**
4. **Run tests** (when available)
   ```bash
   flutter test
   ```
5. **Commit with meaningful messages**
   ```bash
   git commit -m "feat: add amazing feature"
   ```
6. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```
7. **Open a Pull Request**

### **Code Style**

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` to check code quality
- Format code: `flutter format .`
- Add comments for complex logic

### **Commit Message Format**

```
type(scope): subject

body (optional)

footer (optional)
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Example:**
```
feat(auth): add password reset functionality

Implemented magic link-based password reset using Firebase Auth.
Removed OTP system to stay on free tier.

Closes #42
```

---

## 📄 License

This project is licensed under the **MIT License**.

```
MIT License

Copyright (c) 2026 ChestSense

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📞 Support & Contact

### **Project Links**

- **Documentation**: [https://github.com/yourusername/chestsense/wiki](https://github.com/yourusername/chestsense/wiki)
- **Issue Tracker**: [https://github.com/yourusername/chestsense/issues](https://github.com/yourusername/chestsense/issues)
- **Discussions**: [https://github.com/yourusername/chestsense/discussions](https://github.com/yourusername/chestsense/discussions)

### **Firebase Resources**

- **Firebase Console**: [https://console.firebase.google.com](https://console.firebase.google.com)
- **Firebase Documentation**: [https://firebase.google.com/docs](https://firebase.google.com/docs)
- **FlutterFire Documentation**: [https://firebase.flutter.dev](https://firebase.flutter.dev)

### **Flutter Resources**

- **Flutter Documentation**: [https://docs.flutter.dev](https://docs.flutter.dev)
- **Dart Documentation**: [https://dart.dev/guides](https://dart.dev/guides)
- **Flutter Packages**: [https://pub.dev](https://pub.dev)

---

## 🙏 Acknowledgments

- **Flutter Team** for the amazing cross-platform framework
- **Firebase Team** for comprehensive backend services
- **Open Source Community** for invaluable packages and support
- **Medical Professionals** for domain expertise and feedback

---

<div align="center">

**Made with ❤️ using Flutter & Firebase**

⭐ Star this repo if you find it helpful!

[Report Bug](https://github.com/yourusername/chestsense/issues) • [Request Feature](https://github.com/yourusername/chestsense/issues) • [View Demo](https://chestsense-demo.web.app)

</div>