<p align="center">
  <h1 align="center">Pet Grow Up</h1>
  <p align="center">
    <strong>让学习成为一场奇幻冒险</strong><br>
    游戏化宠物养成学习系统 · K-12 语文 / 数学 / 英语
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/Svelte-5-orange" alt="Svelte 5">
    <img src="https://img.shields.io/badge/Spring_Boot-3.2.4-green" alt="Spring Boot">
    <img src="https://img.shields.io/badge/MySQL-8.0-blue" alt="MySQL">
    <img src="https://img.shields.io/badge/MyBatis_Flex-1.9.7-purple" alt="MyBatis-Flex">
  </p>
</p>

---

## 项目简介

Pet Grow Up 是一个将小学 1-6 年级学习内容与宠物养成游戏结合的教育平台。学生通过学习任务赚取能量，养育「学习精灵」，探索语文诗词大陆、数学智慧王国、英语魔法学院三大奇幻世界。

### 核心设计：一核三柱两环

```
                    ┌─────────────────┐
                    │  学习能量系统    │  ← 1 核：学习产生能量，游戏消耗能量
                    └────────┬────────┘
           ┌─────────────────┼─────────────────┐
     ┌─────┴─────┐    ┌─────┴─────┐    ┌──────┴──────┐
     │ 探索/净化  │    │ 情感连接   │    │ 收集/成就   │  ← 3 柱
     └─────┬─────┘    └─────┬─────┘    └──────┬──────┘
           └─────────────────┼─────────────────┘
              ┌──────────────┴──────────────┐
         ┌────┴────┐                  ┌─────┴─────┐
         │ 学科专属 │                  │ 社交互动   │  ← 2 环
         └─────────┘                  └───────────┘
```

## 功能亮点

### 净化之旅（核心玩法）
每次答题 = 一次知识净化。在宇宙星空地图上挑战暗水晶节点，答对触发净化动画，答错不扣能量——零惩罚设计，鼓励持续学习。

### 学习精灵养成
- 4 种性格（元气/温柔/傲娇/勇敢），影响台词与行为
- 7 种情绪状态（开心/普通/低落/暗淡/沉睡...），1 天未学变暗淡，3 天未学进入沉睡
- 12 件可收集配饰（头/颈/眼/特效），扭蛋机抽取
- 自主行为 AI：10 种状态（闲逛/阅读/玩耍/睡觉...）

### 宠物小屋
- 6 种房间主题（温馨暖居/星空夜语/翠林幽居/古风书房/水晶殿堂/深海小屋）
- 12 件手绘 SVG 家具，自由拖拽摆放
- 精灵自主行为：根据家具和快乐度选择行为，CSS 平滑移动

### 12 种互动题型
拖苹果凑十、打地鼠算数、拨钟表认时间、拼音泡泡听音、汉字工坊组字、诗句排序、单词配对......每种题型都有专属交互组件。

### 惊喜系统
- 每日登录盲盒（含 3/7/14/30 天里程碑奖励）
- 学习后随机惊喜事件弹窗
- 宠物小屋装饰系统

### 管理后台
- 题库 CRUD + 12 种题型专属编辑器 + 实时预览
- 知识节点树管理
- 用户管理（角色切换/密码重置）
- 统计仪表盘（学习趋势/能量流转/成就解锁率）

## 技术栈

| 层 | 技术 |
|----|------|
| **前端** | Vite · SvelteKit · Svelte 5 (Runes) · Tailwind CSS |
| **后端** | Spring Boot 3.2.4 · MyBatis-Flex 1.9.7 · Maven |
| **数据库** | MySQL 8.0（自动建表 + 种子数据） |
| **认证** | JWT 双令牌（Access + Refresh） |
| **实时** | STOMP over WebSocket |
| **音频** | Web Audio API 合成（9 BGM + 16 SFX，零外部文件） |
| **渲染** | 全手绘 SVG（精灵/配饰/家具/地图），CSS 动画 |

## 快速开始

### 前置要求

- Docker（用于 MySQL）
- Java 17+ & Maven
- Node.js 22+

### 启动步骤

```bash
# 1. 克隆项目
git clone <repo-url> && cd pet-grow-up

# 2. 启动 MySQL
docker compose up -d

# 3. 启动后端（端口 8080，自动建表 + 播种数据）
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 4. 启动前端（端口 5173）
cd frontend
npm install
npm run dev
```

打开浏览器访问 **http://localhost:5173**

默认管理员账号：`admin` / `admin123`

### WSL 开发环境

MySQL 用 Docker 容器，后端/前端在 WSL 中原生运行（Java 17 + Maven + Node.js 22）。

## 项目结构

```
pet-grow-up/
├── backend/                  # Spring Boot 后端
│   └── src/main/java/com/petgrowup/
│       ├── auth/             # JWT 认证
│       ├── study/            # 学科 / 答题 / 冒险结算
│       ├── spirit/           # 精灵养成
│       ├── energy/           # 学习能量
│       ├── achievement/      # 成就系统
│       ├── admin/            # 管理后台
│       ├── shop/ challenge/ story/ social/ daily/ event/ room/
│       └── common/ config/   # 公共模块
├── frontend/                 # SvelteKit 前端
│   └── src/
│       ├── routes/           # (auth)/ · (admin)/ · app/
│       └── lib/              # components/ stores/ api/ audio/ room/
├── docker-compose.yml        # MySQL 8.0
└── CLAUDE.md                 # AI 编码助手指引
```

## 数据规模

| 指标 | 数量 |
|------|------|
| 数据库表 | 26 张 |
| 知识节点 | 51 个（3 学科 × 多年级） |
| 题库 | 502 题（12 种题型，G1-G3） |
| 剧情章节 | 24 章 |
| BGM | 9 首（3 学科 × 3 场景） |
| 音效 | 16 个 |

## 已实现子系统

| 优先级 | 子系统 | 状态 |
|--------|--------|------|
| P0 | 学习能量 · 探索/净化 · 精灵养成 · 学科系统 · 即时反馈 | ✅ |
| P1 | 成就勋章 · 社交互动 · 商店物品 · 每日挑战 | ✅ |
| — | 剧情 · 惊喜 · 宠物小屋 · 管理后台 | ✅ |
| P2 | 时空裂隙 | ❌ 未实现 |

## 设计文档

- [游戏化宠物养成系统设计方案 v1.0](游戏化宠物养成系统设计方案-v1.md)
- [沉浸式重构方案 v2.0](游戏化学习系统设计方案-v2.md)

## License

MIT
