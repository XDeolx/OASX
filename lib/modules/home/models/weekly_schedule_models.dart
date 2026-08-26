class WeeklyScheduleEntry {
  const WeeklyScheduleEntry({
    required this.task,
    required this.weekday,
    required this.time,
  });

  final String task;
  final int weekday;
  final String time;

  factory WeeklyScheduleEntry.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleEntry(
      task: json['task']?.toString() ?? '',
      weekday: int.tryParse(json['weekday']?.toString() ?? '') ?? 1,
      time: json['time']?.toString() ?? '00:00',
    );
  }

  Map<String, dynamic> toJson() => {
    'task': task,
    'weekday': weekday,
    'time': time,
  };
}

class WeeklyScheduleTask {
  const WeeklyScheduleTask({
    required this.name,
    required this.enabled,
    required this.nextRun,
  });

  final String name;
  final bool enabled;
  final String nextRun;

  factory WeeklyScheduleTask.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleTask(
      name: json['name']?.toString() ?? '',
      enabled: json['enabled'] == true,
      nextRun: json['next_run']?.toString() ?? '',
    );
  }
}

class WeeklyScheduleData {
  const WeeklyScheduleData({
    required this.enabled,
    required this.entries,
    required this.tasks,
    required this.plannedTasks,
    required this.unplannedTasks,
    required this.nextRuns,
  });

  final bool enabled;
  final List<WeeklyScheduleEntry> entries;
  final List<WeeklyScheduleTask> tasks;
  final List<String> plannedTasks;
  final List<String> unplannedTasks;
  final Map<String, String> nextRuns;

  factory WeeklyScheduleData.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleData(
      enabled: json['enabled'] != false,
      entries: _mapList(json['entries'], WeeklyScheduleEntry.fromJson),
      tasks: _mapList(json['tasks'], WeeklyScheduleTask.fromJson),
      plannedTasks: _stringList(json['planned_tasks']),
      unplannedTasks: _stringList(json['unplanned_tasks']),
      nextRuns: _stringMap(json['next_runs']),
    );
  }
}

List<T> _mapList<T>(dynamic value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) {
    return <T>[];
  }
  return value
      .whereType<Map>()
      .map((item) => parse(Map<String, dynamic>.from(item)))
      .toList();
}

List<String> _stringList(dynamic value) {
  if (value is! List) {
    return <String>[];
  }
  return value.map((item) => item.toString()).toList();
}

Map<String, String> _stringMap(dynamic value) {
  if (value is! Map) {
    return <String, String>{};
  }
  return value.map(
    (key, item) => MapEntry(key.toString(), item.toString()),
  );
}
