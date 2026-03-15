import 'dart:io';

import 'package:flutter/services.dart';

class GoogleSignInConfig {
  static const MethodChannel _channel = MethodChannel('app_config');

  static Future<String?> getServerClientId() async {
    if (!Platform.isAndroid) {
      return null;
    }
    final id = await _channel.invokeMethod<String>('getDefaultWebClientId');
    if (id == null || id.trim().isEmpty) {
      return null;
    }
    return id.trim();
  }

  const GoogleSignInConfig._();
}
