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
      expect(
        AppVersionUtils.compareVersion(
          'v0.3.12.9',
          'testoyj-v1.0.0',
        ),
        isTrue,
      );
      expect(
        AppVersionUtils.compareVersion(
          'v1.0.0',
          'testoyj-v1.0.0',
        ),
        isFalse,
      );
      expect(
        AppVersionUtils.compareVersion(
          'v1.0.4',
          'testoyj-v1.0.4.1',
        ),
        isTrue,
      );
      expect(
        AppVersionUtils.compareVersion(
          'v1.0.4.1',
          'testoyj-v1.0.5',
        ),
        isTrue,
      );
    });

    test('formats legacy and stable installed versions', () {
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
      expect(
        AppVersionUtils.formatInstalledVersion(
          version: '1.0.0',
          buildNumber: '0',
        ),
        'v1.0.0',
      );
      expect(
        AppVersionUtils.formatInstalledVersion(
          version: '1.0.4',
          buildNumber: '1',
        ),
        'v1.0.4.1',
      );
    });
  });
}
