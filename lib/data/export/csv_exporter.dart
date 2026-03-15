import 'dart:io';

import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bunk_alert/data/database/local_database_service.dart';

class CsvExporter {
  const CsvExporter._();

  static Future<void> export() async {
    final database = LocalDatabaseService.instance;
    final subjects = await database.subjects.where().findAll();
    final records = await database.attendanceRecords.where().findAll();

    records.sort((a, b) => b.date.compareTo(a.date));

    final subjectMap = {
      for (final subject in subjects) subject.uuid: subject.name,
    };

    final buffer = StringBuffer();
    buffer.writeln('Subject,Date,Day,Status,Note');
    final dateFormat = DateFormat('yyyy-MM-dd');
    final dayFormat = DateFormat('EEE');
    for (final record in records) {
      final subjectName =
          subjectMap[record.subjectUuid] ?? record.subjectUuid;
      buffer.writeln(
        [
          _escapeCsv(subjectName),
          _escapeCsv(dateFormat.format(record.date)),
          _escapeCsv(dayFormat.format(record.date)),
          _escapeCsv(record.status),
          _escapeCsv(record.note ?? ''),
        ].join(','),
      );
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/bunk_alert_export_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(buffer.toString(), flush: true);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Bunk Alert export',
    );
  }

  static String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
