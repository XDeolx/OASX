import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/behavior_analysis_models.dart';
import 'package:oasx/modules/home/services/behavior_log_reader.dart';
import 'package:oasx/utils/platform_utils.dart';

typedef BehaviorDateLoader = Future<List<String>> Function(
  String rootPath,
  String scriptName,
);
typedef BehaviorLogLoader = Future<String> Function(
  String rootPath,
  String scriptName,
  String dateKey,
);

class HomeBehaviorAnalysisController extends GetxController {
  HomeBehaviorAnalysisController({
    GetStorage? storage,
    BehaviorDateLoader? dateLoader,
    BehaviorLogLoader? logLoader,
  })  : _storage = storage ?? GetStorage(),
        _dateLoader = dateLoader ?? listBehaviorLogDates,
        _logLoader = logLoader ?? readBehaviorLog;

  final GetStorage _storage;
  final BehaviorDateLoader _dateLoader;
  final BehaviorLogLoader _logLoader;

  final HomeDashboardController dashboardController =
      Get.find<HomeDashboardController>();

  final availableDateKeys = <String>[].obs;
  final selectedDateKey = ''.obs;
  final analysis = Rxn<BehaviorAnalysisDay>();
  final datesLoading = false.obs;
  final analysisLoading = false.obs;
  final lastErrorMessage = ''.obs;
  final showClickPath = true.obs;

  Worker? _dashboardWorker;
  String _boundScriptName = '';
  int _bindingRevision = 0;
  int _analysisRevision = 0;

  @override
  void onInit() {
    _dashboardWorker = everAll([
      dashboardController.activeScriptName,
      dashboardController.activeWorkbenchTab,
      dashboardController.activeWorkbenchSidebarTab,
      dashboardController.workbenchLayoutMode,
    ], (_) => unawaited(syncBinding()));
    unawaited(syncBinding());
    super.onInit();
  }

  @override
  void onClose() {
    _dashboardWorker?.dispose();
    _dashboardWorker = null;
    super.onClose();
  }

  Future<void> syncBinding() async {
    final scriptName = dashboardController.activeScriptName.value.trim();
    if (!dashboardController.isBehaviorAnalysisVisibleInCurrentLayout ||
        scriptName.isEmpty) {
      _resetHiddenState();
      return;
    }
    if (_boundScriptName == scriptName && availableDateKeys.isNotEmpty) {
      return;
    }
    await _bootstrapForScript(scriptName);
  }

  Future<void> refresh() async {
    final scriptName = dashboardController.activeScriptName.value.trim();
    if (scriptName.isEmpty ||
        !dashboardController.isBehaviorAnalysisVisibleInCurrentLayout) {
      return;
    }
    await _bootstrapForScript(
      scriptName,
      preferredDateKey: selectedDateKey.value,
    );
  }

  void selectDate(String dateKey) {
    if (dateKey == selectedDateKey.value ||
        !availableDateKeys.contains(dateKey) ||
        _boundScriptName.isEmpty) {
      return;
    }
    selectedDateKey.value = dateKey;
    unawaited(_loadAnalysis(_boundScriptName, dateKey));
  }

  void toggleClickPath() {
    showClickPath.value = !showClickPath.value;
  }

  Future<void> _bootstrapForScript(
    String scriptName, {
    String preferredDateKey = '',
  }) async {
    final revision = ++_bindingRevision;
    _analysisRevision++;
    _boundScriptName = scriptName;
    datesLoading.value = true;
    analysisLoading.value = false;
    lastErrorMessage.value = '';
    analysis.value = null;
    availableDateKeys.clear();

    if (PlatformUtils.isWeb) {
      datesLoading.value = false;
      lastErrorMessage.value = 'behavior_analysis_local_only';
      return;
    }

    final rootPath = _rootPath;
    if (rootPath.isEmpty) {
      datesLoading.value = false;
      lastErrorMessage.value = 'behavior_analysis_root_missing';
      return;
    }

    try {
      final dates = await _dateLoader(rootPath, scriptName);
      if (!_isBindingActive(revision, scriptName)) {
        return;
      }
      datesLoading.value = false;
      availableDateKeys.assignAll(dates);
      if (dates.isEmpty) {
        selectedDateKey.value = '';
        return;
      }
      final selected = dates.contains(preferredDateKey)
          ? preferredDateKey
          : dates.first;
      selectedDateKey.value = selected;
      await _loadAnalysis(scriptName, selected);
    } catch (error) {
      if (!_isBindingActive(revision, scriptName)) {
        return;
      }
      datesLoading.value = false;
      lastErrorMessage.value = error.toString();
    }
  }

  Future<void> _loadAnalysis(String scriptName, String dateKey) async {
    final revision = ++_analysisRevision;
    analysisLoading.value = true;
    lastErrorMessage.value = '';
    analysis.value = null;
    try {
      final content = await _logLoader(_rootPath, scriptName, dateKey);
      final parsed = await parseBehaviorLogAsync(
        scriptName: scriptName,
        dateKey: dateKey,
        content: content,
      );
      if (!_isAnalysisActive(revision, scriptName, dateKey)) {
        return;
      }
      analysisLoading.value = false;
      analysis.value = parsed;
    } catch (error) {
      if (!_isAnalysisActive(revision, scriptName, dateKey)) {
        return;
      }
      analysisLoading.value = false;
      lastErrorMessage.value = error.toString();
    }
  }

  void _resetHiddenState() {
    _bindingRevision++;
    _analysisRevision++;
    _boundScriptName = '';
    datesLoading.value = false;
    analysisLoading.value = false;
    availableDateKeys.clear();
    analysis.value = null;
    lastErrorMessage.value = '';
  }

  String get _rootPath {
    final value = _storage.read(StorageKey.rootPathServer.name);
    return value?.toString().trim() ?? '';
  }

  bool _isBindingActive(int revision, String scriptName) {
    return revision == _bindingRevision &&
        _boundScriptName == scriptName &&
        dashboardController.activeScriptName.value.trim() == scriptName &&
        dashboardController.isBehaviorAnalysisVisibleInCurrentLayout;
  }

  bool _isAnalysisActive(
    int revision,
    String scriptName,
    String dateKey,
  ) {
    return revision == _analysisRevision &&
        _boundScriptName == scriptName &&
        selectedDateKey.value == dateKey &&
        dashboardController.isBehaviorAnalysisVisibleInCurrentLayout;
  }
}
