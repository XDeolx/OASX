import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/translation/i18n.dart';
import 'package:oasx/translation/i18n_content.dart';

void main() {
  test('Chess test task has an explicit Chinese name and rollback notice', () {
    final translations = Messages().all_cn_translate;

    expect(translations['Chess'], '百鬼棋局（测试版）');
    expect(
      translations[I18n.chessTestNotice],
      contains('testoyj-chess-legacy'),
    );
  });
}
