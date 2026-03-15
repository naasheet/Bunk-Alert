import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/models/timetable_entry_model.dart';
import 'package:bunk_alert/shared/providers/auth_user_provider.dart';

final selectedTimetableDayProvider = StateProvider<int>((ref) {
  return DateTime.now().weekday;
});

final timetableEntriesStreamProvider =
    StreamProvider<List<TimetableEntryModel>>((ref) {
  final userId = ref.watch(authUserIdProvider).maybeWhen(
        data: (value) => value,
        orElse: () => null,
      );
  if (userId == null) {
    return Stream.value(const <TimetableEntryModel>[]);
  }
  final isar = LocalDatabaseService.instance.isar;
  final query = isar.timetableEntryModels
      .filter()
      .isActiveEqualTo(true)
      .sortByStartMinutes();
  return query.watch(fireImmediately: true);
});
