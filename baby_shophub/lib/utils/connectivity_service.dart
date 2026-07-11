import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Check if there is an active internet connection
  Future<bool> checkConnectivity() async {
    final List<ConnectivityResult> results =
    await _connectivity.checkConnectivity();

    // Returns true if at least one result is not "none"
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get connectivityStream {
    return _connectivity.onConnectivityChanged;
  }
}
