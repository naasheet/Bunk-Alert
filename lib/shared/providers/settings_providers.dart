import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bunk_alert/data/repositories/settings_repository.dart';

final globalTargetProvider = FutureProvider<double>((ref) async {
  return SettingsRepository.instance.getGlobalTargetPercentage();
});
