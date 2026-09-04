import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class BehaviorClickPoint {
  const BehaviorClickPoint({
    required this.x,
    required this.y,
    required this.durationSeconds,
    required this.time,
    required this.label,
    required this.taskName,
  });

  final int x;
  final int y;
  final double durationSeconds;
  final DateTime time;
  final String label;
  final String taskName;

  factory BehaviorClickPoint.fromList(List<dynamic> values) {
    return BehaviorClickPoint(
      x: (values.isNotEmpty ? values[0] as num? : null)?.toInt() ?? 0,
      y: (values.length > 1 ? values[1] as num? : null)?.toInt() ?? 0,
      durationSeconds:
          (values.length > 2 ? values[2] as num? : null)?.toDouble() ?? 0,
      time: DateTime.fromMillisecondsSinceEpoch(
        (values.length > 3 ? values[3] as num? : null)?.toInt() ?? 0,
      ),
      label: values.length > 4 ? values[4]?.toString() ?? '' : '',
      taskName: values.length > 5 ? values[5]?.toString() ?? '' : '',
    );
  }
}

@immutable
class BehaviorRandomWaitEvent {
  const BehaviorRandomWaitEvent({
    required this.time,
    required this.label,
    required this.delaySeconds,
    required this.taskName,
  });

  final DateTime time;
  final String label;
  final double delaySeconds;
  final String taskName;

  factory BehaviorRandomWaitEvent.fromList(List<dynamic> values) {
    return BehaviorRandomWaitEvent(
      time: DateTime.fromMillisecondsSinceEpoch(
        (values.isNotEmpty ? values[0] as num? : null)?.toInt() ?? 0,
      ),
      label: values.length > 1 ? values[1]?.toString() ?? '' : '',
      delaySeconds:
          (values.length > 2 ? values[2] as num? : null)?.toDouble() ?? 0,
      taskName: values.length > 3 ? values[3]?.toString() ?? '' : '',
    );
  }
}

@immutable
class BehaviorTaskStart {
  const BehaviorTaskStart({required this.time, required this.taskName});

  final DateTime time;
  final String taskName;

  factory BehaviorTaskStart.fromList(List<dynamic> values) {
    return BehaviorTaskStart(
      time: DateTime.fromMillisecondsSinceEpoch(
        (values.isNotEmpty ? values[0] as num? : null)?.toInt() ?? 0,
      ),
      taskName: values.length > 1 ? values[1]?.toString() ?? '' : '',
    );
  }
}

@immutable
class BehaviorTaskRun {
  const BehaviorTaskRun({
    required this.startTime,
    required this.endTime,
    required this.taskName,
    required this.endInferred,
  });

  final DateTime startTime;
  final DateTime endTime;
  final String taskName;
  final bool endInferred;

  Duration get duration => endTime.difference(startTime);

  factory BehaviorTaskRun.fromList(List<dynamic> values) {
    return BehaviorTaskRun(
      startTime: DateTime.fromMillisecondsSinceEpoch(
        (values.isNotEmpty ? values[0] as num? : null)?.toInt() ?? 0,
      ),
      endTime: DateTime.fromMillisecondsSinceEpoch(
        (values.length > 1 ? values[1] as num? : null)?.toInt() ?? 0,
      ),
      taskName: values.length > 2 ? values[2]?.toString() ?? '' : '',
      endInferred: values.length > 3 && values[3] == true,
    );
  }
}

@immutable
class BehaviorScriptStart {
  const BehaviorScriptStart({required this.time, required this.label});

  final DateTime time;
  final String label;

  factory BehaviorScriptStart.fromList(List<dynamic> values) {
    return BehaviorScriptStart(
      time: DateTime.fromMillisecondsSinceEpoch(
        (values.isNotEmpty ? values[0] as num? : null)?.toInt() ?? 0,
      ),
      label: values.length > 1 ? values[1]?.toString() ?? '' : '',
    );
  }
}

@immutable
class BehaviorAnomalyEvent {
  const BehaviorAnomalyEvent({
    required this.time,
    required this.type,
    required this.taskName,
    required this.note,
  });

  final DateTime time;
  final String type;
  final String taskName;
  final String note;

  factory BehaviorAnomalyEvent.fromList(List<dynamic> values) {
    return BehaviorAnomalyEvent(
      time: DateTime.fromMillisecondsSinceEpoch(
        (values.isNotEmpty ? values[0] as num? : null)?.toInt() ?? 0,
      ),
      type: values.length > 1 ? values[1]?.toString() ?? '' : '',
      taskName: values.length > 2 ? values[2]?.toString() ?? '' : '',
      note: values.length > 3 ? values[3]?.toString() ?? '' : '',
    );
  }
}

@immutable
class BehaviorClimbSettlementEvent {
  const BehaviorClimbSettlementEvent({
    required this.time,
    required this.taskName,
    required this.type,
    required this.battleNumber,
    required this.mode,
    required this.category,
    required this.region,
    required this.x,
    required this.y,
    required this.detailProgress,
    required this.detailTarget,
    required this.clickCount,
    required this.detail,
  });

  final DateTime time;
  final String taskName;
  final String type;
  final int battleNumber;
  final String mode;
  final String category;
  final String region;
  final int x;
  final int y;
  final int detailProgress;
  final int detailTarget;
  final int clickCount;
  final String detail;

  factory BehaviorClimbSettlementEvent.fromMap(Map<String, dynamic> map) {
    int readInt(String key) => (map[key] as num?)?.toInt() ?? 0;

    return BehaviorClimbSettlementEvent(
      time: DateTime.fromMillisecondsSinceEpoch(readInt('time')),
      taskName: map['task_name']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      battleNumber: readInt('battle'),
      mode: map['mode']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      region: map['region']?.toString() ?? '',
      x: readInt('x'),
      y: readInt('y'),
      detailProgress: readInt('detail_progress'),
      detailTarget: readInt('detail_target'),
      clickCount: readInt('click_count'),
      detail: map['detail']?.toString() ?? '',
    );
  }
}

@immutable
class BehaviorClimbSettlementAnalysis {
  const BehaviorClimbSettlementAnalysis({
    required this.events,
    required this.clicks,
    required this.waits,
  });

  final List<BehaviorClimbSettlementEvent> events;
  final List<BehaviorClickPoint> clicks;
  final List<BehaviorRandomWaitEvent> waits;

  List<BehaviorClimbSettlementEvent> get templates =>
      events.where((event) => event.type == 'template').toList(growable: false);

  List<BehaviorClimbSettlementEvent> get decisions =>
      events.where((event) => event.type == 'decision').toList(growable: false);

  List<BehaviorClimbSettlementEvent> get weightedClicks =>
      events.where((event) => event.type == 'weighted').toList(growable: false);

  List<BehaviorClimbSettlementEvent> get detailViews =>
      events.where((event) => event.type == 'detail').toList(growable: false);

  List<BehaviorClimbSettlementEvent> get bursts =>
      events.where((event) => event.type == 'burst').toList(growable: false);

  Map<String, int> get categoryCounts {
    final counts = {for (final category in const ['A', 'B', 'C', 'D', 'E']) category: 0};
    for (final event in weightedClicks) {
      if (counts.containsKey(event.category)) {
        counts[event.category] = counts[event.category]! + 1;
      }
    }
    return counts;
  }

  Map<String, int> get modeCounts {
    final counts = {'weighted': 0, 'detail': 0, 'burst': 0};
    for (final event in decisions) {
      if (counts.containsKey(event.mode)) {
        counts[event.mode] = counts[event.mode]! + 1;
      }
    }
    return counts;
  }

  bool get hasData => events.isNotEmpty || clicks.isNotEmpty || waits.isNotEmpty;
}

@immutable
class BehaviorAnalysisDay {
  const BehaviorAnalysisDay({
    required this.scriptName,
    required this.dateKey,
    required this.clicks,
    required this.randomWaits,
    required this.randomWaitEvents,
    required this.taskClickDurations,
    required this.taskStarts,
    required this.taskRuns,
    required this.scriptStarts,
    required this.anomalies,
    required this.climbSettlementEvents,
  });

  final String scriptName;
  final String dateKey;
  final List<BehaviorClickPoint> clicks;
  final Map<String, List<double>> randomWaits;
  final List<BehaviorRandomWaitEvent> randomWaitEvents;
  final Map<String, List<double>> taskClickDurations;
  final List<BehaviorTaskStart> taskStarts;
  final List<BehaviorTaskRun> taskRuns;
  final List<BehaviorScriptStart> scriptStarts;
  final List<BehaviorAnomalyEvent> anomalies;
  final List<BehaviorClimbSettlementEvent> climbSettlementEvents;

  int get totalClicks => clicks.length;

  BehaviorClimbSettlementAnalysis get climbSettlementAnalysis =>
      BehaviorClimbSettlementAnalysis(
        events: climbSettlementEvents,
        clicks: clicks
            .where((event) => event.label.startsWith('CLIMB_SETTLEMENT_'))
            .toList(growable: false),
        waits: randomWaitEvents
            .where(
              (event) =>
                  event.label == '爬塔查看详情随机等待' ||
                  event.label == '爬塔快速结算随机等待',
            )
            .toList(growable: false),
      );

  List<String> get taskNames {
    final names = <String>{
      ...clicks.map((event) => event.taskName),
      ...randomWaitEvents.map((event) => event.taskName),
      ...taskStarts.map((event) => event.taskName),
      ...taskRuns.map((event) => event.taskName),
      ...anomalies.map((event) => event.taskName),
      ...climbSettlementEvents.map((event) => event.taskName),
    }..removeWhere((name) => name.trim().isEmpty);
    return names.toList(growable: false)..sort();
  }

  BehaviorAnalysisDay filteredByTask(String taskName) {
    if (taskName.isEmpty) {
      return this;
    }
    final filteredClicks = clicks
        .where((event) => event.taskName == taskName)
        .toList(growable: false);
    final filteredWaitEvents = randomWaitEvents
        .where((event) => event.taskName == taskName)
        .toList(growable: false);
    final filteredWaits = <String, List<double>>{};
    for (final event in filteredWaitEvents) {
      filteredWaits
          .putIfAbsent(event.label, () => <double>[])
          .add(event.delaySeconds);
    }
    final durations = taskClickDurations[taskName];
    return BehaviorAnalysisDay(
      scriptName: scriptName,
      dateKey: dateKey,
      clicks: filteredClicks,
      randomWaits: filteredWaits,
      randomWaitEvents: filteredWaitEvents,
      taskClickDurations: durations == null
          ? const {}
          : {
              taskName: List<double>.unmodifiable(durations),
            },
      taskStarts: taskStarts
          .where((event) => event.taskName == taskName)
          .toList(growable: false),
      taskRuns: taskRuns
          .where((event) => event.taskName == taskName)
          .toList(growable: false),
      scriptStarts: const [],
      anomalies: anomalies
          .where((event) => event.taskName == taskName)
          .toList(growable: false),
      climbSettlementEvents: climbSettlementEvents
          .where((event) => event.taskName == taskName)
          .toList(growable: false),
    );
  }

  bool get isEmpty =>
      clicks.isEmpty &&
      randomWaitEvents.isEmpty &&
      taskStarts.isEmpty &&
      taskRuns.isEmpty &&
      scriptStarts.isEmpty &&
      anomalies.isEmpty &&
      climbSettlementEvents.isEmpty;

  factory BehaviorAnalysisDay.fromMap(Map<String, dynamic> map) {
    return BehaviorAnalysisDay(
      scriptName: map['script_name']?.toString() ?? '',
      dateKey: map['date']?.toString() ?? '',
      clicks: _listValues(map['clicks'])
          .map(BehaviorClickPoint.fromList)
          .toList(growable: false),
      randomWaits: _doubleListMap(map['random_waits']),
      randomWaitEvents: _listValues(map['random_wait_events'])
          .map(BehaviorRandomWaitEvent.fromList)
          .toList(growable: false),
      taskClickDurations: _doubleListMap(map['task_click_durations']),
      taskStarts: _listValues(map['task_starts'])
          .map(BehaviorTaskStart.fromList)
          .toList(growable: false),
      taskRuns: _listValues(map['task_runs'])
          .map(BehaviorTaskRun.fromList)
          .toList(growable: false),
      scriptStarts: _listValues(map['script_starts'])
          .map(BehaviorScriptStart.fromList)
          .toList(growable: false),
      anomalies: _listValues(map['anomalies'])
          .map(BehaviorAnomalyEvent.fromList)
          .toList(growable: false),
      climbSettlementEvents: _mapValues(map['climb_settlement_events'])
          .map(BehaviorClimbSettlementEvent.fromMap)
          .toList(growable: false),
    );
  }

  static Map<String, List<double>> _doubleListMap(dynamic raw) {
    if (raw is! Map) {
      return const {};
    }
    return raw.map<String, List<double>>((key, value) {
      final values = value is List
          ? value
              .whereType<num>()
              .map((item) => item.toDouble())
              .toList(growable: false)
          : const <double>[];
      return MapEntry(key.toString(), values);
    });
  }

  static Iterable<List<dynamic>> _listValues(dynamic raw) sync* {
    if (raw is! List) {
      return;
    }
    for (final value in raw) {
      if (value is List) {
        yield List<dynamic>.from(value);
      }
    }
  }

  static Iterable<Map<String, dynamic>> _mapValues(dynamic raw) sync* {
    if (raw is! List) {
      return;
    }
    for (final value in raw) {
      if (value is Map) {
        yield value.map((key, item) => MapEntry(key.toString(), item));
      }
    }
  }
}

final RegExp _behaviorClickPattern = RegExp(
  r'\[(\d+(?:\.\d+)?)s\]\s+Click\s+\(\s*(\d+)\s*,\s*(\d+)\s*\)\s+@\s+(.+?)\s*$',
);
final RegExp _behaviorTaskStartPattern = RegExp(
  r'Scheduler:\s+Start task\s+`([^`]+)`',
);
final RegExp _behaviorTaskEndPattern = RegExp(
  r'Scheduler:\s+End task\s+`([^`]+)`',
);
final RegExp _behaviorRandomWaitPattern = RegExp(
  r'([^|:\r\n]*随机(?:等待|休息))\s*[:：]\s*(?:[^|\r\n]*?\bdelay\s*=\s*)?(\d+(?:\.\d+)?)s',
);
final RegExp _behaviorClimbFatigueDelayPattern = RegExp(
  r'Climb fatigue (?:settlement )?delay:\s*[^|\r\n]*?\bdelay\s*=\s*(\d+(?:\.\d+)?)s',
  caseSensitive: false,
);
final RegExp _behaviorClimbFatigueRestPattern = RegExp(
  r'Climb fatigue rest:\s*[^|\r\n]*?\bduration\s*=\s*(\d+(?:\.\d+)?)m',
  caseSensitive: false,
);
final RegExp _behaviorRecoveryTaskPattern = RegExp(
  r'Game is not running before task `([^`]+)`, recover it via Restart',
);
final RegExp _behaviorScriptStartPattern = RegExp(
  r'Start scheduler loop:\s*(.*)$',
);
final RegExp _climbSettlementTemplatePattern = RegExp(
  r'Climb settlement template:\s*(.+)$',
  caseSensitive: false,
);
final RegExp _climbSettlementDecisionPattern = RegExp(
  r'Climb settlement behavior:\s*battle=(\d+),\s*kind=(\w+),\s*detail=(\d+)/(\d+)',
  caseSensitive: false,
);
final RegExp _climbSettlementWeightedPattern = RegExp(
  r'Climb settlement weighted click:\s*battle=(\d+),\s*category=([A-E]),\s*region=(R\d+),\s*point=\(\s*(\d+)\s*,\s*(\d+)\s*\)',
  caseSensitive: false,
);
final RegExp _climbSettlementDetailPattern = RegExp(
  r'Climb settlement detail:\s*battle=(\d+),\s*region=(Detail\d+),\s*point=\(\s*(\d+)\s*,\s*(\d+)\s*\)',
  caseSensitive: false,
);
final RegExp _climbSettlementBurstPattern = RegExp(
  r'Climb settlement burst:\s*battle=(\d+),\s*reason=(\w+),\s*clicks=(\d+),\s*anchor_region=(R\d+)',
  caseSensitive: false,
);

Map<String, dynamic> parseBehaviorLogPayload(Map<String, String> request) {
  final scriptName = request['script_name']?.trim() ?? '';
  final dateKey = request['date']?.trim() ?? '';
  final content = request['content'] ?? '';
  final clicks = <List<dynamic>>[];
  final randomWaits = <String, List<double>>{};
  final randomWaitEvents = <List<dynamic>>[];
  final taskClickDurations = <String, List<double>>{};
  final taskStarts = <List<dynamic>>[];
  final taskRuns = <List<dynamic>>[];
  final scriptStarts = <List<dynamic>>[];
  final anomalies = <List<dynamic>>[];
  final climbSettlementEvents = <Map<String, dynamic>>[];
  var currentTask = '';
  var pendingRecoveryTask = '';
  int? openTaskRunIndex;
  DateTime? lastTimestamp;

  void addRandomWait(
    DateTime? time,
    String taskName,
    String label,
    double delaySeconds,
  ) {
    randomWaits.putIfAbsent(label, () => <double>[]).add(delaySeconds);
    randomWaitEvents.add([
      time?.millisecondsSinceEpoch ?? 0,
      label,
      delaySeconds,
      taskName.isEmpty ? 'Unassigned' : taskName,
    ]);
  }

  for (final line in const LineSplitter().convert(content)) {
    final timestamp = _parseBehaviorTimestamp(line);
    final lowerLine = line.toLowerCase();
    if (timestamp != null) {
      lastTimestamp = timestamp;
    }
    final taskStart = _behaviorTaskStartPattern.firstMatch(line);
    if (taskStart != null) {
      if (timestamp != null && openTaskRunIndex != null) {
        final openIndex = openTaskRunIndex;
        taskRuns[openIndex][1] = timestamp.millisecondsSinceEpoch;
        taskRuns[openIndex][3] = true;
        openTaskRunIndex = null;
      }
      currentTask = taskStart.group(1)?.trim() ?? '';
      if (timestamp != null && currentTask.isNotEmpty) {
        taskStarts.add([timestamp.millisecondsSinceEpoch, currentTask]);
        taskRuns.add([
          timestamp.millisecondsSinceEpoch,
          0,
          currentTask,
          false,
        ]);
        openTaskRunIndex = taskRuns.length - 1;
      }
    }

    final scriptStart = _behaviorScriptStartPattern.firstMatch(line);
    if (timestamp != null && scriptStart != null) {
      if (openTaskRunIndex != null) {
        final openIndex = openTaskRunIndex;
        taskRuns[openIndex][1] = timestamp.millisecondsSinceEpoch;
        taskRuns[openIndex][3] = true;
        openTaskRunIndex = null;
      }
      currentTask = '';
      pendingRecoveryTask = '';
      scriptStarts.add([
        timestamp.millisecondsSinceEpoch,
        scriptStart.group(1)?.trim() ?? scriptName,
      ]);
    }

    final recoveryTask = _behaviorRecoveryTaskPattern.firstMatch(line);
    if (recoveryTask != null) {
      pendingRecoveryTask = recoveryTask.group(1)?.trim() ?? '';
    }

    final eventTime = timestamp?.millisecondsSinceEpoch ?? 0;
    final eventTask = currentTask.isEmpty ? 'Unassigned' : currentTask;
    final template = _climbSettlementTemplatePattern.firstMatch(line);
    if (template != null) {
      climbSettlementEvents.add({
        'time': eventTime,
        'task_name': eventTask,
        'type': 'template',
        'detail': template.group(1)?.trim() ?? '',
      });
    }
    final decision = _climbSettlementDecisionPattern.firstMatch(line);
    if (decision != null) {
      climbSettlementEvents.add({
        'time': eventTime,
        'task_name': eventTask,
        'type': 'decision',
        'battle': int.tryParse(decision.group(1) ?? '') ?? 0,
        'mode': decision.group(2)?.toLowerCase() ?? '',
        'detail_progress': int.tryParse(decision.group(3) ?? '') ?? 0,
        'detail_target': int.tryParse(decision.group(4) ?? '') ?? 0,
      });
    }
    final weighted = _climbSettlementWeightedPattern.firstMatch(line);
    if (weighted != null) {
      climbSettlementEvents.add({
        'time': eventTime,
        'task_name': eventTask,
        'type': 'weighted',
        'battle': int.tryParse(weighted.group(1) ?? '') ?? 0,
        'category': weighted.group(2)?.toUpperCase() ?? '',
        'region': weighted.group(3)?.toUpperCase() ?? '',
        'x': int.tryParse(weighted.group(4) ?? '') ?? 0,
        'y': int.tryParse(weighted.group(5) ?? '') ?? 0,
      });
    }
    final detail = _climbSettlementDetailPattern.firstMatch(line);
    if (detail != null) {
      climbSettlementEvents.add({
        'time': eventTime,
        'task_name': eventTask,
        'type': 'detail',
        'battle': int.tryParse(detail.group(1) ?? '') ?? 0,
        'region': detail.group(2) ?? '',
        'x': int.tryParse(detail.group(3) ?? '') ?? 0,
        'y': int.tryParse(detail.group(4) ?? '') ?? 0,
      });
    }
    final burst = _climbSettlementBurstPattern.firstMatch(line);
    if (burst != null) {
      climbSettlementEvents.add({
        'time': eventTime,
        'task_name': eventTask,
        'type': 'burst',
        'battle': int.tryParse(burst.group(1) ?? '') ?? 0,
        'mode': burst.group(2)?.toLowerCase() ?? '',
        'click_count': int.tryParse(burst.group(3) ?? '') ?? 0,
        'region': burst.group(4)?.toUpperCase() ?? '',
      });
    }

    final click = _behaviorClickPattern.firstMatch(line);
    if (click != null) {
      final duration = double.tryParse(click.group(1) ?? '') ?? 0;
      final x = int.tryParse(click.group(2) ?? '') ?? 0;
      final y = int.tryParse(click.group(3) ?? '') ?? 0;
      final taskName = currentTask.isEmpty ? 'Unassigned' : currentTask;
      clicks.add([
        x,
        y,
        duration,
        timestamp?.millisecondsSinceEpoch ?? 0,
        click.group(4)?.trim() ?? '',
        taskName,
      ]);
      taskClickDurations.putIfAbsent(taskName, () => <double>[]).add(duration);
    }

    final wait = _behaviorRandomWaitPattern.firstMatch(line);
    if (wait != null) {
      final label = wait.group(1)?.trim() ?? '';
      final delay = double.tryParse(wait.group(2) ?? '') ?? 0;
      if (label.isNotEmpty) {
        addRandomWait(timestamp, currentTask, label, delay);
      }
    }

    final climbDelay = _behaviorClimbFatigueDelayPattern.firstMatch(line);
    if (climbDelay != null) {
      final delay = double.tryParse(climbDelay.group(1) ?? '') ?? 0;
      final label = line.toLowerCase().contains('settlement delay')
          ? '爬塔疲劳结算延迟'
          : '爬塔疲劳战前延迟';
      addRandomWait(timestamp, currentTask, label, delay);
    }

    final climbRest = _behaviorClimbFatigueRestPattern.firstMatch(line);
    if (climbRest != null) {
      final minutes = double.tryParse(climbRest.group(1) ?? '') ?? 0;
      addRandomWait(timestamp, currentTask, '爬塔疲劳休息', minutes * 60);
    }

    if (timestamp != null &&
        lowerLine.contains('recovery branch:') &&
        lowerLine.contains('full restart')) {
      if (currentTask != 'Restart') {
        anomalies.add([
          timestamp.millisecondsSinceEpoch,
          'app_restart',
          pendingRecoveryTask.isNotEmpty ? pendingRecoveryTask : currentTask,
          _behaviorMessage(line),
        ]);
      }
      pendingRecoveryTask = '';
    }
    if (timestamp != null && line.contains('Restart ATX')) {
      anomalies.add([
        timestamp.millisecondsSinceEpoch,
        'atx_restart',
        currentTask,
        _behaviorMessage(line),
      ]);
    }

    final taskEnd = _behaviorTaskEndPattern.firstMatch(line);
    if (taskEnd != null) {
      final endedTask = taskEnd.group(1)?.trim() ?? '';
      if (timestamp != null &&
          openTaskRunIndex != null &&
          taskRuns[openTaskRunIndex][2] == endedTask) {
        final openIndex = openTaskRunIndex;
        taskRuns[openIndex][1] = timestamp.millisecondsSinceEpoch;
        taskRuns[openIndex][3] = false;
        openTaskRunIndex = null;
      }
      if (currentTask.isEmpty || currentTask == endedTask) {
        currentTask = '';
      }
    }
  }

  if (openTaskRunIndex != null && lastTimestamp != null) {
    final openIndex = openTaskRunIndex;
    final startedAt = taskRuns[openIndex][0] as int;
    if (lastTimestamp.millisecondsSinceEpoch >= startedAt) {
      taskRuns[openIndex][1] = lastTimestamp.millisecondsSinceEpoch;
      taskRuns[openIndex][3] = true;
    }
  }

  return {
    'script_name': scriptName,
    'date': dateKey,
    'clicks': clicks,
    'random_waits': randomWaits,
    'random_wait_events': randomWaitEvents,
    'task_click_durations': taskClickDurations,
    'task_starts': taskStarts,
    'task_runs': taskRuns,
    'script_starts': scriptStarts,
    'anomalies': anomalies,
    'climb_settlement_events': climbSettlementEvents,
  };
}

DateTime? _parseBehaviorTimestamp(String line) {
  if (line.length < 23) {
    return null;
  }
  return DateTime.tryParse(line.substring(0, 23));
}

String _behaviorMessage(String line) {
  final separator = line.lastIndexOf('|');
  return (separator >= 0 ? line.substring(separator + 1) : line).trim();
}

Future<BehaviorAnalysisDay> parseBehaviorLogAsync({
  required String scriptName,
  required String dateKey,
  required String content,
}) async {
  final payload = await compute(parseBehaviorLogPayload, {
    'script_name': scriptName,
    'date': dateKey,
    'content': content,
  });
  return BehaviorAnalysisDay.fromMap(payload);
}
