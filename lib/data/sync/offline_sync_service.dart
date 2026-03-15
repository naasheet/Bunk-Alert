import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:bunk_alert/data/repositories/attendance_repository.dart';
import 'package:bunk_alert/data/sync/cloud_sync_service.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';

class OfflineSyncService {
  OfflineSyncService({
    AttendanceRepository? attendanceRepository,
    Connectivity? connectivity,
    InternetConnectionChecker? connectionChecker,
  })  : _attendanceRepository = attendanceRepository ?? AttendanceRepository(),
        _connectivity = connectivity ?? Connectivity(),
        _connectionChecker =
            connectionChecker ?? InternetConnectionChecker.instance;

  static final OfflineSyncService instance = OfflineSyncService();

  final AttendanceRepository _attendanceRepository;
  final CloudSyncService _cloudSyncService = CloudSyncService.instance;
  final Connectivity _connectivity;
  final InternetConnectionChecker _connectionChecker;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> start() async {
    debugPrint('offline sync: start');
    if (AppAuthOverrides.isTest) {
      debugPrint('offline sync: test mode skip');
      return;
    }
    await _subscription?.cancel();
    debugPrint('offline sync: listen');
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      debugPrint('offline sync: connectivity event $results');
      if (_hasConnectivity(results) && await _connectionChecker.hasConnection) {
        debugPrint('offline sync: connectivity ok');
        final userId = AppAuth.currentUser?.uid;
        if (userId != null) {
          debugPrint('offline sync: syncing for $userId');
          await _attendanceRepository.syncPendingRecords(userId: userId);
          _cloudSyncService.syncAllInBackground(userId: userId);
        }
      }
    });

    debugPrint('offline sync: after listen');
    if (await _connectionChecker.hasConnection) {
      debugPrint('offline sync: initial has connection');
      final userId = AppAuth.currentUser?.uid;
      if (userId != null) {
        debugPrint('offline sync: initial sync for $userId');
        await _attendanceRepository.syncPendingRecords(userId: userId);
        _cloudSyncService.syncAllInBackground(userId: userId);
      }
    }
    debugPrint('offline sync: done');
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  bool _hasConnectivity(List<ConnectivityResult> results) {
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}
