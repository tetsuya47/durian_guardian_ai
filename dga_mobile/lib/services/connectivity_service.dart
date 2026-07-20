import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(InternetConnectionChecker());
});

class ConnectivityService {
  final InternetConnectionChecker _connectionChecker;

  ConnectivityService(this._connectionChecker);

  // Check current connection status
  Future<bool> get isConnected async => await _connectionChecker.hasConnection;

  // Stream of connection changes
  Stream<InternetConnectionStatus> get onStatusChange => _connectionChecker.onStatusChange;
}
