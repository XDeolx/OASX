import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/models/weekly_schedule_models.dart';
import 'package:oasx/modules/home/models/weekly_schedule_operations.dart';

void main() {
  test('weekly schedule model reads turtle and free-cycle settings', () {
    final data = WeeklyScheduleData.fromJson({
      'enabled': true,
      'turtle_mode': true,
      'turtle_keep_tasks': ['AreaBoss', 'KekkaiUtilize'],
      'free_cycle_tasks': ['KekkaiActivation'],
    });

    expect(data.turtleMode, isTrue);
    expect(data.turtleKeepTasks, ['AreaBoss', 'KekkaiUtilize']);
    expect(data.freeCycleTasks, ['KekkaiActivation']);
  });

  test('free-cycle defaults are used only when the field is absent', () {
    final legacy = WeeklyScheduleData.fromJson({'enabled': true});
    final cleared = WeeklyScheduleData.fromJson({
      'enabled': true,
      'free_cycle_tasks': <String>[],
    });

    expect(legacy.freeCycleTasks, weeklyScheduleDefaultFreeCycleTasks);
    expect(cleared.freeCycleTasks, isEmpty);
  });

  test('copy weekday replaces target and keeps other weekdays', () {
    const entries = [
      WeeklyScheduleEntry(task: 'AreaBoss', weekday: 1, time: '09:00'),
      WeeklyScheduleEntry(task: 'Restart', weekday: 1, time: '12:00'),
      WeeklyScheduleEntry(task: 'OldTuesday', weekday: 2, time: '08:00'),
      WeeklyScheduleEntry(task: 'Wednesday', weekday: 3, time: '10:00'),
    ];

    final copied = copyWeeklyScheduleDay(
      entries: entries,
      sourceWeekday: 1,
      targetWeekday: 2,
      replaceTarget: true,
    );

    expect(
      copied.where((entry) => entry.weekday == 2).map((entry) => entry.task),
      ['AreaBoss', 'Restart'],
    );
    expect(copied.any((entry) => entry.task == 'Wednesday'), isTrue);
    expect(copied.any((entry) => entry.task == 'OldTuesday'), isFalse);
  });

  test('copy weekday merges without producing duplicate entries', () {
    const entries = [
      WeeklyScheduleEntry(task: 'AreaBoss', weekday: 1, time: '09:00'),
      WeeklyScheduleEntry(task: 'AreaBoss', weekday: 2, time: '09:00'),
    ];

    final copied = copyWeeklyScheduleDay(
      entries: entries,
      sourceWeekday: 1,
      targetWeekday: 2,
      replaceTarget: false,
    );

    expect(copied, hasLength(2));
  });

  test('import uses enabled task next runs and keeps existing entries', () {
    const entries = [
      WeeklyScheduleEntry(task: 'AreaBoss', weekday: 1, time: '09:00'),
    ];
    const tasks = [
      WeeklyScheduleTask(
        name: 'Restart',
        enabled: true,
        nextRun: '2026-08-26 13:45:00',
      ),
      WeeklyScheduleTask(
        name: 'Disabled',
        enabled: false,
        nextRun: '2026-08-27 14:00:00',
      ),
    ];

    final imported = buildEntriesFromCurrentScheduler(
      entries: entries,
      tasks: tasks,
      replaceExisting: false,
    );

    expect(imported, hasLength(2));
    expect(
      imported,
      contains(
        isA<WeeklyScheduleEntry>()
            .having((entry) => entry.task, 'task', 'Restart')
            .having((entry) => entry.weekday, 'weekday', DateTime.wednesday)
            .having((entry) => entry.time, 'time', '13:45'),
      ),
    );
  });

  test('current week dates keep consecutive weekdays on consecutive dates', () {
    const monday = WeeklyScheduleEntry(
      task: 'AreaBoss',
      weekday: DateTime.monday,
      time: '08:10',
    );
    const tuesday = WeeklyScheduleEntry(
      task: 'AreaBoss',
      weekday: DateTime.tuesday,
      time: '08:10',
    );
    final reference = DateTime(2026, 8, 26, 15);

    expect(
      weeklyScheduleCurrentWeekDateTime(monday, reference),
      DateTime(2026, 8, 24, 8, 10),
    );
    expect(
      weeklyScheduleCurrentWeekDateTime(tuesday, reference),
      DateTime(2026, 8, 25, 8, 10),
    );
  });
}
