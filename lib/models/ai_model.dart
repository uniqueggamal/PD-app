// Export the appropriate AI model based on platform
export 'ai_model_mobile.dart' if (dart.library.html) 'ai_model_web.dart';
