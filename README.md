# LeafMate — Plant Disease Detection App

A Flutter mobile application that helps farmers and home gardeners identify plant diseases from leaf photos using on-device machine learning. The app runs inference offline, shows disease information and treatment guidance in English or Nepali, and includes scan history and plant-care reminders.

## Overview

Plant diseases reduce crop yield and are often hard to diagnose without expert help. **LeafMate** (package name: `plant_disease_detection_app`) lets users capture or upload a leaf image, analyzes it with a TensorFlow Lite model on the device, and returns a predicted disease class with confidence, symptoms, prevention, and treatment details.

The project was developed as a student portfolio application for offline disease identification on common crops such as tomato, potato, maize, apple, grape, and tea.

## Features

- **On-device disease detection** — 51-class image classification using a quantized TFLite model
- **Camera and gallery input** — capture photos or pick images, with optional cropping
- **Bilingual UI** — English and Nepali localization for app text and disease labels
- **Disease details** — cause, symptoms, prevention, and treatment loaded from bundled JSON
- **Scan history** — save, view, and delete past scans (SQLite via `sqflite`)
- **Care reminders** — create reminders with local notifications (`flutter_local_notifications`)
- **Theme support** — light and dark mode
- **Onboarding screens** — introductory walkthrough (route available; currently skipped on launch)
- **Help and About screens** — usage guidance and list of detectable classes

## Technology Stack

| Layer | Technologies |
|-------|----------------|
| Mobile app | Flutter, Dart |
| State management | Riverpod (`flutter_riverpod`) |
| Navigation | `go_router` |
| On-device ML | TensorFlow Lite (`tflite_flutter`) |
| Image handling | `camera`, `image_picker`, `image_cropper`, `image` |
| Local storage | SQLite (`sqflite`), `shared_preferences` |
| Notifications | `flutter_local_notifications`, `timezone` |
| Permissions | `permission_handler` |
| Model training (notebooks) | Python, TensorFlow/Keras, Jupyter (see `assets/ai/`) |

**Not used in the current Dart codebase:** Firebase Auth, Firestore, or Hive (listed in older notes or dependencies but not referenced in `lib/`).

## Architecture / Workflow

```
User opens app
    → Home screen (recent scans)
    → Camera / gallery
    → Image crop (optional)
    → Preprocess (resize 224×224, normalize pixels)
    → TFLite inference (MobileNet-based classifier)
    → Top class + confidence (threshold 0.3)
    → Cure / symptom JSON lookup
    → Display result; optional save to scan history
    → Optional reminder scheduling
```

**Main entry point:** `lib/main.dart`  
**ML logic:** `lib/models/ai_model.dart`  
**Camera flow:** `lib/services/camera_service.dart`  
**Persistence:** `lib/services/db_service.dart`

## Machine Learning

### Dataset and classes

- Training notebooks reference public plant-disease datasets (e.g. PlantVillage-style collections on Kaggle).
- The deployed model predicts **51 classes** (diseases and healthy states across crops including apple, tomato, potato, corn, grape, tea, and others). Labels are defined in `assets/labels/labels.json`.

### Model

- **Architecture:** MobileNet-family CNN (project report and UI describe MobileNetV2; training notebooks also experiment with MobileNetV3).
- **Input:** 224×224 RGB images, normalized to `[-1, 1]`.
- **Output:** 51-class probability vector; highest score above **0.3** is accepted.
- **Deployment:** Quantized TFLite model at `assets/ai/models/mobilenetv2_51classes_quant.tflite` (non-quantized variant also bundled).

### Training and conversion

Training and export scripts live under `assets/ai/`:

- `assets/ai/PD_model_5/PD_model_5.ipynb` — model training experiments
- `assets/ai/converter/tflite_converter.py` — SavedModel → TFLite conversion
- Additional checkpoints (`.h5`, `.keras`, SavedModel) are kept in `assets/ai/models/` for reproducibility

### Limitations (from project scope)

- Accuracy depends on dataset size, class balance, and image quality; real-world photos may differ from training data.
- Predictions are informational only and not a substitute for professional agricultural advice.
- Performance varies by device; inference is skipped on web (`kIsWeb`).
- Region-specific diseases may not be fully represented in the training set.

No specific accuracy metrics are claimed here; see `docs/reports/` for the academic project report.

## Project Structure

```
plant_disease_detection_app/
├── lib/                    # Flutter application source
│   ├── main.dart           # App entry, routing
│   ├── models/             # AI, scan history, reminder models
│   ├── providers/          # Riverpod state
│   ├── screens/            # UI screens
│   ├── services/           # Camera, DB, notifications
│   └── widgets/            # Shared UI components
├── assets/
│   ├── ai/                 # TFLite models, training notebooks, scripts
│   ├── img/                # UI images and onboarding photos
│   ├── labels/             # Class labels, cures, localization JSON
│   ├── logo/               # Branding assets
│   └── screen/             # Onboarding / screenshot images
├── android/ ios/ web/ ...  # Platform runners
├── test/                   # Widget tests
├── docs/
│   ├── architecture/       # Workflow and diagram notes
│   ├── project-notes/      # Development notes and TODO
│   └── reports/            # Academic project report (PDF/DOCX/TXT)
├── pubspec.yaml
└── README.md
```

## Setup and Installation

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) compatible with Dart `^3.8.1` (see `pubspec.yaml`)
- Android Studio / Xcode for mobile builds
- A physical device or emulator with camera support (recommended for full testing)

### Steps

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd plant_disease_detection_app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Verify model assets**

   Ensure these files exist (they are required at runtime):

   - `assets/ai/models/mobilenetv2_51classes_quant.tflite`
   - `assets/ai/models/mobilenetv2_51classes.tflite`
   - Label and cure JSON under `assets/labels/`

4. **Run the app**

   ```bash
   flutter run
   ```

   For a specific device:

   ```bash
   flutter devices
   flutter run -d <device-id>
   ```

5. **Run tests**

   ```bash
   flutter test
   ```

### Android notes

- Minimum SDK follows Flutter defaults (`minSdkVersion` from Flutter Gradle plugin).
- Camera, storage, and notification permissions are requested at runtime where needed.

## Usage

1. Open the app and go to **Scan Leaf** from the home screen or drawer.
2. Take a photo or choose an image from the gallery; crop the leaf if prompted.
3. Wait for on-device analysis; review the predicted disease and treatment information.
4. Save the scan to **Scan History** if desired.
5. Set a **Reminder** for follow-up care from the result or history screen.
6. Switch language (English / Nepali) and theme from the drawer settings.
7. View all supported classes under **About**.

## Screenshots

<!-- Add screenshots here when available, e.g.:
![Home screen](docs/screenshots/home.png)
![Scan result](docs/screenshots/scan_result.png)
-->

Screenshots can be added to `docs/screenshots/` or referenced from `assets/screen/`.

## Future Improvements

- Re-enable first-launch onboarding in `lib/main.dart`
- Improve dataset balance and retrain for better real-world accuracy
- Add app screenshots to this README for portfolio presentation
- Expand test coverage beyond the default widget smoke test
- Clean up unused Android Firebase configuration if analytics is not needed

## Author

**Unique Gaurav Gamal**  
Bachelor of Information Management (BIM) project — National College of Computer Studies, Tribhuvan University

## License

No license file is included yet. Add a `LICENSE` file before publishing if you want to specify terms for reuse.

## Suggested GitHub Topics

`flutter` `dart` `machine-learning` `tensorflow-lite` `plant-disease-detection` `mobile-app` `agriculture` `computer-vision` `offline-inference` `student-project`
