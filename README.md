# ChestSense — CT-Scan Tumor Detection Platform

A clinical-grade, AI-powered Flutter application for detecting and classifying tumors in CT scan images. The app supports two user roles — **Doctor** and **Patient** — with role-specific workflows including Grad-CAM heatmap visualization for physicians.

---

## Table of Contents

1. [Application Overview](#1-application-overview)
2. [Architecture](#2-architecture)
3. [Prerequisites](#3-prerequisites)
4. [Project Setup](#4-project-setup)
5. [Firebase Configuration](#5-firebase-configuration)
6. [Android-Specific Configuration](#6-android-specific-configuration)
7. [iOS-Specific Configuration](#7-ios-specific-configuration)
8. [ML Models](#8-ml-models)
9. [Running the Application](#9-running-the-application)
10. [Building for Release](#10-building-for-release)
11. [Project Structure](#11-project-structure)
12. [Key Files Reference](#12-key-files-reference)
13. [Firestore Security Rules](#13-firestore-security-rules)
14. [Common Errors & Solutions](#14-common-errors--solutions)
15. [Environment Configuration](#15-environment-configuration)
16. [Testing](#16-testing)

---

## 1. Application Overview

ChestSense is a Flutter-based medical imaging application designed to assist oncologists and patients with AI-powered CT scan tumor analysis. The core pipeline combines two deep learning models running entirely **on-device** via TensorFlow Lite:

| Feature | Doctor Role | Patient Role |
|---|---|---|
| CT Scan Upload | ✅ | ✅ |
| YOLO Tumor Detection | ✅ | ✅ |
| DenseNet Classification | ✅ | ✅ |
| Grad-CAM Heatmap | ✅ (physician only) | ❌ |
| Bounding Box Overlay | ✅ | ✅ |
| Profile Management | ✅ | ✅ |
| Test Image Library | ✅ | ✅ |

**Tech Stack:**
- Flutter 3.41.1 / Dart 3.11.0
- Firebase (Auth, Firestore)
- TensorFlow Lite 0.12.0 (on-device inference)
- YOLOv8 (object detection)
- DenseNet121 (tumor classification)
- Grad-CAM (class activation mapping)
- Provider (state management)

---

## 2. Architecture

```
chestsense/
├── lib/
│   ├── main.dart                    # App entry point, Firebase init, service registration
│   ├── firebase_options.dart        # Auto-generated Firebase config (FlutterFire CLI)
│   │
│   ├── core/                        # Infrastructure layer
│   │   ├── app_config.dart          # Environment configs (dev/staging/prod)
│   │   ├── ml_config.dart           # ML model paths, thresholds, input sizes
│   │   ├── service_locator.dart     # Dependency injection container
│   │   ├── service_registration.dart# Registers all ML services at startup
│   │   ├── service_interfaces.dart  # IDetectionService, IClassificationService, IMLPipelineService
│   │   ├── service_lifecycle.dart   # Service init ordering and lifecycle management
│   │   ├── exceptions.dart          # Typed exceptions (ModelInitializationException, etc.)
│   │   └── logger_service.dart      # Structured ML/error logging
│   │
│   ├── services/                    # Business logic layer
│   │   ├── firebase_auth_service.dart
│   │   ├── firebase_db_service.dart
│   │   ├── yolo_detection_service_tflite.dart        # Conditional export
│   │   ├── yolo_detection_service_tflite.native.dart # Android/iOS TFLite implementation
│   │   ├── yolo_detection_service_tflite.web.dart    # Web stub
│   │   ├── densenet_classification_service_tflite.dart
│   │   ├── densenet_classification_service_tflite.native.dart
│   │   ├── densenet_classification_service_tflite.web.dart
│   │   ├── ml_pipeline_service_tflite.dart           # Orchestrates YOLO → DenseNet
│   │   ├── ml_pipeline_service_tflite.native.dart
│   │   ├── ml_pipeline_service_tflite.web.dart
│   │   ├── tflite_interpreter_service.dart           # TFLite interpreter wrapper
│   │   ├── gradcam_service.dart                      # Grad-CAM implementation
│   │   ├── heatmap_generation_service.dart           # Heatmap image rendering
│   │   └── ml_pipeline_provider.dart                 # Provider wrapper for pipeline
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── auth_gate.dart           # Root auth + role-based routing
│   │   │   ├── welcome_screen.dart      # Landing/splash screen
│   │   │   ├── role_selection_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── doctor_signup_screen.dart
│   │   │   └── patient_signup_screen.dart
│   │   ├── dashboards/
│   │   │   └── dashboards.dart          # DoctorDashboard + PatientDashboard
│   │   ├── scan/
│   │   │   └── ct_scan_analysis_screen.dart  # Core scan + result screen
│   │   └── shared/
│   │       ├── profile_screen.dart
│   │       └── tumor_classification_card.dart
│   │
│   ├── ML/
│   │   ├── yolo/
│   │   │   └── best_float16.tflite      # YOLOv8 tumor detection model
│   │   └── detection/
│   │       └── densenet_model.tflite    # DenseNet121 classification model
│   │
│   ├── theme/
│   │   └── app_theme.dart              # AppColors, AppText, AppRadius, shared widgets
│   └── widgets/
│       ├── image_with_bounding_boxes.dart
│       └── test_image_selector.dart
│
├── android/                            # Android platform config
├── ios/                                # iOS platform config
├── test-images/                        # 11 labeled test CT-scan images
├── firestore.rules                     # Firestore security rules
└── pubspec.yaml
```

### ML Inference Pipeline

```
User picks CT scan image
        ↓
Image decoded to img.Image (dart:image)
        ↓
┌─────────────────────────────────────────┐
│           YOLO Detection                │
│  Input:  640×640 RGB float32            │
│  Model:  lib/ML/yolo/best_float16.tflite│
│  Output: Bounding boxes + confidence    │
│  Class:  ['tumor']                      │
└─────────────────────────────────────────┘
        ↓ (detected ROIs)
┌─────────────────────────────────────────┐
│        DenseNet Classification          │
│  Input:  224×224 RGB float32            │
│  Model:  lib/ML/detection/              │
│          densenet_model.tflite          │
│  Normalization: mean=[0.485,0.456,0.406]│
│                 std =[0.229,0.224,0.225]│
│  Output: 4-class probability vector     │
└─────────────────────────────────────────┘
        ↓ (doctor role only)
┌─────────────────────────────────────────┐
│           Grad-CAM Heatmap              │
│  Last conv layer: 7×7×1024 (DenseNet)   │
│  Output: Normalized activation heatmap  │
│          overlaid on original image     │
└─────────────────────────────────────────┘
        ↓
Results shown with bounding boxes,
classification label, confidence score,
and heatmap overlay
```

---

## 3. Prerequisites

### Required Software

| Tool | Version | Install |
|---|---|---|
| Flutter SDK | 3.41.1+ | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| Dart SDK | 3.11.0+ | Bundled with Flutter |
| Android Studio | Latest | [developer.android.com](https://developer.android.com/studio) |
| Xcode | 15.0+ | Mac App Store (iOS only) |
| Java (JDK) | **17 exactly** | See below |
| Firebase CLI | Latest | `npm install -g firebase-tools` |
| FlutterFire CLI | Latest | `dart pub global activate flutterfire_cli` |
| Git LFS | 3.7.1+ | `brew install git-lfs` |

### Installing Java 17 (macOS)

```bash
brew install openjdk@17
sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk \
    /Library/Java/JavaVirtualMachines/openjdk-17.jdk
java -version   # must show openjdk version "17.x.x"
```

> ⚠️ Java 21 or Java 11 will cause Gradle build failures. Only Java 17 is supported.

### Verify Flutter Installation

```bash
flutter doctor -v
```

All checks should pass. If Android toolchain shows issues, run:

```bash
flutter doctor --android-licenses
```

---

## 4. Project Setup

### Step 1 — Clone the Repository

```bash
git clone <repository-url>
cd chestsense
```

### Step 2 — Initialize Git LFS

The ML model `.tflite` files are tracked via Git LFS. Run this before anything else:

```bash
git lfs install
git lfs pull
```

Verify the models are real binary files (not LFS pointer text):

```bash
ls -lh lib/ML/yolo/best_float16.tflite
ls -lh lib/ML/detection/densenet_model.tflite
# Both should show file sizes > 1MB
```

### Step 3 — Install Flutter Dependencies

```bash
flutter pub get
```

### Step 4 — Configure Flutter SDK Path (if path contains spaces)

If your Flutter SDK is installed in a path with spaces (e.g. `/Documents/Flutter SDK/flutter`), create a symlink:

```bash
ln -sf "/path/to/Flutter SDK/flutter" ~/flutter_sdk
```

Then update `android/local.properties`:

```properties
flutter.sdk=/Users/<your-username>/flutter_sdk
sdk.dir=/Users/<your-username>/Library/Android/sdk
```

---

## 5. Firebase Configuration

### Step 1 — Create a Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project named `chestsense` (or any name)
3. Enable the following services:
   - **Authentication** → Email/Password provider
   - **Cloud Firestore** → Start in production mode
4. Do **NOT** enable Firebase Storage (it has been removed from this project)

### Step 2 — Register Apps in Firebase

Register both **Android** and **iOS** apps:

- **Android package name:** `com.example.chestsense`
- **iOS bundle ID:** `com.example.chestsense`

### Step 3 — Generate Firebase Config with FlutterFire CLI

```bash
# Login to Firebase
firebase login

# Configure FlutterFire (run from project root)
flutterfire configure --project=<your-firebase-project-id>
```

This auto-generates `lib/firebase_options.dart`. Do not edit this file manually.

### Step 4 — Download google-services.json

1. In Firebase Console → Project Settings → Your Apps → Android app
2. Download `google-services.json`
3. Place it at: `android/app/google-services.json`

> ⚠️ This file is gitignored. Every developer must download their own copy.

### Step 5 — Deploy Firestore Security Rules

```bash
firebase deploy --only firestore:rules
```

### Firestore Collections Structure

```
users/
  {uid}/
    uid: string
    email: string
    displayName: string
    phone: string
    role: "doctor" | "patient"
    createdAt: timestamp
    updatedAt: timestamp

patients/
  {uid}/
    uid: string
    age: string
    gender: string
    medicalHistory: string
    createdAt: timestamp
    analyses/
      {analysisId}/
        (scan results)

doctors/
  {uid}/
    uid: string
    specialty: string
    licenseNumber: string
    createdAt: timestamp
```

---

## 6. Android-Specific Configuration

### android/local.properties

This file is **gitignored** and must be created manually on each machine:

```properties
# Path to Flutter SDK — use symlink if path has spaces
flutter.sdk=/Users/<your-username>/flutter_sdk

# Path to Android SDK
sdk.dir=/Users/<your-username>/Library/Android/sdk

flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1
```

### android/gradle.properties

Already committed. Verify it contains:

```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
org.gradle.java.home=/Library/Java/JavaVirtualMachines/openjdk-17.jdk/Contents/Home
```

Update `org.gradle.java.home` if your Java 17 is installed at a different path:

```bash
# Find the path
/usr/libexec/java_home -v 17
```

### Minimum SDK Versions

```
minSdk    = Flutter default (currently 21)
targetSdk = Flutter default (currently 35)
compileSdk= Flutter default (currently 35)
```

### Android Icon Files

Icons must be named `ic_launcher.png` and `ic_launcher_round.png` in each density folder:

```
android/app/src/main/res/
├── mipmap-mdpi/
│   ├── ic_launcher.png        (48×48)
│   └── ic_launcher_round.png  (48×48)
├── mipmap-hdpi/               (72×72)
├── mipmap-xhdpi/              (96×96)
├── mipmap-xxhdpi/             (144×144)
└── mipmap-xxxhdpi/            (192×192)
```

---

## 7. iOS-Specific Configuration

### Xcode Setup

Open the iOS project in Xcode once before building:

```bash
open ios/Runner.xcworkspace
```

Sign the app under **Runner → Signing & Capabilities → Team**.

### iOS Permissions

The following permissions are declared in `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Required to capture CT scan images for tumor analysis.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Required to select CT scan images from your photo library.</string>
```

### iOS Icon Files

Icons are in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` and referenced by `Contents.json`. No manual renaming needed.

---

## 8. ML Models

### Model Summary

| Model | Architecture | Purpose | Input Size | Format |
|---|---|---|---|---|
| `best_float16.tflite` | YOLOv8 | Tumor region detection | 640×640 | float16 TFLite |
| `densenet_model.tflite` | DenseNet121 | Tumor classification | 224×224 | float32 TFLite |

### File Locations

```
lib/ML/
├── yolo/
│   └── best_float16.tflite         # YOLOv8 detection model
└── detection/
    └── densenet_model.tflite       # DenseNet121 classification model
```

Both files are declared as Flutter assets in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - lib/ML/yolo/best_float16.tflite
    - lib/ML/detection/densenet_model.tflite
    - test-images/
```

### Model Configuration (`lib/core/ml_config.dart`)

**YOLO Configuration:**

```dart
YOLOConfig(
  modelPath: 'lib/ML/yolo/best_float16.tflite',
  inputWidth: 640,
  inputHeight: 640,
  confidenceThreshold: 0.25,  // development  |  0.35 production
  iouThreshold: 0.45,
  maxDetections: 100,         // development  |  50 production
  numClasses: 1,
  classNames: ['tumor'],
)
```

**DenseNet Configuration:**

```dart
DenseNetConfig(
  modelPath: 'lib/ML/detection/densenet_model.tflite',
  inputWidth: 224,
  inputHeight: 224,
  numClasses: 4,
  mean: [0.485, 0.456, 0.406],
  std:  [0.229, 0.224, 0.225],
)
```

### Replacing or Updating Models

1. Place new `.tflite` file in the appropriate `lib/ML/` subdirectory
2. Update the path in `lib/core/ml_config.dart` (all three environment factories)
3. If input size or class count changed, update the corresponding config values
4. Run `flutter pub get` and rebuild

> ⚠️ Large model files (>50MB) must be tracked with Git LFS:
> ```bash
> git lfs track "*.tflite"
> git add .gitattributes
> git add lib/ML/yolo/best_float16.tflite
> git commit -m "Add updated YOLO model"
> ```

### Grad-CAM (Doctor Role Only)

Grad-CAM uses DenseNet121's last convolutional layer (`7×7×1024`) to generate class activation maps. It is automatically enabled when `userRole == 'doctor'` and produces a color heatmap overlaid on the CT scan image showing the spatial regions that influenced the classification.

---

## 9. Running the Application

### List Connected Devices

```bash
flutter devices
```

### Run on Android Device / Emulator

```bash
# Debug mode
flutter run -d <device-id>

# Example: physical device over ADB WiFi
flutter run -d adb-32281JEHN03561-W3ovLs._adb-tls-connect._tcp

# Example: emulator
flutter run -d emulator-5554
```

### Run on iOS Simulator

```bash
flutter run -d <simulator-id>
# or
flutter run -d iPhone\ 15\ Pro
```

### Run on macOS

```bash
flutter run -d macos
```

> ⚠️ Web platform is not supported due to TFLite FFI incompatibility.

### Hot Reload & Hot Restart

While the app is running in terminal:

```
r  → Hot reload (preserves state)
R  → Hot restart (resets state)
q  → Quit
```

### First-Time Launch Checklist

- [ ] `android/local.properties` created with correct paths
- [ ] `android/app/google-services.json` downloaded from Firebase Console
- [ ] `lib/firebase_options.dart` generated via `flutterfire configure`
- [ ] Git LFS pulled (`git lfs pull`)
- [ ] Both `.tflite` files exist and are >1MB (not LFS pointers)
- [ ] Java 17 installed and `org.gradle.java.home` set correctly
- [ ] `flutter pub get` run successfully

---

## 10. Building for Release

### Android APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (recommended for Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS IPA

```bash
flutter build ipa --release
# Output: build/ios/archive/Runner.xcarchive
```

> ⚠️ Release builds require a proper signing configuration in `android/app/build.gradle.kts`. The current config uses debug keys for all build types.

---

## 11. Project Structure

### Authentication Flow

```
App Launch
    ↓
AuthGate (auth_gate.dart)
    ├── No user → WelcomeScreen
    │       ↓ Get Started
    │   RoleSelectionScreen
    │       ├── Doctor → DoctorSignupScreen
    │       └── Patient → PatientSignupScreen
    │
    └── Authenticated user
            ↓ reads Firestore role field
            ├── role == 'doctor'  → DoctorDashboard
            └── role == 'patient' → PatientDashboard
```

### CT Scan Analysis Flow

```
Dashboard → CTScanAnalysisScreen
    ↓
Image source: Gallery | Camera | Test Image Library
    ↓
Image decoded (dart:image)
    ↓
ML Pipeline: YOLO Detection
    ↓
If detections found:
    ML Pipeline: DenseNet Classification per ROI
    ↓ (doctor only)
    Grad-CAM Heatmap Generation
    ↓
Results displayed:
    - Bounding boxes on image
    - Classification label + confidence
    - Heatmap overlay (doctor only)
    - Per-tumor breakdown
```

### Service Registration (startup)

```
main() → registerServices()
    ├── register IDetectionService    → YOLODetectionServiceTFLite
    ├── register IClassificationService → DenseNetClassificationServiceTFLite
    └── register IMLPipelineService (lazy) → MLPipelineServiceTFLite

main() → initializeServices()
    └── calls initialize() on all registered services in dependency order
```

---

## 12. Key Files Reference

| File | Purpose | When to Edit |
|---|---|---|
| `lib/core/ml_config.dart` | Model paths, thresholds, input dimensions | Replacing models or tuning detection sensitivity |
| `lib/core/app_config.dart` | Environment settings (dev/staging/prod) | Changing environment or feature flags |
| `lib/core/service_registration.dart` | Service DI wiring | Adding new ML services |
| `android/local.properties` | Flutter SDK + Android SDK paths | Setting up on a new machine |
| `android/gradle.properties` | JVM args, Java home path | Changing Java version |
| `android/settings.gradle.kts` | Gradle plugin management | Updating Gradle/plugin versions |
| `android/app/build.gradle.kts` | Android build config, signing | Changing app ID, minSdk, signing |
| `android/app/google-services.json` | Firebase Android config | Switching Firebase projects |
| `lib/firebase_options.dart` | Firebase multi-platform config | Switching Firebase projects (regenerate with FlutterFire CLI) |
| `firestore.rules` | Firestore security rules | Changing data access permissions |
| `pubspec.yaml` | Dependencies and asset declarations | Adding packages or new asset files |

---

## 13. Firestore Security Rules

The rules enforce role-based access control:

- **Users collection** (`/users/{uid}`): Each user reads/writes only their own document. Doctors can read any user document.
- **Patients collection** (`/patients/{uid}`): Patient reads/writes own data. Doctors can read all patient data.
- **Analyses sub-collection** (`/patients/{uid}/analyses/{id}`): Same as parent patient document.
- **Doctors collection** (`/doctors/{uid}`): Any signed-in user can read. Doctors manage own document.

Deploy rules after any change:

```bash
firebase deploy --only firestore:rules
```

---

## 14. Common Errors & Solutions

### Error: `resource mipmap/ic_launcher not found`

**Cause:** Android icon files are not named correctly.

**Solution:**
```bash
cd android/app/src/main/res
for density in mipmap-mdpi mipmap-hdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi; do
  cp $density/<your-icon>.png $density/ic_launcher.png
  cp $density/<your-icon>.png $density/ic_launcher_round.png
done
```

---

### Error: `Unsupported class file major version 65` (or 61, 64)

**Cause:** Wrong Java version. Gradle requires Java 17 exactly.

**Solution:**
```bash
brew install openjdk@17
# Then set in android/gradle.properties:
org.gradle.java.home=/Library/Java/JavaVirtualMachines/openjdk-17.jdk/Contents/Home
```

---

### Error: `flutter.sdk not set in local.properties`

**Cause:** `android/local.properties` is missing or has an incorrect path.

**Solution:** Create the file:
```properties
flutter.sdk=/Users/<your-username>/flutter_sdk
sdk.dir=/Users/<your-username>/Library/Android/sdk
```

If the SDK path has spaces, create a symlink:
```bash
ln -sf "/path/with spaces/flutter" ~/flutter_sdk
```

---

### Error: `Could not resolve com.android.tools.build:gradle`

**Cause:** Gradle cannot reach Maven repositories, or version mismatch.

**Solution:**
```bash
cd android && ./gradlew --refresh-dependencies
```

---

### Error: `No Firebase App '[DEFAULT]' has been created`

**Cause:** Firebase initialized more than once (hot reload).

**Solution:** Already handled in `main.dart` with a try-catch. If it persists:
```bash
flutter clean && flutter run
```

---

### Error: `ModelInitializationException` or TFLite model load fails

**Cause 1:** Git LFS not pulled — model files are LFS pointer text, not real binaries.
```bash
git lfs pull
# Verify: file should be > 1MB
ls -lh lib/ML/yolo/best_float16.tflite
```

**Cause 2:** Asset not declared in `pubspec.yaml`.
```yaml
assets:
  - lib/ML/yolo/best_float16.tflite
  - lib/ML/detection/densenet_model.tflite
```

**Cause 3:** Model path in `ml_config.dart` doesn't match the actual file path.

---

### Error: `MissingPluginException` for image_picker or permission_handler

**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

---

### Error: Gradle build fails with `OutOfMemoryError`

**Solution:** Increase heap in `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G
```

---

### Error: `Execution failed for task ':app:processDebugResources'`

**Cause:** Usually a missing resource file or broken asset reference.

**Solution:** Clean and rebuild with verbose output:
```bash
flutter clean
cd android && ./gradlew assembleDebug --info 2>&1 | grep "error:"
```

---

### iOS: `CocoaPods not installed`

```bash
sudo gem install cocoapods
cd ios && pod install
```

---

## 15. Environment Configuration

The app uses three environments controlled by `lib/core/app_config.dart`:

| Setting | Development | Staging | Production |
|---|---|---|---|
| YOLO confidence threshold | 0.25 | 0.35 | 0.40 |
| YOLO max detections | 100 | 50 | 50 |
| Debug logging | ✅ | ❌ | ❌ |
| Performance monitoring | ✅ | ✅ | ✅ |
| Analytics | ❌ | ✅ | ✅ |

The current build always uses `ConfigService.initialize()` which defaults to `Environment.development`.

To switch environments, modify `lib/core/app_config.dart`:

```dart
// In ConfigService.initialize()
_instance = AppConfig.production();  // or .staging()
```

---

## 16. Testing

### Static Analysis

```bash
flutter analyze
# Expected: "No issues found!"
```

### Unit Tests

```bash
flutter test
```

### Python Model Validation

A Python script is provided for validating TFLite model output shapes:

```bash
pip install tensorflow numpy pillow
python test_models.py
```

### Test Image Library

11 labeled CT scan images are included in `test-images/` for manual in-app testing:

| Filename prefix | Class | Condition |
|---|---|---|
| `A0112`, `A0038` | Class A | Normal |
| `B0038`, `B0019`, `B0012` | Class B | Pneumonia |
| `E0004` (×3 variants) | Class E | Edema |
| `G0048`, `G0002`, `G0056` | Class G | Ground Glass |

Access via the **"Load Test Image"** button on the scan screen.

---

## Contact & Support

For issues with Firebase setup, contact the project maintainer to obtain:
- `google-services.json` (Android)
- `GoogleService-Info.plist` (iOS)
- Firebase project ID

Both files contain sensitive API keys and are excluded from version control.
