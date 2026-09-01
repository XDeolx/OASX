import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/behavior_analysis_controller.dart';
import 'package:oasx/modules/home/models/behavior_analysis_models.dart';
import 'package:oasx/modules/home/widgets/behavior_analysis_charts.dart';
import 'package:oasx/translation/i18n_content.dart';

class BehaviorAnalysisPanel extends StatefulWidget {
  const BehaviorAnalysisPanel({super.key});

  @override
  State<BehaviorAnalysisPanel> createState() => _BehaviorAnalysisPanelState();
}

class _BehaviorAnalysisPanelState extends State<BehaviorAnalysisPanel> {
  HomeBehaviorAnalysisController get controller =>
      Get.find<HomeBehaviorAnalysisController>();

  String _selectedTaskName = '';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final analysis = controller.analysis.value;
      final loading = controller.datesLoading.value ||
          controller.analysisLoading.value;
      final dates = controller.availableDateKeys.toList(growable: false);
      if (analysis == null) {
        return _BehaviorPlaceholder(
          loading: loading,
          message: _resolvePlaceholder(dates),
          onRefresh: controller.refresh,
        );
      }
      return _buildAnalysis(context, analysis, dates);
    });
  }

  Widget _buildAnalysis(
    BuildContext context,
    BehaviorAnalysisDay analysis,
    List<String> dates,
  ) {
    final taskNames = analysis.taskClickDurations.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toList()
      ..sort((left, right) => left.compareTo(right));
    final selectedTask = taskNames.contains(_selectedTaskName)
        ? _selectedTaskName
        : (taskNames.isEmpty ? '' : taskNames.first);
    _selectedTaskName = selectedTask;
    final durationValues =
        analysis.taskClickDurations[selectedTask] ?? const <double>[];
    final allWaitCount = analysis.randomWaits.values
        .fold<int>(0, (total, values) => total + values.length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      children: [
        _PrivacyNotice(),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            DropdownButton<String>(
              value: controller.selectedDateKey.value,
              items: dates
                  .map(
                    (date) => DropdownMenuItem<String>(
                      value: date,
                      child: Text(date),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  controller.selectDate(value);
                }
              },
            ),
            IconButton(
              tooltip: I18n.behaviorAnalysisRefresh.tr,
              onPressed: controller.analysisLoading.value
                  ? null
                  : controller.refresh,
              icon: controller.analysisLoading.value
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _SummaryValue(
              value: analysis.totalClicks.toString(),
              label: I18n.behaviorAnalysisClickCount.tr,
            ),
            _SummaryValue(
              value: allWaitCount.toString(),
              label: I18n.behaviorAnalysisWaitCount.tr,
            ),
            _SummaryValue(
              value: taskNames.length.toString(),
              label: I18n.behaviorAnalysisTaskCount.tr,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionHeader(
          title: I18n.behaviorAnalysisClickPath.tr,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(I18n.behaviorAnalysisShowPath.tr),
              const SizedBox(width: 6),
              Switch(
                value: controller.showClickPath.value,
                onChanged: (_) => controller.toggleClickPath(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (analysis.clicks.isEmpty)
          _EmptySection(message: I18n.behaviorAnalysisNoClicks.tr)
        else
          BehaviorClickPathChart(
            points: analysis.clicks,
            showPath: controller.showClickPath.value,
          ),
        const SizedBox(height: 22),
        _SectionHeader(title: I18n.behaviorAnalysisRandomWaits.tr),
        const SizedBox(height: 8),
        if (analysis.randomWaitEvents.isEmpty)
          _EmptySection(message: I18n.behaviorAnalysisNoWaits.tr)
        else
          BehaviorRandomWaitChart(events: analysis.randomWaitEvents),
        const SizedBox(height: 22),
        _SectionHeader(
          title: I18n.behaviorAnalysisTaskDurations.tr,
          trailing: taskNames.isEmpty
              ? null
              : DropdownButton<String>(
                  value: selectedTask,
                  items: taskNames
                      .map(
                        (name) => DropdownMenuItem<String>(
                          value: name,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              name.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTaskName = value);
                    }
                  },
                ),
        ),
        const SizedBox(height: 8),
        if (durationValues.isEmpty)
          _EmptySection(message: I18n.behaviorAnalysisNoDurations.tr)
        else ...[
          BehaviorDurationHistogram(values: durationValues),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${durationValues.length} ${I18n.behaviorAnalysisSamples.tr} · '
              '${_median(durationValues).toStringAsFixed(3)} s',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
        const SizedBox(height: 22),
        _SectionHeader(title: I18n.behaviorAnalysisTimeline.tr),
        const SizedBox(height: 8),
        if (analysis.taskRuns.isEmpty &&
            analysis.scriptStarts.isEmpty &&
            analysis.anomalies.isEmpty)
          _EmptySection(message: I18n.behaviorAnalysisNoTimeline.tr)
        else
          BehaviorTimelineChart(
            dateKey: analysis.dateKey,
            taskStarts: analysis.taskStarts,
            taskRuns: analysis.taskRuns,
            scriptStarts: analysis.scriptStarts,
            anomalies: analysis.anomalies,
          ),
      ],
    );
  }

  String _resolvePlaceholder(List<String> dates) {
    if (controller.datesLoading.value || controller.analysisLoading.value) {
      return I18n.behaviorAnalysisLoading.tr;
    }
    final error = controller.lastErrorMessage.value;
    if (error == 'behavior_analysis_local_only') {
      return I18n.behaviorAnalysisLocalOnly.tr;
    }
    if (error == 'behavior_analysis_root_missing') {
      return I18n.behaviorAnalysisRootMissing.tr;
    }
    if (error.isNotEmpty) {
      return '${I18n.behaviorAnalysisReadFailed.tr}\n$error';
    }
    if (dates.isEmpty) {
      return I18n.behaviorAnalysisNoLogs.tr;
    }
    return I18n.behaviorAnalysisLoading.tr;
  }

  double _median(List<double> values) {
    final sorted = List<double>.from(values)..sort();
    if (sorted.isEmpty) {
      return 0;
    }
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }
}

class _PrivacyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip_outlined, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              I18n.behaviorAnalysisPrivacyNotice.tr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}

class _BehaviorPlaceholder extends StatelessWidget {
  const _BehaviorPlaceholder({
    required this.loading,
    required this.message,
    required this.onRefresh,
  });

  final bool loading;
  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator()
            else
              const Icon(Icons.insights_rounded, size: 36),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(message, textAlign: TextAlign.center),
            ),
            if (!loading) ...[
              const SizedBox(height: 12),
              IconButton(
                tooltip: I18n.behaviorAnalysisRefresh.tr,
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
