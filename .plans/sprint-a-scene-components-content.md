# Sprint A 计划：场景组件扩充 + 题库重建 + 音频动画升级

> 创建日期：2026-06-30
> 父设计：v2 设计方案（`游戏化学习系统设计方案-v2.md`）
> 决策：渐进演化冒险模式、重建语文节点、按优先级分批

---

## 一、背景与现状

### 已完成（Sprint 1+2）
- 场景组件：`SceneMathTen`(凑十法拖拽)、`SceneTap`(气泡点击)、`SceneMatch`(图形配对)
- 题库 77 题（数学 43、语文 17、英语 17）
- 探索页 + 剧情模式均已接入场景组件
- 音频：单学科 BGM + 基础音效（playCorrect/playWrong/playClick/playTreasure 等）

### 关键差距

**场景组件缺口：**
| 学科 | 知识点 | 目标组件 | 当前 |
|------|--------|----------|:---:|
| 数学 | 20以内加减 | `SceneWhackMole` 打地鼠 | ❌ |
| 数学 | 认识图形 | `SceneShapePuzzle` 拼图工坊 | 部分 |
| 数学 | 认识时间 | `SceneClock` 拨钟表 | ❌ |
| 数学 | 认识人民币 | `SceneShop` 宠物商店 | ❌ |
| 语文 | 拼音·听音识字母 | `ScenePinyinBubble` 拼音泡泡 | ❌ |
| 语文 | 识字·翻牌配对 | `SceneCharMatch` 记忆花园 | ❌ |
| 语文 | 识字·组字寻宝 | `SceneCharBuild` 汉字工坊 | ❌ |

**题库缺口：**
- 语文：17 题全是唐诗宋词，**零拼音零识字**——需重建
- 数学：缺数一数/比多少/认识钟表/认识人民币/找规律等 7 个主题
- 英语：语法题超纲（过去式/三单），缺一年级基础词汇和对话

**音频/动画缺口：**
- BGM：每个学科仅 1 首 BGM，循环播放枯燥
- 场景音效：缺少拖拽吸附、泡泡炸开、地鼠冒头、拨钟表咔嗒声等场景专属音效
- 宠物语音：缺少"迎接"、"鼓励"、"欢呼"等角色化声音反馈
- 过渡动画：题目切换是硬切（`{#key}` 重建），无过渡动效

---

## 二、阶段一：音频系统升级

### 2.1 BGM 扩充

**当前**：每个学科 1 首 BGM（`playBGM(subject)` 循环播放）

**目标**：每个学科 3-4 首 BGM，按场景切换

| 学科 | BGM | 场景 | 风格 |
|------|-----|------|------|
| 数学 | `math_explore` | 冒险/关卡通用 | 轻快节拍 + 音乐盒琶音（现有升级） |
| 数学 | `math_clock` | 认识钟表关卡 | 滴答节奏 + 钟声点缀 |
| 数学 | `math_shop` | 宠物商店关卡 | 活泼买卖主题 + 金币叮当 |
| 语文 | `chinese_explore` | 冒险/关卡通用 | 古筝 + 笛子五声音阶（现有升级） |
| 语文 | `chinese_pinyin` | 拼音关卡 | 轻快字母歌改编 + 泡泡音效 |
| 语文 | `chinese_char` | 识字关卡 | 文雅古风 + 笔墨纸砚氛围 |
| 英语 | `english_explore` | 冒险/关卡通用 | Cmaj7 和弦垫 + 三角波闪烁（现有升级） |
| 英语 | `english_letters` | 字母关卡 | ABC 歌改编 + 铃铛音 |
| 英语 | `english_vocab` | 词汇关卡 | 欢快律动 + 动物叫声采样 |

**实现**：在 `sound-manager.ts` 中扩展 `playBGM(subject, scene?)` 方法，支持场景参数切换曲目。

### 2.2 场景专属音效

| 音效方法 | 触发场景 | 声音设计 |
|----------|---------|------|
| `playMoleAppear()` | 地鼠冒头 | 短促上升滑音 "pop" |
| `playMoleWhack()` | 打中地鼠 | 打击感 "bonk" + 星星闪烁 |
| `playMoleMiss()` | 打错地鼠 | 轻柔 "boing" 弹簧声 |
| `playPuzzleSnap()` | 图形拼图吸附到位 | 清脆 "click-snap" |
| `playClockTick()` | 钟表拨动 | 机械钟表咔嗒声 |
| `playClockChime()` | 时间拨对 | 钟声 "ding-dong" |
| `playCoinDrop()` | 拖拽钱币 | 金币叮当 |
| `playPurchase()` | 购买成功 | 收银机 "cha-ching" |
| `playBubblePop()` | 拼音泡泡炸开 | 水泡破裂 "pop" |
| `playCharGlow()` | 汉字组合发光 | 魔法上升音 "shimmer" |
| `playCardFlip()` | 记忆翻牌 | 卡片翻转 "flip" |

**实现**：全部使用 Web Audio API 合成，无需外部音频文件。

### 2.3 宠物情感音效

| 音效方法 | 触发场景 | 声音设计 |
|----------|---------|------|
| `playPetGreet()` | 进入学习区 | 欢快上升三连音 |
| `playPetEncourage()` | 答错时鼓励 | 温暖柔和上行音 |
| `playPetCelebrate()` | 连续 combo | 宠物欢呼 "yay" 风格 |
| `playPetSleepy()` | 长时间未操作 | 轻柔哈欠声 + 下行音 |
| `playPetEat()` | 喂养/商店购物 | 开心嚼东西声 |

**文件**：`frontend/src/lib/audio/sound-manager.ts`

---

## 三、阶段二：动画系统升级

### 3.1 题目过渡动画

**当前**：`{#key question.questionId}` 硬切换，闪一下

**目标**：300ms 交叉淡入淡出

- 旧题目 `opacity 1→0 + scale 1→0.95`（150ms）
- 新题目 `opacity 0→1 + scale 1.05→1`（150ms）
- 两个动画叠加产生平滑过渡

**实现**：在 `explore/+page.svelte` 中用 CSS transition + Svelte `transition:` 指令

### 3.2 场景组件微动效

每个场景组件添加：
- **入场动画**：组件挂载时带弹入效果（`animate-bounce-in` 已有，统一使用）
- **交互反馈**：点击/拖拽时粒子微喷射（复用 `ParticleEffect`）
- **完成庆祝**：关卡完成时的粒子爆发 + 宠物跳跃

### 3.3 宠物动画增强

在 `SpiritAvatar.svelte` 中增加：
- **眨眼动画**：待机时每 3-5 秒眨一次眼
- **视线跟随**：宠物眼球跟随鼠标/手指移动（CSS `transform`）
- **跳跃庆祝**：答对时的小跳 + 旋转（已有 bounce，增强幅度）

**文件**：
| 文件 | 操作 |
|------|:---:|
| `frontend/src/lib/audio/sound-manager.ts` | 修改（+约 20 个音效方法） |
| `frontend/src/routes/app/study/[subject]/explore/+page.svelte` | 修改（过渡动画） |
| `frontend/src/lib/components/spirit/SpiritAvatar.svelte` | 修改（眨眼+视线） |

---

## 四、阶段三：场景组件（5 个新组件）

### 4.1 `SceneWhackMole.svelte` — 打地鼠·20以内加减

**知识点**：20以内加减法
**玩法**：3×3 地鼠洞，算式在屏幕顶部。地鼠带着不同答案从洞里冒出，孩子点击正确答案。
**自提交**：点对 → 地鼠被敲 + 星星粒子 + combo。点错 → 地鼠鬼脸缩回。

**技术要点**：
- 网格布局 9 个洞，每次随机 4-6 只地鼠冒出（其中 1 个正确答案）
- 地鼠冒出/缩回 CSS transition（translateY），随机停留时间
- 新地鼠每隔 1.5s 刷新一轮
- 音效：`playMoleAppear` / `playMoleWhack` / `playMoleMiss`
- 计时器 8 秒 → 超时自动下一题

### 4.2 `SceneShapePuzzle.svelte` — 拼图工坊·认识图形

**知识点**：认识圆形/正方形/三角形/长方形
**玩法**：右侧目标图案（虚线轮廓），左侧图形库。拖拽图形到对应轮廓，吸附拼合。拼完 → 宠物鼓掌。
**自提交**：所有轮廓填满 → 自动提交。

**技术要点**：
- Pointer Events 拖拽，目标区域碰撞检测（与 SceneMathTen 相同模式）
- 吸附动画（图形滑入轮廓 + 轻微弹性）
- 多套拼图预设（房子🏠、树🌳、车🚗、船⛵）
- 音效：`playPuzzleSnap`

### 4.3 `SceneClock.svelte` — 拨钟表·认识时间

**知识点**：认识整时（1:00, 2:00...12:00）
**玩法**：宠物提示"7:00 该起床啦！"，孩子拖动时针到对应数字。拨对 → 宠物做对应动作。
**自提交**：时针到位 → 自动提交。

**技术要点**：
- CSS 绘制钟面（圆形表盘 + 12 个刻度数字 + 时针/分针）
- 时针拖拽旋转：Pointer Events + `Math.atan2` 角度计算
- 分针固定 12 点方向（整时模式）
- 吸附刻度：拖到接近某个数字时自动对齐
- 音效：`playClockTick`（拖拽时）/ `playClockChime`（拨对时）

### 4.4 `SceneShop.svelte` — 宠物商店·认识人民币

**知识点**：认识元币（1元/5元/10元），简单金额计算
**玩法**：货架展示商品标价，孩子从钱包拖拽纸币到付款区凑金额。凑对 → 宠物开心享用。
**自提交**：金额凑对 → 自动提交。

**技术要点**：
- 商品区 + 钱包区 + 付款区三栏布局
- 纸币 emoji 可拖拽（💵1元×10、💵5元×4、💵10元×2）
- 付款区实时显示累计金额
- 金额凑对 → 商品飞到宠物旁边 + 宠物吃/玩动画
- 音效：`playCoinDrop` / `playPurchase`

### 4.5 `ScenePinyinBubble.svelte` — 拼音泡泡·听音识字母

**知识点**：拼音声母/韵母识别
**玩法**：6-8 个彩色泡泡漂浮，每个内含拼音字母。Web Speech API 朗读发音（如 "b~"），孩子点击正确泡泡。点击 → 泡泡炸开。
**自提交**：点击正确 → 自动提交。

**技术要点**：
- 泡泡随机漂浮动画（CSS `animate-float` + 随机起始位置）
- `speechSynthesis.speak()` 朗读拼音（浏览器内置 TTS）
- 播放按钮可重复听发音
- 泡泡炸开动画（scale 0→1.2→0 + 水珠粒子）
- 音效：`playBubblePop`

### 4.6 `SceneCharBuild.svelte` — 汉字工坊·组字寻宝

**知识点**：偏旁部首 + 汉字结构（一年级上 100 字范围内）
**玩法**：左侧偏旁（亻氵口木扌），右侧声旁（门可十子巴）。拖偏旁到合成台，再拖声旁 → 合并成字。
**自提交**：组对 → 自动提交。

**技术要点**：
- 三栏布局：偏旁区 + 合成台 + 声旁区
- 合成台两个槽位：左槽（偏旁）+ 右槽（声旁）
- 有效组合表（约 30 组）：亻+门=们、氵+可=河、口+十=叶 等
- 组对 → 字发光 + 宠物念出字音 + 飘入图鉴
- 音效：`playCharGlow`

**接入探索页**：所有新组件遵循 `$props({ question, sessionId, onComplete })` 模式，在 `explore/+page.svelte` 中按 `questionType` 路由。

**文件变更**：
| 文件 | 操作 |
|------|:---:|
| `frontend/src/lib/components/study/SceneWhackMole.svelte` | 新建 |
| `frontend/src/lib/components/study/SceneShapePuzzle.svelte` | 新建 |
| `frontend/src/lib/components/study/SceneClock.svelte` | 新建 |
| `frontend/src/lib/components/study/SceneShop.svelte` | 新建 |
| `frontend/src/lib/components/study/ScenePinyinBubble.svelte` | 新建 |
| `frontend/src/lib/components/study/SceneCharBuild.svelte` | 新建 |
| `explore/+page.svelte` | 修改（路由 + 过渡动画） |
| `StoryStudyTask.svelte` | 修改（路由新组件） |

---

## 五、阶段四：题库重建

### 5.1 语文：重建知识节点（删旧建新）

**删除旧节点**：`chinese_intro`、`chinese_tang`、`chinese_song`（唐诗宋词，不对标一年级）

**新建 3 个一年级节点**：

| node_key | name | difficulty | 内容 |
|----------|------|:---:|------|
| `chinese_pinyin` | 拼音入门 | 1 | 声母/韵母/声调识别 |
| `chinese_shizi` | 识字基础 | 1 | 一年级上 100 字（认读+偏旁） |
| `chinese_kewen` | 课文朗读 | 2 | 儿歌/课文背诵（替换唐诗） |

**题目分配（~55 题）**：
| 节点 | SCENE_DRAG | SCENE_TAP | SCENE_MATCH | FILL_BLANK | 小计 |
|------|:---:|:---:|:---:|:---:|:---:|
| chinese_pinyin | 12（拼音泡泡） | 8（听音选字母） | 0 | 0 | 20 |
| chinese_shizi | 10（汉字工坊） | 9（认字选择） | 6（翻牌配对） | 0 | 25 |
| chinese_kewen | 0 | 2（课文理解） | 0 | 3（课文填空） | 5 |

> 保留 静夜思/春晓 两首课内诗到 chinese_kewen。

### 5.2 数学：补全缺失主题

| 知识点 | 新增题目 | 使用题型 |
|--------|:---:|------|
| 数一数 | 5 | SCENE_TAP（数动物/水果，选数字） |
| 比多少 | 5 | SCENE_TAP（哪边多？> < =） |
| 1~5 认识 | 5 | SCENE_TAP（认数+简单加减） |
| 6~10 认识 | 5 | SCENE_TAP（序数+数位） |
| 11~20 认识 | 5 | SCENE_TAP（十位个位） |
| 认识钟表 | 8 | SCENE_DRAG（SceneClock 组件） |
| 认识人民币 | 6 | SCENE_DRAG（SceneShop 组件） |
| 找规律 | 5 | SCENE_MATCH（颜色/形状/数字规律） |

**数学 ~87 题（+44）。**

### 5.3 英语：替换超纲 + 扩充

**删除**：所有语法题（过去式 went、三单 reads、beautiful 反义词等）

**新建节点**：
| node_key | name | content |
|----------|------|------|
| `english_letters` | 字母与发音 | A-Z 大小写配对、听音选字母 |

**题目分配（~50 题）**：
| 节点 | SCENE_MATCH | SCENE_TAP | VOCAB_MATCH | 其他 | 小计 |
|------|:---:|:---:|:---:|:---:|:---:|
| english_letters | 10（字母选图） | 8（听音选字母） | 0 | 0 | 18 |
| english_intro | 4（单词选图） | 4（选单词） | 6（词图配对） | 0 | 14 |
| english_vocab | 0 | 6（学校/身体选词） | 4（主题配对） | FILL 4 | 14 |
| english_grammar → **改** | 0 | 0 | 0 | 0 | 删 |

**英语 ~46 题（+29）。**

### 5.4 题库总览

| 学科 | 当前 | 目标 | 新增 |
|------|:---:|:---:|:---:|
| 数学 | 43 | ~87 | +44 |
| 语文 | 17 | ~55 | +38（重建） |
| 英语 | 17 | ~46 | +29 |
| **合计** | **77** | **~188** | **+111** |

**文件**：`backend/src/main/resources/data.sql`（删旧语文/英语节点+题目，新增节点+题目）

---

## 六、阶段五：冒险模式小步演化

> 本次做最小改动，大的 v2 重构留 Sprint B

1. **BattleScene 趣味升级**：宠物施放技能动画（火苗/星光粒子）、Boss 嘲讽气泡（"哈哈，这题可难了！"）
2. **去掉 HP 扣血**：错误答案不扣 HP，HP 条改为"能量条"（正向量表展示 combo 积累进度）
3. **缩短过渡**：`setTimeout(1500)` → `800ms`，加 CSS fade 过渡
4. **WrongIndicator 弱化**：去骷髅 emoji + 红色闪烁，换宠物鼓励表情 + 温馨文案

| 文件 | 改动 |
|------|------|
| `explore/+page.svelte` | 去 hp -=，缩 setTimeout，加过渡 |
| `BattleScene.svelte` | 技能粒子动画 |
| `WrongIndicator.svelte` | 弱化惩罚感 |

---

## 七、执行顺序

| # | 步骤 | 文件数 | 复杂度 |
|---|------|:---:|:---:|
| 1 | 音频系统升级（BGM + 场景音效 + 宠物音效） | 1 修改 | 大 |
| 2 | 动画系统升级（题目过渡 + 宠物眨眼/视线） | 2 修改 | 小 |
| 3 | SceneShapePuzzle（拼图工坊） | 1 新建 | 中 |
| 4 | SceneClock（拨钟表） | 1 新建 | 中 |
| 5 | SceneWhackMole（打地鼠） | 1 新建 | 中 |
| 6 | SceneShop（宠物商店） | 1 新建 | 中 |
| 7 | ScenePinyinBubble（拼音泡泡） | 1 新建 | 中 |
| 8 | SceneCharBuild（汉字工坊） | 1 新建 | 中 |
| 9 | 全部接入探索页+剧情模式 | 2 修改 | 小 |
| 10 | 语文题库重建 | 1 修改 | 中 |
| 11 | 数学题库扩充 | 1 修改 | 中 |
| 12 | 英语题库重建 | 1 修改 | 中 |
| 13 | 冒险模式小步演化 | 3 修改 | 小 |

---

## 八、验证

1. 每个场景组件创建后在探索关卡中实际游玩一轮
2. 题库重建后重启后端 → API 返回新题目，无 SQL 错误
3. 音频测试：BGM 随场景切换、场景音效触发正确、宠物音效有情感
4. 动画测试：题目过渡平滑无闪烁、宠物眨眼自然、粒子效果流畅
5. 剧情模式中新场景组件正常渲染
