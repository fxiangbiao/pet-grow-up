# Pet Grow Up — Godot 客户端（教 / 学 / 练 / 拓 · 凑十法 MVP）

游戏化宠物养成系统的 **Godot 4.7** 学习客户端，按「教 → 学 → 练 → 拓」四维设计，
首个可玩 MVP 聚焦 **凑十法**（数学 · `math_make_ten`）。

## 运行方式

1. 用 **Godot 4.7** 打开本目录（`godot/project.godot`）。
2. 按 F5 运行主场景（`res://scenes/main_menu.tscn`，已在 project.godot 设定）。
3. 主菜单可选：
   - **登录**：连真实后端（默认 `http://127.0.0.1:8080`，见下）。
   - **离线试玩（无需后端）**：使用内置示例数据，打开即玩。

## 连接真实后端

后端即本仓库 `backend/` 模块（Spring Boot 3.2.4）。本地启动后：

```bash
# 后端（PowerShell，规避 Git Bash 路径 bug）
$env:JAVA_HOME="D:\Apps\Java\jdk-21"; $env:M2_HOME="D:\Apps\Maven\3.9.16"
& "D:\Apps\Maven\3.9.16\bin\mvn.cmd" spring-boot:run
```

- 默认地址 `http://127.0.0.1:8080`，如需改：编辑 `scripts/api_client.gd` 顶部的 `DEFAULT_BASE_URL`。
- 接口前缀均为 `/api/v1`（已接：auth / study / exploration）。
- 学程地图点「凑十法」→ 进入四幕学习循环。

## 已接入的接口（真实后端）

| 维度 | 接口 | 说明 |
|------|------|------|
| 导航 | `GET /api/v1/study/worlds/{subject}` | 学科世界地图节点树 |
| 教   | `GET /api/v1/study/nodes/{id}/teaching` | 结构化教学卡片（intro/concept/steps/example/mnemonic） |
| 练   | `POST /api/v1/exploration/sessions/start` + `/{id}/submit` | 练习会话、提交判分、奖励 |
| 拓   | `GET /api/v1/study/nodes/{id}/generate-variant` + `POST .../explain` | 变式题、讲解评测 |

## 目录结构

```
godot/
├── project.godot            # 工程配置（Godot 4.7, 主场景, 3 个 autoload）
├── icon.svg
├── scripts/
│   ├── api_client.gd        # 后端接口封装（autoload）
│   ├── pet_state.gd         # 宠物养成状态 + 本地存档（autoload）
│   ├── demo.gd              # 离线兜底数据（autoload）
│   ├── base_scene.gd        # 界面底座（背景/顶栏/宠物/toast）
│   ├── act_base.gd          # 四幕基类（pet 摆放 / setup(ctx) / finished 信号）
│   ├── pet_controller.gd    # 宠物精灵 + 动画状态机（idle/wave/cheer/wrong/think）
│   ├── make_ten_ui.gd       # 凑十法交互组件（点苹果凑十）
│   ├── main_menu.gd         # 登录 / 离线试玩
│   ├── world_map.gd         # 学程地图
│   ├── learning_loop.gd     # 四幕编排器（教→学→练→拓）
│   ├── teach_scene.gd       # 教
│   ├── learn_scene.gd       # 学
│   ├── practice_scene.gd    # 练
│   ├── extend_scene.gd      # 拓
│   └── pet_room.gd          # 宠物小屋（奖励锚点）
├── scenes/                  # 与 scripts 对应的 .tscn
├── assets/sprites/pet/      # 程序化生成的占位美术（宠物 5 表情 + 苹果/碗/数字块）
└── tools/generate_pet_animations.py  # 美术生成脚本（Python/PIL）
```

## 重新生成占位美术

```bash
python tools/generate_pet_animations.py
```

## 已知限制（MVP · 2026-09-06 更新）

- **验证状态**：脚本已通过 Godot 4.7 headless 解析冒烟（无语法/加载错误）；
  API 在线链路（注册→地图解锁→教学卡片→SCENE_DRAG 补十练习判分→变式）已对真实
  后端逐项冒烟通过（见提交记录与 docs/部署使用说明.md）。**仍需在本机 Godot 窗口内
  实际试玩一遍**确认交互手感与视觉，发现问题请反馈。
- 美术为**程序化占位图**（Q 版猫精灵），后续可替换为正式美术。
- 离线模式使用内置示例，不与后端同步；在线模式依赖后端 `math_make_ten` 节点已解锁
  （现新注册账号即可直接进入该节点练习）。
- 「练」场景已与后端 SCENE_DRAG「凑十法：A + ? = 10」题型打通：补十模式下答案即补数
  （如 8+?=10 答 2），判分正确；提交 body 与路径均带 sessionId（后端 @NotNull）。
  教学/离线演示仍为求和模式（8+5 补十），互不干扰。
