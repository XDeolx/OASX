import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/models/behavior_analysis_models.dart';

void main() {
  test('parses all clicks, waits, and task click durations from one log', () {
    const content = '''
2026-09-01 01:00:00.000 | INFO | Scheduler: Start task `RealmRaid`
2026-09-01 01:00:01.000 | INFO | [0.14s] Click ( 627, 359) @ TARGET_A
2026-09-01 01:00:02.000 | INFO | 个人突破点击进攻前随机等待: delay=1.37s
2026-09-01 01:00:03.000 | INFO | [0.16s] Click ( 701, 480) @ TARGET_B
2026-09-01 01:00:04.000 | INFO | Scheduler: End task `RealmRaid`
2026-09-01 01:00:05.000 | INFO | [0.12s] Click ( 33, 50) @ UI_BACK
''';

    final result = parseBehaviorLogPayload({
      'script_name': '笙',
      'date': '2026-09-01',
      'content': content,
    });
    final analysis = BehaviorAnalysisDay.fromMap(result);

    expect(analysis.scriptName, '笙');
    expect(analysis.dateKey, '2026-09-01');
    expect(analysis.totalClicks, 3);
    expect(analysis.clicks.first.x, 627);
    expect(analysis.clicks.first.y, 359);
    expect(analysis.clicks.first.durationSeconds, 0.14);
    expect(analysis.clicks.first.time, DateTime(2026, 9, 1, 1, 0, 1));
    expect(analysis.clicks.first.label, 'TARGET_A');
    expect(analysis.clicks.first.taskName, 'RealmRaid');
    expect(
      analysis.randomWaits['个人突破点击进攻前随机等待'],
      [1.37],
    );
    expect(analysis.taskClickDurations['RealmRaid'], [0.14, 0.16]);
    expect(analysis.taskClickDurations['Unassigned'], [0.12]);
    expect(analysis.taskRuns, hasLength(1));
    expect(analysis.taskRuns.single.taskName, 'RealmRaid');
    expect(analysis.taskRuns.single.endInferred, isFalse);
    expect(
      analysis.taskRuns.single.duration,
      const Duration(seconds: 4),
    );
  });

  test('keeps repeated random wait records in log order', () {
    const content = '''
2026-09-01 01:00:00.000 | INFO | 寮奖励随机等待: delay=2.12s
2026-09-01 01:00:01.000 | INFO | 寮奖励随机等待: stage=寮体力完成, delay=3.68s
2026-09-01 01:00:02.000 | INFO | 通用随机休息: delay=7.4s
''';

    final result = parseBehaviorLogPayload({
      'script_name': '冲',
      'date': '2026-09-01',
      'content': content,
    });
    final analysis = BehaviorAnalysisDay.fromMap(result);

    expect(analysis.randomWaits['寮奖励随机等待'], [2.12, 3.68]);
    expect(analysis.randomWaits['通用随机休息'], [7.4]);
    expect(analysis.randomWaitEvents, hasLength(3));
    expect(analysis.randomWaitEvents.last.delaySeconds, 7.4);
  });

  test('parses lifecycle and excludes scheduled restart from anomalies', () {
    const content = '''
2026-09-01 00:00:00.000 | INFO | Start scheduler loop: 笙
2026-09-01 00:10:00.000 | INFO | Scheduler: Start task `Restart`
2026-09-01 00:10:01.000 | INFO | Recovery branch: game unavailable, full restart
2026-09-01 00:10:02.000 | INFO | Scheduler: End task `Restart`
2026-09-01 00:11:00.000 | INFO | Start scheduler loop: 笙
2026-09-01 01:00:00.000 | INFO | Scheduler: Start task `KekkaiUtilize`
2026-09-01 01:02:00.000 | WARNING | Game is not running before task `KekkaiUtilize`, recover it via Restart
2026-09-01 01:02:01.000 | WARNING | Recovery branch: process lost, full restart
2026-09-01 01:02:02.000 | WARNING | Restart ATX
2026-09-01 01:05:00.000 | INFO | Scheduler: Start task `DailyTrifles`
2026-09-01 01:06:00.000 | INFO | Scheduler: End task `DailyTrifles`
''';

    final analysis = BehaviorAnalysisDay.fromMap(parseBehaviorLogPayload({
      'script_name': '笙',
      'date': '2026-09-01',
      'content': content,
    }));

    expect(analysis.scriptStarts, hasLength(2));
    expect(analysis.taskStarts, hasLength(3));
    expect(analysis.anomalies, hasLength(2));
    expect(analysis.anomalies.first.type, 'app_restart');
    expect(analysis.anomalies.first.taskName, 'KekkaiUtilize');
    expect(analysis.anomalies.first.note, contains('full restart'));
    expect(analysis.anomalies.last.type, 'atx_restart');

    final restartRun = analysis.taskRuns.first;
    expect(restartRun.taskName, 'Restart');
    expect(restartRun.endInferred, isFalse);
    final inferredRun = analysis.taskRuns[1];
    expect(inferredRun.taskName, 'KekkaiUtilize');
    expect(inferredRun.endTime, DateTime(2026, 9, 1, 1, 5));
    expect(inferredRun.endInferred, isTrue);
    expect(analysis.taskRuns.last.endInferred, isFalse);
  });

  test('closes an unfinished task at the next scheduler loop', () {
    const content = '''
2026-09-01 02:00:00.000 | INFO | Scheduler: Start task `Chess`
2026-09-01 02:15:00.000 | INFO | [0.15s] Click ( 640, 360) @ CHESS_TARGET
2026-09-01 02:16:00.000 | INFO | Start scheduler loop: 冲
''';

    final analysis = BehaviorAnalysisDay.fromMap(parseBehaviorLogPayload({
      'script_name': '冲',
      'date': '2026-09-01',
      'content': content,
    }));

    expect(analysis.taskRuns, hasLength(1));
    expect(analysis.taskRuns.single.endTime, DateTime(2026, 9, 1, 2, 16));
    expect(analysis.taskRuns.single.endInferred, isTrue);
  });
}
