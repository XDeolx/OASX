import 'dart:io';

Future<List<String>> listBehaviorLogDates(
  String rootPath,
  String scriptName,
) async {
  final normalizedRoot = rootPath.trim();
  final normalizedScript = scriptName.trim();
  if (normalizedRoot.isEmpty || normalizedScript.isEmpty) {
    return const [];
  }
  final logDirectory = Directory(
    '$normalizedRoot${Platform.pathSeparator}log',
  );
  if (!await logDirectory.exists()) {
    return const [];
  }
  final pattern = RegExp(
    '^([0-9]{4}-[0-9]{2}-[0-9]{2})_${RegExp.escape(normalizedScript)}\\.txt\$',
  );
  final dates = <String>{};
  await for (final entity in logDirectory.list(followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    final fileName = entity.uri.pathSegments.last;
    final match = pattern.firstMatch(fileName);
    if (match != null) {
      dates.add(match.group(1)!);
    }
  }
  final sorted = dates.toList()..sort((left, right) => right.compareTo(left));
  return sorted;
}

Future<String> readBehaviorLog(
  String rootPath,
  String scriptName,
  String dateKey,
) async {
  final file = File(
    '${rootPath.trim()}${Platform.pathSeparator}log${Platform.pathSeparator}'
    '${dateKey.trim()}_${scriptName.trim()}.txt',
  );
  if (!await file.exists()) {
    throw FileSystemException('Behavior log does not exist', file.path);
  }
  return file.readAsString();
}
