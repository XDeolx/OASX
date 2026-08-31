import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/home/models/weekly_schedule_models.dart';
import 'package:oasx/modules/home/models/weekly_schedule_operations.dart';
import 'package:oasx/modules/home/widgets/weekly_schedule_time_picker.dart';
import 'package:oasx/translation/i18n_content.dart';

class WeeklySchedulePanel extends StatefulWidget {
  const WeeklySchedulePanel({
    super.key,
    required this.scriptName,
    this.initialData,
  });

  final String scriptName;
  final WeeklyScheduleData? initialData;

  @override
  State<WeeklySchedulePanel> createState() => _WeeklySchedulePanelState();
}

class _WeeklySchedulePanelState extends State<WeeklySchedulePanel> {
  WeeklyScheduleData? _data;
  List<WeeklyScheduleEntry> _entries = [];
  bool _enabled = true;
  bool _catchUpMissed = false;
  bool _turtleMode = false;
  Set<String> _turtleKeepTasks = {};
  Set<String> _freeCycleTasks = Set<String>.from(
    weeklyScheduleDefaultFreeCycleTasks,
  );
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  int _selectedWeekday = 0;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    final initialData = widget.initialData;
    if (initialData == null) {
      _load();
    } else {
      _data = initialData;
      _entries = List<WeeklyScheduleEntry>.from(initialData.entries);
      _enabled = initialData.enabled;
      _catchUpMissed = initialData.catchUpMissed;
      _turtleMode = initialData.turtleMode;
      _turtleKeepTasks = initialData.turtleKeepTasks.toSet();
      _freeCycleTasks = initialData.freeCycleTasks.toSet();
      _loading = false;
    }
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) {
        return;
      }
      final previousDate = DateTime(_now.year, _now.month, _now.day);
      final nextNow = DateTime.now();
      final nextDate = DateTime(nextNow.year, nextNow.month, nextNow.day);
      setState(() => _now = nextNow);
      if (nextDate != previousDate) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WeeklySchedulePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptName != widget.scriptName) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _dirty = false;
    });
    final data = await ApiClient().getWeeklySchedule(widget.scriptName);
    if (!mounted) {
      return;
    }
    if (data == null) {
      setState(() => _loading = false);
      Get.snackbar(I18n.error.tr, I18n.weeklyScheduleLoadFailed.tr);
      return;
    }
    _useData(data);
  }

  void _useData(WeeklyScheduleData data) {
    final serverNow = DateTime.tryParse(data.serverNow);
    setState(() {
      _data = data;
      _entries = List<WeeklyScheduleEntry>.from(data.entries);
      _enabled = data.enabled;
      _catchUpMissed = data.catchUpMissed;
      _turtleMode = data.turtleMode;
      _turtleKeepTasks = data.turtleKeepTasks.toSet();
      _freeCycleTasks = data.freeCycleTasks.toSet();
      _loading = false;
      _saving = false;
      _dirty = false;
      if (serverNow != null) {
        _now = serverNow;
      }
    });
  }

  Future<WeeklyScheduleData?> _save({bool notify = true}) async {
    setState(() => _saving = true);
    final data = await ApiClient().putWeeklySchedule(
      widget.scriptName,
      enabled: _enabled,
      catchUpMissed: _catchUpMissed,
      turtleMode: _turtleMode,
      turtleKeepTasks: _turtleKeepTasks.toList()..sort(),
      freeCycleTasks: _freeCycleTasks.toList()..sort(),
      entries: _entries,
    );
    if (!mounted) {
      return data;
    }
    if (data == null) {
      setState(() => _saving = false);
      Get.snackbar(I18n.error.tr, I18n.weeklyScheduleSaveFailed.tr);
      return null;
    }
    _useData(data);
    if (notify) {
      Get.snackbar(I18n.success.tr, I18n.weeklyScheduleSaved.tr);
    }
    return data;
  }

  Future<void> _apply({
    bool allowDisabled = false,
    bool preserveExistingTimes = false,
  }) async {
    if (_saving || (!allowDisabled && (!_enabled || _entries.isEmpty))) {
      return;
    }
    if (_dirty && await _save(notify: false) == null) {
      return;
    }
    setState(() => _saving = true);
    final data = await ApiClient().applyWeeklySchedule(
      widget.scriptName,
      preserveExistingTimes: preserveExistingTimes,
    );
    if (!mounted) {
      return;
    }
    if (data == null) {
      setState(() => _saving = false);
      Get.snackbar(I18n.error.tr, I18n.weeklyScheduleApplyFailed.tr);
      return;
    }
    _useData(data);
    Get.snackbar(I18n.success.tr, I18n.weeklyScheduleApplied.tr);
  }

  Future<void> _addEntry() async {
    final entry = await _showEntryDialog();
    if (entry == null || !mounted) {
      return;
    }
    setState(() {
      _entries.add(entry);
      _sortEntries();
      _dirty = true;
      _selectedWeekday = entry.weekday;
    });
    await _save(notify: false);
  }

  Future<void> _bulkAddEntries() async {
    final request = await _showBulkAddDialog();
    if (request == null || !mounted) {
      return;
    }
    setState(() {
      _entries = addWeeklyTaskToWeekdays(
        entries: _entries,
        task: request.task,
        weekdays: request.weekdays,
        baseTime: request.baseTime,
        minOffsetMinutes: request.minOffsetMinutes,
        maxOffsetMinutes: request.maxOffsetMinutes,
        replaceSameTask: request.replaceSameTask,
      );
      _selectedWeekday = 0;
      _dirty = true;
    });
    if (await _save(notify: false) != null && mounted) {
      Get.snackbar(I18n.success.tr, I18n.weeklyScheduleBulkAdded.tr);
    }
  }

  Future<void> _editEntry(int index) async {
    final entry = await _showEntryDialog(initial: _entries[index]);
    if (entry == null || !mounted) {
      return;
    }
    setState(() {
      _entries[index] = entry;
      _sortEntries();
      _dirty = true;
      _selectedWeekday = entry.weekday;
    });
    await _save(notify: false);
  }

  Future<void> _setEnabled(bool value) async {
    final restoreTurtleTasks = !value && _turtleMode;
    setState(() {
      _enabled = value;
      if (restoreTurtleTasks) {
        _turtleMode = false;
      }
      _dirty = true;
    });
    final data = await _save(notify: false);
    if (value && data != null) {
      await _apply();
    } else if (restoreTurtleTasks && data != null) {
      await _apply(allowDisabled: true, preserveExistingTimes: true);
    }
  }

  Future<void> _setTurtleMode(bool value) async {
    if (value) {
      final selected = await _showTurtleTasksDialog();
      if (selected == null || !mounted) {
        return;
      }
      setState(() {
        _turtleMode = true;
        _turtleKeepTasks = selected;
        _dirty = true;
      });
    } else {
      setState(() {
        _turtleMode = false;
        _dirty = true;
      });
    }
    final data = await _save(notify: false);
    if (data != null) {
      await _apply(
        allowDisabled: !value,
        preserveExistingTimes: true,
      );
    }
  }

  Future<void> _editTurtleTasks() async {
    final selected = await _showTurtleTasksDialog();
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _turtleKeepTasks = selected;
      _dirty = true;
    });
    final data = await _save(notify: false);
    if (data != null && _turtleMode) {
      await _apply(preserveExistingTimes: true);
    }
  }

  Future<Set<String>?> _showTurtleTasksDialog() {
    final tasks = _data!.tasks.map((task) => task.name).toList()..sort();
    final defaults = {'KekkaiUtilize', 'KekkaiActivation', 'AreaBoss'};
    final selected = _turtleKeepTasks.isNotEmpty
        ? Set<String>.from(_turtleKeepTasks)
        : tasks.where(defaults.contains).toSet();
    if (selected.isEmpty && tasks.isNotEmpty) {
      selected.add(tasks.first);
    }
    return _showTaskSelectionDialog(
      tasks: tasks,
      selected: selected,
      title: I18n.weeklyScheduleTurtleSelectTitle.tr,
      requireSelection: true,
    );
  }

  Future<void> _editFreeCycleTasks() async {
    final tasks = _data!.tasks.map((task) => task.name).toList()..sort();
    final selected = await _showTaskSelectionDialog(
      tasks: tasks,
      selected: _freeCycleTasks,
      title: I18n.weeklyScheduleFreeCycleSelectTitle.tr,
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _freeCycleTasks = selected;
      _dirty = true;
    });
    await _save(notify: false);
  }

  Future<Set<String>?> _showTaskSelectionDialog({
    required List<String> tasks,
    required Set<String> selected,
    required String title,
    bool requireSelection = false,
  }) {
    final dialogSelection = Set<String>.from(selected);
    return showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            height: 420,
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: dialogSelection.contains(task),
                  title: Text(task.tr),
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        dialogSelection.add(task);
                      } else {
                        dialogSelection.remove(task);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(I18n.cancel.tr),
            ),
            FilledButton(
              onPressed: requireSelection && dialogSelection.isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(dialogSelection),
              child: Text(I18n.confirm.tr),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setCatchUpMissed(bool value) async {
    setState(() {
      _catchUpMissed = value;
      _dirty = true;
    });
    await _save(notify: false);
  }

  Future<void> _deleteEntry(int index) async {
    setState(() {
      _entries.removeAt(index);
      _dirty = true;
    });
    await _save(notify: false);
  }

  Future<void> _copyDay() async {
    final source = _selectedWeekday == 0
        ? DateTime.now().weekday
        : _selectedWeekday;
    final request = await _showCopyDayDialog(
      sourceWeekday: source,
      targetWeekday: source == 7 ? 1 : source + 1,
    );
    if (request == null || !mounted) {
      return;
    }
    if (!_entries.any((entry) => entry.weekday == request.sourceWeekday)) {
      Get.snackbar(I18n.error.tr, I18n.weeklyScheduleNoSourceEntries.tr);
      return;
    }
    setState(() {
      _entries = copyWeeklyScheduleDay(
        entries: _entries,
        sourceWeekday: request.sourceWeekday,
        targetWeekday: request.targetWeekday,
        replaceTarget: request.replaceTarget,
      );
      _selectedWeekday = request.targetWeekday;
      _dirty = true;
    });
    if (await _save(notify: false) != null && mounted) {
      Get.snackbar(I18n.success.tr, I18n.weeklyScheduleDayCopied.tr);
    }
  }

  Future<_CopyDayRequest?> _showCopyDayDialog({
    required int sourceWeekday,
    required int targetWeekday,
  }) {
    var source = sourceWeekday;
    var target = targetWeekday;
    var replaceTarget = true;
    return showDialog<_CopyDayRequest>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(I18n.weeklyScheduleCopyDayTitle.tr),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: source,
                  decoration: InputDecoration(
                    labelText: I18n.weeklyScheduleSourceDay.tr,
                    border: const OutlineInputBorder(),
                  ),
                  items: _weekdayMenuItems(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => source = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: target,
                  decoration: InputDecoration(
                    labelText: I18n.weeklyScheduleTargetDay.tr,
                    border: const OutlineInputBorder(),
                  ),
                  items: _weekdayMenuItems(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => target = value);
                    }
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: replaceTarget,
                  title: Text(I18n.weeklyScheduleReplaceTarget.tr),
                  onChanged: (value) {
                    setDialogState(() => replaceTarget = value ?? true);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(I18n.cancel.tr),
            ),
            FilledButton(
              onPressed: source == target
                  ? null
                  : () => Navigator.of(dialogContext).pop(
                        _CopyDayRequest(
                          sourceWeekday: source,
                          targetWeekday: target,
                          replaceTarget: replaceTarget,
                        ),
                      ),
              child: Text(I18n.confirm.tr),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importCurrentScheduler() async {
    final importable = _data!.tasks.where(
      (task) => task.enabled && DateTime.tryParse(task.nextRun) != null,
    );
    if (importable.isEmpty) {
      Get.snackbar(I18n.error.tr, I18n.weeklyScheduleNoEnabledTasks.tr);
      return;
    }
    var replaceExisting = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(I18n.weeklyScheduleImportCurrentTitle.tr),
          content: SizedBox(
            width: 420,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: replaceExisting,
              title: Text(I18n.weeklyScheduleReplaceExisting.tr),
              subtitle: Text('${importable.length}'),
              onChanged: (value) {
                setDialogState(() => replaceExisting = value ?? false);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(I18n.cancel.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(I18n.confirm.tr),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _entries = buildEntriesFromCurrentScheduler(
        entries: _entries,
        tasks: _data!.tasks,
        replaceExisting: replaceExisting,
      );
      _selectedWeekday = 0;
      _dirty = true;
    });
    if (await _save(notify: false) != null && mounted) {
      Get.snackbar(I18n.success.tr, I18n.weeklyScheduleImported.tr);
    }
  }

  List<DropdownMenuItem<int>> _weekdayMenuItems() {
    return List.generate(
      7,
      (index) => DropdownMenuItem(
        value: index + 1,
        child: Text(_weekdayLabel(index + 1)),
      ),
    );
  }

  Future<WeeklyScheduleEntry?> _showEntryDialog({
    WeeklyScheduleEntry? initial,
  }) async {
    final tasks = _data?.tasks
            .map((task) => task.name)
            .where((task) => !_turtleMode || _turtleKeepTasks.contains(task))
            .toList() ??
        [];
    if (tasks.isEmpty) {
      return null;
    }
    var task = initial?.task ?? tasks.first;
    var weekday = initial?.weekday ?? DateTime.now().weekday;
    var runTime = WeeklyScheduleClockTime.parse(initial?.time ?? '09:00:00');
    return showDialog<WeeklyScheduleEntry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            initial == null
                ? I18n.weeklyScheduleAdd.tr
                : I18n.weeklyScheduleEdit.tr,
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: task,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: I18n.weeklyScheduleTask.tr,
                    border: const OutlineInputBorder(),
                  ),
                  items: tasks
                      .map(
                        (name) => DropdownMenuItem(
                          value: name,
                          child: Text(name.tr, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => task = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: weekday,
                  decoration: InputDecoration(
                    labelText: I18n.weeklyScheduleWeekday.tr,
                    border: const OutlineInputBorder(),
                  ),
                  items: List.generate(
                    7,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(_weekdayLabel(index + 1)),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => weekday = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(I18n.weeklyScheduleTime.tr),
                  trailing: Text(
                    runTime.format(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () async {
                    final selected = await showWeeklyScheduleTimePicker(
                      context: dialogContext,
                      initialTime: runTime,
                    );
                    if (selected != null) {
                      setDialogState(() => runTime = selected);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(I18n.cancel.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                WeeklyScheduleEntry(
                  task: task,
                  weekday: weekday,
                  time: runTime.format(),
                ),
              ),
              child: Text(I18n.confirm.tr),
            ),
          ],
        ),
      ),
    );
  }

  Future<_BulkAddRequest?> _showBulkAddDialog() async {
    final tasks = _data?.tasks
            .map((task) => task.name)
            .where((task) => !_turtleMode || _turtleKeepTasks.contains(task))
            .toList() ??
        [];
    if (tasks.isEmpty) {
      return null;
    }
    var task = tasks.first;
    var runTime = const WeeklyScheduleClockTime(
      hour: 9,
      minute: 0,
      second: 0,
    );
    var weekdays = <int>{
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    };
    var offsetRange = const RangeValues(5, 10);
    var replaceSameTask = true;
    return showDialog<_BulkAddRequest>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(I18n.weeklyScheduleBulkAddTitle.tr),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: task,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: I18n.weeklyScheduleTask.tr,
                      border: const OutlineInputBorder(),
                    ),
                    items: tasks
                        .map(
                          (name) => DropdownMenuItem(
                            value: name,
                            child: Text(
                              name.tr,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => task = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: Text(I18n.weeklyScheduleTime.tr),
                    trailing: Text(
                      runTime.format(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: () async {
                      final selected = await showWeeklyScheduleTimePicker(
                        context: dialogContext,
                        initialTime: runTime,
                      );
                      if (selected != null) {
                        setDialogState(() => runTime = selected);
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    I18n.weeklyScheduleTargetDays.tr,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (index) {
                      final weekday = index + 1;
                      return FilterChip(
                        label: Text(_weekdayLabel(weekday, short: true)),
                        selected: weekdays.contains(weekday),
                        onSelected: (selected) {
                          setDialogState(() {
                            weekdays = Set<int>.from(weekdays);
                            if (selected) {
                              weekdays.add(weekday);
                            } else {
                              weekdays.remove(weekday);
                            }
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          I18n.weeklyScheduleRandomOffset.tr,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Text(
                        '${offsetRange.start.round()}-'
                        '${offsetRange.end.round()} '
                        '${I18n.weeklyScheduleMinutes.tr}',
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: offsetRange,
                    min: 0,
                    max: 60,
                    divisions: 60,
                    labels: RangeLabels(
                      offsetRange.start.round().toString(),
                      offsetRange.end.round().toString(),
                    ),
                    onChanged: (value) {
                      setDialogState(() => offsetRange = value);
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: replaceSameTask,
                    title: Text(I18n.weeklyScheduleReplaceSameTask.tr),
                    onChanged: (value) {
                      setDialogState(() => replaceSameTask = value ?? true);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(I18n.cancel.tr),
            ),
            FilledButton(
              onPressed: weekdays.isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(
                        _BulkAddRequest(
                          task: task,
                          weekdays: weekdays,
                          baseTime: runTime.format(),
                          minOffsetMinutes: offsetRange.start.round(),
                          maxOffsetMinutes: offsetRange.end.round(),
                          replaceSameTask: replaceSameTask,
                        ),
                      ),
              child: Text(I18n.confirm.tr),
            ),
          ],
        ),
      ),
    );
  }

  void _sortEntries() {
    _entries.sort((a, b) {
      final day = a.weekday.compareTo(b.weekday);
      if (day != 0) {
        return day;
      }
      final time = a.time.compareTo(b.time);
      return time != 0 ? time : a.task.compareTo(b.task);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_data == null) {
      return Center(
        child: IconButton.filledTonal(
          tooltip: I18n.retry.tr,
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      );
    }
    final visibleEntries = _entries
        .asMap()
        .entries
        .where(
          (item) =>
              (!_turtleMode || _turtleKeepTasks.contains(item.value.task)) &&
              (_selectedWeekday == 0 ||
                  item.value.weekday == _selectedWeekday),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(),
        const SizedBox(height: 6),
        _buildTimeStatus(),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(I18n.weeklyScheduleAll.tr)),
              ...List.generate(
                7,
                (index) => ButtonSegment(
                  value: index + 1,
                  label: Text(_weekdayLabel(index + 1, short: true)),
                ),
              ),
            ],
            selected: {_selectedWeekday},
            showSelectedIcon: false,
            onSelectionChanged: (value) {
              setState(() => _selectedWeekday = value.first);
            },
          ),
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: const ValueKey<String>('weekly-schedule-coverage'),
          child: _buildCoverage(),
        ),
        const Divider(height: 20),
        Expanded(
          child: ListView(
            key: const PageStorageKey<String>('weekly-schedule-list'),
            children: [
              if (visibleEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(child: Text(I18n.weeklyScheduleEmpty.tr)),
                )
              else
                ...visibleEntries.map(_buildEntry),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final primaryControls = Wrap(
      key: const ValueKey<String>('weekly-schedule-primary-controls'),
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 6,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactSwitch(
              value: _enabled,
              onChanged: _saving ? null : _setEnabled,
            ),
            const SizedBox(width: 6),
            Text(
              _enabled
                  ? I18n.weeklyScheduleEnabled.tr
                  : I18n.weeklyScheduleDisabled.tr,
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Checkbox(
                value: _catchUpMissed,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: _saving
                    ? null
                    : (value) => _setCatchUpMissed(value ?? false),
              ),
            ),
            const SizedBox(width: 4),
            Text(I18n.weeklyScheduleCatchUpMissed.tr),
          ],
        ),
      ],
    );
    final modeControls = Wrap(
      key: const ValueKey<String>('weekly-schedule-mode-controls'),
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 6,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactSwitch(
              value: _turtleMode,
              onChanged: _saving || !_enabled ? null : _setTurtleMode,
            ),
            const SizedBox(width: 6),
            Text(I18n.weeklyScheduleTurtleMode.tr),
            IconButton(
              tooltip: I18n.weeklyScheduleTurtleSelect.tr,
              visualDensity: VisualDensity.compact,
              onPressed: _saving || !_enabled ? null : _editTurtleTasks,
              icon: Icon(
                Icons.shield_rounded,
                color: _turtleMode ? Colors.lightBlue : null,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(I18n.weeklyScheduleFreeCycle.tr),
            IconButton(
              tooltip: I18n.weeklyScheduleFreeCycleSelect.tr,
              visualDensity: VisualDensity.compact,
              onPressed: _saving || !_enabled ? null : _editFreeCycleTasks,
              icon: Icon(
                Icons.autorenew_rounded,
                color: _freeCycleTasks.isNotEmpty ? Colors.lightBlue : null,
              ),
            ),
          ],
        ),
        if (_dirty)
          Text(
            I18n.argsDraftDirty.tr,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
      ],
    );
    final status = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        primaryControls,
        const SizedBox(height: 4),
        modeControls,
      ],
    );
    final actions = Wrap(
      key: const ValueKey<String>('weekly-schedule-actions'),
      alignment: WrapAlignment.end,
      runAlignment: WrapAlignment.end,
      children: [
        IconButton(
          tooltip: I18n.weeklyScheduleAdd.tr,
          onPressed: _saving ? null : _addEntry,
          icon: const Icon(Icons.add_rounded),
        ),
        IconButton(
          tooltip: I18n.weeklyScheduleBulkAdd.tr,
          onPressed: _saving ? null : _bulkAddEntries,
          icon: const Icon(Icons.calendar_month_rounded),
        ),
        IconButton(
          tooltip: I18n.weeklyScheduleCopyDay.tr,
          onPressed: _saving || _entries.isEmpty ? null : _copyDay,
          icon: const Icon(Icons.copy_all_rounded),
        ),
        IconButton(
          tooltip: I18n.weeklyScheduleImportCurrent.tr,
          onPressed: _saving ? null : _importCurrentScheduler,
          icon: const Icon(Icons.playlist_add_rounded),
        ),
        IconButton(
          tooltip: I18n.argsSaveChanges.tr,
          onPressed: _saving || !_dirty ? null : _save,
          icon: const Icon(Icons.save_rounded),
        ),
        IconButton(
          tooltip: I18n.weeklyScheduleResetTimes.tr,
          onPressed: _saving || !_enabled || _entries.isEmpty ? null : _apply,
          icon: const Icon(Icons.restart_alt_rounded),
        ),
        IconButton(
          tooltip: I18n.homeConnectionRetryAction.tr,
          onPressed: _saving ? null : _load,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 840) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              status,
              const SizedBox(height: 2),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: status),
            const SizedBox(width: 12),
            SizedBox(width: 336, child: actions),
          ],
        );
      },
    );
  }

  Widget _buildCompactSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SizedBox(
      width: 42,
      height: 30,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(value: value, onChanged: onChanged),
      ),
    );
  }

  Widget _buildTimeStatus() {
    final data = _data!;
    final lastApplied = data.lastAppliedAt.isEmpty
        ? I18n.weeklyScheduleNotSynced.tr
        : data.lastAppliedAt;
    return Wrap(
      spacing: 18,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildStatusText(
          Icons.schedule_rounded,
          '${I18n.weeklyScheduleCurrentTime.tr}: ${_formatDateTime(_now)}',
        ),
        _buildStatusText(
          Icons.date_range_rounded,
          '${I18n.weeklyScheduleCurrentWeek.tr}: ${data.currentWeekStart}',
        ),
        _buildStatusText(
          Icons.update_rounded,
          '${I18n.weeklyScheduleLastSynced.tr}: $lastApplied',
        ),
      ],
    );
  }

  Widget _buildStatusText(IconData icon, String text) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverage() {
    final visibleEntries = _entries.where(
      (entry) => !_turtleMode || _turtleKeepTasks.contains(entry.task),
    );
    final planned = visibleEntries.map((entry) => entry.task).toSet().toList()
      ..sort();
    final allTasks = _turtleMode
        ? Set<String>.from(_turtleKeepTasks)
        : _data!.tasks.map((task) => task.name).toSet();
    final unplanned = allTasks.difference(planned.toSet()).toList()..sort();
    final freeCycle = _freeCycleTasks.toList()..sort();
    if (_turtleMode) {
      final retained = allTasks.toList()..sort();
      return Wrap(
        spacing: 20,
        runSpacing: 4,
        children: [
          _buildCoverageAction(
            icon: Icons.shield_rounded,
            iconColor: Colors.lightBlue,
            label: I18n.weeklyScheduleTurtleKeep.tr,
            count: retained.length,
            onPressed: () => _showTaskListDialog(
              title: I18n.weeklyScheduleTurtleSelectTitle.tr,
              tasks: retained,
            ),
          ),
          _buildCoverageAction(
            icon: Icons.autorenew_rounded,
            iconColor: _freeCycleTasks.isNotEmpty ? Colors.lightBlue : null,
            label: I18n.weeklyScheduleFreeCycle.tr,
            count: freeCycle.length,
            onPressed: _editFreeCycleTasks,
          ),
        ],
      );
    }
    return Wrap(
      spacing: 20,
      runSpacing: 4,
      children: [
        _buildCoverageAction(
          icon: Icons.event_available_rounded,
          label: I18n.weeklySchedulePlanned.tr,
          count: planned.length,
          onPressed: () => _showTaskListDialog(
            title: I18n.weeklySchedulePlanned.tr,
            tasks: planned,
          ),
        ),
        _buildCoverageAction(
          icon: Icons.event_busy_rounded,
          label: I18n.weeklyScheduleUnplanned.tr,
          count: unplanned.length,
          onPressed: () => _showTaskListDialog(
            title: I18n.weeklyScheduleUnplanned.tr,
            tasks: unplanned,
          ),
        ),
        _buildCoverageAction(
          icon: Icons.autorenew_rounded,
          iconColor: _freeCycleTasks.isNotEmpty ? Colors.lightBlue : null,
          label: I18n.weeklyScheduleFreeCycle.tr,
          count: freeCycle.length,
          onPressed: _editFreeCycleTasks,
        ),
      ],
    );
  }

  Widget _buildCoverageAction({
    required IconData icon,
    Color? iconColor,
    required String label,
    required int count,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: iconColor),
      label: Text('$label  $count'),
    );
  }

  Future<void> _showTaskListDialog({
    required String title,
    required List<String> tasks,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          height: 420,
          child: tasks.isEmpty
              ? Center(child: Text(I18n.weeklyScheduleEmpty.tr))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final nextRun = _dirty ? null : _data!.nextRuns[task];
                    return ListTile(
                      dense: true,
                      title: Text(task.tr),
                      subtitle: nextRun == null ? null : Text(nextRun),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(I18n.confirm.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(MapEntry<int, WeeklyScheduleEntry> indexedEntry) {
    final index = indexedEntry.key;
    final entry = indexedEntry.value;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              _weekdayLabel(entry.weekday, short: true),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      title: Text(entry.task.tr),
      subtitle: Text(_entryScheduledAt(entry)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: I18n.weeklyScheduleEdit.tr,
            onPressed: _saving ? null : () => _editEntry(index),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: I18n.delete.tr,
            onPressed: _saving ? null : () => _deleteEntry(index),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday, {bool short = false}) {
    final labels = short
        ? [
            I18n.weekdayMonShort,
            I18n.weekdayTueShort,
            I18n.weekdayWedShort,
            I18n.weekdayThuShort,
            I18n.weekdayFriShort,
            I18n.weekdaySatShort,
            I18n.weekdaySunShort,
          ]
        : [
            I18n.weekdayMonday,
            I18n.weekdayTuesday,
            I18n.weekdayWednesday,
            I18n.weekdayThursday,
            I18n.weekdayFriday,
            I18n.weekdaySaturday,
            I18n.weekdaySunday,
          ];
    return labels[weekday - 1].tr;
  }

  String _entryScheduledAt(WeeklyScheduleEntry entry) {
    if (entry.scheduledAt.isNotEmpty) {
      return entry.scheduledAt;
    }
    final scheduledAt = weeklyScheduleCurrentWeekDateTime(
      entry,
      DateTime.now(),
    );
    final displayTime = entry.time.length == 5
        ? '${entry.time}:00'
        : entry.time;
    return '${scheduledAt.year.toString().padLeft(4, '0')}-'
        '${scheduledAt.month.toString().padLeft(2, '0')}-'
        '${scheduledAt.day.toString().padLeft(2, '0')} '
        '$displayTime';
  }

  String _formatDateTime(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}';
  }
}

class _CopyDayRequest {
  const _CopyDayRequest({
    required this.sourceWeekday,
    required this.targetWeekday,
    required this.replaceTarget,
  });

  final int sourceWeekday;
  final int targetWeekday;
  final bool replaceTarget;
}

class _BulkAddRequest {
  const _BulkAddRequest({
    required this.task,
    required this.weekdays,
    required this.baseTime,
    required this.minOffsetMinutes,
    required this.maxOffsetMinutes,
    required this.replaceSameTask,
  });

  final String task;
  final Set<int> weekdays;
  final String baseTime;
  final int minOffsetMinutes;
  final int maxOffsetMinutes;
  final bool replaceSameTask;
}
