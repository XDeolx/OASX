import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/service/locale_service.dart';
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

  test('older remote translations cannot remove the Chess test marker', () {
    final merged = protectBundledChessTestTranslations({
      'zh_CN': {
        'Chess': '百鬼棋局',
        I18n.chessTestNotice: '旧提示',
      },
      'en_US': {
        'Chess': 'Chess',
        I18n.chessTestNotice: 'Old notice',
      },
    });

    expect(merged['zh_CN']!['Chess'], '百鬼棋局（测试版）');
    expect(
      merged['zh_CN']![I18n.chessTestNotice],
      contains('testoyj-chess-legacy'),
    );
    expect(merged['en_US']!['Chess'], 'Chess (Test)');
    expect(
      merged['en_US']![I18n.chessTestNotice],
      contains('testoyj-chess-legacy'),
    );
  });
}
