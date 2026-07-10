// Shared label maps for admin pages — eliminates duplication across pages

export const USER_ROLE_LABELS: Record<string, string> = {
  STUDENT: '学生',
  ADMIN: '管理员',
};

export const ITEM_CATEGORY_LABELS: Record<string, string> = {
  FOOD: '食物',
  TOY: '玩具',
  ACCESSORY: '配饰',
  DECORATION: '装饰',
  ROOM_THEME: '房间主题',
  CONSUMABLE: '消耗品',
};

export const EFFECT_TYPE_LABELS: Record<string, string> = {
  HAPPINESS: '快乐度',
  ENERGY: '精力',
  AFFECTION: '亲密度',
  COSMETIC: '外观',
};

export const ACHIEVEMENT_CATEGORY_LABELS: Record<string, string> = {
  STUDY: '学习',
  SUBJECT: '学科',
  SPIRIT: '精灵',
  COLLECTION: '收集',
  EVENT: '活动',
  SOCIAL: '社交',
};

export const ACHIEVEMENT_RARITY_LABELS: Record<string, string> = {
  COMMON: '普通',
  RARE: '稀有',
  EPIC: '史诗',
  LEGENDARY: '传说',
};

export const ENERGY_SOURCE_LABELS: Record<string, string> = {
  study_session: '学习探险',
  achievement: '成就奖励',
  daily_challenge: '每日挑战',
  random_event: '随机惊喜',
  story_chapter: '剧情章节',
  daily_reward: '每日签到',
  shop_purchase: '商店购买',
  gacha_draw: '扭蛋抽卡',
  feed: '喂养精灵',
  evolve: '精灵进化',
};
