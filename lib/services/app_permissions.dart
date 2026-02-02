import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static Future<bool> requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      return true;
    } else {
      status = await Permission.camera.request();
      return status.isGranted || status.isPermanentlyDenied;
    }
  }
}
