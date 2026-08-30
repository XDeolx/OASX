// ignore_for_file: non_constant_identifier_names
part of i18n;

final Map<String, String> _cn_utilize_config = {
  'utilize_config': '结界蹭卡配置',
  'utilize_rule': '寄养规则',
  'utilize_rule_help': '挑选结界卡的规则，使用默认default即可，具体规则看文档[任务列表]，不可以选auto,已经弃置了。',
  'select_friend_list': '优先好友分组',
  'select_friend_list_help': '优先扫描所选分组；没有符合策略的四星以上卡时，自动扫描另一分组。',
  'lazy_mode': '怠惰模式',
  'lazy_mode_help': '随机采用快速选卡策略，减少逐张查看结界卡详情的操作。',
  'lazy_mode_weight': '怠惰模式触发概率',
  'lazy_mode_weight_help': '取值 0 到 1；1 表示每次都使用怠惰模式。',
  'shikigami_class': '寄养式神类型',
  'shikigami_class_help': '选择的式神类别（寄养默认选择N卡，且不建议选别的）',
  'shikigami_order': '选中第几个式神寄养',
  'shikigami_order_help': '从左开始选第几个式神',
  'guild_ap_enable': '顺路收取寮补给',
  'guild_ap_enable_help': '必选项',
  'guild_assets_enable': '顺路收取寮资金',
  'guild_assets_enable_help': '必选项',
  'guild_lottery_enable': '顺手进行寮抽奖',
  'guild_lottery_enable_help':
      '只控制是否进行寮抽奖，默认关闭。无论是否开启，蹭卡收尾都会顺手收取当前可见的寮资金（金币）和体力。',
  'guild_reward_random_wait': '寮奖励随机等待',
  'guild_reward_random_wait_help':
      '开启后，顺手收取寮资金（金币）、体力以及已启用的寮抽奖时，会在动作之间随机等待 2-4 秒；默认关闭。',
  'box_ap_enable': '顺路收取体力盒子',
  'box_ap_enable_help': '必选项',
  'box_exp_enable': '顺路收取经验盒子',
  'box_exp_enable_help': '必选项',
  'box_exp_waste': '从盒子提取经验时浪费一部分',
  'box_exp_waste_help':
      '某些时候寄养上存在满级的式神，收取经验盒子时会有提示，对于挂机玩家这点经验微不足道。如果不使能这一选项，将跳过收取经验盒子',
};
