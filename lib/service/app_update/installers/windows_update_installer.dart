import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:oasx/api/github_release_model.dart';
import 'package:oasx/service/app_update/installers/app_update_installer.dart';
import 'package:oasx/service/app_update/models/app_update_plan.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';

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
    final currentProcessId = pid;
    final executablePath = Platform.resolvedExecutable;
    final installDirectory = File(executablePath).parent.path;
    final executableName = File(executablePath).uri.pathSegments.last;
    final scriptFile = File('${package.filePath}.ps1');
    final launcherFile = File('${package.filePath}.cmd');
    final powershellPath = _resolvePowerShellPath();
    final scriptContent = buildScript(
      currentProcessId: currentProcessId,
      installDirectory: installDirectory,
      zipPath: package.filePath,
      executableName: executableName,
    );
    final launcherContent = _buildLauncherScript(
      powershellPath: powershellPath,
      scriptPath: scriptFile.path,
    );
    await scriptFile.writeAsString(scriptContent, encoding: utf8);
    await launcherFile.writeAsString(launcherContent, encoding: utf8);
    await Process.start(
      'cmd.exe',
      [
        '/c',
        'start',
        '',
        'cmd.exe',
        '/c',
        'call',
        launcherFile.path,
      ],
      runInShell: false,
      workingDirectory: scriptFile.parent.path,
    );
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      exit(0);
    });
  }

  /// Builds the Windows handoff script that applies the downloaded zip.
  @visibleForTesting
  String buildScript({
    required int currentProcessId,
    required String installDirectory,
    required String zipPath,
    required String executableName,
  }) {
    final installDirLiteral = _psLiteral(installDirectory);
    final zipPathLiteral = _psLiteral(zipPath);
    final executableLiteral = _psLiteral(executableName);
    return r'''
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'OASX Updater'
$processId = __PROCESS_ID__
$installDir = __INSTALL_DIR__
$zipPath = __ZIP_PATH__
$exeName = __EXE_NAME__
$originalExeName = $exeName
$installParent = Split-Path -Parent $installDir
$installName = Split-Path -Leaf $installDir
$workRoot = Join-Path $installParent ('.oasx_update_' + $processId)
$stageDir = Join-Path $workRoot 'stage'
$backupDir = Join-Path $installParent ($installName + '.oasx_backup')
$targetExe = Join-Path $installDir $exeName
$logPath = Join-Path ([System.IO.Path]::GetDirectoryName($zipPath)) 'oasx_update.log'
$backupCreated = $false

function Write-Step($message) {
  $line = '[OASX Updater] ' + $message
  Write-Host $line
  Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

try {
  Set-Content -LiteralPath $logPath -Value '[OASX Updater] Starting update...' -Encoding UTF8

  Write-Step 'Waiting for OASX to exit...'
  for ($index = 0; $index -lt 120; $index++) {
    if (-not (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
      break
    }
    Start-Sleep -Milliseconds 500
  }

  if (Get-Process -Id $processId -ErrorAction SilentlyContinue) {
    throw 'Timed out waiting for the running OASX process to exit.'
  }

  Write-Step 'Preparing update workspace...'
  if (Test-Path $workRoot) {
    Remove-Item -LiteralPath $workRoot -Recurse -Force
  }
  New-Item -ItemType Directory -Path $stageDir -Force | Out-Null

  Write-Step 'Extracting update package...'
  Expand-Archive -LiteralPath $zipPath -DestinationPath $stageDir -Force

  if (-not (Test-Path $stageDir)) {
    throw 'The extracted update directory does not exist.'
  }

  $packageRoot = $stageDir
  $stagedExe = Join-Path $packageRoot $exeName
  if (-not (Test-Path $stagedExe)) {
    $foundExe = Get-ChildItem -LiteralPath $stageDir -Filter $exeName -File -Recurse | Select-Object -First 1
    if ($null -eq $foundExe) {
      $foundExe = Get-ChildItem -LiteralPath $stageDir -Filter *.exe -File -Recurse | Select-Object -First 1
    }
    if ($null -eq $foundExe) {
      throw 'No executable was found in the extracted update package.'
    }
    $stagedExe = $foundExe.FullName
    $packageRoot = Split-Path -Parent $stagedExe
    $exeName = Split-Path -Leaf $stagedExe
  }
  $targetExe = Join-Path $installDir $exeName

  if (-not (Test-Path $stagedExe)) {
    throw 'The update package executable could not be validated.'
  }

  Write-Step 'Backing up current installation...'
  if (Test-Path $backupDir) {
    Remove-Item -LiteralPath $backupDir -Recurse -Force
  }
  if (-not (Test-Path $installDir)) {
    throw 'The current installation directory does not exist.'
  }
  Move-Item -LiteralPath $installDir -Destination $backupDir
  $backupCreated = $true

  Write-Step 'Replacing installation files...'
  Move-Item -LiteralPath $packageRoot -Destination $installDir

  if (-not (Test-Path $targetExe)) {
    throw ('The updated executable was not found: ' + $targetExe)
  }

  Write-Step 'Starting updated OASX...'
  $newProcess = Start-Process -FilePath $targetExe -ArgumentList '--skip-parent-console' -WorkingDirectory $installDir -PassThru
  Start-Sleep -Seconds 3
  $newProcess.Refresh()
  if ($newProcess.HasExited) {
    throw 'The updated OASX process exited during startup.'
  }

  Write-Step 'Update complete. Removing backup...'
  Remove-Item -LiteralPath $backupDir -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 800
  exit 0
} catch {
  $failureMessage = $_.Exception.Message
  Write-Host ''
  Write-Host '[OASX Updater] Update failed.' -ForegroundColor Red
  Write-Host $failureMessage -ForegroundColor Red
  Add-Content -LiteralPath $logPath -Value ('[OASX Updater] Update failed: ' + $failureMessage) -Encoding UTF8

  if ($backupCreated -and (Test-Path $backupDir)) {
    Write-Step 'Restoring previous installation...'
    if (Test-Path $installDir) {
      Remove-Item -LiteralPath $installDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (-not (Test-Path $installDir)) {
      Move-Item -LiteralPath $backupDir -Destination $installDir
    }
    $restoredExe = Join-Path $installDir $originalExeName
    if (Test-Path $restoredExe) {
      Start-Process -FilePath $restoredExe -ArgumentList '--skip-parent-console' -WorkingDirectory $installDir | Out-Null
      Write-Step 'Previous version restored and restarted.'
    }
  }

  Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host ''
  Write-Host ('Update log: ' + $logPath)
  Read-Host 'Press Enter to close this window'
  exit 1
}
'''
        .replaceFirst('__PROCESS_ID__', currentProcessId.toString())
        .replaceFirst('__INSTALL_DIR__', installDirLiteral)
        .replaceFirst('__ZIP_PATH__', zipPathLiteral)
        .replaceFirst('__EXE_NAME__', executableLiteral);
  }

  /// Converts a value into a PowerShell single-quoted literal.
  String _psLiteral(String value) {
    final escaped = value.replaceAll("'", "''");
    return "'$escaped'";
  }

  /// Builds the visible launcher command script that hosts the updater window.
  String _buildLauncherScript({
    required String powershellPath,
    required String scriptPath,
  }) {
    final escapedPowerShellPath = _cmdEscape(powershellPath);
    final escapedScriptPath = _cmdEscape(scriptPath);
    return '''
@echo off
title OASX Updater
setlocal
"$escapedPowerShellPath" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$escapedScriptPath"
exit /b %errorlevel%
''';
  }

  /// Escapes a Windows command argument for use inside a batch file.
  String _cmdEscape(String value) {
    return value.replaceAll('"', '""');
  }

  /// Resolves the full PowerShell executable path for Windows.
  String _resolvePowerShellPath() {
    final systemRoot = Platform.environment['SystemRoot'];
    if (systemRoot == null || systemRoot.isEmpty) {
      return 'powershell.exe';
    }
    return '$systemRoot\\System32\\WindowsPowerShell\\v1.0\\powershell.exe';
  }
}
