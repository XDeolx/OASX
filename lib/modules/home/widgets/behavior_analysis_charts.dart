import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/models/behavior_analysis_models.dart';
import 'package:oasx/translation/i18n_content.dart';

const Size _clickSourceSize = Size(1280, 720);

class BehaviorClickPathChart extends StatefulWidget {
  const BehaviorClickPathChart({
    super.key,
    required this.points,
    required this.showPath,
  });

  final List<BehaviorClickPoint> points;
  final bool showPath;

  @override
  State<BehaviorClickPathChart> createState() => _BehaviorClickPathChartState();
}

class _BehaviorClickPathChartState extends State<BehaviorClickPathChart> {
  static const double _sourceCellSize = 48;
  final Map<int, List<int>> _pointBins = {};
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _rebuildBins();
  }

  @override
  void didUpdateWidget(covariant BehaviorClickPathChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.points, widget.points)) {
      _hoveredIndex = null;
      _rebuildBins();
    }
  }

  void _rebuildBins() {
    _pointBins.clear();
    for (var index = 0; index < widget.points.length; index++) {
      final point = widget.points[index];
      final key = _binKey(
        point.x ~/ _sourceCellSize,
        point.y ~/ _sourceCellSize,
      );
      _pointBins.putIfAbsent(key, () => <int>[]).add(index);
    }
  }

  int _binKey(int x, int y) => x * 1000 + y;

  void _handleHover(Offset localPosition, Size size) {
    if (size.isEmpty || widget.points.isEmpty) {
      return;
    }
    final sourcePosition = Offset(
      localPosition.dx / size.width * _clickSourceSize.width,
      localPosition.dy / size.height * _clickSourceSize.height,
    );
    final sourceThreshold = math.max(
      16 / size.width * _clickSourceSize.width,
      16 / size.height * _clickSourceSize.height,
    ).toDouble();
    final range = (sourceThreshold / _sourceCellSize).ceil() + 1;
    final centerX = sourcePosition.dx ~/ _sourceCellSize;
    final centerY = sourcePosition.dy ~/ _sourceCellSize;
    var bestDistance = double.infinity;
    int? bestIndex;
    for (var dx = -range; dx <= range; dx++) {
      for (var dy = -range; dy <= range; dy++) {
        for (final index in
            _pointBins[_binKey(centerX + dx, centerY + dy)] ?? const <int>[]) {
          final point = widget.points[index];
          final screenOffset = Offset(
            point.x / _clickSourceSize.width * size.width,
            point.y / _clickSourceSize.height * size.height,
          );
          final distance = (screenOffset - localPosition).distance;
          if (distance <= 16 && distance < bestDistance) {
            bestDistance = distance;
            bestIndex = index;
          }
        }
      }
    }
    if (bestIndex != _hoveredIndex) {
      setState(() => _hoveredIndex = bestIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final point = _hoveredIndex == null
              ? null
              : widget.points[_hoveredIndex!];
          final pointOffset = point == null
              ? null
              : Offset(
                  point.x / _clickSourceSize.width * size.width,
                  point.y / _clickSourceSize.height * size.height,
                );
          return MouseRegion(
            cursor: point == null ? MouseCursor.defer : SystemMouseCursors.click,
            onHover: (event) => _handleHover(event.localPosition, size),
            onExit: (_) {
              if (_hoveredIndex != null) {
                setState(() => _hoveredIndex = null);
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _ClickPathPainter(
                      points: widget.points,
                      showPath: widget.showPath,
                      hoveredIndex: _hoveredIndex,
                      colorScheme: Theme.of(context).colorScheme,
                    ),
                  ),
                ),
                if (point != null && pointOffset != null)
                  _hoverCard(
                    context,
                    pointOffset,
                    size,
                    [
                      '${I18n.behaviorAnalysisTime.tr}：${_formatTime(point.time)}',
                      '${I18n.behaviorAnalysisTask.tr}：${point.taskName.tr}',
                      '${I18n.behaviorAnalysisTarget.tr}：${point.label}',
                      '${I18n.behaviorAnalysisCoordinates.tr}：(${point.x}, ${point.y})',
                      '${I18n.behaviorAnalysisDuration.tr}：${point.durationSeconds.toStringAsFixed(3)} s',
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ClickPathPainter extends CustomPainter {
  const _ClickPathPainter({
    required this.points,
    required this.showPath,
    required this.hoveredIndex,
    required this.colorScheme,
  });

  final List<BehaviorClickPoint> points;
  final bool showPath;
  final int? hoveredIndex;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = Offset.zero & size;
    canvas.drawRect(
      frame,
      Paint()..color = colorScheme.surfaceContainerLowest,
    );
    final gridPaint = Paint()
      ..strokeWidth = 1
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.45);
    for (var column = 0; column <= 8; column++) {
      final x = size.width * column / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var row = 0; row <= 8; row++) {
      final y = size.height * row / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (points.isEmpty) {
      return;
    }

    Offset scaled(BehaviorClickPoint point) => Offset(
          point.x / _clickSourceSize.width * size.width,
          point.y / _clickSourceSize.height * size.height,
        );

    if (showPath && points.length > 1) {
      final first = scaled(points.first);
      final path = Path()..moveTo(first.dx, first.dy);
      for (final point in points.skip(1)) {
        final offset = scaled(point);
        path.lineTo(offset.dx, offset.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.45, size.width / 1800).toDouble()
          ..color = colorScheme.primary.withValues(alpha: 0.075),
      );
    }

    final radius = (size.width / 520).clamp(1.1, 2.4).toDouble();
    for (var index = 0; index < points.length; index++) {
      final isHovered = hoveredIndex == index;
      canvas.drawCircle(
        scaled(points[index]),
        isHovered ? radius + 3 : radius,
        Paint()
          ..color = isHovered
              ? colorScheme.primary
              : colorScheme.error.withValues(alpha: 0.55),
      );
    }
    canvas.drawRect(
      frame.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colorScheme.outlineVariant,
    );
  }

  @override
  bool shouldRepaint(_ClickPathPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.showPath != showPath ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class BehaviorRandomWaitChart extends StatefulWidget {
  const BehaviorRandomWaitChart({super.key, required this.events});

  final List<BehaviorRandomWaitEvent> events;

  @override
  State<BehaviorRandomWaitChart> createState() => _BehaviorRandomWaitChartState();
}

class _BehaviorRandomWaitChartState extends State<BehaviorRandomWaitChart> {
  int? _hoveredIndex;

  void _handleHover(Offset position, Size size) {
    final layout = _buildWaitLayout(widget.events, size);
    var bestDistance = double.infinity;
    int? bestIndex;
    for (final mark in layout.marks) {
      final distance = (mark.offset - position).distance;
      if (distance <= 14 && distance < bestDistance) {
        bestDistance = distance;
        bestIndex = mark.eventIndex;
      }
    }
    if (bestIndex != _hoveredIndex) {
      setState(() => _hoveredIndex = bestIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.events.map((event) => event.label).toSet();
    final height = math.max(190.0, labels.length * 54.0 + 42.0).toDouble();
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final layout = _buildWaitLayout(widget.events, size);
          final event = _hoveredIndex == null
              ? null
              : widget.events[_hoveredIndex!];
          final mark = _hoveredIndex == null
              ? null
              : layout.marks
                  .where((item) => item.eventIndex == _hoveredIndex)
                  .firstOrNull;
          return MouseRegion(
            cursor: event == null ? MouseCursor.defer : SystemMouseCursors.click,
            onHover: (value) => _handleHover(value.localPosition, size),
            onExit: (_) {
              if (_hoveredIndex != null) {
                setState(() => _hoveredIndex = null);
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _RandomWaitPainter(
                      layout: layout,
                      events: widget.events,
                      hoveredIndex: _hoveredIndex,
                      colorScheme: Theme.of(context).colorScheme,
                      textStyle:
                          Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
                      textDirection: Directionality.of(context),
                    ),
                  ),
                ),
                if (event != null && mark != null)
                  _hoverCard(context, mark.offset, size, [
                    '${I18n.behaviorAnalysisTime.tr}：${_formatTime(event.time)}',
                    '${I18n.behaviorAnalysisCategory.tr}：${event.label}',
                    '${I18n.behaviorAnalysisDuration.tr}：${_formatWaitDuration(event.delaySeconds)}',
                    '${I18n.behaviorAnalysisTask.tr}：${event.taskName.tr}',
                  ]),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WaitMark {
  const _WaitMark(this.eventIndex, this.offset);

  final int eventIndex;
  final Offset offset;
}

class _WaitLayout {
  const _WaitLayout({
    required this.labels,
    required this.marks,
    required this.labelWidth,
    required this.plotWidth,
    required this.plotHeight,
    required this.axisMax,
    required this.rowHeight,
  });

  final List<String> labels;
  final List<_WaitMark> marks;
  final double labelWidth;
  final double plotWidth;
  final double plotHeight;
  final double axisMax;
  final double rowHeight;
}

_WaitLayout _buildWaitLayout(
  List<BehaviorRandomWaitEvent> events,
  Size size,
) {
  final labels = events.map((event) => event.label).toSet().toList()..sort();
  final labelWidth = math.min(150.0, size.width * 0.36).toDouble();
  final plotWidth = math.max(1.0, size.width - labelWidth - 12).toDouble();
  final plotHeight = math.max(1.0, size.height - 40).toDouble();
  final maxValue = events.fold<double>(
    0,
    (current, event) => math.max(current, event.delaySeconds).toDouble(),
  );
  final axisMax = math.max(1.0, (maxValue * 1.08).ceilToDouble()).toDouble();
  final rowHeight = labels.isEmpty ? plotHeight : plotHeight / labels.length;
  final labelIndexes = {
    for (var index = 0; index < labels.length; index++) labels[index]: index,
  };
  final groupIndexes = <String, int>{};
  final marks = <_WaitMark>[];
  for (var index = 0; index < events.length; index++) {
    final event = events[index];
    final row = labelIndexes[event.label] ?? 0;
    final itemIndex = groupIndexes.update(
      event.label,
      (value) => value + 1,
      ifAbsent: () => 0,
    );
    final centerY = 10 + rowHeight * (row + 0.5);
    final jitter = ((itemIndex * 17) % 13 - 6) *
        math.min(1.15, rowHeight / 20).toDouble();
    marks.add(
      _WaitMark(
        index,
        Offset(
          labelWidth + event.delaySeconds / axisMax * plotWidth,
          centerY + jitter,
        ),
      ),
    );
  }
  return _WaitLayout(
    labels: labels,
    marks: marks,
    labelWidth: labelWidth,
    plotWidth: plotWidth,
    plotHeight: plotHeight,
    axisMax: axisMax,
    rowHeight: rowHeight,
  );
}

class _RandomWaitPainter extends CustomPainter {
  const _RandomWaitPainter({
    required this.layout,
    required this.events,
    required this.hoveredIndex,
    required this.colorScheme,
    required this.textStyle,
    required this.textDirection,
  });

  final _WaitLayout layout;
  final List<BehaviorRandomWaitEvent> events;
  final int? hoveredIndex;
  final ColorScheme colorScheme;
  final TextStyle textStyle;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..strokeWidth = 1
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.55);
    for (var tick = 0; tick <= 5; tick++) {
      final x = layout.labelWidth + layout.plotWidth * tick / 5;
      canvas.drawLine(
        Offset(x, 10),
        Offset(x, 10 + layout.plotHeight),
        gridPaint,
      );
      _paintText(
        canvas,
        (layout.axisMax * tick / 5).toStringAsFixed(1),
        Offset(x, 10 + layout.plotHeight + 17),
        textStyle,
        textDirection,
        anchor: _TextAnchor.center,
      );
    }
    for (var row = 0; row < layout.labels.length; row++) {
      final label = layout.labels[row];
      final centerY = 10 + layout.rowHeight * (row + 0.5);
      _paintText(
        canvas,
        label,
        Offset(layout.labelWidth - 8, centerY),
        textStyle,
        textDirection,
        anchor: _TextAnchor.right,
        maxWidth: layout.labelWidth - 12,
      );
      final values = events
          .where((event) => event.label == label)
          .map((event) => event.delaySeconds)
          .toList()
        ..sort();
      if (values.isNotEmpty) {
        final middle = values.length ~/ 2;
        final median = values.length.isOdd
            ? values[middle]
            : (values[middle - 1] + values[middle]) / 2;
        final medianX =
            layout.labelWidth + median / layout.axisMax * layout.plotWidth;
        canvas.drawLine(
          Offset(medianX, centerY - layout.rowHeight * 0.25),
          Offset(medianX, centerY + layout.rowHeight * 0.25),
          Paint()
            ..strokeWidth = 3
            ..color = colorScheme.primary,
        );
      }
    }
    for (final mark in layout.marks) {
      final hovered = mark.eventIndex == hoveredIndex;
      canvas.drawCircle(
        mark.offset,
        hovered ? 6 : 3.2,
        Paint()
          ..color = hovered
              ? colorScheme.primary
              : colorScheme.tertiary.withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_RandomWaitPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.events != events ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class BehaviorDurationHistogram extends StatefulWidget {
  const BehaviorDurationHistogram({super.key, required this.values});

  final List<double> values;

  @override
  State<BehaviorDurationHistogram> createState() =>
      _BehaviorDurationHistogramState();
}

class _BehaviorDurationHistogramState extends State<BehaviorDurationHistogram> {
  int? _hoveredBin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final data = _buildHistogram(widget.values, size);
          final hoveredBin = _hoveredBin != null && _hoveredBin! < data.bins.length
              ? _hoveredBin
              : null;
          return MouseRegion(
            cursor:
                hoveredBin == null ? MouseCursor.defer : SystemMouseCursors.click,
            onHover: (event) {
              int? next;
              if (data.plotRect.contains(event.localPosition)) {
                next = ((event.localPosition.dx - data.plotRect.left) /
                        data.barWidth)
                    .floor()
                    .clamp(0, data.bins.length - 1)
                    .toInt();
              }
              if (next != _hoveredBin) {
                setState(() => _hoveredBin = next);
              }
            },
            onExit: (_) {
              if (_hoveredBin != null) {
                setState(() => _hoveredBin = null);
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _DurationHistogramPainter(
                      data: data,
                      hoveredBin: hoveredBin,
                      colorScheme: Theme.of(context).colorScheme,
                      textStyle:
                          Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
                      textDirection: Directionality.of(context),
                    ),
                  ),
                ),
                if (hoveredBin != null)
                  _hoverCard(
                    context,
                    data.barRects[hoveredBin].topCenter,
                    size,
                    [
                      '${I18n.behaviorAnalysisRange.tr}：${data.binStart(hoveredBin).toStringAsFixed(3)}–${data.binEnd(hoveredBin).toStringAsFixed(3)} s',
                      '${I18n.behaviorAnalysisCount.tr}：${data.bins[hoveredBin]}',
                      '${I18n.behaviorAnalysisProportion.tr}：${(data.bins[hoveredBin] / widget.values.length * 100).toStringAsFixed(1)}%',
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistogramData {
  const _HistogramData({
    required this.bins,
    required this.barRects,
    required this.plotRect,
    required this.axisMax,
    required this.maxCount,
    required this.barWidth,
  });

  final List<int> bins;
  final List<Rect> barRects;
  final Rect plotRect;
  final double axisMax;
  final int maxCount;
  final double barWidth;

  double binStart(int index) => axisMax * index / bins.length;
  double binEnd(int index) => axisMax * (index + 1) / bins.length;
}

_HistogramData _buildHistogram(List<double> values, Size size) {
  const left = 44.0;
  const right = 10.0;
  const top = 10.0;
  const bottom = 34.0;
  final plotWidth = math.max(1.0, size.width - left - right).toDouble();
  final plotHeight = math.max(1.0, size.height - top - bottom).toDouble();
  final maxDuration = values.fold<double>(
    0,
    (current, value) => math.max(current, value).toDouble(),
  );
  final axisMax =
      math.max(0.2, (maxDuration / 0.05).ceil() * 0.05).toDouble();
  final binCount = math.min(
    24,
    math.max(10, (axisMax / 0.01).ceil()),
  ).toInt();
  final bins = List<int>.filled(binCount, 0);
  for (final value in values) {
    final index = math.min(
      binCount - 1,
      (value / axisMax * binCount).floor(),
    ).toInt();
    bins[index]++;
  }
  final maxCount = math.max(
    1,
    bins.fold<int>(0, (current, value) => math.max(current, value).toInt()),
  ).toInt();
  final barWidth = plotWidth / binCount;
  final gap = math.min(2.0, barWidth * 0.15).toDouble();
  final barRects = <Rect>[];
  for (var index = 0; index < bins.length; index++) {
    final height = bins[index] / maxCount * plotHeight;
    barRects.add(
      Rect.fromLTWH(
        left + index * barWidth + gap / 2,
        top + plotHeight - height,
        math.max(0.5, barWidth - gap).toDouble(),
        height,
      ),
    );
  }
  return _HistogramData(
    bins: bins,
    barRects: barRects,
    plotRect: Rect.fromLTWH(left, top, plotWidth, plotHeight),
    axisMax: axisMax,
    maxCount: maxCount,
    barWidth: barWidth,
  );
}

class _DurationHistogramPainter extends CustomPainter {
  const _DurationHistogramPainter({
    required this.data,
    required this.hoveredBin,
    required this.colorScheme,
    required this.textStyle,
    required this.textDirection,
  });

  final _HistogramData data;
  final int? hoveredBin;
  final ColorScheme colorScheme;
  final TextStyle textStyle;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..strokeWidth = 1
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.5);
    for (var tick = 0; tick <= 4; tick++) {
      final y = data.plotRect.bottom - data.plotRect.height * tick / 4;
      canvas.drawLine(
        Offset(data.plotRect.left, y),
        Offset(data.plotRect.right, y),
        gridPaint,
      );
      _paintText(
        canvas,
        (data.maxCount * tick / 4).round().toString(),
        Offset(data.plotRect.left - 6, y),
        textStyle,
        textDirection,
        anchor: _TextAnchor.right,
      );
    }
    for (var index = 0; index < data.barRects.length; index++) {
      canvas.drawRect(
        data.barRects[index],
        Paint()
          ..color = index == hoveredBin
              ? colorScheme.tertiary
              : colorScheme.primary.withValues(alpha: 0.75),
      );
    }
    for (var tick = 0; tick <= 4; tick++) {
      final x = data.plotRect.left + data.plotRect.width * tick / 4;
      _paintText(
        canvas,
        (data.axisMax * tick / 4).toStringAsFixed(2),
        Offset(x, data.plotRect.bottom + 13),
        textStyle,
        textDirection,
        anchor: _TextAnchor.center,
      );
    }
  }

  @override
  bool shouldRepaint(_DurationHistogramPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.hoveredBin != hoveredBin ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class BehaviorTimelineChart extends StatefulWidget {
  const BehaviorTimelineChart({
    super.key,
    required this.dateKey,
    required this.taskStarts,
    required this.taskRuns,
    required this.scriptStarts,
    required this.anomalies,
  });

  final String dateKey;
  final List<BehaviorTaskStart> taskStarts;
  final List<BehaviorTaskRun> taskRuns;
  final List<BehaviorScriptStart> scriptStarts;
  final List<BehaviorAnomalyEvent> anomalies;

  @override
  State<BehaviorTimelineChart> createState() => _BehaviorTimelineChartState();
}

class _BehaviorTimelineChartState extends State<BehaviorTimelineChart> {
  _TimelineMark? _hoveredMark;

  @override
  void didUpdateWidget(covariant BehaviorTimelineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateKey != widget.dateKey ||
        !identical(oldWidget.taskRuns, widget.taskRuns) ||
        !identical(oldWidget.scriptStarts, widget.scriptStarts) ||
        !identical(oldWidget.anomalies, widget.anomalies)) {
      _hoveredMark = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final layout = _buildTimelineLayout(
            widget.dateKey,
            widget.taskStarts,
            widget.taskRuns,
            widget.scriptStarts,
            widget.anomalies,
            size,
          );
          return MouseRegion(
            cursor: _hoveredMark == null
                ? MouseCursor.defer
                : SystemMouseCursors.click,
            onHover: (event) {
              _TimelineMark? next;
              var nearest = double.infinity;
              for (final mark in layout.marks) {
                final distance = mark.endOffset == null
                    ? (mark.offset - event.localPosition).distance
                    : _distanceToHorizontalSegment(
                        event.localPosition,
                        mark.offset,
                        mark.endOffset!,
                      );
                if (distance <= 15 && distance < nearest) {
                  nearest = distance;
                  next = mark;
                }
              }
              if (next != _hoveredMark) {
                setState(() => _hoveredMark = next);
              }
            },
            onExit: (_) {
              if (_hoveredMark != null) {
                setState(() => _hoveredMark = null);
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _TimelinePainter(
                      layout: layout,
                      hoveredMark: _hoveredMark,
                      colorScheme: Theme.of(context).colorScheme,
                      textStyle:
                          Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
                      textDirection: Directionality.of(context),
                    ),
                  ),
                ),
                if (_hoveredMark != null)
                  _hoverCard(
                    context,
                    _hoveredMark!.offset,
                    size,
                    _timelineTooltip(_hoveredMark!),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _timelineTooltip(_TimelineMark mark) {
    switch (mark.kind) {
      case _TimelineMarkKind.anomaly:
        final event = widget.anomalies[mark.sourceIndex];
        final title = event.type == 'atx_restart'
            ? I18n.behaviorAnalysisAtxRestart.tr
            : I18n.behaviorAnalysisAnomalyRestart.tr;
        return [
          title,
          '${I18n.behaviorAnalysisTime.tr}：${_formatTime(event.time)}',
          if (event.taskName.isNotEmpty)
            '${I18n.behaviorAnalysisTask.tr}：${event.taskName.tr}',
          if (event.note.isNotEmpty)
            '${I18n.behaviorAnalysisNote.tr}：${event.note}',
        ];
      case _TimelineMarkKind.task:
        final event = widget.taskRuns[mark.sourceIndex];
        return [
          I18n.behaviorAnalysisTaskRun.tr,
          '${I18n.behaviorAnalysisTask.tr}：${event.taskName.tr}',
          '${I18n.behaviorAnalysisStartTime.tr}：${_formatTime(event.startTime)}',
          '${I18n.behaviorAnalysisEndTime.tr}：${_formatTime(event.endTime)}',
          '${I18n.behaviorAnalysisDuration.tr}：${_formatDuration(event.duration)}',
          if (event.endInferred)
            '${I18n.behaviorAnalysisNote.tr}：${I18n.behaviorAnalysisInferredEnd.tr}',
        ];
      case _TimelineMarkKind.scriptStart:
        final event = widget.scriptStarts[mark.sourceIndex];
        return [
          I18n.behaviorAnalysisScriptStart.tr,
          '${I18n.behaviorAnalysisTime.tr}：${_formatTime(event.time)}',
          if (event.label.isNotEmpty)
            '${I18n.behaviorAnalysisNote.tr}：${event.label}',
        ];
      case _TimelineMarkKind.plannedRestart:
        final event = widget.taskStarts[mark.sourceIndex];
        return [
          I18n.behaviorAnalysisPlannedRestart.tr,
          '${I18n.behaviorAnalysisTime.tr}：${_formatTime(event.time)}',
          '${I18n.behaviorAnalysisNote.tr}：Scheduler: Start task `Restart`',
        ];
    }
  }
}

enum _TimelineMarkKind { anomaly, task, scriptStart, plannedRestart }

class _TimelineMark {
  const _TimelineMark({
    required this.kind,
    required this.sourceIndex,
    required this.offset,
    this.endOffset,
    this.label = '',
    this.endInferred = false,
  });

  final _TimelineMarkKind kind;
  final int sourceIndex;
  final Offset offset;
  final Offset? endOffset;
  final String label;
  final bool endInferred;

  @override
  bool operator ==(Object other) {
    return other is _TimelineMark &&
        other.kind == kind &&
        other.sourceIndex == sourceIndex;
  }

  @override
  int get hashCode => Object.hash(kind, sourceIndex);
}

class _TimelineLayout {
  const _TimelineLayout({
    required this.marks,
    required this.plotLeft,
    required this.plotRight,
  });

  final List<_TimelineMark> marks;
  final double plotLeft;
  final double plotRight;
}

_TimelineLayout _buildTimelineLayout(
  String dateKey,
  List<BehaviorTaskStart> taskStarts,
  List<BehaviorTaskRun> taskRuns,
  List<BehaviorScriptStart> scriptStarts,
  List<BehaviorAnomalyEvent> anomalies,
  Size size,
) {
  final parsedStart = DateTime.tryParse(dateKey);
  final allTimes = <DateTime>[
    ...taskStarts.map((event) => event.time),
    ...taskRuns.expand((event) => [event.startTime, event.endTime]),
    ...scriptStarts.map((event) => event.time),
    ...anomalies.map((event) => event.time),
  ];
  DateTime fallbackStart;
  if (parsedStart == null) {
    allTimes.sort();
    final first = allTimes.isEmpty ? DateTime.now() : allTimes.first;
    fallbackStart = DateTime(first.year, first.month, first.day);
  } else {
    fallbackStart = parsedStart;
  }
  final start = fallbackStart;
  final end = start.add(const Duration(days: 1));
  final plotLeft = math.min(116.0, size.width * 0.3).toDouble();
  final plotRight = math.max(plotLeft + 1, size.width - 12).toDouble();
  final plotWidth = plotRight - plotLeft;

  double xFor(DateTime time) {
    final fraction = time.difference(start).inMilliseconds /
        end.difference(start).inMilliseconds;
    return plotLeft + fraction.clamp(0.0, 1.0).toDouble() * plotWidth;
  }

  final marks = <_TimelineMark>[];
  for (var index = 0; index < anomalies.length; index++) {
    marks.add(_TimelineMark(
      kind: _TimelineMarkKind.anomaly,
      sourceIndex: index,
      offset: Offset(xFor(anomalies[index].time), 42),
    ));
  }
  for (var index = 0; index < taskRuns.length; index++) {
    if (taskRuns[index].taskName == 'Restart') {
      continue;
    }
    marks.add(_TimelineMark(
      kind: _TimelineMarkKind.task,
      sourceIndex: index,
      offset: Offset(xFor(taskRuns[index].startTime), 98),
      endOffset: Offset(xFor(taskRuns[index].endTime), 98),
      label: taskRuns[index].taskName,
      endInferred: taskRuns[index].endInferred,
    ));
  }
  for (var index = 0; index < taskStarts.length; index++) {
    if (taskStarts[index].taskName != 'Restart') {
      continue;
    }
    marks.add(_TimelineMark(
      kind: _TimelineMarkKind.plannedRestart,
      sourceIndex: index,
      offset: Offset(xFor(taskStarts[index].time), 146),
    ));
  }
  for (var index = 0; index < scriptStarts.length; index++) {
    marks.add(_TimelineMark(
      kind: _TimelineMarkKind.scriptStart,
      sourceIndex: index,
      offset: Offset(xFor(scriptStarts[index].time), 166),
    ));
  }
  return _TimelineLayout(
    marks: marks,
    plotLeft: plotLeft,
    plotRight: plotRight,
  );
}

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter({
    required this.layout,
    required this.hoveredMark,
    required this.colorScheme,
    required this.textStyle,
    required this.textDirection,
  });

  final _TimelineLayout layout;
  final _TimelineMark? hoveredMark;
  final ColorScheme colorScheme;
  final TextStyle textStyle;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    const laneYs = [42.0, 98.0, 156.0];
    final laneLabels = [
      I18n.behaviorAnalysisAnomalyLane.tr,
      I18n.behaviorAnalysisTaskLane.tr,
      I18n.behaviorAnalysisLifecycleLane.tr,
    ];
    final linePaint = Paint()
      ..strokeWidth = 1
      ..color = colorScheme.outlineVariant;
    for (var index = 0; index < laneYs.length; index++) {
      canvas.drawLine(
        Offset(layout.plotLeft, laneYs[index]),
        Offset(layout.plotRight, laneYs[index]),
        linePaint,
      );
      _paintText(
        canvas,
        laneLabels[index],
        Offset(layout.plotLeft - 9, laneYs[index]),
        textStyle,
        textDirection,
        anchor: _TextAnchor.right,
        maxWidth: layout.plotLeft - 14,
      );
    }
    final width = layout.plotRight - layout.plotLeft;
    for (var tick = 0; tick <= 6; tick++) {
      final x = layout.plotLeft + width * tick / 6;
      canvas.drawLine(
        Offset(x, 18),
        Offset(x, 184),
        Paint()
          ..strokeWidth = 1
          ..color = colorScheme.outlineVariant.withValues(alpha: 0.4),
      );
      _paintText(
        canvas,
        tick == 6 ? '24:00' : '${(tick * 4).toString().padLeft(2, '0')}:00',
        Offset(x, 202),
        textStyle,
        textDirection,
        anchor: _TextAnchor.center,
      );
    }

    for (final mark in layout.marks) {
      final hovered = mark == hoveredMark;
      switch (mark.kind) {
        case _TimelineMarkKind.anomaly:
          _paintIcon(
            canvas,
            Icons.dangerous_rounded,
            mark.offset,
            colorScheme.error,
            hovered ? 27 : 22,
          );
        case _TimelineMarkKind.task:
          final end = mark.endOffset ?? mark.offset;
          final taskColor = _taskColor(mark.label, colorScheme);
          canvas.drawLine(
            mark.offset,
            end,
            Paint()
              ..strokeWidth = hovered ? 14 : 10
              ..strokeCap = StrokeCap.round
              ..color = taskColor.withValues(
                alpha: mark.endInferred ? 0.58 : 0.9,
              ),
          );
          if ((end.dx - mark.offset.dx).abs() >= 54) {
            _paintText(
              canvas,
              mark.label.tr,
              Offset((mark.offset.dx + end.dx) / 2, 80),
              textStyle.copyWith(color: taskColor),
              textDirection,
              anchor: _TextAnchor.center,
              maxWidth: (end.dx - mark.offset.dx).abs(),
            );
          }
        case _TimelineMarkKind.plannedRestart:
          _paintIcon(
            canvas,
            Icons.autorenew_rounded,
            mark.offset,
            colorScheme.secondary,
            hovered ? 25 : 20,
          );
        case _TimelineMarkKind.scriptStart:
          // local_shipping has its cab on the right, matching timeline direction.
          _paintIcon(
            canvas,
            Icons.local_shipping_rounded,
            mark.offset,
            colorScheme.primary,
            hovered ? 27 : 22,
          );
      }
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.hoveredMark != hoveredMark ||
        oldDelegate.colorScheme != colorScheme;
  }
}

void _paintIcon(
  Canvas canvas,
  IconData icon,
  Offset center,
  Color color,
  double size,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        color: color,
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
  );
}

double _distanceToHorizontalSegment(Offset point, Offset start, Offset end) {
  final left = math.min(start.dx, end.dx).toDouble();
  final right = math.max(start.dx, end.dx).toDouble();
  final nearestX = point.dx.clamp(left, right).toDouble();
  return (point - Offset(nearestX, start.dy)).distance;
}

Color _taskColor(String taskName, ColorScheme colorScheme) {
  var hash = 0;
  for (final codeUnit in taskName.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  final hue = (hash % 360).toDouble();
  final value = colorScheme.brightness == Brightness.dark ? 0.86 : 0.68;
  return HSVColor.fromAHSV(1, hue, 0.58, value).toColor();
}

Widget _hoverCard(
  BuildContext context,
  Offset anchor,
  Size size,
  List<String> lines,
) {
  final width = math.max(1.0, math.min(290.0, size.width - 16)).toDouble();
  final left = anchor.dx + 12 + width <= size.width - 8
      ? anchor.dx + 12
      : math.max(8.0, anchor.dx - width - 12).toDouble();
  final estimatedHeight = math.min(
    math.max(1.0, size.height - 16),
    lines.length * 22.0 + 18,
  ).toDouble();
  final top = math.min(
    math.max(8.0, anchor.dy + 12),
    math.max(8.0, size.height - estimatedHeight - 8),
  ).toDouble();
  return Positioned(
    left: left,
    top: top,
    width: width,
    child: IgnorePointer(
      child: Material(
        elevation: 6,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines
                .map(
                  (line) => Text(
                    line,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    ),
  );
}

String _formatTime(DateTime time) {
  if (time.millisecondsSinceEpoch == 0) {
    return '-';
  }
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}.'
      '${time.millisecond.toString().padLeft(3, '0')}';
}

String _formatDuration(Duration duration) {
  final milliseconds = math.max(0, duration.inMilliseconds).toInt();
  final hours = milliseconds ~/ Duration.millisecondsPerHour;
  final minutes =
      (milliseconds ~/ Duration.millisecondsPerMinute).remainder(60);
  final seconds =
      (milliseconds / Duration.millisecondsPerSecond).remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes}m ${seconds.toStringAsFixed(1)}s';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds.toStringAsFixed(1)}s';
  }
  return '${seconds.toStringAsFixed(1)}s';
}

String _formatWaitDuration(double seconds) {
  if (seconds >= 60) {
    return _formatDuration(
      Duration(milliseconds: (seconds * Duration.millisecondsPerSecond).round()),
    );
  }
  return '${seconds.toStringAsFixed(3)} s';
}

void _paintText(
  Canvas canvas,
  String text,
  Offset offset,
  TextStyle style,
  TextDirection textDirection, {
  _TextAnchor anchor = _TextAnchor.left,
  double? maxWidth,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth ?? double.infinity);
  final dx = switch (anchor) {
    _TextAnchor.left => offset.dx,
    _TextAnchor.center => offset.dx - painter.width / 2,
    _TextAnchor.right => offset.dx - painter.width,
  };
  painter.paint(canvas, Offset(dx, offset.dy - painter.height / 2));
}

enum _TextAnchor { left, center, right }
