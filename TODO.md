# TODO List for Plant Disease Detection App Refactoring

## Part 1: Clean Dependencies (pubspec.yaml)
- [x] Remove Firebase-related dependencies: firebase_core, firebase_auth, cloud_firestore
- [x] Remove commented google_sign_in line
- [x] Run flutter pub get

## Part 2: Remove Auth Logic (main.dart)
- [x] Remove Firebase imports: firebase_core, firebase_options
- [x] Remove Firebase.initializeApp() from main()
- [x] Ensure home is set directly to HomeLandingScreen (already done via GoRouter)

## Part 3: Fix Camera Crash (cameraScreen.dart)
- [x] Remove _loadModel() call from initState()
- [x] Move model loading logic to _runPrediction() or image capture function

## Part 4: Clean Up Unused Files
- [x] Delete authentication-related files in lib/screens (e.g., login_screen.dart)
- [x] Remove any remaining imports of deleted files from main.dart
