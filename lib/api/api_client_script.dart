part of 'api_client.dart';

extension ApiClientScriptX on ApiClient {
  Future<WeeklyScheduleData?> getWeeklySchedule(String scriptName) async {
    final res = await request(
      () => get(
        '/$scriptName/weekly_schedule',
        options: _backendNoCacheOptions(),
      ),
    );
    if (!res.isSuccess || res.data is! Map) {
      return null;
    }
    return WeeklyScheduleData.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<WeeklyScheduleData?> putWeeklySchedule(
    String scriptName, {
    required bool enabled,
    required bool catchUpMissed,
    required bool turtleMode,
    required List<String> turtleKeepTasks,
    required List<String> freeCycleTasks,
    required List<WeeklyScheduleEntry> entries,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/weekly_schedule',
        data: {
          'enabled': enabled,
          'catch_up_missed': catchUpMissed,
          'turtle_mode': turtleMode,
          'turtle_keep_tasks': turtleKeepTasks,
          'free_cycle_tasks': freeCycleTasks,
          'entries': entries.map((entry) => entry.toJson()).toList(),
        },
      ),
    );
    if (!res.isSuccess || res.data is! Map) {
      return null;
    }
    return WeeklyScheduleData.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<WeeklyScheduleData?> applyWeeklySchedule(
    String scriptName, {
    bool preserveExistingTimes = false,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/weekly_schedule/apply',
        queryParameters: {
          'preserve_existing_times': preserveExistingTimes,
        },
      ),
    );
    if (!res.isSuccess || res.data is! Map) {
      return null;
    }
    return WeeklyScheduleData.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  /// Loads the full argument model for one task.
  Future<Map<String, dynamic>> getScriptTask(
    String scriptName,
    String taskName,
  ) async {
    final res = await request(
      () => get(
        '/$scriptName/$taskName/args',
        options: _backendNoCacheOptions(),
      ),
    );
    return res.data ?? {};
  }

  /// Persists one task argument through the generic value endpoint.
  Future<bool> putScriptArg(
    String scriptName,
    String taskName,
    String groupName,
    String argumentName,
    String type,
    dynamic value,
  ) async {
    final res = await request(
      () => put(
        '/$scriptName/$taskName/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  /// Synchronizes one task back into the waiting queue immediately.
  Future<bool> syncScriptTaskNextRun(
    String scriptName,
    String taskName,
    String targetDt,
  ) async {
    final res = await request(
      () => put(
        '/$scriptName/$taskName/sync_next_run',
        queryParameters: {'target_dt': targetDt},
      ),
    );
    return res.isSuccess && res.data == true;
  }
}
