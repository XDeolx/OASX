import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/api/github_release_model.dart';
import 'package:oasx/service/app_update/update_package_io.dart';

void main() {
  test('fetchJsonMap sends GitHub headers and parses release JSON', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final requestHandled = server.first.then((request) async {
      expect(request.headers.value(HttpHeaders.userAgentHeader), 'OASX-Updater');
      expect(
        request.headers.value(HttpHeaders.acceptHeader),
        'application/vnd.github+json',
      );
      expect(
        request.headers.value('X-GitHub-Api-Version'),
        '2022-11-28',
      );
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'tag_name': 'testoyj-v0.3.12.7',
          'html_url': 'https://example.test/release',
        }),
      );
      await request.response.close();
    });

    final result = await UpdatePackageIo.fetchJsonMap(
      'http://${server.address.host}:${server.port}/latest',
    );

    await requestHandled;
    expect(result['tag_name'], 'testoyj-v0.3.12.7');
    expect(result['html_url'], 'https://example.test/release');
  });

  test('fetchJsonMap reports the remote status code', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final requestHandled = server.first.then((request) async {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
    });

    final request = UpdatePackageIo.fetchJsonMap(
      'http://${server.address.host}:${server.port}/latest',
    );

    await expectLater(
      request,
      throwsA(
        isA<HttpException>().having(
          (error) => error.message,
          'message',
          'request_failed_403',
        ),
      ),
    );
    await requestHandled;
  });

  test('fetchLatestReleaseTag parses a relative GitHub redirect', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final requestHandled = server.first.then((request) async {
      expect(request.headers.value(HttpHeaders.userAgentHeader), 'OASX-Updater');
      request.response.statusCode = HttpStatus.found;
      request.response.headers.set(
        HttpHeaders.locationHeader,
        '/XDeolx/OASX/releases/tag/testoyj-v1.0.1',
      );
      await request.response.close();
    });

    final tag = await UpdatePackageIo.fetchLatestReleaseTag(
      'http://${server.address.host}:${server.port}/releases/latest',
    );

    await requestHandled;
    expect(tag, 'testoyj-v1.0.1');
  });

  test('fallback release metadata points to the versioned Windows zip', () {
    final release = GithubReleaseModel.fromTagFallback(
      tag: 'testoyj-v1.0.1',
      releaseBaseUrl: 'https://github.com/XDeolx/OASX/releases',
    );

    expect(release.version, 'testoyj-v1.0.1');
    expect(
      release.releasePageUrl,
      'https://github.com/XDeolx/OASX/releases/tag/testoyj-v1.0.1',
    );
    expect(release.assets, hasLength(1));
    expect(release.assets!.single.name, 'oasx_testoyj-v1.0.1_windows.zip');
    expect(
      release.assets!.single.downloadUrl,
      'https://github.com/XDeolx/OASX/releases/download/'
      'testoyj-v1.0.1/oasx_testoyj-v1.0.1_windows.zip',
    );
  });
}
