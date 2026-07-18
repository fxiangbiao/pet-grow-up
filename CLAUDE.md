# CLAUDE.md

AI 编码助手在本仓库工作时的参考指引。

## 项目概述

游戏化宠物养成学习系统。K-12 学习内容（语文/数学/英语）与精灵养成结合。

核心：学习能量系统 —— 学习产生能量，游戏消耗能量。

## 技术栈

| 层 | 选型 |
|----|------|
| 前端 | SvelteKit + Svelte 5（Runes）+ Tailwind CSS |
| 后端 | Spring Boot 3.2.4 + MyBatis-Flex 1.9.7 |
| 数据库 | MySQL 8.0（schema.sql + data.sql，启动自动建表播种） |
| 认证 | JWT 双令牌（access + refresh） |
| 实时 | STOMP over WebSocket |

## 项目结构

```
backend/src/main/java/com/petgrowup/
├── admin/        # 管理后台
├── auth/         # JWT 认证
├── spirit/       # 精灵养成 + 性格
├── energy/       # 学习能量流水
├── study/        # 学科/答题/冒险/教学内容
├── achievement/  # 成就（8 Checker）
├── social/       # 好友/排行榜
├── shop/         # 商店+背包
├── challenge/    # 每日挑战
├── story/        # 剧情数据（entity/mapper/service）
├── daily/ event/ # 每日奖励+随机事件
├── room/         # 宠物小屋
├── user/         # 用户资料
└── common/ config/ websocket/

frontend/src/
├── routes/
│   ├── (auth)/        # 登录/注册
│   ├── (admin)/admin/ # 管理后台
│   └── app/           # 主应用
└── lib/
    ├── components/    # UI 组件
    ├── stores/        # Svelte 5 rune 状态（*.svelte.ts）
    ├── api/           # Fetch 封装
    ├── audio/         # Web Audio API BGM+SFX 合成
    └── types/         # TypeScript 接口
```

## 学习闭环流程

```
chapter_intro → teaching → practice → playing → expand → result
```

- `chapter_intro`：章节剧情开场（ChapterIntro 组件，打字机效果）
- `teaching`：知识卡片（KnowledgeCards，可跳过）
- `practice`：热身练习（不计分，可跳过）
- `playing`：答题打怪（BattleScene + EnemySprite，答题=攻击）
- `expand`：举一反三（LearnByAnalogy + LittleTeacher，必选）
- `result`：成绩报告（SessionResult）

核心页面：`frontend/src/routes/app/study/[subject]/explore/+page.svelte`

## 约定

- **前端**：Svelte 5 runes（`$state`/`$derived`/`$derived.by`/`$effect`/`$props`）
- **后端**：按业务模块分包，每模块 `controller/service/mapper/entity/dto`
- **响应**：统一 `ApiResponse<T>`，异常走 `GlobalExceptionHandler`
- **场景组件**：`$props({ question, sessionId, onComplete })` 自提交模式
- **音频**：Web Audio API 合成，无外部音频文件
- **SVG**：精灵/配饰/家具/敌人全部手绘 SVG，CSS 动画

## 本地运行

```bash
# Docker 全栈部署
docker compose up --build -d

# 或本地开发
docker compose up -d mysql          # MySQL
cd backend && mvn spring-boot:run   # 后端 :8080
cd frontend && npm run dev          # 前端 :5173
```

## 待办

- 测试覆盖薄弱（仅 5 个测试文件）
- 题库需扩展 G4-G6（当前仅 G1-G3）
- P2 时空裂隙未实现
