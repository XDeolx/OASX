import 'dart:math';

import 'package:oasx/modules/home/models/weekly_schedule_models.dart';

List<WeeklyScheduleEntry> addWeeklyTaskToWeekdays({
  required List<WeeklyScheduleEntry> entries,
  required String task,
  required Set<int> weekdays,
  required String baseTime,
  required int minOffsetMinutes,
  required int maxOffsetMinutes,
  required bool replaceSameTask,
  int Function(int max)? nextInt,
}) {
  final selectedWeekdays = weekdays
      .where(
        (weekday) =>
            weekday >= DateTime.monday && weekday <= DateTime.sunday,
      )
      .toSet()
      .toList()
    ..sort();
  if (selectedWeekdays.isEmpty) {
    return List<WeeklyScheduleEntry>.from(entries);
  }

  final baseSeconds = _parseClockSeconds(baseTime);
  final firstOffset = minOffsetMinutes.clamp(0, 1439).toInt();
  final secondOffset = maxOffsetMinutes.clamp(0, 1439).toInt();
  final minOffsetSeconds = min(firstOffset, secondOffset) * 60;
  final maxOffsetSeconds = max(firstOffset, secondOffset) * 60;
  final offsets = <int>[
    for (
      var offset = -maxOffsetSeconds;
      offset <= maxOffsetSeconds;
      offset++
    )
      if (offset.abs() >= minOffsetSeconds &&
          baseSeconds + offset >= 0 &&
          baseSeconds + offset < 24 * 60 * 60)
        offset,
  ];
  final randomNextInt = nextInt ?? Random().nextInt;
  for (var index = offsets.length - 1; index > 0; index--) {
    final swapIndex = randomNextInt(index + 1);
    if (swapIndex < 0 || swapIndex > index) {
      throw RangeError.range(swapIndex, 0, index, 'nextInt result');
    }
    final value = offsets[index];
    offsets[index] = offsets[swapIndex];
    offsets[swapIndex] = value;
  }

  final retained = entries.where(
    (entry) =>
        !replaceSameTask ||
        entry.task != task ||
        !selectedWeekdays.contains(entry.weekday),
  );
  final generated = <WeeklyScheduleEntry>[];
  for (var index = 0; index < selectedWeekdays.length; index++) {
    final offset = offsets.isEmpty ? 0 : offsets[index % offsets.length];
    generated.add(
      WeeklyScheduleEntry(
        task: task,
        weekday: selectedWeekdays[index],
        time: _formatClockSeconds(baseSeconds + offset),
      ),
    );
  }
  return normalizeWeeklyScheduleEntries(retained.followedBy(generated));
}

int _parseClockSeconds(String value) {
  final parts = value.split(':');
  if (parts.length < 2 || parts.length > 3) {
    throw FormatException('Invalid weekly schedule time: $value');
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  final second = parts.length == 3 ? int.tryParse(parts[2]) : 0;
  if (hour == null ||
      minute == null ||
      second == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59 ||
      second < 0 ||
      second > 59) {
    throw FormatException('Invalid weekly schedule time: $value');
  }
  return hour * 60 * 60 + minute * 60 + second;
}

String _formatClockSeconds(int value) {
  final hour = value ~/ 3600;
  final minute = value % 3600 ~/ 60;
  final second = value % 60;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}:'
      '${second.toString().padLeft(2, '0')}';
}

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
          '${nextRun.minute.toString().padLeft(2, '0')}:'
          '${nextRun.second.toString().padLeft(2, '0')}',
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
    parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
  );
}
