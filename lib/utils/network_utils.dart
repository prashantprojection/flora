import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  /// Checks if the device has an active internet connection (WiFi or Mobile Data).
  /// Note: This checks for network interface connection, not necessarily internet access (ping).
  static Future<bool> hasInternetConnection() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }

    // In a production app, you might want to ping a known server here
    // to confirm actual data throughput.
    // For now, interface check is sufficient for UX gating.
    return true;
  }
}
