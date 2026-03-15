import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bunk_alert/shared/auth/app_auth.dart';

final authUserIdProvider = StreamProvider<String?>((ref) {
  return AppAuth.authStateChanges()
      .map((user) => user?.uid)
      .distinct();
});
