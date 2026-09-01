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

  int get totalClicks => clicks.length;

  List<String> get taskNames {
    final names = <String>{
      ...clicks.map((event) => event.taskName),
      ...randomWaitEvents.map((event) => event.taskName),
      ...taskStarts.map((event) => event.taskName),
      ...taskRuns.map((event) => event.taskName),
      ...anomalies.map((event) => event.taskName),
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
    );
  }

  bool get isEmpty =>
      clicks.isEmpty &&
      randomWaitEvents.isEmpty &&
      taskStarts.isEmpty &&
      taskRuns.isEmpty &&
      scriptStarts.isEmpty &&
      anomalies.isEmpty;

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
final RegExp _behaviorRecoveryTaskPattern = RegExp(
  r'Game is not running before task `([^`]+)`, recover it via Restart',
);
final RegExp _behaviorScriptStartPattern = RegExp(
  r'Start scheduler loop:\s*(.*)$',
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
  var currentTask = '';
  var pendingRecoveryTask = '';
  int? openTaskRunIndex;
  DateTime? lastTimestamp;

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
        randomWaits.putIfAbsent(label, () => <double>[]).add(delay);
        randomWaitEvents.add([
          timestamp?.millisecondsSinceEpoch ?? 0,
          label,
          delay,
          currentTask.isEmpty ? 'Unassigned' : currentTask,
        ]);
      }
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
