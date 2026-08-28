import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oasx/translation/i18n_content.dart';

class WeeklyScheduleClockTime {
  const WeeklyScheduleClockTime({
    required this.hour,
    required this.minute,
    required this.second,
  });

  final int hour;
  final int minute;
  final int second;

  int get hourOfPeriod {
    final value = hour % 12;
    return value == 0 ? 12 : value;
  }

  bool get isPm => hour >= 12;

  String format() {
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:'
        '${second.toString().padLeft(2, '0')}';
  }

  factory WeeklyScheduleClockTime.parse(
    String value, {
    WeeklyScheduleClockTime fallback = const WeeklyScheduleClockTime(
      hour: 9,
      minute: 0,
      second: 0,
    ),
  }) {
    final parts = value.split(':');
    if (parts.length < 2 || parts.length > 3) {
      return fallback;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = parts.length == 3 ? int.tryParse(parts[2]) : 0;
    if (hour == null ||
        minute == null ||
        second == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59) {
      return fallback;
    }
    return WeeklyScheduleClockTime(
      hour: hour,
      minute: minute,
      second: second,
    );
  }
}

Future<WeeklyScheduleClockTime?> showWeeklyScheduleTimePicker({
  required BuildContext context,
  required WeeklyScheduleClockTime initialTime,
}) {
  return showDialog<WeeklyScheduleClockTime>(
    context: context,
    builder: (context) => _WeeklyScheduleTimePicker(initialTime: initialTime),
  );
}

enum _ClockField { hour, minute, second }

class _WeeklyScheduleTimePicker extends StatefulWidget {
  const _WeeklyScheduleTimePicker({required this.initialTime});

  final WeeklyScheduleClockTime initialTime;

  @override
  State<_WeeklyScheduleTimePicker> createState() =>
      _WeeklyScheduleTimePickerState();
}

class _WeeklyScheduleTimePickerState
    extends State<_WeeklyScheduleTimePicker> {
  late int _hour;
  late int _minute;
  late int _second;
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late final TextEditingController _secondController;
  _ClockField _field = _ClockField.hour;
  bool _keyboardMode = false;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _second = widget.initialTime.second;
    _hourController = TextEditingController(text: _hourOfPeriod.toString());
    _minuteController = TextEditingController(
      text: _minute.toString().padLeft(2, '0'),
    );
    _secondController = TextEditingController(
      text: _second.toString().padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  int get _hourOfPeriod {
    final value = _hour % 12;
    return value == 0 ? 12 : value;
  }

  bool get _isPm => _hour >= 12;

  bool get _keyboardValid {
    return _validController(_hourController, 1, 12) &&
        _validController(_minuteController, 0, 59) &&
        _validController(_secondController, 0, 59);
  }

  bool _validController(
    TextEditingController controller,
    int minimum,
    int maximum,
  ) {
    final value = int.tryParse(controller.text);
    return value != null && value >= minimum && value <= maximum;
  }

  void _setPeriod(bool isPm) {
    setState(() {
      _hour = (_hourOfPeriod % 12) + (isPm ? 12 : 0);
    });
  }

  void _toggleEntryMode() {
    setState(() {
      _keyboardMode = !_keyboardMode;
      if (_keyboardMode) {
        _syncControllers();
      }
    });
  }

  void _syncControllers() {
    _hourController.text = _hourOfPeriod.toString().padLeft(2, '0');
    _minuteController.text = _minute.toString().padLeft(2, '0');
    _secondController.text = _second.toString().padLeft(2, '0');
  }

  void _setDialValue(Offset position, Size size) {
    final center = size.center(Offset.zero);
    final delta = position - center;
    if (delta.distance < size.shortestSide * 0.08) {
      return;
    }
    var angle = math.atan2(delta.dx, -delta.dy);
    if (angle < 0) {
      angle += math.pi * 2;
    }
    setState(() {
      if (_field == _ClockField.hour) {
        var value = (angle / (math.pi * 2) * 12).round() % 12;
        if (value == 0) {
          value = 12;
        }
        _hour = (value % 12) + (_isPm ? 12 : 0);
      } else {
        final value = (angle / (math.pi * 2) * 60).round() % 60;
        if (_field == _ClockField.minute) {
          _minute = value;
        } else {
          _second = value;
        }
      }
    });
  }

  void _advanceField() {
    setState(() {
      _field = switch (_field) {
        _ClockField.hour => _ClockField.minute,
        _ClockField.minute => _ClockField.second,
        _ClockField.second => _ClockField.second,
      };
    });
  }

  void _updateKeyboardValue(_ClockField field, String text) {
    final value = int.tryParse(text);
    if (value == null) {
      return;
    }
    setState(() {
      _field = field;
      switch (field) {
        case _ClockField.hour:
          if (value >= 1 && value <= 12) {
            _hour = (value % 12) + (_isPm ? 12 : 0);
          }
          break;
        case _ClockField.minute:
          if (value >= 0 && value <= 59) {
            _minute = value;
          }
          break;
        case _ClockField.second:
          if (value >= 0 && value <= 59) {
            _second = value;
          }
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(I18n.weeklyScheduleTime.tr)),
          IconButton(
            tooltip: _keyboardMode
                ? I18n.weeklyScheduleClockInput.tr
                : I18n.weeklyScheduleKeyboardInput.tr,
            onPressed: _toggleEntryMode,
            icon: Icon(
              _keyboardMode
                  ? Icons.schedule_rounded
                  : Icons.keyboard_rounded,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('AM')),
                  ButtonSegment(value: true, label: Text('PM')),
                ],
                selected: {_isPm},
                onSelectionChanged: (selection) {
                  _setPeriod(selection.first);
                },
              ),
              const SizedBox(height: 16),
              if (_keyboardMode) _buildKeyboardInput() else _buildClockInput(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(I18n.cancel.tr),
        ),
        FilledButton(
          onPressed: _keyboardMode && !_keyboardValid
              ? null
              : () => Navigator.of(context).pop(
                    WeeklyScheduleClockTime(
                      hour: _hour,
                      minute: _minute,
                      second: _second,
                    ),
                  ),
          child: Text(I18n.confirm.tr),
        ),
      ],
    );
  }

  Widget _buildClockInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimePart(
              _hourOfPeriod,
              _ClockField.hour,
              I18n.hour.tr,
            ),
            _buildSeparator(),
            _buildTimePart(_minute, _ClockField.minute, I18n.minute.tr),
            _buildSeparator(),
            _buildTimePart(_second, _ClockField.second, I18n.seconds.tr),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final diameter = math.min(constraints.maxWidth, 300.0);
            final size = Size.square(diameter);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                _setDialValue(details.localPosition, size);
                _advanceField();
              },
              onPanStart: (details) {
                _setDialValue(details.localPosition, size);
              },
              onPanUpdate: (details) {
                _setDialValue(details.localPosition, size);
              },
              onPanEnd: (_) => _advanceField(),
              child: CustomPaint(
                size: size,
                painter: _ClockPainter(
                  hour: _hour,
                  minute: _minute,
                  second: _second,
                  field: _field,
                  colorScheme: Theme.of(context).colorScheme,
                  textStyle: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimePart(int value, _ClockField field, String tooltip) {
    final selected = _field == field;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _field = field),
        child: Container(
          width: 62,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            value.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(':', style: Theme.of(context).textTheme.headlineMedium),
    );
  }

  Widget _buildKeyboardInput() {
    return Row(
      children: [
        _buildNumberField(
          controller: _hourController,
          field: _ClockField.hour,
          label: I18n.hour.tr,
        ),
        const SizedBox(width: 10),
        _buildNumberField(
          controller: _minuteController,
          field: _ClockField.minute,
          label: I18n.minute.tr,
        ),
        const SizedBox(width: 10),
        _buildNumberField(
          controller: _secondController,
          field: _ClockField.second,
          label: I18n.seconds.tr,
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required _ClockField field,
    required String label,
  }) {
    return Expanded(
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: _keyboardFieldValid(field)
              ? null
              : I18n.weeklyScheduleInvalidTime.tr,
        ),
        onTap: () => setState(() => _field = field),
        onChanged: (value) => _updateKeyboardValue(field, value),
      ),
    );
  }

  bool _keyboardFieldValid(_ClockField field) {
    return switch (field) {
      _ClockField.hour => _validController(_hourController, 1, 12),
      _ClockField.minute => _validController(_minuteController, 0, 59),
      _ClockField.second => _validController(_secondController, 0, 59),
    };
  }
}

class _ClockPainter extends CustomPainter {
  const _ClockPainter({
    required this.hour,
    required this.minute,
    required this.second,
    required this.field,
    required this.colorScheme,
    required this.textStyle,
  });

  final int hour;
  final int minute;
  final int second;
  final _ClockField field;
  final ColorScheme colorScheme;
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = colorScheme.surfaceContainerHighest,
    );
    _drawTicks(canvas, center, radius);
    _drawLabels(canvas, center, radius);

    for (final item in _ClockField.values.where((item) => item != field)) {
      _drawHand(canvas, center, radius, item, selected: false);
    }
    _drawHand(canvas, center, radius, field, selected: true);
    canvas.drawCircle(
      center,
      radius * 0.025,
      Paint()..color = colorScheme.primary,
    );
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 60; index++) {
      final angle = index * math.pi * 2 / 60;
      final major = index % 5 == 0;
      paint.strokeWidth = major ? 2 : 1;
      final outer = _point(center, radius * 0.93, angle);
      final inner = _point(center, radius * (major ? 0.87 : 0.9), angle);
      canvas.drawLine(inner, outer, paint);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius) {
    final labels = field == _ClockField.hour
        ? List.generate(12, (index) => index + 1)
        : List.generate(12, (index) => index * 5);
    for (var index = 0; index < labels.length; index++) {
      final angle = (index + 1) * math.pi * 2 / 12;
      final value = field == _ClockField.hour
          ? labels[index].toString()
          : labels[(index + 1) % labels.length].toString().padLeft(2, '0');
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: textStyle?.copyWith(color: colorScheme.onSurface),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final point = _point(center, radius * 0.72, angle);
      painter.paint(
        canvas,
        point - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  void _drawHand(
    Canvas canvas,
    Offset center,
    double radius,
    _ClockField hand, {
    required bool selected,
  }) {
    final angle = switch (hand) {
      _ClockField.hour =>
        ((hour % 12) + minute / 60) * math.pi * 2 / 12,
      _ClockField.minute => (minute + second / 60) * math.pi * 2 / 60,
      _ClockField.second => second * math.pi * 2 / 60,
    };
    final length = switch (hand) {
      _ClockField.hour => 0.42,
      _ClockField.minute => 0.58,
      _ClockField.second => 0.68,
    };
    final paint = Paint()
      ..color = selected
          ? colorScheme.primary
          : colorScheme.onSurfaceVariant.withValues(alpha: 0.35)
      ..strokeWidth = selected ? 4 : 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, _point(center, radius * length, angle), paint);
  }

  Offset _point(Offset center, double radius, double angle) {
    return center + Offset(math.sin(angle) * radius, -math.cos(angle) * radius);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) {
    return oldDelegate.hour != hour ||
        oldDelegate.minute != minute ||
        oldDelegate.second != second ||
        oldDelegate.field != field ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.textStyle != textStyle;
  }
}
