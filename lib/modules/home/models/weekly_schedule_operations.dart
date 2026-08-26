import 'package:oasx/modules/home/models/weekly_schedule_models.dart';

List<WeeklyScheduleEntry> copyWeeklyScheduleDay({
  required List<WeeklyScheduleEntry> entries,
  required int sourceWeekday,
  required int targetWeekday,
  required bool replaceTarget,
}) {
  if (sourceWeekday == targetWeekday) {
    return List<WeeklyScheduleEntry>.from(entries);
  }
  final copied = entries
      .where((entry) => entry.weekday == sourceWeekday)
      .map(
        (entry) => WeeklyScheduleEntry(
          task: entry.task,
          weekday: targetWeekday,
          time: entry.time,
        ),
      );
  final result = entries
      .where((entry) => !replaceTarget || entry.weekday != targetWeekday)
      .followedBy(copied);
  return normalizeWeeklyScheduleEntries(result);
}

List<WeeklyScheduleEntry> buildEntriesFromCurrentScheduler({
  required List<WeeklyScheduleEntry> entries,
  required List<WeeklyScheduleTask> tasks,
  required bool replaceExisting,
}) {
  final imported = tasks.where((task) => task.enabled).map((task) {
    final nextRun = DateTime.tryParse(task.nextRun);
    if (nextRun == null) {
      return null;
    }
    return WeeklyScheduleEntry(
      task: task.name,
      weekday: nextRun.weekday,
      time: '${nextRun.hour.toString().padLeft(2, '0')}:'
          '${nextRun.minute.toString().padLeft(2, '0')}',
    );
  }).whereType<WeeklyScheduleEntry>();
  return normalizeWeeklyScheduleEntries(
    (replaceExisting ? const <WeeklyScheduleEntry>[] : entries)
        .followedBy(imported),
  );
}

List<WeeklyScheduleEntry> normalizeWeeklyScheduleEntries(
  Iterable<WeeklyScheduleEntry> entries,
) {
  final unique = <String, WeeklyScheduleEntry>{};
  for (final entry in entries) {
    unique['${entry.task}\u0000${entry.weekday}\u0000${entry.time}'] = entry;
  }
  final result = unique.values.toList();
  result.sort((a, b) {
    final day = a.weekday.compareTo(b.weekday);
    if (day != 0) {
      return day;
    }
    final time = a.time.compareTo(b.time);
    return time != 0 ? time : a.task.compareTo(b.task);
  });
  return result;
}

DateTime weeklyScheduleCurrentWeekDateTime(
  WeeklyScheduleEntry entry,
  DateTime reference,
) {
  final referenceDay = DateTime(reference.year, reference.month, reference.day);
  final weekStart = referenceDay.subtract(
    Duration(days: reference.weekday - DateTime.monday),
  );
  final runDate = weekStart.add(Duration(days: entry.weekday - 1));
  final parts = entry.time.split(':');
  return DateTime(
    runDate.year,
    runDate.month,
    runDate.day,
    int.tryParse(parts.first) ?? 0,
    parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
  );
}
