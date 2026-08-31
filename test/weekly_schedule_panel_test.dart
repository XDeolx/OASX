import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/models/weekly_schedule_models.dart';
import 'package:oasx/modules/home/widgets/weekly_schedule_panel.dart';

void main() {
  testWidgets('weekly schedule renders populated data without exceptions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: WeeklySchedulePanel(
            scriptName: 'test',
            initialData: _populatedData,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('09:00'), findsNWidgets(3));
    expect(find.text('2026-08-24 09:00:00'), findsOneWidget);
    expect(find.text('2026-08-26 09:00:00'), findsNWidgets(2));
    expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);
    expect(find.byIcon(Icons.event_busy_rounded), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('weekly schedule toolbar keeps controls in stable narrow rows', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: WeeklySchedulePanel(
            scriptName: 'test',
            initialData: _turtleData,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final primary = find.byKey(
      const ValueKey<String>('weekly-schedule-primary-controls'),
    );
    final modes = find.byKey(
      const ValueKey<String>('weekly-schedule-mode-controls'),
    );
    final actions = find.byKey(
      const ValueKey<String>('weekly-schedule-actions'),
    );

    expect(primary, findsOneWidget);
    expect(modes, findsOneWidget);
    expect(actions, findsOneWidget);
    final coverage = find.byKey(
      const ValueKey<String>('weekly-schedule-coverage'),
    );
    expect(coverage, findsOneWidget);
    expect(
      find.descendant(of: find.byType(ListView), matching: coverage),
      findsNothing,
    );
    expect(
      tester.getTopLeft(modes).dy,
      greaterThan(tester.getTopLeft(primary).dy),
    );
    expect(
      tester.getTopLeft(actions).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(modes).dy),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('turtle mode hides schedule entries outside retained tasks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: WeeklySchedulePanel(
            scriptName: 'test',
            initialData: _turtleData,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('AreaBoss'), findsNWidgets(2));
    expect(find.text('Restart'), findsNothing);
    expect(find.byIcon(Icons.shield_rounded), findsNWidgets(2));
    final shieldIcons = tester.widgetList<Icon>(
      find.byIcon(Icons.shield_rounded),
    );
    expect(shieldIcons.every((icon) => icon.color == Colors.lightBlue), isTrue);
    expect(find.byIcon(Icons.autorenew_rounded), findsNWidgets(2));
    final freeCycleIcons = tester.widgetList<Icon>(
      find.byIcon(Icons.autorenew_rounded),
    );
    expect(
      freeCycleIcons.every((icon) => icon.color == Colors.lightBlue),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'bulk add dialog selects every weekday and replacement by default',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: WeeklySchedulePanel(
              scriptName: 'test',
              initialData: _populatedData,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
      final weekdayChips = tester.widgetList<FilterChip>(
        find.byType(FilterChip),
      );
      expect(weekdayChips, hasLength(7));
      expect(weekdayChips.every((chip) => chip.selected), isTrue);
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue,
      );
      final range = tester.widget<RangeSlider>(find.byType(RangeSlider)).values;
      expect(range.start, 5);
      expect(range.end, 10);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(TextButton).last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

const _populatedData = WeeklyScheduleData(
  enabled: false,
  entries: [
    WeeklyScheduleEntry(
      task: 'AreaBoss',
      weekday: 1,
      time: '09:00',
      scheduledAt: '2026-08-24 09:00:00',
    ),
    WeeklyScheduleEntry(
      task: 'AreaBoss',
      weekday: 3,
      time: '09:00',
      scheduledAt: '2026-08-26 09:00:00',
    ),
    WeeklyScheduleEntry(
      task: 'Restart',
      weekday: 3,
      time: '09:00',
      scheduledAt: '2026-08-26 09:00:00',
    ),
  ],
  tasks: [
    WeeklyScheduleTask(
      name: 'AreaBoss',
      enabled: true,
      nextRun: '2026-08-31 09:00:00',
    ),
    WeeklyScheduleTask(
      name: 'Restart',
      enabled: true,
      nextRun: '2026-08-26 09:00:00',
    ),
    WeeklyScheduleTask(
      name: 'Guild',
      enabled: false,
      nextRun: '2026-08-27 09:00:00',
    ),
  ],
  plannedTasks: ['AreaBoss', 'Restart'],
  unplannedTasks: ['Guild'],
  nextRuns: {},
  serverNow: '2026-08-26 15:00:00',
  currentWeekStart: '2026-08-24',
  todayWeekday: DateTime.wednesday,
);

const _turtleData = WeeklyScheduleData(
  enabled: true,
  turtleMode: true,
  turtleKeepTasks: ['AreaBoss'],
  entries: [
    WeeklyScheduleEntry(
      task: 'AreaBoss',
      weekday: 1,
      time: '09:00',
      scheduledAt: '2026-08-24 09:00:00',
    ),
    WeeklyScheduleEntry(
      task: 'AreaBoss',
      weekday: 3,
      time: '09:00',
      scheduledAt: '2026-08-26 09:00:00',
    ),
    WeeklyScheduleEntry(
      task: 'Restart',
      weekday: 3,
      time: '09:00',
      scheduledAt: '2026-08-26 09:00:00',
    ),
  ],
  tasks: [
    WeeklyScheduleTask(
      name: 'AreaBoss',
      enabled: true,
      nextRun: '2026-08-31 09:00:00',
    ),
    WeeklyScheduleTask(
      name: 'Restart',
      enabled: false,
      nextRun: '2026-08-26 09:00:00',
    ),
  ],
  plannedTasks: ['AreaBoss', 'Restart'],
  unplannedTasks: [],
  nextRuns: {},
  serverNow: '2026-08-26 15:00:00',
  currentWeekStart: '2026-08-24',
  todayWeekday: DateTime.wednesday,
);
