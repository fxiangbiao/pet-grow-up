# CLAUDE.md

本文件为 AI 编码助手在本仓库工作时提供指引。

## 项目概述

游戏化宠物养成学习系统 —— 将 K-12 学习（语文、数学、英语）转化为冒险体验。
学生通过完成学习任务养成「学习精灵」，探索各学科主题的奇幻世界。

核心设计：「一核三柱两环」
- **1 核**：学习能量系统（一切学习产生能量，一切游戏消耗能量）
- **3 柱**：探索/净化、情感连接、收集/成就
- **2 环**：学科专属、社交互动

## 技术栈

| 层 | 选型 |
|----|------|
| 前端 | Vite + SvelteKit + Svelte 5（runes）+ Tailwind CSS |
| 后端 | Spring Boot 3.2.4 + Mybatis-Flex 1.9.7 + Maven |
| 数据库 | MySQL 8.0（`schema.sql` + `data.sql`，启动自动建表播种） |
| 认证 | JWT（jjwt 0.12.x，access + refresh 双令牌） |
| 实时通信 | STOMP over WebSocket |
| API 文档 | springdoc-openapi（Swagger UI） |

## 项目结构

```
pet-grow-up/
├── backend/
│   └── src/main/java/com/petgrowup/
│       ├── admin/           # 管理后台（用户/商品/题库/节点/统计）
│       ├── auth/            # JWT 认证
│       ├── spirit/          # 精灵养成 + 性格维度
│       ├── energy/          # 学习能量（产生与消费流水）
│       ├── study/           # 学科世界 / 知识图谱 / 答题 / 冒险结算
│       ├── achievement/     # 成就（8 Checker + 注册表）
│       ├── social/          # 好友 / 排行榜
│       ├── shop/            # 商店 + 背包
│       ├── challenge/       # 每日挑战
│       ├── story/           # 剧情章节
│       ├── daily/ + event/  # 每日奖励 + 随机事件引擎
│       ├── room/            # 宠物小屋（家具/主题/拖拽）
│       ├── user/            # 用户资料
│       ├── common/          # ApiResponse / 异常 / JwtUtil / EnergyCalculator
│       ├── config/          # Security / CORS / JWT Filter / WebSocket
│       └── websocket/       # 实时学习反馈
├── frontend/
│   └── src/
│       ├── routes/
│       │   ├── (auth)/          # 登录 / 注册
│       │   ├── (admin)/admin/   # 管理后台
│       │   └── app/             # 主应用（study/spirit/story/shop/...）
│       └── lib/
│           ├── components/      # 各模块 UI 组件
│           ├── stores/          # Svelte 5 rune 状态（*.svelte.ts）
│           ├── api/             # Fetch 封装 + 各模块 API client
│           ├── types/           # TypeScript 接口
│           ├── audio/           # Web Audio API BGM + SFX 合成
│           ├── room/            # 房间家具/主题 SVG 渲染
│           └── accessories/     # 配饰 SVG 渲染注册表
├── docker-compose.yml           # MySQL 8.0
└── 游戏化宠物养成系统设计方案-v1.md / v2.md  # 产品设计文档
```

## 已实现子系统

| 优先级 | 子系统 | 后端包 | 前端目录 | 状态 |
|--------|--------|--------|----------|------|
| P0 | 学习能量 | `energy` | `stores/energy.svelte.ts`, `api/energy.ts` | ✅ |
| P0 | 探索/净化（冒险模式） | `study` | `routes/app/study/`, `components/study/` | ✅ |
| P0 | 精灵养成 | `spirit` | `routes/app/spirit/`, `components/spirit/` | ✅ |
| P0 | 学科系统（3 学科） | `study` | 按 `[subject]` 路由 | ✅ |
| P0 | 即时反馈 | `websocket` + `study` | `components/feedback/`, `api/study-ws.ts` | ✅ |
| P1 | 成就勋章 | `achievement` | `components/achievement/` | ✅ |
| P1 | 社交互动 | `social` | `routes/app/social/` | ✅ |
| P1 | 商店/物品 | `shop` | `routes/app/shop/` | ✅ |
| P1 | 每日挑战 | `challenge` | `routes/app/daily/` | ✅ |
| — | 剧情系统 | `story` | `routes/app/story/` | ✅ |
| — | 惊喜系统 | `daily` + `event` | `components/daily/` | ✅ |
| — | 宠物小屋 | `room` | `routes/app/pet-room/`, `lib/room/` | ✅ |
| — | 管理后台 | `admin` | `routes/(admin)/admin/` | ✅ |
| P2 | 时空裂隙 | — | — | ❌ |

### 核心玩法：净化之旅

答题 = 知识净化。前端维护全部实时状态（Energy/Combo/Guardian/宝箱），后端仅结算时记录。
- 探索模式：星空地图 → 暗水晶节点 → 净化动画 → 答题 → 守护者遭遇
- 剧情模式：星空地图 → 章节节点 → 叙事 → 净化场景
- 零惩罚：答错不扣能量，combo 归零 + 守护者鼓励即可继续
- 关键 DTO：`AnswerResultDTO`（含 isLastQuestion）、`SessionResultDTO`（含 maxCombo/bossDefeated）

### 12 种题型组件

所有场景组件遵循 `$props({ question, sessionId, onComplete })` 自提交模式：
SCENE_DRAG / SCENE_TAP / SCENE_MATCH / SCENE_WHACK_MOLE / SCENE_SHAPE_PUZZLE /
SCENE_CLOCK / SCENE_SHOP / SCENE_PINYIN / SCENE_CHAR_BUILD / POEM_SEQUENCE /
MATH_INPUT / VOCAB_MATCH

### 管理后台

- 角色：`users.role`（STUDENT/ADMIN），JWT 含 role claim，`@PreAuthorize("hasRole('ADMIN')")`
- 模块：题库 CRUD + 知识节点树 + 用户管理 + 商品管理 + 统计仪表盘
- 编辑器：12 种题型各有专属编辑器，通过 `QuestionFormShell.svelte` 中央调度
- 预览：`AdminQuestionPreview.svelte` 缩放容器 + `{#key}` 强制重挂载 + `preview` prop 禁用交互
- 统计：CSS 柱状图（无图表库），8 概览指标 + 学习趋势 + 能量流转 + 成就解锁率

## 本地运行

```bash
# 1. 启动 MySQL
docker compose up -d

# 2. 后端（端口 8080，建表+播种自动执行）
cd backend && mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 3. 前端（端口 5173）
cd frontend && npm install && npm run dev
```

WSL 开发环境：MySQL 用 Docker 容器，后端/前端在 WSL 中原生运行（Java 17 + Maven + Node.js 22）。

## 约定

- **前端**：Svelte 5 runes（`$state` / `$derived` / `$derived.by` / `$effect` / `$props`），状态存放于 `lib/stores/*.svelte.ts`
- **后端**：按业务模块分包，每模块含 `controller / service / mapper / entity / dto`
- **响应**：统一 `ApiResponse<T>`，异常走 `GlobalExceptionHandler`
- **能量**：计算集中在 `EnergyCalculator`
- **音频**：Web Audio API 合成（9 BGM + 16 SFX），无外部音频文件
- **SVG 渲染**：精灵/配饰/家具/地图全部手绘 SVG，CSS 动画

## 待办与风险

- **测试覆盖薄弱**：仅 5 个测试文件，其余 10+ 模块无测试
- **P2 时空裂隙未实现**：设计文档中唯一缺失的子系统
- **SCENE_SHAPE_PUZZLE 用 GenericEditor**：唯一未配专属编辑器的题型
- **题库需扩展 G4-G6**：当前 502 题仅覆盖 G1-G3
- **旧组件可清理**：HpBar/BossBattle/BossHealthBar 等旧战斗组件已无引用
