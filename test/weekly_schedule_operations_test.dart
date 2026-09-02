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

  test('weekly schedule model reads refresh rules and generated snapshot', () {
    final data = WeeklyScheduleData.fromJson({
      'enabled': true,
      'week_refresh': {
        'enabled': true,
        'min_offset_seconds': 600,
        'max_offset_seconds': 1200,
        'excluded_tasks': ['Restart'],
        'freeze_windows': [
          {'weekday': 3, 'start': '04:00:00', 'end': '10:00:00'},
        ],
        'boundaries': [
          {
            'task': 'AreaBoss',
            'weekday': 1,
            'start': '07:30:00',
            'end': '08:30:00',
          },
        ],
        'generated_week': '2026-W36',
        'generated_entries': [
          {'task': 'AreaBoss', 'weekday': 1, 'time': '08:14:37'},
        ],
      },
      'effective_entries': [
        {'task': 'AreaBoss', 'weekday': 1, 'time': '08:14:37'},
      ],
    });

    expect(data.weekRefresh.enabled, isTrue);
    expect(data.weekRefresh.excludedTasks, ['Restart']);
    expect(data.weekRefresh.freezeWindows.single.weekday, DateTime.wednesday);
    expect(data.weekRefresh.boundaries.single.end, '08:30:00');
    expect(data.weekRefresh.generatedWeek, '2026-W36');
    expect(data.effectiveEntries.single.time, '08:14:37');
    expect(data.weekRefresh.toRequestJson(), isNot(contains('generated_week')));
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

  test('bulk add creates one second-level randomized time per selected day', () {
    final added = addWeeklyTaskToWeekdays(
      entries: const [],
      task: 'AreaBoss',
      weekdays: const {1, 2, 3, 4, 5, 6, 7},
      baseTime: '09:00',
      minOffsetMinutes: 5,
      maxOffsetMinutes: 10,
      replaceSameTask: true,
      nextInt: (_) => 0,
    );

    expect(added, hasLength(7));
    expect(added.map((entry) => entry.weekday).toSet(), {1, 2, 3, 4, 5, 6, 7});
    expect(added.map((entry) => entry.time).toSet(), hasLength(7));
    final generatedSeconds = <int>[];
    for (final entry in added) {
      final parts = entry.time.split(':').map(int.parse).toList();
      final value = parts[0] * 3600 + parts[1] * 60 + parts[2];
      final offsetSeconds = (value - 9 * 3600).abs();
      expect(offsetSeconds, inInclusiveRange(5 * 60, 10 * 60));
      generatedSeconds.add(parts[2]);
    }
    expect(generatedSeconds.any((second) => second != 0), isTrue);
  });

  test('bulk add replaces only matching tasks on selected weekdays', () {
    const entries = [
      WeeklyScheduleEntry(task: 'AreaBoss', weekday: 1, time: '08:00'),
      WeeklyScheduleEntry(task: 'AreaBoss', weekday: 2, time: '08:00'),
      WeeklyScheduleEntry(task: 'Restart', weekday: 1, time: '07:00'),
    ];

    final added = addWeeklyTaskToWeekdays(
      entries: entries,
      task: 'AreaBoss',
      weekdays: const {1},
      baseTime: '09:00',
      minOffsetMinutes: 0,
      maxOffsetMinutes: 0,
      replaceSameTask: true,
    );

    expect(
      added.where((entry) => entry.task == 'AreaBoss' && entry.weekday == 1),
      hasLength(1),
    );
    expect(
      added.any((entry) => entry.task == 'AreaBoss' && entry.weekday == 2),
      isTrue,
    );
    expect(
      added.any((entry) => entry.task == 'Restart' && entry.weekday == 1),
      isTrue,
    );
  });

  test('bulk add keeps an existing matching task when replace is disabled', () {
    const entries = [
      WeeklyScheduleEntry(task: 'AreaBoss', weekday: 1, time: '08:00'),
    ];

    final added = addWeeklyTaskToWeekdays(
      entries: entries,
      task: 'AreaBoss',
      weekdays: const {1},
      baseTime: '09:00',
      minOffsetMinutes: 0,
      maxOffsetMinutes: 0,
      replaceSameTask: false,
    );

    expect(
      added.where((entry) => entry.task == 'AreaBoss' && entry.weekday == 1),
      hasLength(2),
    );
  });

  test('bulk add keeps randomized times within the selected weekday', () {
    final added = addWeeklyTaskToWeekdays(
      entries: const [],
      task: 'AreaBoss',
      weekdays: const {1},
      baseTime: '00:03',
      minOffsetMinutes: 5,
      maxOffsetMinutes: 10,
      replaceSameTask: true,
      nextInt: (_) => 0,
    );

    final parts = added.single.time.split(':').map(int.parse).toList();
    final value = parts[0] * 3600 + parts[1] * 60 + parts[2];
    expect(value, inInclusiveRange(8 * 60, 13 * 60));
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
            .having((entry) => entry.time, 'time', '13:45:00'),
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

  test('randomized bulk add also randomizes seconds', () {
    final added = addWeeklyTaskToWeekdays(
      entries: const [],
      task: 'AreaBoss',
      weekdays: const {1},
      baseTime: '09:00:37',
      minOffsetMinutes: 5,
      maxOffsetMinutes: 10,
      replaceSameTask: true,
      nextInt: (_) => 0,
    );

    expect(added.single.time.endsWith(':37'), isFalse);
  });

  test('current week date reads second precision and legacy minute times', () {
    const precise = WeeklyScheduleEntry(
      task: 'AreaBoss',
      weekday: DateTime.monday,
      time: '08:10:37',
    );
    const legacy = WeeklyScheduleEntry(
      task: 'Restart',
      weekday: DateTime.tuesday,
      time: '09:05',
    );
    final reference = DateTime(2026, 8, 26, 15);

    expect(
      weeklyScheduleCurrentWeekDateTime(precise, reference),
      DateTime(2026, 8, 24, 8, 10, 37),
    );
    expect(
      weeklyScheduleCurrentWeekDateTime(legacy, reference),
      DateTime(2026, 8, 25, 9, 5),
    );
  });
}
