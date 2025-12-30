import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  /// Checks for an update and triggers the immediate update flow if one is available.
  /// This blocks the user from using the app until the update is installed.
  static Future<void> checkAndForceUpdate() async {
    // In-app updates are only available on Android.
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // For immediate updates, we don't need to listen to a stream.
        // The Google Play UI takes over.
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      // If the update check fails (e.g. no internet, or app not in Play Store yet),
      // we generally want to let the user into the app rather than blocking them forever.
      debugPrint('Update check failed: $e');
    }
  }
}
