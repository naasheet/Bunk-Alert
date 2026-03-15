import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield _isOffline(initial);
  await for (final event in connectivity.onConnectivityChanged) {
    yield _isOffline(event);
  }
});

bool _isOffline(dynamic event) {
  if (event is ConnectivityResult) {
    return event == ConnectivityResult.none;
  }
  if (event is List<ConnectivityResult>) {
    return event.isEmpty || event.contains(ConnectivityResult.none);
  }
  return true;
}
