const weeklyScheduleDefaultFreeCycleTasks = <String>[
  'KekkaiActivation',
  'KekkaiUtilize',
];

const weeklyRefreshDefaultFreezeWindows = <WeeklyRefreshFreezeWindow>[
  WeeklyRefreshFreezeWindow(
    weekday: DateTime.wednesday,
    start: '04:00:00',
    end: '10:00:00',
  ),
];

class WeeklyScheduleEntry {
  const WeeklyScheduleEntry({
    required this.task,
    required this.weekday,
    required this.time,
    this.scheduledAt = '',
  });

  final String task;
  final int weekday;
  final String time;
  final String scheduledAt;

  factory WeeklyScheduleEntry.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleEntry(
      task: json['task']?.toString() ?? '',
      weekday: int.tryParse(json['weekday']?.toString() ?? '') ?? 1,
      time: json['time']?.toString() ?? '00:00:00',
      scheduledAt: json['scheduled_at']?.toString() ?? '',
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

class WeeklyRefreshFreezeWindow {
  const WeeklyRefreshFreezeWindow({
    required this.weekday,
    required this.start,
    required this.end,
  });

  final int weekday;
  final String start;
  final String end;

  factory WeeklyRefreshFreezeWindow.fromJson(Map<String, dynamic> json) {
    return WeeklyRefreshFreezeWindow(
      weekday: int.tryParse(json['weekday']?.toString() ?? '') ?? 1,
      start: json['start']?.toString() ?? '00:00:00',
      end: json['end']?.toString() ?? '23:59:59',
    );
  }

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'start': start,
        'end': end,
      };
}

class WeeklyRefreshBoundary {
  const WeeklyRefreshBoundary({
    required this.task,
    required this.weekday,
    required this.start,
    required this.end,
  });

  final String task;
  final int weekday;
  final String start;
  final String end;

  factory WeeklyRefreshBoundary.fromJson(Map<String, dynamic> json) {
    return WeeklyRefreshBoundary(
      task: json['task']?.toString() ?? '',
      weekday: int.tryParse(json['weekday']?.toString() ?? '') ?? 1,
      start: json['start']?.toString() ?? '00:00:00',
      end: json['end']?.toString() ?? '23:59:59',
    );
  }

  Map<String, dynamic> toJson() => {
        'task': task,
        'weekday': weekday,
        'start': start,
        'end': end,
      };
}

class WeeklyRefreshIssue {
  const WeeklyRefreshIssue({
    required this.task,
    required this.weekday,
    required this.baseTime,
    required this.reason,
  });

  final String task;
  final int weekday;
  final String baseTime;
  final String reason;

  factory WeeklyRefreshIssue.fromJson(Map<String, dynamic> json) {
    return WeeklyRefreshIssue(
      task: json['task']?.toString() ?? '',
      weekday: int.tryParse(json['weekday']?.toString() ?? '') ?? 1,
      baseTime: json['base_time']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class WeeklyRefreshSettings {
  const WeeklyRefreshSettings({
    this.enabled = false,
    this.minOffsetSeconds = 600,
    this.maxOffsetSeconds = 1200,
    this.excludedTasks = const [],
    this.freezeWindows = weeklyRefreshDefaultFreezeWindows,
    this.boundaries = const [],
    this.generatedWeek = '',
    this.generatedAt = '',
    this.generatedEntries = const [],
    this.issues = const [],
  });

  final bool enabled;
  final int minOffsetSeconds;
  final int maxOffsetSeconds;
  final List<String> excludedTasks;
  final List<WeeklyRefreshFreezeWindow> freezeWindows;
  final List<WeeklyRefreshBoundary> boundaries;
  final String generatedWeek;
  final String generatedAt;
  final List<WeeklyScheduleEntry> generatedEntries;
  final List<WeeklyRefreshIssue> issues;

  factory WeeklyRefreshSettings.fromJson(Map<String, dynamic> json) {
    return WeeklyRefreshSettings(
      enabled: json['enabled'] == true,
      minOffsetSeconds:
          int.tryParse(json['min_offset_seconds']?.toString() ?? '') ?? 600,
      maxOffsetSeconds:
          int.tryParse(json['max_offset_seconds']?.toString() ?? '') ?? 1200,
      excludedTasks: _stringList(json['excluded_tasks']),
      freezeWindows: json.containsKey('freeze_windows')
          ? _mapList(
              json['freeze_windows'],
              WeeklyRefreshFreezeWindow.fromJson,
            )
          : weeklyRefreshDefaultFreezeWindows,
      boundaries: _mapList(
        json['boundaries'],
        WeeklyRefreshBoundary.fromJson,
      ),
      generatedWeek: json['generated_week']?.toString() ?? '',
      generatedAt: json['generated_at']?.toString() ?? '',
      generatedEntries: _mapList(
        json['generated_entries'],
        WeeklyScheduleEntry.fromJson,
      ),
      issues: _mapList(json['issues'], WeeklyRefreshIssue.fromJson),
    );
  }

  WeeklyRefreshSettings copyWith({
    bool? enabled,
    int? minOffsetSeconds,
    int? maxOffsetSeconds,
    List<String>? excludedTasks,
    List<WeeklyRefreshFreezeWindow>? freezeWindows,
    List<WeeklyRefreshBoundary>? boundaries,
    String? generatedWeek,
    String? generatedAt,
    List<WeeklyScheduleEntry>? generatedEntries,
    List<WeeklyRefreshIssue>? issues,
  }) {
    return WeeklyRefreshSettings(
      enabled: enabled ?? this.enabled,
      minOffsetSeconds: minOffsetSeconds ?? this.minOffsetSeconds,
      maxOffsetSeconds: maxOffsetSeconds ?? this.maxOffsetSeconds,
      excludedTasks: excludedTasks ?? this.excludedTasks,
      freezeWindows: freezeWindows ?? this.freezeWindows,
      boundaries: boundaries ?? this.boundaries,
      generatedWeek: generatedWeek ?? this.generatedWeek,
      generatedAt: generatedAt ?? this.generatedAt,
      generatedEntries: generatedEntries ?? this.generatedEntries,
      issues: issues ?? this.issues,
    );
  }

  Map<String, dynamic> toRequestJson() => {
        'enabled': enabled,
        'min_offset_seconds': minOffsetSeconds,
        'max_offset_seconds': maxOffsetSeconds,
        'excluded_tasks': excludedTasks,
        'freeze_windows': freezeWindows.map((item) => item.toJson()).toList(),
        'boundaries': boundaries.map((item) => item.toJson()).toList(),
      };
}

class WeeklyRefreshPreview {
  const WeeklyRefreshPreview({
    required this.entries,
    required this.issues,
  });

  final List<WeeklyScheduleEntry> entries;
  final List<WeeklyRefreshIssue> issues;

  factory WeeklyRefreshPreview.fromJson(Map<String, dynamic> json) {
    return WeeklyRefreshPreview(
      entries: _mapList(json['entries'], WeeklyScheduleEntry.fromJson),
      issues: _mapList(json['issues'], WeeklyRefreshIssue.fromJson),
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
    this.catchUpMissed = false,
    this.turtleMode = false,
    this.turtleKeepTasks = const [],
    this.freeCycleTasks = weeklyScheduleDefaultFreeCycleTasks,
    this.weekRefresh = const WeeklyRefreshSettings(),
    this.supportsWeekRefresh = false,
    this.effectiveEntries = const [],
    this.lastAppliedDate = '',
    this.lastAppliedAt = '',
    this.serverNow = '',
    this.currentWeekStart = '',
    this.todayWeekday = 1,
  });

  final bool enabled;
  final bool catchUpMissed;
  final bool turtleMode;
  final List<String> turtleKeepTasks;
  final List<String> freeCycleTasks;
  final WeeklyRefreshSettings weekRefresh;
  final bool supportsWeekRefresh;
  final List<WeeklyScheduleEntry> effectiveEntries;
  final List<WeeklyScheduleEntry> entries;
  final List<WeeklyScheduleTask> tasks;
  final List<String> plannedTasks;
  final List<String> unplannedTasks;
  final Map<String, String> nextRuns;
  final String lastAppliedDate;
  final String lastAppliedAt;
  final String serverNow;
  final String currentWeekStart;
  final int todayWeekday;

  factory WeeklyScheduleData.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleData(
      enabled: json['enabled'] != false,
      catchUpMissed: json['catch_up_missed'] == true,
      turtleMode: json['turtle_mode'] == true,
      turtleKeepTasks: _stringList(json['turtle_keep_tasks']),
      freeCycleTasks: json.containsKey('free_cycle_tasks')
          ? _stringList(json['free_cycle_tasks'])
          : weeklyScheduleDefaultFreeCycleTasks,
      weekRefresh: json['week_refresh'] is Map
          ? WeeklyRefreshSettings.fromJson(
              Map<String, dynamic>.from(json['week_refresh'] as Map),
            )
          : const WeeklyRefreshSettings(),
      supportsWeekRefresh: json.containsKey('week_refresh'),
      effectiveEntries: _mapList(
        json['effective_entries'],
        WeeklyScheduleEntry.fromJson,
      ),
      entries: _mapList(json['entries'], WeeklyScheduleEntry.fromJson),
      tasks: _mapList(json['tasks'], WeeklyScheduleTask.fromJson),
      plannedTasks: _stringList(json['planned_tasks']),
      unplannedTasks: _stringList(json['unplanned_tasks']),
      nextRuns: _stringMap(json['next_runs']),
      lastAppliedDate: json['last_applied_date']?.toString() ?? '',
      lastAppliedAt: json['last_applied_at']?.toString() ?? '',
      serverNow: json['server_now']?.toString() ?? '',
      currentWeekStart: json['current_week_start']?.toString() ?? '',
      todayWeekday: int.tryParse(json['today_weekday']?.toString() ?? '') ?? 1,
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
