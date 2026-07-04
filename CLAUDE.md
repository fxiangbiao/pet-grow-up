# CLAUDE.md

本文件为 Claude Code（claude.ai/code）在本仓库工作时提供指引。

## 项目概述

游戏化宠物养成系统 —— 一个将 K-12 学习（语文、数学、英语）转化为冒险体验的
游戏化学习平台。学生通过完成学习任务来养成「学习精灵」，探索各学科主题的奇幻世界。

核心设计理念：「一核三柱两环」
- **1 核**：学习能量系统 —— 一切学习产生能量，一切游戏内容消耗能量
- **3 柱**：探索/净化系统、情感连接系统、收集/成就系统
- **2 环**：学科专属系统、社交互动系统

## 项目状态

v2 重构阶段。P0/P1 子系统全部落地，P2（时空裂隙）未实现。
- Sprint 1（2026-06-29）：双路径「凑十法」Demo 对比，**选定 Svelte 路径继续**。
- Sprint 2（2026-06-30）：场景组件扩充（SceneTap/SceneMatch）+ 题库 45→77 + 剧情模式接入场景题型。
- Sprint A（2026-06-30）：6 个新场景组件 + 题库 77→~200 + 音频动画升级 + 冒险模式渐进演化。
- **Sprint B（2026-07-02）**：宇宙星空冒险地图 + 战斗动画重构 + BGM 柔和化 + 题库扩充至 491 题（年级 1-3）+ 剧情 24 章。
- **Sprint C（2026-07-03）**：星灵羁绊核心 — 性格选择（4 选 1）、多情绪动画（greeting/sleeping/dim）、迎接/告别系统、休眠机制（损失厌恶）。
- **Sprint D（2026-07-03）**：净化重构 — 战斗系统→净化系统（HP→能量水晶、Boss→守护者、怪物→暗水晶、「⚔️ 攻击」→「🌟 净化」、移除死亡惩罚）。
- **Sprint E（2026-07-03）**：收集驱动 — 配饰系统（12 件装备）、扭蛋机（稀有度分层）、星灵装备 UI、成就图鉴（翻书模式 + 知识点图鉴）。
- **Sprint F（2026-07-04）**：惊喜系统 — 每日登录盲盒（含 3/7/14/30 天里程碑）、学习后随机惊喜事件、宠物小屋装饰（自由放置 + 6 主题房间）。
- **Sprint F Layer 1（2026-07-04）**：视觉升级 — 配饰/家具从 emoji 升级为手绘 SVG 渲染器、6 种可收集房间主题、slot_data JSON 迁移为自由坐标。
- **Sprint F Layer 2（2026-07-04）**：交互升级 — 自由拖拽摆放家具（pointer capture + 实时位置保存）、点击交互（窗户→昼夜切换、灯→开关、地毯→精灵旋转舞蹈、精灵→对话气泡）。
- **Sprint F Layer 3（2026-07-04）**：精灵 AI — 自主行为状态机（10 种状态：idle/wander/sit/read/play/sleep），基于家具存在性和快乐度的加权随机选择，CSS transition 平滑移动，行为标签指示器。
  v2 设计方案见 `游戏化学习系统设计方案-v2.md`。

## 已实现子系统

按设计文档优先级，对应代码位置：

| 优先级 | 子系统 | 后端包 | 前端目录 | 状态 |
|--------|--------|--------|----------|------|
| **P0** | 学习能量 | `energy` | `lib/stores/energy.svelte.ts`, `lib/api/energy.ts` | ✅ |
| **P0** | 探索/战斗（含冒险模式） | `study` | `routes/app/study/...`, `lib/components/study/` | ✅ |
| **P0** | 精灵养成 | `spirit` | `routes/app/spirit/`, `lib/components/spirit/` | ✅ |
| **P0** | 学科系统（3 学科） | `study` (SubjectWorld) | 同上，按 `[subject]` 路由 | ✅ |
| **P0** | 即时反馈 | `websocket` + `study` | `lib/components/feedback/`, `lib/api/study-ws.ts` | ✅ |
| **P1** | 成就勋章 | `achievement` | `lib/components/achievement/`, `lib/stores/achievement.svelte.ts` | ✅ |
| **P1** | 社交互动 | `social` | `routes/app/social/`, `lib/components/social/` | ✅ |
| **P1** | 商店/物品 | `shop` | `routes/app/shop/`, `lib/components/shop/` | ✅ |
| **P1** | 每日挑战 | `challenge` | `routes/app/daily/`, `lib/api/challenge.ts` | ✅ |
| — | 剧情系统 | `story` | `routes/app/story/`, `lib/components/story/` | ✅ |
| — | 用户中心 | `user` | `lib/api/user.ts` | ✅ |
| — | 惊喜系统 | `daily` + `event` | `lib/components/daily/`, `lib/components/study/RandomEventOverlay.svelte` | ✅ |
| — | 宠物小屋 | `room` | `routes/app/pet-room/`, `lib/components/room/`, `lib/room/` | ✅ |
| **P2** | 时空裂隙系统 | — | — | ❌ 未实现 |

### 冒险模式（Sprint D 净化重构，核心玩法）

每次答题被改造为一次「知识净化之旅」，前端维护全部实时状态（Energy/Combo/Guardian/宝箱），
后端仅在结算时记录 `maxCombo` / `bossDefeated` / `comboBonusEnergy`。关键契约：

- `study/dto/AnswerResultDTO.java` —— 含 `isLastQuestion`
- `study/dto/SessionResultDTO.java` —— 含 `maxCombo`、`bossDefeated`（字段名保留，语义变为守护者净化）、`comboBonusEnergy`
- 探索模式：宇宙星空地图（`AdventureMap.svelte`）→ 暗水晶节点 → 净化动画 → 答题 → 守护者遭遇
- 剧情模式：宇宙星空地图（`StoryMap.svelte`）→ 章节节点 → ChapterDialog → 净化场景
- 净化动画状态机：`idle → player_purify → idle`（答对）/ `idle → enemy_encourage → idle`（答错）/ `guardian_purified`（守护者净化）
- **零惩罚**：答错不扣能量、不死亡——combo 归零 + 守护者温和鼓励即可继续

**探索模式组件**（`frontend/src/lib/components/study/`）：
| 组件 | 用途 |
|------|------|
| `AdventureMap.svelte` | SVG 星空地图：60 颗闪烁星星 + 星云 + 星座连线 + 暗水晶节点（dark/purifying/purified 三态） + 精灵令牌 |
| `BattleScene.svelte` | 净化场景：精灵（左）vs 暗水晶（右），含净化/鼓励/守护者净化动画 + 地面场景 |
| `EnergyBar.svelte` | ⚡ 能量水晶条（替代旧 HpBar），答错闪红不扣值 |
| `ComboCounter.svelte` | ⭐ 星光连击倍率 |
| `GuardianEncounter.svelte` | 守护者净化（替代旧 BossBattle）：问候→净化光环→金光粒子→馈赠 |
| `GuardianReward.svelte` | 守护者馈赠弹窗 |
| `ExploreConfirm.svelte` | 冒险出发确认弹窗 |

**剧情模式组件**（`frontend/src/lib/components/story/`）：
| 组件 | 用途 |
|------|------|
| `StoryMap.svelte` | SVG 星空剧情地图：自适应行/列，蛇形星座连线，章节节点 + 精灵追踪 |
| `StoryStudyTask.svelte` | 剧情学习任务：净化场景 + 题目 + 净化动画 + Energy/Combo |
| `ChapterDialog.svelte` | 章节弹窗：叙事→对话→选择学科→学习任务→结果 |

### 情感宠物系统（Sprint C 羁绊核心）

`frontend/src/lib/components/spirit/` 目录：
| 组件 | 用途 |
|------|------|
| `SpiritAvatar.svelte` | SVG 精灵：7 种 mood（含 greeting/sleeping/dim）+ 4 种性格台词 + 眨眼/视线追踪 + SVG 配饰渲染（注册表驱动，按形态适配锚点）+ 休眠降饱和 |
| `PersonalityPicker.svelte` | 4 张性格卡片（元气/温柔/傲娇/勇敢），hover 预览台词 |
| `SpiritGreeting.svelte` | 回归迎接横幅：性格台词 + 打字机效果 + 休眠提示 |
| `SpiritSpeech.svelte` | 独立台词气泡，打字机动画 |
| `DormancyOverlay.svelte` | 沉睡全屏覆盖层，引导唤醒 |
| `PersonalityRadar.svelte` | 6 维度性格雷达图 |

**星灵 behavior：**
- 1 天未学 → dormancyLevel=1（暗淡，saturate 0.6）
- 3 天未学 → dormancyLevel=2（沉睡，Zzz 漂浮 + 覆盖层）
- 开始学习 → `recordInteraction()` 自动唤醒
- 打开 App >30min 间隔 → 性格迎接动画

### 配饰与收集系统（Sprint E 收集驱动）

- **12 件配饰**：头部×4、颈部×4（含毅力围巾）、眼部×2、特效×2
- **装备栏位**：head/neck/eyes/effect 各 1 件，星灵详情页切换
- **扭蛋机**：单抽 50⚡ / 每日免费 / 稀有度分层（Common 70%, Rare 25%, Epic 5%）/ 重复返还
- **成就图鉴**：列表/翻书双模式，知识点图鉴按学科分组
- `spirit_accessory` 表记录装备状态

### 惊喜系统（Sprint F）

`frontend/src/lib/components/daily/` + `frontend/src/lib/components/study/RandomEventOverlay.svelte`：

| 组件 | 用途 |
|------|------|
| `BlindBoxAnimation.svelte` | 每日盲盒：idle→抖动→开启→揭晓奖励，里程碑（3/7/14/30 天）光环特效 |
| `RandomEventOverlay.svelte` | 学习后随机惊喜弹窗：bounceIn 动画 + 精灵台词 + 奖励摘要 |

**后端：**
- `daily/` — 每日奖励状态查询/领取，`updateLoginStreak()` 钩在 `AuthService.login()`
- `event/` — 随机事件引擎：概率独立投骰，按正确率/连续天数过滤，钩在 `ExplorationService.completeSession()`
- `DailyRewardDef` 7 条种子（3 每日随机 + 4 里程碑），`RandomEventDef` 6 条种子（BONUS_ENERGY/SPIRIT_GIFT/DOUBLE_REWARD/STREAK_BONUS/FREE_ITEM）

### 宠物小屋与配饰渲染（Sprint F Layer 1）

`frontend/src/lib/room/` + `frontend/src/lib/accessories/`：

| 目录 | 用途 |
|------|------|
| `lib/accessories/renderers/` | 配饰 SVG 渲染注册表 — head/neck/eyes/effects 各 2-4 个 renderer，按精灵形态（书童/猫/巫师）调整锚点 |
| `lib/room/furniture/` | 12 件家具手绘 SVG 渲染器（床/沙发/书架/灯/地毯/盆栽/窗户/海报/球/挂饰/桌/钟），含投影 + 环境光 |
| `lib/room/themes/` | 6 种房间主题（温馨暖居/星空夜语/翠林幽居/古风书房/水晶殿堂/深海小屋），墙壁/地板/窗/灯/地毯/环境粒子 |
| `PetRoomScene.svelte` | 多层 SVG 房间：主题墙 → 粒子 → 窗/灯 → 地板 → 家具（按 y 排序 + 拖拽）→ 精灵（CSS 定位，行为状态机驱动平滑移动） |
| `DecorationPicker.svelte` | 底部弹出装饰品选择器 |
| `behavior.ts` | 精灵自主行为引擎：10 状态加权随机 + 家具感知 + 快乐度调制 |

**数据库：**
- `room_theme_def` 表（6 主题种子）+ `ROOM_THEME` 类别 `item_def`（5 件可购买/扭蛋主题）
- `pet_room.slot_data` 从 `{"slot_key": item_def_id}` 迁移为 `[{"userItemId":N, "itemDefId":N, "itemKey":"...", "x":100, "y":200}]` 自由坐标格式
- `pet_room.room_style` 默认值从 `'DEFAULT'` 改为 `'cozy_warm'`

**API 新增：** `PUT /pet-room/position`（更新家具位置），`PUT /pet-room/theme`（切换主题）

### 场景化题型组件（Sprint 1-2 + Sprint A）

12 种题型全部拥有专属交互组件，场景类题型遵循 `$props({ question, sessionId, onComplete })` 自提交模式：

| 题型 | 组件 | 学科 | 玩法 |
|------|------|------|------|
| `SCENE_DRAG` | `SceneMathTen.svelte` | 数学 | 拖苹果到碗凑十 |
| `SCENE_TAP` | `SceneTap.svelte` | 数学/语文/英语 | 浮动泡泡点击答题 |
| `SCENE_MATCH` | `SceneMatch.svelte` | 数学/英语 | 图形/卡片配对识别 |
| `SCENE_WHACK_MOLE` | `SceneWhackMole.svelte` | 数学 | 打地鼠·20以内加减 |
| `SCENE_SHAPE_PUZZLE` | `SceneShapePuzzle.svelte` | 数学 | 拼图工坊·认识图形 |
| `SCENE_CLOCK` | `SceneClock.svelte` | 数学 | 拨钟表·认识整时 |
| `SCENE_SHOP` | `SceneShop.svelte` | 数学 | 宠物商店·认识人民币 |
| `SCENE_PINYIN` | `ScenePinyinBubble.svelte` | 语文 | 拼音泡泡·听音识字母 |
| `SCENE_CHAR_BUILD` | `SceneCharBuild.svelte` | 语文 | 汉字工坊·组字寻宝 |
| `POEM_SEQUENCE` | `PoemSequence.svelte` | 语文 | 诗句拖拽排序 |
| `MATH_INPUT` | `MathInput.svelte` | 数学 | 数字键盘输入 |
| `VOCAB_MATCH` | `VocabMatch.svelte` | 英语 | 单词释义配对 |

### 音频系统（Sprint B 柔和化升级）

`frontend/src/lib/audio/sound-manager.ts` — Web Audio API 合成，无外部音频文件依赖。
- **9 首 BGM**（3学科×3场景）：全部重写为 sine+triangle 波，自然小调/Dorian 调式，低频旋律（C4-C5），
  节奏脉冲（volume LFO），主音量降至 0.12。去掉 sawtooth/square 等刺耳波形。
- **11 个场景专属音效** + **5 个宠物情感音效** + **Boss 音效**（已柔和化）
- Boss 主题从 sawtooth/square 改为 sine/triangle

## 技术栈

| 层 | 选型 |
|----|------|
| 前端 | Vite + SvelteKit + Svelte 5（runes）+ Tailwind CSS |
| 后端 | Spring Boot 3.2.4 + Mybatis-Flex 1.9.7 + Maven |
| 数据库 | MySQL 8.0（`schema.sql` + `data.sql`，Spring Boot 启动时 `sql.init.mode=always` 自动建表与播种） |
| 认证 | JWT（jjwt 0.12.x，access + refresh 双令牌） |
| 实时通信 | STOMP over WebSocket |
| API 文档 | springdoc-openapi（Swagger UI） |

## 项目结构

```
pet-grow-up/
├── backend/                     # Spring Boot + Mybatis-Flex
│   └── src/
│       ├── main/java/com/petgrowup/
│       │   ├── auth/            # JWT 认证（access + refresh）
│       │   ├── spirit/          # 精灵/学习精灵养成 + 性格维度
│       │   ├── energy/          # 学习能量系统（产生与消费流水）
│       │   ├── study/           # 学科世界 / 知识图谱 / 答题 / 冒险结算
│       │   ├── achievement/     # 成就（8 个 Checker + 注册表）
│       │   ├── social/          # 好友 / 排行榜 / 用户搜索
│       │   ├── shop/            # 商店购买 + 背包物品使用
│       │   ├── challenge/       # 每日挑战定义与进度
│       │   ├── story/           # 剧情章节与学习任务
│       │   ├── user/            # 用户资料
│       │   ├── common/          # ApiResponse / 异常处理 / JwtUtil / EnergyCalculator
│       │   ├── config/          # SecurityConfig / WebConfig / JwtAuthenticationFilter / WebSocketConfig
│       │   └── websocket/       # 实时学习反馈
│       ├── main/resources/
│       │   ├── application.yml          # 含开发用 DB 口令（与 docker-compose 一致）
│       │   ├── application-dev.yml      # dev profile（日志 + CORS）
│       │   ├── schema.sql               # 21 张表 DDL（含 grade_level 迁移）
│       │   └── data.sql                 # 种子数据（1133 行：44 知识节点 + 491 题 + 24 剧情章节）
│       └── test/                # 仅 5 个测试：auth/spirit/exploration/achievement/EnergyCalculator
├── frontend/                    # Vite + SvelteKit
│   └── src/
│       ├── routes/              # SvelteKit 文件路由
│       │   ├── (auth)/          # 登录 / 注册
│       │   └── app/             # 鉴权后主应用（/app, /app/study, /app/spirit ...）
│       └── lib/
│           ├── components/      # layout / spirit / study / story / energy / feedback / shop / social / common
│           ├── stores/          # Svelte 5 rune 状态（auth/spirit/energy/toast/achievement/story）
│           ├── api/             # Fetch 封装 + 各模块 API client
│           ├── types/           # TypeScript 接口（含 adventure-map.ts）
│           └── audio/           # Web Audio API BGM + SFX 合成（sound-manager.ts）
├── docker-compose.yml           # MySQL 8.0（仅数据库，无后端/前端容器化）
├── 游戏化宠物养成系统设计方案-v1.md   # 产品设计文档 v1.0
├── 游戏化学习系统设计方案-v2.md    # 沉浸式重构方案 v2.0（2026-06-27）
├── .plans/                      # Sprint 计划文档
└── .gitignore
```

## 数据库

25 张表（含 Sprint F 的 `daily_reward_def`、`random_event_def`、`pet_room`、`room_theme_def`），Spring Boot 启动时通过 `schema.sql`（`CREATE TABLE IF NOT EXISTS`）自动建表，
`data.sql` 播种学科世界、题目、成就定义、商店物品（含配饰）、剧情章节等基础数据。
开发库口令与 `docker-compose.yml` 保持一致（非生产凭证）。

### 知识图谱（Sprint B 扩展）

`knowledge_node` 表新增 `grade_level` 列（INT 1-6 对应小学年级）：

| 学科 | G1 | G2 | G3 | 合计 |
|------|:--:|:--:|:--:|:----:|
| 语文（诗词大陆） | 6 | 5 | 4 | **15** |
| 数学（智慧王国） | 11 | 6 | 6 | **23** |
| 英语（魔法学院） | 5 | 4 | 4 | **13** |

题库 491 题，覆盖 12 种题型，剧情章节 24 章（chapter 1-12 为 G1，13-24 为 G2-G3）。

## 本地运行

```bash
# 1. 启动 MySQL（默认口令见 docker-compose.yml）
docker compose up -d

# 2. 后端（默认端口 8080，建表+播种自动执行）
cd backend && mvn spring-boot:run

# 3. 前端（默认端口 5173）
cd frontend && npm install && npm run dev
```

## 待办与风险

- **测试覆盖薄弱**：仅 5 个测试文件，集中在 5 个模块，其余 9 个业务模块无测试。
- **未容器化后端/前端**：`docker-compose.yml` 仅含 MySQL，无应用镜像与发布流程。
- **P2 时空裂隙系统未实现**：设计文档中唯一缺失的子系统。
- **题库需持续对标课标**：当前 491 题覆盖 G1-G3，后续需扩展 G4-G6 及更多题型变体。
- **知识节点 grade_level 未在 API 暴露**：前端目前未按年级筛选节点，后续需在 SubjectWorld API 中增加年级过滤。
- **旧组件清理**：`HpBar/BossBattle/BossHealthBar/BossLootDrop/BossPhaseOverlay/BossSection/DamageNumber/AdventurePath/EnemySprite` 等旧战斗组件保留在磁盘上但已无引用，后续可安全删除。
- **多精灵同屏 + 好友访客模式待实施**：多只精灵同时出现在房间、好友互相参观小屋、留言/表情反应。

## 约定

- 前端使用 Svelte 5 runes（`$state` / `$derived` / `$derived.by` / `$effect` / `$props`），状态存放于 `lib/stores/*.svelte.ts`。
- 后端按业务模块分包，每个模块含 `controller / service / mapper / entity / dto` 分层。
- 统一响应封装 `common/response/ApiResponse`，异常走 `common/exception/GlobalExceptionHandler`。
- 学习能量计算集中在 `common/util/EnergyCalculator`。
- 冒险地图/战斗系统全部前端逻辑，后端 API 不变（`startSession` / `submitAnswer` / `getSessionResult`）。
- SVG 渲染地图（无外部游戏引擎依赖），CSS 动画（闪烁星星、脉冲光环、令牌浮动）。
