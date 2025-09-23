// PermissionManager stub
import 'package:adaptive_media_picker/adaptive_media_picker.dart';

class PermissionManager {
  const PermissionManager();

  static bool bypassPlatformChannelsForTests = false;

  Future<PermissionResolution> ensureMediaPermission({
    required ImageSource source,
    required MediaType mediaType,
  }) async {
    return PermissionResolution.grantedFull();
  }

  Future<void> presentLimitedIfAvailable() async {
    // Do nothing on unsupported platforms
  }

  bool isValidImageExtension(String path) => true;
  bool isValidVideoExtension(String path) => true;
}
