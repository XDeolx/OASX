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
  bool _showClimbClickPath = true;

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
          onRefresh: controller.refreshAnalysis,
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
    final taskNames = analysis.taskNames;
    if (_selectedTaskName.isNotEmpty &&
        !taskNames.contains(_selectedTaskName)) {
      _selectedTaskName = '';
    }
    final filteredAnalysis = analysis.filteredByTask(_selectedTaskName);
    final durationValues = filteredAnalysis.taskClickDurations.values
        .expand((values) => values)
        .toList(growable: false);
    final allWaitCount = filteredAnalysis.randomWaits.values
        .fold<int>(0, (total, values) => total + values.length);
    final tasksWithClicks = filteredAnalysis.clicks
        .map((event) => event.taskName)
        .toSet()
        .length;
    final climbSettlement = filteredAnalysis.climbSettlementAnalysis;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      children: [
        _PrivacyNotice(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  _AnalysisSelector(
                    icon: Icons.calendar_today_outlined,
                    tooltip: I18n.behaviorAnalysisTime.tr,
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
                  _AnalysisSelector(
                    icon: Icons.filter_alt_outlined,
                    tooltip: I18n.behaviorAnalysisTaskFilter.tr,
                    value: _selectedTaskName,
                    items: [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text(I18n.behaviorAnalysisAllTasks.tr),
                      ),
                      ...taskNames.map(
                        (name) => DropdownMenuItem<String>(
                          value: name,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              name.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTaskName = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: I18n.behaviorAnalysisRefresh.tr,
              onPressed: controller.analysisLoading.value
                  ? null
                  : controller.refreshAnalysis,
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
              value: filteredAnalysis.totalClicks.toString(),
              label: I18n.behaviorAnalysisClickCount.tr,
            ),
            _SummaryValue(
              value: allWaitCount.toString(),
              label: I18n.behaviorAnalysisWaitCount.tr,
            ),
            _SummaryValue(
              value: tasksWithClicks.toString(),
              label: I18n.behaviorAnalysisTaskCount.tr,
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (climbSettlement.hasData) ...[
          _ClimbSettlementSection(
            analysis: climbSettlement,
            showPath: _showClimbClickPath,
            onShowPathChanged: (value) {
              setState(() => _showClimbClickPath = value);
            },
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 22),
        ],
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
        if (filteredAnalysis.clicks.isEmpty)
          _EmptySection(message: I18n.behaviorAnalysisNoClicks.tr)
        else
          BehaviorClickPathChart(
            points: filteredAnalysis.clicks,
            showPath: controller.showClickPath.value,
          ),
        const SizedBox(height: 22),
        _SectionHeader(title: I18n.behaviorAnalysisRandomWaits.tr),
        const SizedBox(height: 8),
        if (filteredAnalysis.randomWaitEvents.isEmpty)
          _EmptySection(message: I18n.behaviorAnalysisNoWaits.tr)
        else
          BehaviorRandomWaitChart(events: filteredAnalysis.randomWaitEvents),
        const SizedBox(height: 22),
        _SectionHeader(title: I18n.behaviorAnalysisTaskDurations.tr),
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
        if (filteredAnalysis.taskRuns.isEmpty &&
            filteredAnalysis.scriptStarts.isEmpty &&
            filteredAnalysis.anomalies.isEmpty)
          _EmptySection(message: I18n.behaviorAnalysisNoTimeline.tr)
        else
          BehaviorTimelineChart(
            dateKey: filteredAnalysis.dateKey,
            taskStarts: filteredAnalysis.taskStarts,
            taskRuns: filteredAnalysis.taskRuns,
            scriptStarts: filteredAnalysis.scriptStarts,
            anomalies: filteredAnalysis.anomalies,
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

class _ClimbSettlementSection extends StatelessWidget {
  const _ClimbSettlementSection({
    required this.analysis,
    required this.showPath,
    required this.onShowPathChanged,
  });

  static const _expectedWeights = {
    'A': 5,
    'B': 5,
    'C': 25,
    'D': 20,
    'E': 45,
  };

  final BehaviorClimbSettlementAnalysis analysis;
  final bool showPath;
  final ValueChanged<bool> onShowPathChanged;

  @override
  Widget build(BuildContext context) {
    final randomBursts = analysis.bursts
        .where((event) => event.mode == 'random')
        .toList(growable: false);
    final detailDecisions = analysis.decisions
        .where((event) => event.mode == 'detail')
        .toList(growable: false);
    final detailCount = detailDecisions.isEmpty
        ? analysis.detailViews.length
        : detailDecisions.length;
    final latestTemplate = analysis.templates.isEmpty
        ? ''
        : analysis.templates.last.detail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: I18n.behaviorAnalysisClimbSettlement.tr),
        const SizedBox(height: 5),
        Text(
          I18n.behaviorAnalysisClimbSettlementDescription.tr,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _SummaryValue(
              value: analysis.templates.length.toString(),
              label: I18n.behaviorAnalysisClimbTemplates.tr,
            ),
            _SummaryValue(
              value: analysis.decisions.length.toString(),
              label: I18n.behaviorAnalysisClimbBattles.tr,
            ),
            _SummaryValue(
              value: analysis.weightedClicks.length.toString(),
              label: I18n.behaviorAnalysisClimbWeighted.tr,
            ),
            _SummaryValue(
              value: detailCount.toString(),
              label: I18n.behaviorAnalysisClimbDetails.tr,
            ),
            _SummaryValue(
              value: randomBursts.length.toString(),
              label: I18n.behaviorAnalysisClimbBursts.tr,
            ),
          ],
        ),
        if (latestTemplate.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.grid_view_outlined, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${I18n.behaviorAnalysisClimbLatestTemplate.tr}：$latestTemplate',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
        if (detailDecisions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${I18n.behaviorAnalysisClimbDetailBattles.tr}：'
            '${detailDecisions.map((event) => '#${event.battleNumber} (${event.detailProgress}/${event.detailTarget})').join('、')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (randomBursts.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '${I18n.behaviorAnalysisClimbBurstBattles.tr}：'
            '${randomBursts.map((event) => '#${event.battleNumber}').join('、')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 18),
        _SectionHeader(
          title: I18n.behaviorAnalysisClimbCategoryDistribution.tr,
        ),
        const SizedBox(height: 8),
        if (analysis.weightedClicks.isEmpty)
          _EmptySection(message: I18n.behaviorAnalysisClimbNoWeighted.tr)
        else
          _ClimbCategoryDistribution(
            counts: analysis.categoryCounts,
            expectedWeights: _expectedWeights,
          ),
        const SizedBox(height: 18),
        _SectionHeader(
          title: I18n.behaviorAnalysisClimbClickPath.tr,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(I18n.behaviorAnalysisShowPath.tr),
              const SizedBox(width: 6),
              Switch(value: showPath, onChanged: onShowPathChanged),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (analysis.clicks.isEmpty)
          _EmptySection(message: I18n.behaviorAnalysisClimbNoClicks.tr)
        else
          BehaviorClickPathChart(
            points: analysis.clicks,
            showPath: showPath,
          ),
        const SizedBox(height: 18),
        _SectionHeader(title: I18n.behaviorAnalysisClimbWaits.tr),
        const SizedBox(height: 8),
        if (analysis.waits.isEmpty)
          _EmptySection(message: I18n.behaviorAnalysisClimbNoWaits.tr)
        else
          BehaviorRandomWaitChart(events: analysis.waits),
      ],
    );
  }
}

class _ClimbCategoryDistribution extends StatelessWidget {
  const _ClimbCategoryDistribution({
    required this.counts,
    required this.expectedWeights,
  });

  final Map<String, int> counts;
  final Map<String, int> expectedWeights;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final category in const ['A', 'B', 'C', 'D', 'E']) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final count = counts[category] ?? 0;
              final proportion = total == 0 ? 0.0 : count / total;
              final valueText = '$count  '
                  '${I18n.behaviorAnalysisClimbActual.tr} '
                  '${(proportion * 100).toStringAsFixed(1)}%  ·  '
                  '${I18n.behaviorAnalysisClimbExpected.tr} '
                  '${expectedWeights[category]}%';
              final progress = ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: proportion,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              );
              final categoryLabel = Text(
                category,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              );
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        categoryLabel,
                        const Spacer(),
                        Text(
                          valueText,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    progress,
                  ],
                );
              }
              return Row(
                children: [
                  SizedBox(width: 26, child: categoryLabel),
                  Expanded(child: progress),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 170,
                    child: Text(
                      valueText,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              );
            },
          ),
          if (category != 'E') const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AnalysisSelector extends StatelessWidget {
  const _AnalysisSelector({
    required this.icon,
    required this.tooltip,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String tooltip;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 7),
          DropdownButton<String>(
            value: value,
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
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
