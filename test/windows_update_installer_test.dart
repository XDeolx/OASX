import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/service/app_update/installers/windows_update_installer.dart';

void main() {
  const installer = WindowsUpdateInstaller();

  test('Windows update manifest preserves special paths exactly', () {
    final manifest = jsonDecode(
      installer.buildManifestJson(
        currentProcessId: 123,
        installDirectory: r"C:\Users\x'y\OASX [test]",
        zipPath: r"C:\Users\x'y\下载\oasx 100% & test.zip",
        executableName: 'oasx.exe',
      ),
    ) as Map<String, dynamic>;

    expect(manifest['schemaVersion'], 1);
    expect(manifest['processId'], 123);
    expect(manifest['installDirectory'], r"C:\Users\x'y\OASX [test]");
    expect(manifest['zipPath'], r"C:\Users\x'y\下载\oasx 100% & test.zip");
    expect(manifest['executableName'], 'oasx.exe');
  });

  test('Windows updater preflights before handoff and supports rollback', () {
    final script = installer.buildScript();

    expect(script, contains('ConvertFrom-Json'));
    expect(
      script,
      contains(r'[System.IO.Directory]::Exists($installDir)'),
    );
    expect(script, contains(r'[System.IO.Directory]::Move'));
    expect(script, contains(r"$basePath + '.ready'"));
    expect(script, contains(r"$basePath + '.failed'"));
    expect(script, contains('Creating recovery copy...'));
    expect(script, contains('Preflight complete. Waiting for OASX to exit...'));
    expect(script, contains('Previous version restored and restarted.'));
    expect(script, isNot(contains('Read-Host')));
    expect(script, isNot(contains(r'Test-Path $installDir')));
  });

  test('Windows updater handoff returns when ready marker appears', () async {
    final directory = await Directory.systemTemp.createTemp('oasx_ready_test_');
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final readyFile = File('${directory.path}\\update.ready');
    final failureFile = File('${directory.path}\\update.failed');
    final cancelFile = File('${directory.path}\\update.cancel');

    final readyWriter = Future<void>.delayed(
      const Duration(milliseconds: 20),
      () async {
        await readyFile.writeAsString('ready');
      },
    );

    await installer.waitForHandoff(
      readyFile: readyFile,
      failureFile: failureFile,
      cancelFile: cancelFile,
      timeout: const Duration(seconds: 1),
      pollInterval: const Duration(milliseconds: 10),
    );
    await readyWriter;
    expect(cancelFile.existsSync(), isFalse);
  });

  test('Windows updater handoff exposes the preparation failure', () async {
    final directory = await Directory.systemTemp.createTemp('oasx_fail_test_');
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final readyFile = File('${directory.path}\\update.ready');
    final failureFile = File('${directory.path}\\update.failed');
    final cancelFile = File('${directory.path}\\update.cancel');
    await failureFile.writeAsString('\uFEFFInstall directory is unavailable.');

    await expectLater(
      installer.waitForHandoff(
        readyFile: readyFile,
        failureFile: failureFile,
        cancelFile: cancelFile,
        timeout: const Duration(seconds: 1),
        pollInterval: const Duration(milliseconds: 10),
      ),
      throwsA(
        isA<WindowsUpdateHandoffException>().having(
          (error) => error.message,
          'message',
          'Install directory is unavailable.',
        ),
      ),
    );
  });

  test('Windows updater handoff timeout leaves a cancel marker', () async {
    final directory = await Directory.systemTemp.createTemp('oasx_timeout_test_');
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final readyFile = File('${directory.path}\\update.ready');
    final failureFile = File('${directory.path}\\update.failed');
    final cancelFile = File('${directory.path}\\update.cancel');

    await expectLater(
      installer.waitForHandoff(
        readyFile: readyFile,
        failureFile: failureFile,
        cancelFile: cancelFile,
        timeout: const Duration(milliseconds: 30),
        pollInterval: const Duration(milliseconds: 10),
      ),
      throwsA(isA<WindowsUpdateHandoffException>()),
    );
    expect(cancelFile.existsSync(), isTrue);
  });
}
