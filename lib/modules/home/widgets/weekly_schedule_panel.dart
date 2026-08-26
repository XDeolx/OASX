import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/home/models/weekly_schedule_models.dart';
import 'package:oasx/modules/home/models/weekly_schedule_operations.dart';
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
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  int _selectedWeekday = 0;

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
      _loading = false;
    }
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
    setState(() {
      _data = data;
      _entries = List<WeeklyScheduleEntry>.from(data.entries);
      _enabled = data.enabled;
      _loading = false;
      _saving = false;
      _dirty = false;
    });
  }

  Future<WeeklyScheduleData?> _save({bool notify = true}) async {
    setState(() => _saving = true);
    final data = await ApiClient().putWeeklySchedule(
      widget.scriptName,
      enabled: _enabled,
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

  Future<void> _apply() async {
    if (_saving || !_enabled || _entries.isEmpty) {
      return;
    }
    if (_dirty && await _save(notify: false) == null) {
      return;
    }
    setState(() => _saving = true);
    final data = await ApiClient().applyWeeklySchedule(widget.scriptName);
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
    setState(() {
      _enabled = value;
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
    final tasks = _data?.tasks.map((task) => task.name).toList() ?? [];
    if (tasks.isEmpty) {
      return null;
    }
    var task = initial?.task ?? tasks.first;
    var weekday = initial?.weekday ?? DateTime.now().weekday;
    final parts = (initial?.time ?? '09:00').split(':');
    var runTime = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
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
                    _formatTime(runTime),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () async {
                    final selected = await showTimePicker(
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
                  time: _formatTime(runTime),
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
              _selectedWeekday == 0 ||
              item.value.weekday == _selectedWeekday,
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(),
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
        Expanded(
          child: ListView(
            key: const PageStorageKey<String>('weekly-schedule-list'),
            children: [
              _buildCoverage(),
              const Divider(height: 20),
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
    final status = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: _enabled,
          onChanged: _saving ? null : _setEnabled,
        ),
        Flexible(
          child: Text(
            _enabled
                ? I18n.weeklyScheduleEnabled.tr
                : I18n.weeklyScheduleDisabled.tr,
          ),
        ),
        if (_dirty)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              I18n.argsDraftDirty.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: I18n.weeklyScheduleAdd.tr,
          onPressed: _saving ? null : _addEntry,
          icon: const Icon(Icons.add_rounded),
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
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              status,
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }
        return Row(
          children: [Expanded(child: status), actions],
        );
      },
    );
  }

  Widget _buildCoverage() {
    final planned = _entries.map((entry) => entry.task).toSet().toList()..sort();
    final allTasks = _data!.tasks.map((task) => task.name).toSet();
    final unplanned = allTasks.difference(planned.toSet()).toList()..sort();
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
      ],
    );
  }

  Widget _buildCoverageAction({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
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
      subtitle: _dirty || _data!.nextRuns[entry.task] == null
          ? null
          : Text(_data!.nextRuns[entry.task]!),
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

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
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
