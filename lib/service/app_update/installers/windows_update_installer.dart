import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:oasx/api/github_release_model.dart';
import 'package:oasx/service/app_update/installers/app_update_installer.dart';
import 'package:oasx/service/app_update/models/app_update_plan.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';

/// Raised when the external Windows updater cannot safely take over.
class WindowsUpdateHandoffException implements Exception {
  /// Creates a handoff failure with a user-facing reason.
  const WindowsUpdateHandoffException(this.message);

  /// Reason reported by the updater.
  final String message;

  @override
  String toString() => message;
}

/// Applies Windows portable zip updates through an external PowerShell script.
class WindowsUpdateInstaller implements AppUpdateInstaller {
  /// Creates a Windows update installer.
  const WindowsUpdateInstaller();

  @override
  String get installActionKey => I18n.downloadAndUpdate;

  @override
  Future<bool> canInstallInApp() async {
    final platformUtils = PlatformUtils();
    return !await platformUtils.isInstalledFromMicrosoftStore();
  }

  @override
  Future<GithubReleaseAssetModel?> selectAsset(
      GithubReleaseModel release) async {
    final assets = release.assets ?? const <GithubReleaseAssetModel>[];
    for (final asset in assets) {
      final name = (asset.name ?? '').toLowerCase();
      if (name.contains('windows') && name.endsWith('.zip')) {
        return asset;
      }
    }
    return null;
  }

  @override
  Future<void> install(DownloadedUpdatePackage package) async {
    final executablePath = Platform.resolvedExecutable;
    final packageBasePath = package.filePath;
    final scriptFile = File('$packageBasePath.ps1');
    final manifestFile = File('$packageBasePath.manifest.json');
    final readyFile = File('$packageBasePath.ready');
    final failureFile = File('$packageBasePath.failed');
    final cancelFile = File('$packageBasePath.cancel');

    for (final marker in [readyFile, failureFile, cancelFile]) {
      if (await marker.exists()) {
        await marker.delete();
      }
    }

    await manifestFile.writeAsString(
      buildManifestJson(
        currentProcessId: pid,
        installDirectory: File(executablePath).parent.path,
        zipPath: package.filePath,
        executableName: File(executablePath).uri.pathSegments.last,
      ),
      encoding: utf8,
      flush: true,
    );
    await scriptFile.writeAsString(
      buildScript(),
      encoding: utf8,
      flush: true,
    );

    // Keep the process observable until it writes the handoff marker. Detached
    // launch can silently fail on some Windows installations before PowerShell
    // starts, leaving OASX with no diagnostic to show.
    final updaterProcess = await Process.start(
      _resolvePowerShellPath(),
      [
        '-NoLogo',
        '-NoProfile',
        '-WindowStyle',
        'Hidden',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
      ],
      workingDirectory: scriptFile.parent.path,
    );

    await waitForHandoff(
      readyFile: readyFile,
      failureFile: failureFile,
      cancelFile: cancelFile,
      updaterExitCode: updaterProcess.exitCode,
    );
    exit(0);
  }

  /// Serializes update paths without embedding them in shell source code.
  @visibleForTesting
  String buildManifestJson({
    required int currentProcessId,
    required String installDirectory,
    required String zipPath,
    required String executableName,
  }) {
    return jsonEncode({
      'schemaVersion': 1,
      'processId': currentProcessId,
      'installDirectory': installDirectory,
      'zipPath': zipPath,
      'executableName': executableName,
    });
  }

  /// Waits until the updater has completed all checks and is ready to take over.
  @visibleForTesting
  Future<void> waitForHandoff({
    required File readyFile,
    required File failureFile,
    required File cancelFile,
    Future<int>? updaterExitCode,
    Duration timeout = const Duration(minutes: 3),
    Duration pollInterval = const Duration(milliseconds: 200),
  }) async {
    int? processExitCode;
    updaterExitCode?.then((code) {
      processExitCode = code;
    });
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await failureFile.exists()) {
        final reason = (await failureFile.readAsString())
            .replaceFirst('\uFEFF', '')
            .trim();
        throw WindowsUpdateHandoffException(
          reason.isEmpty ? 'Windows updater preparation failed.' : reason,
        );
      }
      if (await readyFile.exists()) {
        return;
      }
      if (processExitCode != null) {
        throw WindowsUpdateHandoffException(
          'Windows updater exited before preparing the update '
          '(exit code $processExitCode).',
        );
      }
      await Future<void>.delayed(pollInterval);
    }

    await cancelFile.writeAsString('cancel', flush: true);
    throw const WindowsUpdateHandoffException(
      'Windows updater preparation timed out. OASX was kept open.',
    );
  }

  /// Builds a path-safe updater script compatible with Windows PowerShell 5.1.
  @visibleForTesting
  String buildScript() {
    return r'''
$ErrorActionPreference = 'Stop'

$scriptPath = $MyInvocation.MyCommand.Path
$basePath = [System.IO.Path]::Combine(
  [System.IO.Path]::GetDirectoryName($scriptPath),
  [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)
)
$manifestPath = $basePath + '.manifest.json'
$readyPath = $basePath + '.ready'
$failurePath = $basePath + '.failed'
$cancelPath = $basePath + '.cancel'
$logPath = $basePath + '.update.log'
$processId = $null
$installDir = $null
$installParent = $null
$installName = $null
$exeName = $null
$workRoot = $null
$stageDir = $null
$recoveryDir = $null
$oldInstallDir = $null
$handoffReady = $false

function Write-Step($message) {
  $line = ('{0:yyyy-MM-dd HH:mm:ss.fff} [OASX Updater] {1}' -f (Get-Date), $message)
  [System.IO.File]::AppendAllText($logPath, $line + [Environment]::NewLine)
}

function Remove-Directory($path) {
  if ($path -and [System.IO.Directory]::Exists($path)) {
    [System.IO.Directory]::Delete($path, $true)
  }
}

function Copy-Directory($source, $destination) {
  [System.IO.Directory]::CreateDirectory($destination) | Out-Null
  foreach ($directory in [System.IO.Directory]::GetDirectories(
      $source, '*', [System.IO.SearchOption]::AllDirectories)) {
    $relative = $directory.Substring($source.Length).TrimStart('\')
    [System.IO.Directory]::CreateDirectory(
      [System.IO.Path]::Combine($destination, $relative)
    ) | Out-Null
  }
  foreach ($file in [System.IO.Directory]::GetFiles(
      $source, '*', [System.IO.SearchOption]::AllDirectories)) {
    $relative = $file.Substring($source.Length).TrimStart('\')
    $target = [System.IO.Path]::Combine($destination, $relative)
    [System.IO.File]::Copy($file, $target, $true)
  }
}

function Start-Oasx($path, $workingDirectory) {
  $startInfo = New-Object System.Diagnostics.ProcessStartInfo
  $startInfo.FileName = $path
  $startInfo.Arguments = '--skip-parent-console'
  $startInfo.WorkingDirectory = $workingDirectory
  $startInfo.UseShellExecute = $true
  return [System.Diagnostics.Process]::Start($startInfo)
}

try {
  [System.IO.File]::Delete($readyPath)
  [System.IO.File]::Delete($failurePath)
  [System.IO.File]::WriteAllText($logPath, '')
  Write-Step ('Windows version: ' + [Environment]::OSVersion.VersionString)
  Write-Step ('PowerShell version: ' + $PSVersionTable.PSVersion.ToString())

  if (-not [System.IO.File]::Exists($manifestPath)) {
    throw ('Update manifest was not found: ' + $manifestPath)
  }
  $manifestText = [System.IO.File]::ReadAllText($manifestPath)
  $manifest = $manifestText | ConvertFrom-Json
  if ([int]$manifest.schemaVersion -ne 1) {
    throw 'The update manifest version is not supported.'
  }

  $processId = [int]$manifest.processId
  $installDir = [System.IO.Path]::GetFullPath([string]$manifest.installDirectory)
  $zipPath = [System.IO.Path]::GetFullPath([string]$manifest.zipPath)
  $exeName = [string]$manifest.executableName
  $installParent = [System.IO.Directory]::GetParent($installDir).FullName
  $installName = [System.IO.Path]::GetFileName($installDir.TrimEnd('\'))
  $workRoot = [System.IO.Path]::Combine($installParent, '.oasx_update_' + $processId)
  $stageDir = [System.IO.Path]::Combine($workRoot, 'stage')
  $recoveryDir = [System.IO.Path]::Combine(
    $installParent, $installName + '.oasx_recovery_' + $processId
  )
  $oldInstallDir = [System.IO.Path]::Combine(
    $installParent, $installName + '.oasx_old_' + $processId
  )
  $currentExe = [System.IO.Path]::Combine($installDir, $exeName)

  Write-Step ('Install directory: ' + $installDir)
  Write-Step ('Current executable: ' + $currentExe)
  Write-Step ('Update package: ' + $zipPath)

  if (-not [System.IO.Directory]::Exists($installDir)) {
    throw ('The current installation directory does not exist: ' + $installDir)
  }
  if (-not [System.IO.File]::Exists($currentExe)) {
    throw ('The current executable does not exist: ' + $currentExe)
  }
  if (-not [System.IO.File]::Exists($zipPath)) {
    throw ('The downloaded update package does not exist: ' + $zipPath)
  }

  Write-Step 'Checking write access...'
  $probePath = [System.IO.Path]::Combine(
    $installParent, '.oasx_write_probe_' + $processId + '.tmp'
  )
  try {
    [System.IO.File]::WriteAllText($probePath, 'test')
  } finally {
    [System.IO.File]::Delete($probePath)
  }

  Write-Step 'Preparing update workspace...'
  Remove-Directory $workRoot
  Remove-Directory $recoveryDir
  Remove-Directory $oldInstallDir
  [System.IO.Directory]::CreateDirectory($stageDir) | Out-Null

  Write-Step 'Extracting update package...'
  Expand-Archive -LiteralPath $zipPath -DestinationPath $stageDir -Force
  $stagedExecutables = [System.IO.Directory]::GetFiles(
    $stageDir, $exeName, [System.IO.SearchOption]::AllDirectories
  )
  if ($stagedExecutables.Count -eq 0) {
    throw ('The update package does not contain ' + $exeName + '.')
  }
  $stagedExe = $stagedExecutables[0]
  $packageRoot = [System.IO.Path]::GetDirectoryName($stagedExe)

  Write-Step 'Creating recovery copy...'
  Copy-Directory $installDir $recoveryDir
  $recoveryExe = [System.IO.Path]::Combine($recoveryDir, $exeName)
  if (-not [System.IO.File]::Exists($recoveryExe)) {
    throw 'The recovery copy could not be validated.'
  }

  if ([System.IO.File]::Exists($cancelPath)) {
    throw 'The running OASX cancelled the update handoff.'
  }

  Write-Step 'Preflight complete. Waiting for OASX to exit...'
  [System.IO.File]::WriteAllText($readyPath, 'ready')
  $handoffReady = $true
  for ($index = 0; $index -lt 240; $index++) {
    if (-not (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
      break
    }
    Start-Sleep -Milliseconds 500
  }
  if (Get-Process -Id $processId -ErrorAction SilentlyContinue) {
    throw 'Timed out waiting for the running OASX process to exit.'
  }

  Write-Step 'Replacing installation files...'
  if ([System.IO.Directory]::Exists($installDir)) {
    [System.IO.Directory]::Move($installDir, $oldInstallDir)
  } else {
    Write-Step 'Install directory disappeared after handoff; using recovery copy if rollback is needed.'
  }
  [System.IO.Directory]::Move($packageRoot, $installDir)
  $targetExe = [System.IO.Path]::Combine($installDir, $exeName)
  if (-not [System.IO.File]::Exists($targetExe)) {
    throw ('The updated executable was not found: ' + $targetExe)
  }

  Write-Step 'Starting updated OASX...'
  $newProcess = Start-Oasx $targetExe $installDir
  Start-Sleep -Seconds 3
  $newProcess.Refresh()
  if ($newProcess.HasExited) {
    throw 'The updated OASX process exited during startup.'
  }

  Write-Step 'Update complete. Removing recovery files...'
  Remove-Directory $oldInstallDir
  Remove-Directory $recoveryDir
  Remove-Directory $workRoot
  exit 0
} catch {
  $failureMessage = $_.Exception.Message
  try {
    Write-Step ('Update failed: ' + $failureMessage)
    $failureDetail = $failureMessage + [Environment]::NewLine + 'Log: ' + $logPath
    [System.IO.File]::WriteAllText($failurePath, $failureDetail)
  } catch {}

  $runningProcess = $null
  if ($processId) {
    $runningProcess = Get-Process -Id $processId -ErrorAction SilentlyContinue
  }

  if ($handoffReady -and -not $runningProcess) {
    try {
      Write-Step 'Restoring previous installation...'
      Remove-Directory $installDir
      if ([System.IO.Directory]::Exists($oldInstallDir)) {
        [System.IO.Directory]::Move($oldInstallDir, $installDir)
      } elseif ([System.IO.Directory]::Exists($recoveryDir)) {
        [System.IO.Directory]::Move($recoveryDir, $installDir)
      }
      $restoredExe = [System.IO.Path]::Combine($installDir, $exeName)
      if ([System.IO.File]::Exists($restoredExe)) {
        Start-Oasx $restoredExe $installDir | Out-Null
        Write-Step 'Previous version restored and restarted.'
      }
    } catch {
      try { Write-Step ('Rollback failed: ' + $_.Exception.Message) } catch {}
    }

    try {
      Add-Type -AssemblyName System.Windows.Forms
      [System.Windows.Forms.MessageBox]::Show(
        "OASX update failed and the previous version was restored.`n`n$failureMessage`n`nLog: $logPath",
        'OASX Updater',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
      ) | Out-Null
    } catch {}
  }

  if (-not $handoffReady) {
    Remove-Directory $recoveryDir
    Remove-Directory $workRoot
  }
  exit 1
}
''';
  }

  /// Resolves the full Windows PowerShell path without relying on PATH.
  String _resolvePowerShellPath() {
    final systemRoot = Platform.environment['SystemRoot'];
    if (systemRoot == null || systemRoot.isEmpty) {
      return 'powershell.exe';
    }
    return '$systemRoot\\System32\\WindowsPowerShell\\v1.0\\powershell.exe';
  }
}
