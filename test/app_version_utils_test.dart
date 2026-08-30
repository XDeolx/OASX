import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/service/app_update/app_version_utils.dart';

void main() {
  group('AppVersionUtils', () {
    test('recognizes newer testoyj release tags', () {
      expect(
        AppVersionUtils.compareVersion(
          'v0.3.12.4',
          'testoyj-v0.3.12.5',
        ),
        isTrue,
      );
      expect(
        AppVersionUtils.compareVersion(
          'v0.3.12.5',
          'testoyj-v0.3.12.5',
        ),
        isFalse,
      );
      expect(
        AppVersionUtils.compareVersion(
          'v0.3.12.5',
          'testoyj-v0.3.12.4',
        ),
        isFalse,
      );
    });

    test('includes the Windows build number in the installed version', () {
      expect(
        AppVersionUtils.formatInstalledVersion(
          version: '0.3.12',
          buildNumber: '5',
        ),
        'v0.3.12.5',
      );
      expect(
        AppVersionUtils.formatInstalledVersion(
          version: '0.3.12',
          buildNumber: '0',
        ),
        'v0.3.12',
      );
    });
  });
}
