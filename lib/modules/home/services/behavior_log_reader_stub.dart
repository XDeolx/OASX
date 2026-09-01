Future<List<String>> listBehaviorLogDates(
  String rootPath,
  String scriptName,
) async {
  return const [];
}

Future<String> readBehaviorLog(
  String rootPath,
  String scriptName,
  String dateKey,
) async {
  throw UnsupportedError('Behavior analysis requires local file access');
}
