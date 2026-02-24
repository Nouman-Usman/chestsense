# YOLO + Doctr Integration Setup Checklist

## ✅ Pre-Integration Setup (You have your converted .tflite model)

### Step 1: Model Conversion ⚙️
- [ ] Have your `best.pt` file ready
- [ ] Convert to TensorFlow Lite format (.tflite)
  - [ ] Use online converter: https://convertmodel.com/
  - [ ] OR use local tools (see INTEGRATION_GUIDE.md for commands)
  - [ ] Result: `best.tflite` file
- [ ] Note the model's input size (typically 640x640)

### Step 2: Project Setup 📦
- [ ] Ensure Flutter is up to date: `flutter upgrade`
- [ ] Run: `flutter pub get`
  - [ ] New packages installed:
    - [ ] `tflite_flutter: ^0.10.4`
    - [ ] `google_mlkit_text_recognition: ^0.15.0`
    - [ ] `image: ^4.1.7`
    - [ ] `permission_handler: ^11.4.4`

### Step 3: File Organization 📁
- [ ] Create directory: `lib/ML/yolo/`
- [ ] Place `best.tflite` in: `lib/ML/yolo/best.tflite`
- [ ] Verify path is correct

### Step 4: Assets Configuration 🎨
- [ ] Open `pubspec.yaml`
- [ ] Locate `flutter:` section
- [ ] Add assets:
```yaml
flutter:
  assets:
    - lib/ML/yolo/best.tflite
```
- [ ] Run: `flutter pub get` again

### Step 5: Verify Integration ✓
- [ ] Check these files exist:
  - [ ] `lib/services/ml_service.dart` (enhanced)
  - [ ] `lib/services/yolo_detection_service.dart` (new)
  - [ ] `lib/services/doctr_service.dart` (new)
  - [ ] `lib/screens/shared/xray_upload_screen.dart` (enhanced)
  - [ ] `lib/main.dart` (updated)

- [ ] Check documentation exists:
  - [ ] `lib/ML/INTEGRATION_GUIDE.md`
  - [ ] `lib/ML/API_REFERENCE.md`
  - [ ] `YOLO_DOCTR_SETUP.md`
  - [ ] `IMPLEMENTATION_SUMMARY.md`

## 🚀 Testing

### Test 1: Build Compilation ✓
```bash
flutter clean
flutter pub get
flutter analyze
```
- [ ] No errors reported
- [ ] Only missing package errors until dependencies install

### Test 2: Run Application
```bash
flutter run
```
- [ ] App launches successfully
- [ ] No crashes on startup
- [ ] MLService initializes (check console for "ML Services initialized")

### Test 3: Patient Upload Screen
```
1. [ ] Login as patient
2. [ ] Navigate to home screen
3. [ ] Tap "X-Ray Analysis" or equivalent
4. [ ] Screen should load without errors
5. [ ] Image picker works (select image)
6. [ ] "Analyse X-Ray" button appears
```

### Test 4: Full Analysis Flow
```
1. [ ] Upload X-ray image
2. [ ] See "Uploading image..." status
3. [ ] See "AI model analyzing..." status
4. [ ] Results display with:
   - [ ] Severity level (colored badge)
   - [ ] Anomaly score (progress bar)
   - [ ] Individual detections listed
   - [ ] OCR keywords (if text present)
   - [ ] Processing time shown
5. [ ] No crashes during analysis
```

## 🔧 Configuration Adjustments (Optional)

### Adjust Detection Sensitivity
In `lib/services/yolo_detection_service.dart`:
```dart
// Line ~124
static const double confidenceThreshold = 0.5;  // 0.3-0.7 typical
static const double iouThreshold = 0.45;        // 0.4-0.5 typical
```
- [ ] Adjusted if needed for your use case

### Verify Model Input Size
In `lib/services/ml_service.dart` around line 110:
```dart
final imageWidth = 640;   // Must match your model input
final imageHeight = 640;  // Change if model uses different size
```
- [ ] Matches your converted model input dimensions

### Enable/Disable Features in Upload Screen
In `lib/screens/shared/xray_upload_screen.dart` around line 133:
```dart
final combined = await mlService.analyzeChestXray(
  imageFile: fileArg,
  imageUrl: url,
  imageWidth: imageWidth,
  imageHeight: imageHeight,
  includeDocumentOCR: true,   // [ ] Set to false to skip OCR
  useBackendAPI: false,        // [ ] Set to true if backend configured
);
```

## 📱 Platform-Specific Setup (If Needed)

### Android
- [ ] Permissions set in `android/app/build.gradle` (if needed)
- [ ] Run: `flutter run --verbose` if issues occur

### iOS  
- [ ] Permissions set in `ios/Runner/Info.plist` (if needed)
- [ ] May need pod update: `cd ios && pod install && cd ..`

### Web (If Supporting)
- [ ] Note: YOLO/TFLite support may be limited on web
- [ ] Test separately before deploying

## 📊 Firebase Integration Check

- [ ] Firestore security rules allow patient analyses:
```
allow write: if request.auth.uid == userId;
```
- [ ] Storage bucket configured for X-ray images
- [ ] Results display correctly in Firestore console

## 🎯 Feature Verification

### YOLO Detection Features
- [ ] Detects anomalies with confidence scores
- [ ] Generates severity classifications
- [ ] Shows bounding boxes in results
- [ ] Lists detections sorted by confidence
- [ ] Calculates processing time correctly

### Doctr OCR Features
- [ ] Extracts text from document images
- [ ] Identifies medical keywords
- [ ] Shows OCR confidence score
- [ ] Displays keywords as chips in UI

### Combined Features
- [ ] Both YOLO and Doctr run together
- [ ] Results display in single card
- [ ] Generate Report button works (if added)
- [ ] Severity combines both analyses
- [ ] All results saved to Firestore

## 🐛 Debugging Checklist

If errors occur, check:

### Build Errors
- [ ] Run `flutter clean` first
- [ ] Run `flutter pub get` again
- [ ] Check `pubspec.yaml` formatting
- [ ] Verify all imports are correct
- [ ] Check for typos in file paths

### Runtime Errors
- [ ] Check console logs for specific errors
- [ ] Verify `best.tflite` is in correct path
- [ ] Confirm model input size matches code
- [ ] Check Firebase is properly initialized
- [ ] Ensure permissions are granted

### Analysis Not Running
- [ ] Check model file exists and path is correct
- [ ] Verify image is valid format (JPG/PNG)
- [ ] Check image size (should be >100x100 pixels)
- [ ] Ensure enough RAM available
- [ ] Check network for Firebase operations

### Incorrect Results
- [ ] Verify model was properly converted to TFLite
- [ ] Check confidence threshold setting
- [ ] Ensure image preprocessing is correct
- [ ] Test with known good images first

## 📚 Documentation References

| Document | Purpose |
|----------|---------|
| `INTEGRATION_GUIDE.md` | Complete technical documentation |
| `API_REFERENCE.md` | Quick method/class reference |
| `YOLO_DOCTR_SETUP.md` | Setup and quick start |
| `IMPLEMENTATION_SUMMARY.md` | What was implemented and why |

## ✨ Success Indicators

Your integration is successful when:

✅ App builds without errors
✅ App launches and MLService initializes
✅ Patient can select and upload X-ray
✅ YOLO detection runs and shows results
✅ OCR extracts text (if text is in image)
✅ Combined results display in UI
✅ Results save to Firestore
✅ Doctor can see results (if doctor UI implemented)

## 🚨 Common Issues & Solutions

| Issue | Check | Solution |
|-------|-------|----------|
| "Model not found" | `lib/ML/yolo/best.tflite` exists | Place model file in correct path |
| "Undefined Interpreter" | Dependencies installed | Run `flutter pub get` |
| "Poor detection quality" | Model accuracy | Verify model was newly trained |
| "Analysis too slow" | Image size, device specs | Reduce image resolution |
| "OCR not working" | Image has text | Ensure text is visible and clear |
| "Firebase errors" | Firebase setup | Check Firebase console config |
| "Permission denied" | App permissions | Grant camera/storage permissions |

## 📋 Final Checklist Before Production

- [ ] All tests pass locally
- [ ] No console warnings or errors
- [ ] Model detection accuracy verified
- [ ] OCR tested with actual documents
- [ ] Firebase rules properly configured
- [ ] Error handling implemented
- [ ] User feedback messages set
- [ ] Performance acceptable
- [ ] Doctor review UI ready (if needed)
- [ ] Documentation updated
- [ ] Team trained on new features
- [ ] Backup of model files
- [ ] Version bumped in pubspec.yaml
- [ ] CHANGELOG updated

## 🎉 Launch Readiness

Once all checkboxes are complete:

```bash
# Final build and test
flutter clean
flutter pub get
flutter build apk    # or ios, web as needed
flutter run --release

# Verify on actual device
# Test patient workflow end-to-end
# Check Firestore data structure
# Verify doctor can see results
```

**Ready to launch! 🚀**

---

**Keep this checklist handy for future reference and troubleshooting!**
