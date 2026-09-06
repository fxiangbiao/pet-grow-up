# Godot 路径 · 教 / 学 / 练 / 拓 游戏化学习设计方案（v3）

> 日期：2026-07-25 | 作者：WorkBuddy
> 背景：v1/v2 其他智能体的双路径 Spike 试过**效果不好** → 本次**单走 Godot 路径**，按「教·学·练·拓」四维重新设计学习体验。
> 引擎：Godot 4.7（已确认本地有 4.7 工程可参照），导出目标 HTML5/WASM（未来可 Android/iOS）。

---

## 0. 设计判词：为什么之前"不好玩"，这次怎么改

v1/v2 自己诊断的痛点：**静态宠物、关卡是"读文本+做题"套壳、反馈延迟、无差异化养成**。本次设计的核心纠正——

> **让宠物成为"全程在场的教练"，把每一次学习拆成 教→学→练→拓 四幕，每一幕都有即时互动与表情反馈，而不是"看一段文字再答题"。**

- 教 = 宠物**说书演示**（动态绘本，不是静态页面）
- 学 = 宠物**先做一遍、孩子跟着做**（脚手架，不焦虑）
- 练 = 题目**变成游戏**（拖/拍/拼，毫秒级反馈+连击+星级）
- 拓 = 孩子**反过来教宠物 / 做变式**（迁移与元认知）

---

## 1. 四维学习闭环（对每个知识点 node 跑一遍）

```
        ┌──────────────────────────────────────────────────────┐
        │             learning_loop（四幕编排状态机）            │
        │                                                        │
  ① 教  │  teach_scene：宠物按 teaching 卡片"说书"               │
  ② 学  │  learn_scene：宠物示范→孩子跟着动手（不计分）          │
  ③ 练  │  practice_scene：题目变游戏，即时反馈+连击+星级        │
  ④ 拓  │  extend_scene：变式挑战 / 孩子讲给宠物听              │
        │        │                                               │
        └────────┼──────────────────────────────────────────────┘
                 ▼
         world_map 节点进度（星级/解锁）→ 下一关
                 ▼
         WeaknessController 记薄弱点 → 下次针对性出题
```

### ① 教 Teach（讲解·示范）
- **数据**：`GET /api/v1/study/nodes/{nodeId}/teaching` → `cards[]`
  - 卡片类型：`intro`(开场，宠物挥手+插图) / `concept`(概念+演示动画) / `steps`(分步揭示) / `example`(举例，含 `interactive` 提示) / `mnemonic`(口诀儿歌)
  - 字段：`title / content / spriteAction / animation / interactive / illustration / steps`
- **玩法**：绘本式动画场景。宠物按卡片顺序推进，配合插图与演示动画（`make_ten_demo` 等）。
- **目标**：建立表象——"看懂"。

### ② 学 Learn（引导·动手）
- **数据**：复用 `teaching` 卡片的 `interactive` 字段
  - 已有类型：`drag_to_make_ten` / `tap_answer` / `letter_match` / `phonics_blend` / `pinyin_combine` / `character_match` / `word_match` / `read_along` / `find_shapes` / `borrow_demo` …
- **玩法**：宠物"我先做一次，你跟着做"——同一场景里，宠物示范后孩子拖苹果/点答案/拼读音，宠物实时鼓励、纠错、自动降难度。
- **目标**：在保护下"会做"（无压力、不计分）。

### ③ 练 Practice（巩固·游戏化答题）
- **数据**：
  - `POST /api/v1/exploration/sessions/start`
    - 请求：`{ subject, sessionType, difficultyLevel(1-5), knowledgeNodeId }`
    - 返回：`QuestionDTO { sessionId, questionId, questionType, questionText, options, points, totalQuestions, answeredCount }`
  - `POST /api/v1/exploration/sessions/{id}/submit`
    - 请求：`{ questionId, answer, timeSpent }`
    - 返回：`AnswerResultDTO { isCorrect, correctAnswer, explanation, pointsEarned, isSessionComplete, isLastQuestion, nextQuestion, sceneRewardItem, sceneRewardCount }`
  - `GET /api/v1/exploration/sessions/{id}/result` → `SessionResultDTO`（星级）
- **玩法**：把题目变游戏（凑十法=拖苹果入碗合成能量块；20以内加减=打地鼠；图形=找图形；拼音=泡泡）。毫秒级反馈+宠物表情+连击(combo)+结算星级。`sceneRewardItem` 直接进奖励层。
- **目标**：在反馈中"练熟"。

### ④ 拓 Extend（拓展·迁移）
- **数据**：
  - `GET /api/v1/study/nodes/{nodeId}/generate-variant?originalQuestionId=` → 变式题 Map
  - `POST /api/v1/study/nodes/{nodeId}/explain` `{ text }` → 讲解评估（元认知）
- **玩法**：① 变式挑战（换情境/更难）；②「小老师」环节——孩子用文字给宠物讲一遍，宠物评估并反应；③ 生活应用微场景。
- **目标**：迁移与创造——"学活"。

---

## 2. 后端接口映射表（已逐条核实存在）

| 维度 | 方法 | 端点 | 关键返回 |
|------|------|------|----------|
| 教 | GET | `/api/v1/study/nodes/{id}/teaching` | `cards[]` JSON |
| 学 | — | 复用 teaching 的 `interactive` 字段 | — |
| 练(开始) | POST | `/api/v1/exploration/sessions/start` | `QuestionDTO` |
| 练(提交) | POST | `/api/v1/exploration/sessions/{id}/submit` | `AnswerResultDTO` |
| 练(结算) | GET | `/api/v1/exploration/sessions/{id}/result` | `SessionResultDTO` |
| 拓(变式) | GET | `/api/v1/study/nodes/{id}/generate-variant` | 变式题 Map |
| 拓(讲解) | POST | `/api/v1/study/nodes/{id}/explain` | 评估 Map |
| 导航 | GET | `/api/v1/study/worlds/{subject}` | `WorldMapDTO{nodes[]}` |
| 导航 | GET | `/api/v1/study/subjects` | 学科进度 |
| 宠物 | GET | `/api/v1/spirit/**`、`/api/v1/pet-room/**` | 宠物状态/装饰（奖励锚点） |

- **认证**：`POST /api/v1/auth/login` → JWT；后续请求头 `Authorization: Bearer <token>`。
- `NodeDTO`：`nodeId / name / description / difficulty / isUnlocked / isCompleted / starRating / parentId / children[]`（树形学程）。

---

## 3. Godot 工程结构（v3，按四维重组）

```
pet-growup-godot/
├── project.godot
├── scenes/
│   ├── main_menu.tscn          # 登录 / 选宠 / 进入世界
│   ├── world_map.tscn          # 学科世界地图（拉 /worlds/{subject}）
│   ├── learning_loop.tscn      # ★核心：编排 教→学→练→拓 四幕
│   ├── teach/teach_scene.tscn      # 教：绘本式讲解
│   ├── learn/learn_scene.tscn      # 学：引导动手
│   ├── practice/practice_scene.tscn# 练：游戏化答题
│   ├── extend/extend_scene.tscn    # 拓：变式 / 小老师
│   └── pet_room.tscn           # 宠物小屋（奖励 / 情感锚点）
├── scripts/
│   ├── api_client.gd           # HTTP + JWT 封装
│   ├── learning_loop.gd        # 四幕状态机
│   ├── teach_card.gd           # 渲染单张教学卡
│   ├── pet_controller.gd       # 宠物动画状态机(idle/wave/cheer/think/wrong)
│   ├── question_renderer.gd    # questionType → 交互
│   ├── session_manager.gd      # 练 会话状态
│   └── audio_manager.gd        # 音效
├── assets/  (sprites/ui/audio，先用占位图，后替换)
└── shaders/
```

---

## 4. MVP 切片（首个可玩交付 = 凑十法 完整闭环）

目标：选 `math_make_ten` 节点，走完 **教→学→练→拓** 四幕，本机 Godot 4.7 打开即玩，直连本地后端。

| 幕 | 实现要点 |
|----|----------|
| 教 | `teach_scene` 拉 teaching API，渲染 5 张卡片（含 `make_ten_demo` 动画 + 拖苹果交互提示） |
| 学 | `learn_scene` 拖 2 个苹果进碗，宠物示范+鼓励，不计分 |
| 练 | `practice_scene` start session → 拖苹果凑十 → submit → 结算星级（用 `sceneRewardItem`） |
| 拓 | `extend_scene` `generate-variant` 出一道变式 |
| 宠物 | 占位精灵（idle/wave/cheer/wrong）+ 占位音效 |
| 数据 | 直连 `localhost:8080`（需后端 `mvn.cmd` 在跑 + 一个测试孩子账号 JWT） |

---

## 5. 风险与依赖（必须说清）

- 🔴 **沙箱无 Godot**：我只能写 `.tscn` / `.gd` + 占位资源，**无法在本环境运行验证**，需你本机 Godot 4.7 打开试跑。这是物理限制，不是代码问题。
- 🟠 **美术**：先用 `godot-placeholder-animator` 技能生成宠物占位动画帧，真实美术后续替换（结构预留 `assets/`）。
- 🟠 **后端依赖**：需本地启动后端（已验证 `mvn.cmd clean compile` 通过）；teaching/session/variant 接口均已就绪。
- 🟠 **账号**：需一个测试孩子账号拿 JWT（登录接口）。
- 🟢 四幕设计完全基于**已存在的真实接口**，不是空中楼阁。

---

## 6. 待你拍板（见随附提问）

1. MVP 范围：凑十法完整四幕？还是先教+学两幕看手感？
2. 美术：先用占位动画跑通？（推荐，再换真实美术）
3. 是否需要我顺手确认/补足后端「凑十法」练习题目（practice 用）？
