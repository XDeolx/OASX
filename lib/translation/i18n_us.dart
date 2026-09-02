// ignore_for_file: non_constant_identifier_names
part of i18n;

final Map<String, String> _us_base_map = {
  ..._us_ui,
  ..._us_script,
  ..._us_global_game,
  ..._us_restart,
  ..._us_invite_config,
  ..._us_general_battle_config,
  ..._us_switch_soul,
};

final Map<String, String> _us_ui = {
  I18n.logOut: 'Logout',
  I18n.zhCn: '简体中文',
  I18n.enUs: 'English',
  I18n.run: 'Running',
  I18n.pending: 'Pending',
  I18n.waiting: 'Waiting',
  I18n.stop: 'Stopped',
  I18n.warning: 'Warning',
  'Chess': 'Chess (Test)',
  I18n.chessTestNotice:
      'This is the new Chess test implementation. If it is unstable, switch OAS to the testoyj-chess-legacy branch to use the previous version.',
  I18n.connecting: 'Connecting',
  I18n.cancel: 'Cancel',
  I18n.confirm: 'Confirm',
  I18n.retry: 'Retry',
  I18n.selectAll: 'Select all',
  I18n.back: 'Back',
  I18n.clear: 'Clear',
  I18n.selectedCount: 'Selected @count',
  I18n.time: 'Time',
  I18n.projectStatement: 'Open Source Software',
  I18n.taskSetting: 'Settings',
  I18n.copy: 'Copy',
  I18n.noData: 'No data',
  I18n.notifyTestHelp:
      'Please refer to the documentation [Message Push] to fill in the relevant configuration',
  I18n.rootPathServerHelp:
      'OASX and OAS are two different things. Do not confuse them, do not put them in the same directory, do not use spaces, do not use Chinese characters, and do not use overly long paths',
  I18n.installOasHelp:
      'This will download and decompress from Github. Please maintain a stable network connection. At the same time, this directory will be cleared',
  I18n.importDeployFile: 'Import deploy file',
  I18n.exportDeployFile: 'Export deploy file',
  I18n.selectDeployFile: 'Click to select or drop a YAML file here',
  I18n.deployFileNameInvalid: 'The imported file must be a .yaml file',
  I18n.deployFileImportSuccess: 'Deploy file imported',
  I18n.deployFileImportFailed: 'Failed to import deploy file',
  I18n.deployFileExportSuccess: 'Deploy file exported',
  I18n.deployFileExportFailed: 'Failed to export deploy file',
  I18n.configImportJson: 'Import JSON config',
  I18n.configExport: 'Export',
  I18n.selectConfigJsonFile: 'Click to select or drop a JSON config file here',
  I18n.configJsonFileInvalid: 'The imported file must be a .json file',
  I18n.configImportSuccess: 'Config imported',
  I18n.configImportFailed: 'Failed to import config',
  I18n.configExportSuccess: 'Config exported',
  I18n.configExportFailed: 'Failed to export config',
  I18n.taskJsonImport: 'Import',
  I18n.taskJsonExport: 'Export masked file',
  I18n.taskJsonCopy: 'Copy unmasked info',
  I18n.taskJsonSelectFile: 'Click to select or drop a JSON file here',
  I18n.taskJsonChooseOne: 'Choose one option',
  I18n.taskJsonTextHint: 'Paste task JSON content',
  I18n.taskJsonSourceInvalid:
      'Select a JSON file or enter JSON content, but not both',
  I18n.taskJsonFileInvalid: 'The imported file must be a .json file',
  I18n.taskJsonImportSuccess: 'Task JSON imported',
  I18n.taskJsonImportFailed: 'Failed to import task JSON',
  I18n.taskJsonExportSuccess: 'Task JSON exported',
  I18n.taskJsonExportFailed: 'Failed to export task JSON',
  I18n.taskJsonCopySuccess: 'Task JSON copied',
  I18n.taskJsonCopyFailed: 'Failed to copy task JSON',
  I18n.taskJsonDiscardDraftPrompt:
      'Importing task JSON will discard unsaved changes. Continue?',
  I18n.configUpdateTip:
      'The current script is running, please stop it before making modifications.',
  I18n.minimizeToSystemTrayHelp:
      'Minimized to the system tray when closing a window',
  I18n.shutdownOasOnExit: 'Shut down OAS on exit',
  I18n.shutdownOasOnExitHelp:
      'Automatically shut down OAS when OASX really exits. Minimize to tray will not trigger it',
  I18n.launchAtStartupHelp: 'Launch OASX when you sign in',
  I18n.launchAtStartupUpdateFailed: 'Failed to update launch at startup',
  I18n.updateProxyUrl: 'Proxy URL',
  I18n.updateProxyUrlHelp:
      'Used when downloading update packages, for example http://127.0.0.1:7897',
  I18n.openReleasePage: 'Open release page',
  I18n.downloadAndUpdate: 'Download and update',
  I18n.downloadAndInstall: 'Download and install',
  I18n.updateReleasePageOnly:
      'This platform can only continue on the release page',
  I18n.updateDownloading: 'Downloading update package',
  I18n.updatePreparing: 'Preparing update install',
  I18n.updateCheckFailed: 'Failed to check for updates',
  I18n.updateDownloadFailed: 'Failed to download the update package',
  I18n.updateInstallFailed: 'Update preparation failed: @error',
  I18n.updateDownloadProgress: 'Downloaded @received / @total (@percent%)',
  I18n.updateDownloadProgressUnknown: 'Downloaded @received',
  I18n.updateInvalidPackage:
      'The downloaded package failed checksum validation',
  I18n.updateInstallStarted: 'The platform installer has been opened',
  I18n.updateAllowUnknownApps:
      'Allow installs from this source first, then try again',
  I18n.exitOasx: 'Exit OASX',
  I18n.exitDialogMinimizeToTray: 'Minimize to system tray',
  I18n.doNotRemindAgain: 'Do not remind again',
  I18n.scriptList: 'Configs',
  I18n.trayRunningConfigs: 'Running',
  I18n.trayStoppedConfigs: 'Not running',
  I18n.trayAbnormalConfigs: 'Abnormal',
  I18n.loginAddress: 'Login address',
  I18n.username: 'Username',
  I18n.password: 'Password',
  I18n.userSetting: 'User settings',
  I18n.homeSelectControlScript: 'Select control scripts',
  I18n.homeOverviewControl: 'Overview and control',
  I18n.homeMasterSwitch: 'Master switch',
  I18n.homeRunningCount: 'Running: @running / @total',
  I18n.homeTotalScripts: 'Total scripts',
  I18n.homeControlScriptCount: 'Control scripts: @count',
  I18n.turnOnTheLinker: 'Turn on the linker',
  I18n.closeTheLinker: 'Close the linker',
  I18n.homeNoTask: 'No tasks',
  I18n.homeNoLog: 'No logs yet',
  I18n.homeUnconfiguredTask: 'No tasks, please configure the script first',
  I18n.homeRunningTask: 'Running task',
  I18n.homePendingTask: 'Pending task',
  I18n.homeWaitingTask: 'Waiting task',
  I18n.homeConnectionRetryHint:
      'Please confirm the backend service has started and user settings are correct',
  I18n.homeConnectionRetryAction: 'Refresh',
  I18n.homeEmptyScriptHint: 'Add a config first',
  I18n.homeLoadingAutoDeploying: 'Auto deployment in progress, please wait',
  I18n.homeGoDeployPage: 'Go to deploy page',
  I18n.homeLoadingAutoLogin: 'Logging into OAS, please wait',
  I18n.homeLoadingConfigDetail: 'Loading config details, please wait',
  I18n.homeScriptAbnormal: 'Abnormal',
  I18n.homeScriptOffline: 'Offline',
  I18n.homeScriptSearchHint: 'Search configs',
  I18n.homeSortByStatus: 'Sort by status',
  I18n.homeSortByName: 'Sort by name',
  I18n.homeNoScriptSelected: 'Select a config first',
  I18n.homeRestoreSidebar: 'Restore right sidebar',
  I18n.homeStatusTab: 'Status',
  I18n.homeTasksTab: 'Tasks',
  I18n.weeklyScheduleTab: 'Weekly plan',
  I18n.weeklyScheduleLoadFailed: 'Failed to load weekly plan',
  I18n.weeklyScheduleSaveFailed: 'Failed to save weekly plan',
  I18n.weeklyScheduleApplyFailed: 'Failed to sync today\'s plan',
  I18n.weeklyScheduleSaved: 'Weekly plan saved',
  I18n.weeklyScheduleApplied: 'Today\'s plan synced to the main scheduler',
  I18n.weeklyScheduleAdd: 'Add schedule time',
  I18n.weeklyScheduleEdit: 'Edit schedule time',
  I18n.weeklyScheduleTask: 'Task',
  I18n.weeklyScheduleBulkAdd: 'Add to multiple weekdays',
  I18n.weeklyScheduleBulkAddTitle: 'Add task to weekdays',
  I18n.weeklyScheduleBulkAdded: 'Task added to the weekly plan',
  I18n.weeklyScheduleTargetDays: 'Target weekdays',
  I18n.weeklyScheduleRandomOffset:
      'Second-level random offset before or after base time',
  I18n.weeklyScheduleMinutes: 'minutes',
  I18n.weeklyScheduleReplaceSameTask:
      'Replace the same task on selected weekdays',
  I18n.weeklyScheduleKeyboardInput: 'Switch to keyboard input',
  I18n.weeklyScheduleClockInput: 'Switch to clock input',
  I18n.weeklyScheduleInvalidTime: 'Time is out of range',
  I18n.weeklyScheduleWeekday: 'Weekday',
  I18n.weeklyScheduleTime: 'Run time',
  I18n.weeklyScheduleAll: 'All',
  I18n.weeklyScheduleEmpty: 'No schedule times',
  I18n.weeklyScheduleEnabled: 'Weekly plan enabled',
  I18n.weeklyScheduleDisabled: 'Weekly plan disabled',
  I18n.weeklyScheduleResetTimes: 'Sync today\'s plan now',
  I18n.weeklySchedulePlanned: 'Planned tasks',
  I18n.weeklyScheduleUnplanned: 'Unplanned tasks',
  I18n.weeklyScheduleCopyDay: 'Copy one day',
  I18n.weeklyScheduleCopyDayTitle: 'Copy weekday plan',
  I18n.weeklyScheduleSourceDay: 'Source weekday',
  I18n.weeklyScheduleTargetDay: 'Target weekday',
  I18n.weeklyScheduleReplaceTarget: 'Clear target weekday before copying',
  I18n.weeklyScheduleNoSourceEntries: 'The source weekday has no entries',
  I18n.weeklyScheduleDayCopied: 'Weekday plan copied',
  I18n.weeklyScheduleImportCurrent: 'Import current scheduler',
  I18n.weeklyScheduleImportCurrentTitle: 'Import current scheduler tasks',
  I18n.weeklyScheduleReplaceExisting: 'Clear weekly plan before importing',
  I18n.weeklyScheduleNoEnabledTasks: 'No enabled scheduler tasks to import',
  I18n.weeklyScheduleImported: 'Current scheduler tasks imported',
  I18n.weeklyScheduleViewTasks: 'View tasks',
  I18n.weeklyScheduleCatchUpMissed: 'Run missed plans from today',
  I18n.weeklyScheduleCurrentTime: 'Current time',
  I18n.weeklyScheduleCurrentWeek: 'This week starts',
  I18n.weeklyScheduleLastSynced: 'Today synced',
  I18n.weeklyScheduleNotSynced: 'Not synced yet',
  I18n.weeklyScheduleTurtleMode: 'Turtle mode',
  I18n.weeklyScheduleTurtleSelect: 'Select retained turtle-mode tasks',
  I18n.weeklyScheduleTurtleSelectTitle: 'Turtle-mode retained tasks',
  I18n.weeklyScheduleTurtleKeep: 'Retained tasks',
  I18n.weeklyScheduleTurtleEmpty: 'Select at least one retained task',
  I18n.weeklyScheduleFreeCycle: 'Free cycle',
  I18n.weeklyScheduleFreeCycleSelect: 'Select free-cycle tasks',
  I18n.weeklyScheduleFreeCycleSelectTitle: 'Free-cycle tasks',
  I18n.weeklyRefresh: 'Weekly refresh',
  I18n.weeklyRefreshSettings: 'Weekly refresh settings',
  I18n.weeklyRefreshRange: 'Range',
  I18n.weeklyRefreshExcluded: 'Excluded tasks',
  I18n.weeklyRefreshBoundaries: 'Task boundaries',
  I18n.weeklyRefreshPreview: 'Preview',
  I18n.weeklyRefreshRandomRange: 'Random offset around the base time',
  I18n.weeklyRefreshRandomRangeHelp:
      'Generated once per week to the second without cumulative drift',
  I18n.weeklyRefreshFreezeWindows: 'Frozen periods',
  I18n.weeklyRefreshAddFreeze: 'Add frozen period',
  I18n.weeklyRefreshNoFreeze: 'No frozen periods',
  I18n.weeklyRefreshExcludedTaskHelp:
      'Keep the base time and exclude it from weekly refresh',
  I18n.weeklyRefreshClearBoundary: 'Clear task boundary',
  I18n.weeklyRefreshGeneratePreview: 'Generate preview',
  I18n.weeklyRefreshPreviewEmpty:
      'Generate a preview to inspect this week\'s time changes',
  I18n.weeklyRefreshPreviewFailed: 'Failed to generate weekly refresh preview',
  I18n.weeklyRefreshBoundaryStart: 'Earliest time',
  I18n.weeklyRefreshBoundaryEnd: 'Latest time',
  I18n.weeklyRefreshNow: 'Refresh this week now',
  I18n.weeklyRefreshNowConfirm:
      'Regenerate this week and sync today\'s scheduler now?',
  I18n.weeklyRefreshFailed: 'Failed to refresh this week',
  I18n.weeklyRefreshApplied: 'This week was regenerated and synced',
  I18n.weeklyRefreshNoCandidate:
      'No valid random time within the boundary; base time retained',
  I18n.weeklyRefreshIssues: 'Weekly refresh conflicts',
  I18n.weekdayMonday: 'Monday',
  I18n.weekdayTuesday: 'Tuesday',
  I18n.weekdayWednesday: 'Wednesday',
  I18n.weekdayThursday: 'Thursday',
  I18n.weekdayFriday: 'Friday',
  I18n.weekdaySaturday: 'Saturday',
  I18n.weekdaySunday: 'Sunday',
  I18n.weekdayMonShort: 'Mon',
  I18n.weekdayTueShort: 'Tue',
  I18n.weekdayWedShort: 'Wed',
  I18n.weekdayThuShort: 'Thu',
  I18n.weekdayFriShort: 'Fri',
  I18n.weekdaySatShort: 'Sat',
  I18n.weekdaySunShort: 'Sun',
  I18n.homeStatsTab: 'Stats',
  I18n.homeParamsTab: 'Params',
  I18n.homeStatsGeneratedAt: 'Generated at',
  I18n.homeStatsRetentionDays: 'Retention days',
  I18n.homeStatsToday: 'Today',
  I18n.homeStatsSelectedDate: 'Selected date',
  I18n.homeStatsTasks: 'Tasks',
  I18n.homeStatsRunCount: 'Runs',
  I18n.homeStatsTotalDuration: 'Total runtime',
  I18n.homeStatsBattleCount: 'Battles',
  I18n.homeStatsBattleTotalDuration: 'Total battle duration',
  I18n.homeStatsBattleAvgDuration: 'Avg battle duration',
  I18n.homeStatsAvgRunDuration: 'Avg run duration',
  I18n.homeStatsMetricRunCount: 'Run count',
  I18n.homeStatsMetricBattleCount: 'Battle count',
  I18n.homeStatsMetricBattleAvgDuration: 'Avg battle duration',
  I18n.homeStatsMetricAvgRunDuration: 'Avg runtime',
  I18n.homeStatsWaitingSnapshot: 'Waiting for statistics snapshot',
  I18n.homeStatsConnected: 'Stats stream connected',
  I18n.homeStatsDisconnected: 'Stats stream disconnected',
  I18n.homeStatsReconnecting: 'Stats stream reconnecting',
  I18n.homeStatsStreamError: 'Stats stream error',
  I18n.homeStatsTimelineEmpty: 'No timeline data for today yet',
  I18n.homeStatsChartEmpty: 'No chart data for the selected day',
  I18n.homeStatsTaskDetails: 'Task details',
  I18n.homeStatsTaskDetailEmpty: 'No run details for the focused task',
  I18n.homeStatsNoTaskSelected: 'Select a task first',
  I18n.homeStatsExtensionsEmpty: 'No extension fields for this task',
  I18n.homeStatsDuration: 'Duration',
  I18n.homeStatsTodayChartTitle: 'Today task timeline',
  I18n.homeStatsHistoryChartTitle: 'Historical task chart',
  I18n.homeStatsTodayChartEmpty: 'No realtime task blocks for today yet',
  I18n.homeStatsHistoryDateEmpty: 'No historical date is available yet',
  I18n.homeStatsLatestTask: 'Latest task',
  I18n.homeStatsLatestTime: 'Latest time',
  I18n.homeStatsCurrentTask: 'Current task',
  I18n.homeStatsCurrentTime: 'Current time',
  I18n.homeStatsIdle: 'Idle',
  I18n.homeStatsStartTime: 'Start time',
  I18n.homeStatsTaskFilter: 'Task filter',
  I18n.homeStatsAllTasks: 'All tasks',
  I18n.homeStatsRunDetails: 'Run details',
  I18n.homeStatsSelectedBlock: 'Selected block',
  I18n.homeStatsLoadingMessage: 'Collecting statistics, please wait',
  I18n.homeStatsSummaryRunDuration: 'Runtime',
  I18n.homeStatsSummaryRunTaskCount: 'Task total',
  I18n.homeStatsSummaryTotalBattleCount: 'Battle total',
  I18n.homeStatsSortByData: 'Data',
  I18n.homeStatsSortByTime: 'Time',
  I18n.homeStatsNoBattle: 'No battle',
  I18n.homeTaskFilterAll: 'All tasks',
  I18n.homeTaskFilterEnabled: 'Enabled',
  I18n.homeTaskFilterDisabled: 'Disabled',
  I18n.homeTaskEnabled: 'Enabled',
  I18n.homeTaskDisabled: 'Disabled',
  I18n.homeQuickRun: 'Run now',
  I18n.homeQuickWait: 'Wait now',
  I18n.homeQuickRunAll: 'Run all now',
  I18n.homeQuickWaitAll: 'Wait all now',
  I18n.homeBulkQuickScheduleTimedOut:
      'Bulk quick scheduling is still running; controls were restored',
  I18n.homeOpenTaskParams: 'Edit',
  I18n.homeTaskConfigureAndEnable: 'Configure and enable',
  I18n.homeTaskSelectPrompt: 'Select a task from the task list first',
  I18n.homeRealtimeLog: 'Realtime',
  I18n.homeHistoryLog: 'History',
  I18n.homeLogSearchHint: 'Search logs or enter regex',
  I18n.homeLogUseRegex: 'Regex',
  I18n.homeLogWrapLines: 'Wrap lines',
  I18n.homeLogAutoScroll: 'Auto-scroll',
  I18n.homeLogLoadOlder: 'Load older',
  I18n.homeLogEmptyFiltered: 'No matching logs',
  I18n.homeLogInfoTab: 'Info',
  I18n.homeLogErrorTab: 'Error',
  I18n.homeLogNoErrors: 'No error logs today',
  I18n.homeLogImages: 'images',
  I18n.homeLogSelectError: 'Select an error log',
  I18n.homeLogDownloadImage: 'Download image',
  I18n.homeLogImageSaveSuccess: 'Image saved',
  I18n.homeLogImageSaveFailed: 'Failed to save image',
  I18n.homeLogScrollToBottom: 'Scroll to bottom',
  I18n.behaviorAnalysisTab: 'Behavior',
  I18n.behaviorAnalysisPrivacyNotice:
      'Privacy: OASX reads and analyzes this data only on this device. It is not linked to game accounts and is never uploaded. Results belong only to the current configuration log; if one configuration is used for multiple accounts, the combined log is shown and individual accounts cannot be distinguished.',
  I18n.behaviorAnalysisRefresh: 'Reload and analyze log',
  I18n.behaviorAnalysisTaskFilter: 'Task filter',
  I18n.behaviorAnalysisAllTasks: 'All tasks',
  I18n.behaviorAnalysisClickCount: 'clicks',
  I18n.behaviorAnalysisWaitCount: 'random waits',
  I18n.behaviorAnalysisTaskCount: 'tasks with clicks',
  I18n.behaviorAnalysisClickPath: 'Click positions and sequence path',
  I18n.behaviorAnalysisShowPath: 'Show path',
  I18n.behaviorAnalysisRandomWaits: 'Random wait distribution',
  I18n.behaviorAnalysisTaskDurations: 'Task click-duration distribution',
  I18n.behaviorAnalysisTimeline: 'Task and restart timeline',
  I18n.behaviorAnalysisNoClicks: 'No click records were found in this log',
  I18n.behaviorAnalysisNoWaits: 'No random wait records were found in this log',
  I18n.behaviorAnalysisNoDurations: 'No click durations were found for this task',
  I18n.behaviorAnalysisNoLogs: 'No local logs are available for this configuration',
  I18n.behaviorAnalysisNoTimeline: 'No task or restart events were found in this log',
  I18n.behaviorAnalysisSamples: 'samples, median',
  I18n.behaviorAnalysisLoading: 'Analyzing the local log',
  I18n.behaviorAnalysisLocalOnly:
      'Behavior analysis requires a desktop build with access to local OAS logs',
  I18n.behaviorAnalysisRootMissing: 'Set a valid OAS root directory first',
  I18n.behaviorAnalysisReadFailed: 'Failed to read the local log',
  I18n.behaviorAnalysisTime: 'Time',
  I18n.behaviorAnalysisTask: 'Task',
  I18n.behaviorAnalysisTarget: 'Target',
  I18n.behaviorAnalysisCoordinates: 'Coordinates',
  I18n.behaviorAnalysisDuration: 'Duration',
  I18n.behaviorAnalysisCategory: 'Category',
  I18n.behaviorAnalysisRange: 'Range',
  I18n.behaviorAnalysisCount: 'Count',
  I18n.behaviorAnalysisProportion: 'Share',
  I18n.behaviorAnalysisNote: 'Note',
  I18n.behaviorAnalysisStartTime: 'Start',
  I18n.behaviorAnalysisEndTime: 'End',
  I18n.behaviorAnalysisTaskRun: 'Task run',
  I18n.behaviorAnalysisScriptStart: 'Script start',
  I18n.behaviorAnalysisPlannedRestart: 'Scheduled restart',
  I18n.behaviorAnalysisAnomalyRestart: 'Unexpected restart',
  I18n.behaviorAnalysisAtxRestart: 'Unexpected ATX restart',
  I18n.behaviorAnalysisInferredEnd:
      'The log has no end record; inferred from the next task or final log entry',
  I18n.behaviorAnalysisAnomalyLane: 'Unexpected restart',
  I18n.behaviorAnalysisTaskLane: 'Task run',
  I18n.behaviorAnalysisLifecycleLane: 'Script lifecycle',
  I18n.argsDraftDirty: 'Pending changes',
  I18n.argsMixedValue: 'Mixed value',
  I18n.argsDiscardChanges: 'Discard',
  I18n.argsSaveChanges: 'Save',
  I18n.argsValidationFailed: 'Fix validation errors before saving',
  I18n.argsInvalidInteger: 'Enter a valid integer',
  I18n.argsInvalidNumber: 'Enter a valid number',
  I18n.argsInvalidTime: 'Time must use HH:MM:SS',
  I18n.argsInvalidTimeDelta: 'Duration must use DD HH:MM:SS',
  I18n.argsInvalidDateTime: 'Date time must use YYYY-MM-DD HH:MM:SS',
  I18n.argsInvalidEnum: 'Select a valid option',
  I18n.argsMinValue: 'Min value',
  I18n.argsMaxValue: 'Max value',
  I18n.argsUnsavedPrompt: 'There are unsaved changes. Discard them?',
  I18n.taskManage: 'Task Manager',
  I18n.taskManageTitle: 'Task Manager',
  I18n.taskSearchHint: 'Search tasks',
  I18n.taskNotFound: 'No matching tasks',
  I18n.taskMenuLoadFailed: 'Failed to load task menu',
};

final Map<String, String> _us_script = {
  I18n.serialHelp: '''Common emulator serials can be found in the list below. 
Fill in "auto" to automatically detect the emulator. When multiple emulators are running or an emulator that does not support automatic detection is used, "auto" cannot be used and must be filled in manually.
  
Default emulator serials: 
[MuMu Player 12]: 127.0.0.1:16384 
[MuMu Player]: 127.0.0.1:7555 
[LDPlayer](all series): emulator-5554 or 127.0.0.1:5555
If it's not mentioned, it may not have been tested or is not recommended. You can try it yourself. 
If you use the multi-instance function of the emulator, their serials will not be the default. You can query them by executing adb devices in console.bat, or fill them in according to the official emulator tutorial''',
  I18n.handleHelp:
      '''Fill in "auto" to automatically detect the emulator. "auto" cannot be used when multiple emulators are running or when using an emulator that does not support automatic detection; it must be filled in manually. The input is the handle title or handle number. The handle number changes each time the emulator is started. Clearing it means not using the window operation method.

Handle Title: 
[MuMu Player 12]: "MuMu Player 12" 
[MuMu Player]: "MuMu Player" 
[LDPlayer](all series): "LDPlayer"

Handle Number: 
Some emulators have the same handle title when multiple instances are opened (referring to MuMu). In this case, you need to manually obtain the emulator's handle number and set it manually. 
Please refer to the documentation for tools to obtain it: [Emulator Support]''',
  I18n.packageNameHelp:
      'When multiple game clients are installed on the emulator, you need to manually select the server',
  I18n.screenshotMethodHelp:
      '''When automatic selection is used, a performance test will be performed once, and it will automatically change to the fastest screenshot solution. The general speed is: 
window_background ~= nemu_ipc >>> DroidCast_raw > ADB_nc >> DroidCast > uiautomator2 ~= ADB 
Using window_background for screenshots is about 10ms, compared to DroidCast_raw which is about 100ms (only on the author's computer). However, window_background has a fatal flaw: the emulator cannot be minimized. 
nemu_ipc is limited to MuMu Player 12 and requires a version greater than 3.8.13, and the emulator's execution path needs to be set''',
  I18n.controlMethodHelp:
      '''Speed: window_message ~= minitouch > Hermit >>> uiautomator2 ~= ADB 
The control method simulates human speed, and faster is not always better. Using (window_message) may occasionally fail''',
  I18n.emulatorinfoTypeHelp: '''Select the type of emulator you are using''',
  I18n.emulatorinfoNameHelp:
      '''Example: MuMuPlayer-12.0-0, if unclear, please consult the documentation''',
  I18n.adbRestartHelp: '',
  I18n.notifyConfigHelp:
      'Input is in YAML format, there is a space after the colon ":", for details please refer to the documentation [Message Push]',
  I18n.screenshotIntervalHelp:
      'The minimum interval between two screenshots, limited to 0.1 ~ 0.3, can reduce CPU usage for high-configuration computers',
  I18n.combatScreenshotIntervalHelp:
      'The minimum interval between two screenshots, limited to 0.1 ~ 1.0, can reduce CPU usage during battles',
  I18n.taskHoardingDurationHelp:
      'Can reduce the frequency of game operations during farming periods. After a task is triggered, wait X minutes, then execute the accumulated tasks all at once',
  I18n.whenTaskQueueEmptyHelp:
      'Close the game when there are no tasks, which can reduce CPU usage during farming periods',
  I18n.scheduleRuleHelp:
      '''The scheduling objects referred to here are those in Pending; tasks in Waiting are not included. 
Filter-based scheduling: The default option. The execution order of tasks will be scheduled according to the order determined during development, which is generally the optimal solution. 
First-In, First-Out (FIFO)-based scheduling: Tasks will be sorted by their next execution time, and those at the front will be executed first. 
Priority-based scheduling: High-priority tasks are executed before low-priority tasks. Tasks with the same priority are executed in a first-come, first-served order''',
  'emulatorinfo_path_help':
      'Example: "E:\\ProgramFiles\\MuMuPlayer-12.0\\shell\\MuMuPlayer.exe"',
};

final Map<String, String> _us_restart = {
  I18n.enableHelp: 'Add this task to the scheduler',
  I18n.nextRunHelp:
      'The time will be automatically calculated based on the interval below',
  I18n.priorityHelp:
      'This option is valid if the scheduling rule is set to priority-based. The default is 5. The lower the number, the higher the priority. The range is [1-15]. If the priority is the same, tasks are scheduled on a first-come, first-served basis',
  I18n.successIntervalHelp: '',
  I18n.failureIntervalHelp: '',
  I18n.serverUpdateHelp:
      'If it\'s not set to the default "09:00:00", the task will forcibly set the next run time to the set value of the next day after each execution',
  I18n.harvestEnableHelp:
      'This section is for automatically clicking on login rewards when logging into the game. It is a required option',
  'rest_task_datetime_help': '',
  'delay_date_help':
      'When the forced execution time is enabled above, customize how many days later to enforce execution. By default, it\'s one day later, meaning the next day',
  'float_time_help':
      'To prevent account suspension, the next run time will be randomly delayed within this range; generally, three to five minutes is sufficient. When forced execution is enabled, ensure it does not exceed the window: for example, Kirin at 19:00 + 2 minutes, Demon Encounter at 17:00 + 1.5 hours, to avoid affecting other tasks',
};

final Map<String, String> _us_global_game = {
  I18n.friendInvitationHelp: 'Accept all by default',
  'accept_invitation_complete_now_help':
      'To prevent cancellation by the other party due to two hours of inactivity, it is enabled by default',
  I18n.invitationDetectIntervalHelp:
      'Detect collaboration every 10 seconds by default',
  I18n.whenNetworkAbnormalHelp: 'By default, it will wait for 10 seconds first',
  I18n.whenNetworkErrorHelp: 'Restart the game',
  I18n.homeClientClearHelp:
      'Sometimes it may require clearing the cache when entering the courtyard',
  I18n.enableHelp: 'Add this task to the scheduler',
  I18n.brokerHelp: '',
  I18n.portHelp: '',
  I18n.transportHelp: '',
  I18n.caHelp: '',
  I18n.usernameHelp: '',
  I18n.passwordHelp: '',
  // ---------------------------------------------------------------------
  'costume_main': 'On Tranquil Views',
  'costume_main_1': 'Celestial Garden',
  'costume_main_2': 'Luminescent Night',
  'costume_main_3': 'Melodic Pavilion',
  'costume_main_4': 'Painted Panorama',
  'costume_main_5': 'Autumn Maples',
  'costume_main_6': 'Hot Spring',
  'costume_main_7': 'Summer Nights',
  'costume_main_8': 'Far-sailing Ship',
  // ---------------------------------------------------------------------
  'costume_realm_default': 'Umbrella Sanctuary',
  'costume_realm_1': 'Demon Spirit Charms',
  'costume_realm_2': 'Fox\'s Defensive Realm',
  'costume_realm_3': 'Threaded Memories',
  'costume_realm_4': 'Sea of Flowers',
  // ---------------------------------------------------------------------
  'costume_battle_1': 'Realm of Melodies',
};

final Map<String, String> _us_invite_config = {
  'invite_number_help':
      'This is effective when you are the team leader. You can choose 1 or 2. If you choose 1, only the first teammate will be invited',
  'friend_name_help':
      'When inputting your teammate\'s name, it must be the full name. This is based on OCR recognition, so if the name is too unusual, it\'s recommended to spend 200 Jade to change it to something more standard',
  'friend_2_name_help': 'Same as above',
  'find_mode_help':
      'By default, it will automatically search from the list above: \n"Friend" -> "Recent" -> "Guildmate" -> "Cross-server". Of course, it is recommended to select ‘recent_friend’ as this will be faster',
  'wait_time_help':
      'Keep the default setting for one minute, and invite once every 20 seconds during this period',
  'default_invite_help': '',
};

final Map<String, String> _us_general_battle_config = {
  'lock_team_enable_help':
      'If the team is locked, preset teams and buff features cannot be enabled',
  'preset_enable_help':
      'The team preset will be switched during the first battle',
  'preset_group_help': 'Select[1~7]',
  'preset_team_help': 'Select[1~5]',
  'green_enable_help':
      'Click the green mark at the moment the battle starts, with no feedback on the click',
  'green_mark_help':
      'Select from [Left 1, Left 2, Left 3, Left 4, Left 5, Main Onmyoji]',
  'random_click_swipt_enable_help':
      'Anti-blocking optimization: may trigger 0-8 times in every three minutes of battle. Please note that this conflicts with the green mark function and may cause random clicks on the green mark',
};

final Map<String, String> _us_switch_soul = {
  'switch_group_team_help':
      '''The initial value is not suitable; you need to set it according to your own situation. 
'1,2' indicates the first preset group and the second team. 
Please use a comma from the English input method. 
Preset groups support [1-7], and preset teams support [1-4]''',
  'enable_switch_by_name_help':
      'This is another way to switch souls. Compared to the method above, it supports more presets, but similarly, you still need to ensure that the preset team is in a locked state',
};
