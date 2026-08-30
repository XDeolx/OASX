import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/service/app_update/installers/windows_update_installer.dart';

void main() {
  test('Windows updater stages beside install and rolls back on failure', () {
    const installer = WindowsUpdateInstaller();
    final script = installer.buildScript(
      currentProcessId: 123,
      installDirectory: r'E:\Apps\OASX',
      zipPath: r'C:\Temp\oasx.zip',
      executableName: 'oasx.exe',
    );

    expect(script, contains(r'$workRoot = Join-Path $installParent'));
    expect(script, contains(r'$backupDir = Join-Path $installParent'));
    expect(script, contains(r'$backupCreated = $true'));
    expect(script, contains('Restoring previous installation...'));
    expect(script, contains('Previous version restored and restarted.'));
    expect(script, contains('-PassThru'));
    expect(script, contains('The updated OASX process exited during startup.'));
  });
}
