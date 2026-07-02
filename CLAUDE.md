# CLAUDE.md

本文件为 Claude Code（claude.ai/code）在本仓库工作时提供指引。

## 项目概述

游戏化宠物养成系统 —— 一个将 K-12 学习（语文、数学、英语）转化为冒险体验的
游戏化学习平台。学生通过完成学习任务来养成「学习精灵」，探索各学科主题的奇幻世界。

核心设计理念：「一核三柱两环」
- **1 核**：学习能量系统 —— 一切学习产生能量，一切游戏内容消耗能量
- **3 柱**：探索/战斗系统、情感连接系统、收集/成就系统
- **2 环**：学科专属系统、社交互动系统

## 项目状态

实现阶段。P0/P1 子系统全部落地，P2（时空裂隙）未实现。
- Sprint 1（2026-06-29）：双路径「凑十法」Demo 对比，**选定 Svelte 路径继续**。
- Sprint 2（2026-06-30）：场景组件扩充（SceneTap/SceneMatch）+ 题库 45→77 + 剧情模式接入场景题型。
- Sprint A（2026-06-30）：6 个新场景组件 + 题库 77→~200 + 音频动画升级 + 冒险模式渐进演化。
- **Sprint B（2026-07-02）**：宇宙星空冒险地图 + 战斗动画重构 + BGM 柔和化 + 题库扩充至 491 题（年级 1-3）+ 剧情 24 章。
  计划文档见 `.plans/`，v2 设计方案见 `游戏化学习系统设计方案-v2.md`。

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
| **P2** | 时空裂隙系统 | — | — | ❌ 未实现 |

### 冒险模式（Sprint B 重构，核心玩法）

每次答题被改造为一次「小冒险」，前端维护全部实时状态（HP/Combo/Boss/宝箱），
后端仅在结算时记录 `maxCombo` / `bossDefeated` / `comboBonusEnergy`。关键契约：

- `study/dto/AnswerResultDTO.java` —— 含 `isLastQuestion`（标记 Boss 题）
- `study/dto/SessionResultDTO.java` —— 含 `maxCombo`、`bossDefeated`、`comboBonusEnergy`
- 探索模式：宇宙星空地图（`AdventureMap.svelte`）→ 怪物节点 → BattleScene 对战 → 答题 → 攻击动画
- 剧情模式：宇宙星空地图（`StoryMap.svelte`）→ 章节节点 → ChapterDialog → BattleScene 对战
- 战斗动画状态机：`idle → player_attack → idle`（答对）/ `idle → enemy_attack → idle`（答错）/ `enemy_defeated`（击杀）

**探索模式组件**（`frontend/src/lib/components/study/`）：
| 组件 | 用途 |
|------|------|
| `AdventureMap.svelte` | SVG 星空地图：60 颗闪烁星星 + 星云 + 星座连线 + 怪物节点 + HP 条 + 精灵令牌 |
| `BattleScene.svelte` | 对战画面：精灵（左）vs 怪物（右），含攻击/受击/击杀动画 + 地面场景 |
| `EnemySprite.svelte` | SVG 怪物精灵：minion（3 variant）/ boss，含 idle/hit/attacking/defeated 状态 |
| `HpBar.svelte` | ❤️ HP 红心条 |
| `ComboCounter.svelte` | 🔥 连击倍率 |
| `BossBattle.svelte` | Boss 终结战（充能→战斗→终结一击→战利品） |
| `ExploreConfirm.svelte` | 冒险出发确认弹窗 |

**剧情模式组件**（`frontend/src/lib/components/story/`）：
| 组件 | 用途 |
|------|------|
| `StoryMap.svelte` | SVG 星空剧情地图：自适应行/列，蛇形星座连线，章节节点 + 精灵追踪 |
| `StoryStudyTask.svelte` | 剧情学习任务：BattleScene 对战 + 题目 + 攻击动画 + HP/Combo |
| `ChapterDialog.svelte` | 章节弹窗：叙事→对话→选择学科→学习任务→结果 |

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

20 张表，Spring Boot 启动时通过 `schema.sql`（`CREATE TABLE IF NOT EXISTS`）自动建表，
`data.sql` 播种学科世界、题目、成就定义、商店物品、剧情章节等基础数据。
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

## 约定

- 前端使用 Svelte 5 runes（`$state` / `$derived` / `$derived.by` / `$effect` / `$props`），状态存放于 `lib/stores/*.svelte.ts`。
- 后端按业务模块分包，每个模块含 `controller / service / mapper / entity / dto` 分层。
- 统一响应封装 `common/response/ApiResponse`，异常走 `common/exception/GlobalExceptionHandler`。
- 学习能量计算集中在 `common/util/EnergyCalculator`。
- 冒险地图/战斗系统全部前端逻辑，后端 API 不变（`startSession` / `submitAnswer` / `getSessionResult`）。
- SVG 渲染地图（无外部游戏引擎依赖），CSS 动画（闪烁星星、脉冲光环、令牌浮动）。
