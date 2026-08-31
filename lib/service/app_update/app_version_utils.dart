import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Contains shared app-version helpers for update checks.
class AppVersionUtils {
  /// Returns true when [latest] is newer than [current].
  static bool compareVersion(String current, String latest) {
    final currentParts = _normalizeVersion(current);
    final latestParts = _normalizeVersion(latest);
    final maxLength = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;
    for (var index = 0; index < maxLength; index++) {
      final currentValue =
          index < currentParts.length ? currentParts[index] : 0;
      final latestValue = index < latestParts.length ? latestParts[index] : 0;
      if (latestValue > currentValue) {
        return true;
      }
      if (latestValue < currentValue) {
        return false;
      }
    }
    return false;
  }

  /// Returns the normalized application version string.
  static Future<String> getCurrentVersion() async {
    if (!kReleaseMode) {
      return 'v0.0.1';
    }
    final packageInfo = await PackageInfo.fromPlatform();
    return formatInstalledVersion(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }

  /// Combines the package version and build number used by testoyj releases.
  static String formatInstalledVersion({
    required String version,
    required String buildNumber,
  }) {
    final normalizedVersion = version.trim().split('-').first;
    final normalizedBuild = buildNumber.trim();
    final majorVersion = int.tryParse(normalizedVersion.split('.').first) ?? 0;
    if (majorVersion >= 1) {
      return 'v$normalizedVersion';
    }
    if (normalizedBuild.isEmpty || normalizedBuild == '0') {
      return 'v$normalizedVersion';
    }
    return 'v$normalizedVersion.$normalizedBuild';
  }

  /// Normalizes a semantic version string into integer parts.
  static List<int> _normalizeVersion(String version) {
    final match = RegExp(r'v?(\d+(?:\.\d+)*)').firstMatch(version.trim());
    final normalized = match?.group(1) ?? '';
    return normalized
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }
}
