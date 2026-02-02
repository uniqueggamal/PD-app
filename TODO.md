# TODO: Fix Flutter App Startup Freeze and Camera Tab Hang

## Completed Tasks
- [x] Add FutureProvider for TFLite interpreter in home_provider.dart (lazy loading)
- [x] Modify ai_model.dart: Remove interpreter loading from loadModel, add setInterpreter method
- [x] Update camera_service.dart: In runPrediction, await interpreter from provider, set to AiModel, then load labels
- [x] Verify cameraScreen.dart has clear loading UI with timeout/retry (already implemented)

## Followup Steps
- [ ] Test on mid-range Android device (OPPO/Realme CPH2263) to ensure no startup freeze, smooth camera tab switch, prediction works
- [ ] Monitor frame skips at launch (should be reduced)
- [ ] Confirm app responsiveness early in startup
- [ ] Ensure all features (prediction, crop, gallery, cure cards, localization) still work
