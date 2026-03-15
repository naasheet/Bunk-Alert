import 'package:bunk_alert/data/models/timetable_entry_model.dart';
import 'package:bunk_alert/data/repositories/timetable_repository.dart';

class GetTodayScheduleUsecase {
  GetTodayScheduleUsecase({TimetableRepository? repository})
      : _repository = repository ?? TimetableRepository();

  final TimetableRepository _repository;

  Future<List<TimetableEntryModel>> call({DateTime? now}) {
    final today = now ?? DateTime.now();
    return _repository.getByDayOfWeek(today.weekday);
  }
}
