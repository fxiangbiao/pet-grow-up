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

当前处于 **实现阶段**。前后端代码均已完整，P0/P1 子系统全部落地，仅 P2
（时空裂隙系统）尚未实现。代码已纳入 Git 版本控制（2026-06-27 完成 initial commit）。

> 设计文档（v1.0, 2026-04-20）位于 `游戏化宠物养成系统设计方案.md`；
> 冒险模式改造方案见 `冒险模式设计方案.md`，且**已全栈实现**。

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

### 冒险模式（已落地，核心玩法）

每次答题被改造为一次「小冒险」，前端维护全部实时状态（HP/Combo/Boss/宝箱），
后端仅在结算时记录 `maxCombo` / `bossDefeated` / `comboBonusEnergy`。关键契约：

- `study/dto/AnswerResultDTO.java` —— 含 `isLastQuestion`（标记 Boss 题）
- `study/dto/SessionResultDTO.java` —— 含 `maxCombo`、`bossDefeated`、`comboBonusEnergy`
- 前端组件：`AdventurePath` / `ComboCounter` / `BossBattle` / `HpBar` / `TreasureChest` 等
  （见 `frontend/src/lib/components/study/`）

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
│       │   ├── schema.sql               # 20 张表 DDL（336 行）
│       │   └── data.sql                 # 种子数据（237 行）
│       └── test/                # 仅 5 个测试：auth/spirit/exploration/achievement/EnergyCalculator
├── frontend/                    # Vite + SvelteKit
│   └── src/
│       ├── routes/              # SvelteKit 文件路由
│       │   ├── (auth)/          # 登录 / 注册
│       │   └── app/             # 鉴权后主应用（/app, /app/study, /app/spirit ...）
│       └── lib/
│           ├── components/      # layout / spirit / study / energy / feedback / shop / social / common
│           ├── stores/          # Svelte 5 rune 状态（auth/spirit/energy/toast/achievement/story）
│           ├── api/             # Fetch 封装 + 各模块 API client
│           └── types/           # TypeScript 接口
├── docker-compose.yml           # MySQL 8.0（仅数据库，无后端/前端容器化）
├── 游戏化宠物养成系统设计方案.md   # 产品设计文档 v1.0
├── 冒险模式设计方案.md           # 冒险模式改造方案（已实现）
└── .gitignore
```

## 数据库

20 张表，Spring Boot 启动时通过 `schema.sql`（`CREATE TABLE IF NOT EXISTS`）自动建表，
`data.sql` 播种学科世界、题目、成就定义、商店物品、剧情章节等基础数据。
开发库口令与 `docker-compose.yml` 保持一致（非生产凭证）。

## 本地运行

```bash
# 1. 启动 MySQL（默认口令见 docker-compose.yml）
docker compose up -d

# 2. 后端（默认端口 8080，建表+播种自动执行）
cd backend && ./mvnw spring-boot:run        # 或 mvn spring-boot:run

# 3. 前端（默认端口 5173）
cd frontend && npm install && npm run dev
```

## 待办与风险

- **测试覆盖薄弱**：仅 5 个测试文件，集中在 5 个模块，其余 9 个业务模块无测试。
- **未容器化后端/前端**：`docker-compose.yml` 仅含 MySQL，无应用镜像与发布流程。
- **P2 时空裂隙系统未实现**：设计文档中唯一缺失的子系统。
- **学习内容数据**：`data.sql` 种子内容是否充足，需结合实际学科题库评估。

## 约定

- 前端使用 Svelte 5 runes（`$state` / `$derived`），状态存放于 `lib/stores/*.svelte.ts`。
- 后端按业务模块分包，每个模块含 `controller / service / mapper / entity / dto` 分层。
- 统一响应封装 `common/response/ApiResponse`，异常走 `common/exception/GlobalExceptionHandler`。
- 学习能量计算集中在 `common/util/EnergyCalculator`。
