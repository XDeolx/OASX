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

  test('parses climb fatigue delays and minute-based rest records', () {
    const content = '''
2026-09-04 09:00:00.000 | INFO | Scheduler: Start task `ActivityShikigami`
2026-09-04 09:00:01.000 | INFO | Climb fatigue delay: progress=12/60, delay=1.48s, range=1.20-2.00s
2026-09-04 09:01:02.000 | INFO | Climb fatigue settlement delay: delay=2.37s
2026-09-04 09:02:03.000 | INFO | Climb fatigue rest: completed=60/60, duration=6.25m
2026-09-04 09:08:03.000 | INFO | Climb fatigue rest finished: actual_duration=6.00m, cycle reset
2026-09-04 09:09:00.000 | INFO | Scheduler: End task `ActivityShikigami`
''';

    final analysis = BehaviorAnalysisDay.fromMap(parseBehaviorLogPayload({
      'script_name': '玖',
      'date': '2026-09-04',
      'content': content,
    }));

    expect(analysis.randomWaits['爬塔疲劳战前延迟'], [1.48]);
    expect(analysis.randomWaits['爬塔疲劳结算延迟'], [2.37]);
    expect(analysis.randomWaits['爬塔疲劳休息'], [375.0]);
    expect(analysis.randomWaitEvents, hasLength(3));
    expect(
      analysis.filteredByTask('ActivityShikigami').randomWaitEvents,
      hasLength(3),
    );
  });

  test('separates climb settlement templates, modes, regions, and waits', () {
    const content = '''
2026-09-04 10:00:00.000 | INFO | Scheduler: Start task `ActivityShikigami`
2026-09-04 10:00:01.000 | INFO | Climb settlement template: A=R1/R10, B=R2/R4, C=R6, D=R9, E=R7
2026-09-04 10:01:00.000 | INFO | Climb settlement behavior: battle=1, kind=weighted, detail=8/24
2026-09-04 10:01:01.000 | INFO | Climb settlement weighted click: battle=1, category=C, region=R6, point=(1042,398)
2026-09-04 10:01:01.100 | INFO | [0.14s] Click (1042,398) @ CLIMB_SETTLEMENT_C_R6
2026-09-04 10:02:00.000 | INFO | Climb settlement behavior: battle=2, kind=detail, detail=24/24
2026-09-04 10:02:01.000 | INFO | Climb settlement detail: battle=2, region=Detail2, point=(725,401)
2026-09-04 10:02:01.100 | INFO | [0.13s] Click (725,401) @ CLIMB_SETTLEMENT_DETAIL2
2026-09-04 10:02:01.200 | INFO | 爬塔查看详情随机等待: battle=2, delay=1.23s
2026-09-04 10:02:02.500 | INFO | Climb settlement burst: battle=2, reason=detail, clicks=4, anchor_region=R7
2026-09-04 10:02:02.600 | INFO | [0.11s] Click (1100,580) @ CLIMB_SETTLEMENT_BURST_E_DETAIL
2026-09-04 10:03:00.000 | INFO | Climb settlement behavior: battle=3, kind=burst, detail=1/31
2026-09-04 10:03:01.000 | INFO | Climb settlement burst: battle=3, reason=random, clicks=3, anchor_region=R7
2026-09-04 10:03:01.100 | INFO | 爬塔快速结算随机等待: battle=3, reason=random, click=2/3, delay=0.124s
2026-09-04 10:04:00.000 | INFO | Scheduler: End task `ActivityShikigami`
''';

    final analysis = BehaviorAnalysisDay.fromMap(parseBehaviorLogPayload({
      'script_name': '玖',
      'date': '2026-09-04',
      'content': content,
    }));
    final climb = analysis.climbSettlementAnalysis;

    expect(climb.hasData, isTrue);
    expect(climb.templates, hasLength(1));
    expect(climb.templates.single.detail, contains('A=R1/R10'));
    expect(climb.decisions, hasLength(3));
    expect(climb.modeCounts, {
      'weighted': 1,
      'detail': 1,
      'burst': 1,
    });
    expect(climb.weightedClicks.single.category, 'C');
    expect(climb.weightedClicks.single.region, 'R6');
    expect(climb.categoryCounts['C'], 1);
    expect(climb.detailViews.single.region, 'Detail2');
    expect(climb.bursts, hasLength(2));
    expect(climb.bursts.last.mode, 'random');
    expect(climb.bursts.last.clickCount, 3);
    expect(climb.clicks, hasLength(3));
    expect(climb.waits, hasLength(2));
    expect(climb.waits.first.delaySeconds, 1.23);

    final unrelated = analysis.filteredByTask('RealmRaid');
    expect(unrelated.climbSettlementAnalysis.hasData, isFalse);
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

  test('filters every task-scoped behavior collection together', () {
    const content = '''
2026-09-01 03:00:00.000 | INFO | Start scheduler loop: 冲
2026-09-01 03:01:00.000 | INFO | Scheduler: Start task `RealmRaid`
2026-09-01 03:01:01.000 | INFO | [0.12s] Click ( 100, 200) @ RAID_TARGET
2026-09-01 03:01:02.000 | INFO | 个人突破随机等待: delay=1.25s
2026-09-01 03:01:03.000 | WARNING | Restart ATX
2026-09-01 03:02:00.000 | INFO | Scheduler: End task `RealmRaid`
2026-09-01 03:03:00.000 | INFO | Scheduler: Start task `Chess`
2026-09-01 03:03:01.000 | INFO | [0.18s] Click ( 300, 400) @ CHESS_TARGET
2026-09-01 03:04:00.000 | INFO | Scheduler: End task `Chess`
''';

    final analysis = BehaviorAnalysisDay.fromMap(parseBehaviorLogPayload({
      'script_name': '冲',
      'date': '2026-09-01',
      'content': content,
    }));
    final filtered = analysis.filteredByTask('RealmRaid');

    expect(analysis.taskNames, ['Chess', 'RealmRaid']);
    expect(filtered.clicks, hasLength(1));
    expect(filtered.clicks.single.label, 'RAID_TARGET');
    expect(filtered.randomWaitEvents, hasLength(1));
    expect(filtered.randomWaits.values.single, [1.25]);
    expect(filtered.taskClickDurations.keys, ['RealmRaid']);
    expect(filtered.taskStarts.single.taskName, 'RealmRaid');
    expect(filtered.taskRuns.single.taskName, 'RealmRaid');
    expect(filtered.anomalies.single.taskName, 'RealmRaid');
    expect(filtered.scriptStarts, isEmpty);
  });
}
