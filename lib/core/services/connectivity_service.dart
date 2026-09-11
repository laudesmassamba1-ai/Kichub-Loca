import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ValueNotifier<bool> isOnline = ValueNotifier(true);
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await checkNow();

    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (isOnline.value != online) {
        isOnline.value = online;
        debugPrint('[Connectivity] online=$online');
      }
    });
  }

  static Future<bool> checkNow() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final online = results.any((r) => r != ConnectivityResult.none);
      isOnline.value = online;
      return online;
    } catch (_) {
      isOnline.value = true;
      return true;
    }
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}