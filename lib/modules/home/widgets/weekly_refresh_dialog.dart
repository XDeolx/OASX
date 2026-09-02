import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/home/models/weekly_schedule_models.dart';
import 'package:oasx/modules/home/widgets/weekly_schedule_time_picker.dart';
import 'package:oasx/translation/i18n_content.dart';

typedef WeeklyRefreshWeekdayLabel = String Function(int weekday);

Future<WeeklyRefreshSettings?> showWeeklyRefreshDialog({
  required BuildContext context,
  required String scriptName,
  required List<WeeklyScheduleEntry> entries,
  required WeeklyRefreshSettings initialSettings,
  required WeeklyRefreshWeekdayLabel weekdayLabel,
}) {
  return showDialog<WeeklyRefreshSettings>(
    context: context,
    builder: (dialogContext) => _WeeklyRefreshDialog(
      scriptName: scriptName,
      entries: entries,
      initialSettings: initialSettings,
      weekdayLabel: weekdayLabel,
    ),
  );
}

class _WeeklyRefreshDialog extends StatefulWidget {
  const _WeeklyRefreshDialog({
    required this.scriptName,
    required this.entries,
    required this.initialSettings,
    required this.weekdayLabel,
  });

  final String scriptName;
  final List<WeeklyScheduleEntry> entries;
  final WeeklyRefreshSettings initialSettings;
  final WeeklyRefreshWeekdayLabel weekdayLabel;

  @override
  State<_WeeklyRefreshDialog> createState() => _WeeklyRefreshDialogState();
}

class _WeeklyRefreshDialogState extends State<_WeeklyRefreshDialog> {
  late RangeValues _offsetMinutes;
  late Set<String> _excludedTasks;
  late List<WeeklyRefreshFreezeWindow> _freezeWindows;
  late Map<String, WeeklyRefreshBoundary> _boundaries;
  WeeklyRefreshPreview? _preview;
  bool _previewing = false;

  @override
  void initState() {
    super.initState();
    final settings = widget.initialSettings;
    _offsetMinutes = RangeValues(
      (settings.minOffsetSeconds / 60).clamp(0, 120).toDouble(),
      (settings.maxOffsetSeconds / 60).clamp(0, 120).toDouble(),
    );
    final plannedTasks = widget.entries.map((entry) => entry.task).toSet();
    final plannedKeys = widget.entries
        .map((entry) => _entryKey(entry.task, entry.weekday))
        .toSet();
    _excludedTasks = settings.excludedTasks
        .where(plannedTasks.contains)
        .toSet();
    _freezeWindows = List<WeeklyRefreshFreezeWindow>.from(
      settings.freezeWindows,
    );
    _boundaries = {
      for (final boundary in settings.boundaries)
        if (plannedKeys.contains(_entryKey(boundary.task, boundary.weekday)))
          _entryKey(boundary.task, boundary.weekday): boundary,
    };
  }

  WeeklyRefreshSettings get _settings {
    return widget.initialSettings.copyWith(
      minOffsetSeconds: (_offsetMinutes.start * 60).round(),
      maxOffsetSeconds: (_offsetMinutes.end * 60).round(),
      excludedTasks: _excludedTasks.toList()..sort(),
      freezeWindows: List<WeeklyRefreshFreezeWindow>.from(_freezeWindows),
      boundaries: _boundaries.values.toList()
        ..sort((a, b) {
          final day = a.weekday.compareTo(b.weekday);
          return day != 0 ? day : a.task.compareTo(b.task);
        }),
      generatedWeek: '',
      generatedAt: '',
      generatedEntries: const [],
      issues: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    return AlertDialog(
      title: Text(I18n.weeklyRefreshSettings.tr),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: SizedBox(
        width: min(media.width * 0.84, 760),
        height: min(media.height * 0.72, 600),
        child: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: I18n.weeklyRefreshRange.tr),
                  Tab(text: I18n.weeklyRefreshExcluded.tr),
                  Tab(text: I18n.weeklyRefreshBoundaries.tr),
                  Tab(text: I18n.weeklyRefreshPreview.tr),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildRangeTab(),
                    _buildExcludedTab(),
                    _buildBoundariesTab(),
                    _buildPreviewTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(I18n.cancel.tr),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_settings),
          icon: const Icon(Icons.save_rounded),
          label: Text(I18n.argsSaveChanges.tr),
        ),
      ],
    );
  }

  Widget _buildRangeTab() {
    final rangeLabel = '${_offsetMinutes.start.round()}-'
        '${_offsetMinutes.end.round()} ${I18n.weeklyScheduleMinutes.tr}';
    return ListView(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.swap_horiz_rounded),
          title: Text(I18n.weeklyRefreshRandomRange.tr),
          subtitle: Text(I18n.weeklyRefreshRandomRangeHelp.tr),
          trailing: Text(rangeLabel),
        ),
        RangeSlider(
          values: _offsetMinutes,
          min: 0,
          max: 120,
          divisions: 120,
          labels: RangeLabels(
            _offsetMinutes.start.round().toString(),
            _offsetMinutes.end.round().toString(),
          ),
          onChanged: (value) {
            setState(() {
              _offsetMinutes = value;
              _preview = null;
            });
          },
        ),
        const Divider(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                I18n.weeklyRefreshFreezeWindows.tr,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: I18n.weeklyRefreshAddFreeze.tr,
              onPressed: _addFreezeWindow,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        if (_freezeWindows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(I18n.weeklyRefreshNoFreeze.tr)),
          )
        else
          ..._freezeWindows.asMap().entries.map((indexed) {
            final freeze = indexed.value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.ac_unit_rounded),
              title: Text(widget.weekdayLabel(freeze.weekday)),
              subtitle: Text('${freeze.start} - ${freeze.end}'),
              onTap: () => _editFreezeWindow(indexed.key),
              trailing: IconButton(
                tooltip: I18n.delete.tr,
                onPressed: () {
                  setState(() {
                    _freezeWindows.removeAt(indexed.key);
                    _preview = null;
                  });
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildExcludedTab() {
    final plannedTasks = widget.entries.map((entry) => entry.task).toSet().toList()
      ..sort();
    return ListView.builder(
      itemCount: plannedTasks.length,
      itemBuilder: (context, index) {
        final task = plannedTasks[index];
        return CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: _excludedTasks.contains(task),
          title: Text(task.tr),
          subtitle: Text(I18n.weeklyRefreshExcludedTaskHelp.tr),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _excludedTasks.add(task);
              } else {
                _excludedTasks.remove(task);
              }
              _preview = null;
            });
          },
        );
      },
    );
  }

  Widget _buildBoundariesTab() {
    final uniqueEntries = <String, WeeklyScheduleEntry>{};
    for (final entry in widget.entries) {
      uniqueEntries.putIfAbsent(
        _entryKey(entry.task, entry.weekday),
        () => entry,
      );
    }
    final entries = uniqueEntries.values.toList()
      ..sort((a, b) {
        final day = a.weekday.compareTo(b.weekday);
        final time = a.time.compareTo(b.time);
        return day != 0 ? day : (time != 0 ? time : a.task.compareTo(b.task));
      });
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final key = _entryKey(entry.task, entry.weekday);
        final boundary = _boundaries[key];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            boundary == null ? Icons.horizontal_rule_rounded : Icons.schedule,
          ),
          title: Text(entry.task.tr),
          subtitle: Text(
            '${widget.weekdayLabel(entry.weekday)}  ${entry.time}'
            '${boundary == null ? '' : '  |  ${boundary.start} - ${boundary.end}'}',
          ),
          onTap: () => _editBoundary(entry),
          trailing: boundary == null
              ? const Icon(Icons.chevron_right_rounded)
              : IconButton(
                  tooltip: I18n.weeklyRefreshClearBoundary.tr,
                  onPressed: () {
                    setState(() {
                      _boundaries.remove(key);
                      _preview = null;
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        );
      },
    );
  }

  Widget _buildPreviewTab() {
    final preview = _preview;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _previewing ? null : _loadPreview,
            icon: _previewing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.shuffle_rounded),
            label: Text(I18n.weeklyRefreshGeneratePreview.tr),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: preview == null
              ? Center(child: Text(I18n.weeklyRefreshPreviewEmpty.tr))
              : _buildPreviewList(preview),
        ),
      ],
    );
  }

  Widget _buildPreviewList(WeeklyRefreshPreview preview) {
    final baseByKey = {
      for (final entry in widget.entries)
        _entryKey(entry.task, entry.weekday): entry.time,
    };
    final issuesByKey = {
      for (final issue in preview.issues)
        _entryKey(issue.task, issue.weekday): issue,
    };
    return ListView.builder(
      itemCount: preview.entries.length,
      itemBuilder: (context, index) {
        final entry = preview.entries[index];
        final key = _entryKey(entry.task, entry.weekday);
        final baseTime = baseByKey[key] ?? entry.time;
        final hasIssue = issuesByKey.containsKey(key);
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            hasIssue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
            color: hasIssue ? Theme.of(context).colorScheme.error : null,
          ),
          title: Text(entry.task.tr),
          subtitle: Text(
            hasIssue
                ? '${widget.weekdayLabel(entry.weekday)}  |  '
                    '${I18n.weeklyRefreshNoCandidate.tr}'
                : widget.weekdayLabel(entry.weekday),
          ),
          trailing: Text('$baseTime  ->  ${entry.time}'),
        );
      },
    );
  }

  Future<void> _loadPreview() async {
    setState(() => _previewing = true);
    final preview = await ApiClient().previewWeeklyRefresh(
      widget.scriptName,
      entries: widget.entries,
      settings: _settings,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _previewing = false;
      _preview = preview;
    });
    if (preview == null) {
      Get.snackbar(I18n.error.tr, I18n.weeklyRefreshPreviewFailed.tr);
    }
  }

  Future<void> _addFreezeWindow() async {
    final freeze = await _showFreezeEditor(
      const WeeklyRefreshFreezeWindow(
        weekday: DateTime.wednesday,
        start: '04:00:00',
        end: '10:00:00',
      ),
    );
    if (freeze != null && mounted) {
      setState(() {
        _freezeWindows.add(freeze);
        _preview = null;
      });
    }
  }

  Future<void> _editFreezeWindow(int index) async {
    final freeze = await _showFreezeEditor(_freezeWindows[index]);
    if (freeze != null && mounted) {
      setState(() {
        _freezeWindows[index] = freeze;
        _preview = null;
      });
    }
  }

  Future<WeeklyRefreshFreezeWindow?> _showFreezeEditor(
    WeeklyRefreshFreezeWindow initial,
  ) async {
    var weekday = initial.weekday;
    var start = WeeklyScheduleClockTime.parse(initial.start);
    var end = WeeklyScheduleClockTime.parse(initial.end);
    return showDialog<WeeklyRefreshFreezeWindow>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(I18n.weeklyRefreshFreezeWindows.tr),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      child: Text(widget.weekdayLabel(index + 1)),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => weekday = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _timeTile(
                  dialogContext: dialogContext,
                  label: I18n.weeklyRefreshBoundaryStart.tr,
                  value: start,
                  onChanged: (value) => setDialogState(() => start = value),
                ),
                _timeTile(
                  dialogContext: dialogContext,
                  label: I18n.weeklyRefreshBoundaryEnd.tr,
                  value: end,
                  onChanged: (value) => setDialogState(() => end = value),
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
              onPressed: _seconds(start) >= _seconds(end)
                  ? null
                  : () => Navigator.of(dialogContext).pop(
                        WeeklyRefreshFreezeWindow(
                          weekday: weekday,
                          start: start.format(),
                          end: end.format(),
                        ),
                      ),
              child: Text(I18n.confirm.tr),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editBoundary(WeeklyScheduleEntry entry) async {
    final key = _entryKey(entry.task, entry.weekday);
    final initial = _boundaries[key];
    var start = WeeklyScheduleClockTime.parse(initial?.start ?? '00:00:00');
    var end = WeeklyScheduleClockTime.parse(initial?.end ?? '23:59:59');
    final boundary = await showDialog<WeeklyRefreshBoundary>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${entry.task.tr} | ${widget.weekdayLabel(entry.weekday)}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _timeTile(
                  dialogContext: dialogContext,
                  label: I18n.weeklyRefreshBoundaryStart.tr,
                  value: start,
                  onChanged: (value) => setDialogState(() => start = value),
                ),
                _timeTile(
                  dialogContext: dialogContext,
                  label: I18n.weeklyRefreshBoundaryEnd.tr,
                  value: end,
                  onChanged: (value) => setDialogState(() => end = value),
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
              onPressed: _seconds(start) > _seconds(end)
                  ? null
                  : () => Navigator.of(dialogContext).pop(
                        WeeklyRefreshBoundary(
                          task: entry.task,
                          weekday: entry.weekday,
                          start: start.format(),
                          end: end.format(),
                        ),
                      ),
              child: Text(I18n.confirm.tr),
            ),
          ],
        ),
      ),
    );
    if (boundary != null && mounted) {
      setState(() {
        _boundaries[key] = boundary;
        _preview = null;
      });
    }
  }

  Widget _timeTile({
    required BuildContext dialogContext,
    required String label,
    required WeeklyScheduleClockTime value,
    required ValueChanged<WeeklyScheduleClockTime> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule_rounded),
      title: Text(label),
      trailing: Text(value.format()),
      onTap: () async {
        final selected = await showWeeklyScheduleTimePicker(
          context: dialogContext,
          initialTime: value,
        );
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }

  String _entryKey(String task, int weekday) => '$weekday\u0000$task';

  int _seconds(WeeklyScheduleClockTime value) {
    return value.hour * 3600 + value.minute * 60 + value.second;
  }
}
