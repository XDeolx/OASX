import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/widgets/weekly_schedule_time_picker.dart';

void main() {
  test('clock time parses legacy minute precision', () {
    final time = WeeklyScheduleClockTime.parse('09:05');

    expect(time.hour, 9);
    expect(time.minute, 5);
    expect(time.second, 0);
    expect(time.hourOfPeriod, 9);
    expect(time.isPm, isFalse);
    expect(time.format(), '09:05:00');
  });

  test('clock time preserves seconds and PM period', () {
    final time = WeeklyScheduleClockTime.parse('18:30:37');

    expect(time.hourOfPeriod, 6);
    expect(time.isPm, isTrue);
    expect(time.format(), '18:30:37');
  });

  test('clock time falls back for invalid values', () {
    final time = WeeklyScheduleClockTime.parse('25:90:90');

    expect(time.format(), '09:00:00');
  });
}
