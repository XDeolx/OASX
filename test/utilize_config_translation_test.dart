import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/translation/i18n.dart';

void main() {
  test('kekkai utilize guild reward options have Chinese translations', () {
    final translations = Messages().keys['zh_CN']!;

    expect(translations['guild_lottery_enable'], '顺手进行寮抽奖');
    expect(
      translations['guild_lottery_enable_help'],
      contains('默认关闭'),
    );
    expect(translations['guild_reward_random_wait'], '寮奖励随机等待');
    expect(
      translations['guild_reward_random_wait_help'],
      contains('2-4 秒'),
    );
  });
}
