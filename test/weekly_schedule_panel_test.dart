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
