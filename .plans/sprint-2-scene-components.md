# Sprint 2 计划：场景组件 → 内容扩充 → 剧情模式 → 体验打磨

## 背景

Sprint 1 完成了"凑十法"拖拽场景组件（`SceneMathTen.svelte`），娃已验证路径 A（Svelte）可行。
Sprint 2 按用户指定的优先级推进：**1 → 2 → 3 → 4**。

### 当前题型覆盖状况

| 题型 | 探索模式 | 剧情模式 | 独立组件 |
|------|:---:|:---:|:---:|
| `MULTIPLE_CHOICE` | 内联按钮 | 内联按钮 | ❌ |
| `FILL_BLANK` | 内联输入框 | 内联输入框 | ❌ |
| `TRUE_FALSE` | 内联按钮 | 内联按钮 | ❌ |
| `MATH_INPUT` | `<MathInput>` | `<MathInput>` | ✅ |
| `POEM_SEQUENCE` | `<PoemSequence>` | `<PoemSequence>` | ✅ |
| `VOCAB_MATCH` | `<VocabMatch>` | `<VocabMatch>` | ✅ |
| `SCENE_DRAG` | `<SceneMathTen>` | **缺失** ❌ | ✅ |
| `SCENE_TAP` | 等同于选择题 | **缺失** ❌ | ❌ |
| `SCENE_MATCH` | 硬编码 CSS 图形 | **缺失** ❌ | ❌ |

**核心发现**：剧情模式（`StoryStudyTask.svelte`）完全没有处理任何 SCENE_* 题型。如果故事关卡抽到数学题，会渲染空白。

种子数据：共 45 题（语文 12、数学 21、英语 12）。数学的 `math_geometry` 节点只有 4 道 SCENE_MATCH，最薄弱。

---

## 阶段一：补场景组件

### 1a. 新建 `SceneTap.svelte` — SCENE_TAP 点击答题组件

**参考模板**：`SceneMathTen.svelte` 的 props 模式 —— `$props({ question, sessionId, onComplete })`，使用 Svelte 5 runes，点击后自动提交。

**交互设计**：
- 题目以宠物气泡提示形式展示
- 选项渲染为彩色可点击气泡/卡片（比普通按钮更大、更有游戏感）
- 点击后高亮 + 缩放动画，自动提交答案
- 按学科配色（数学=蓝色系）
- 内部自行解析 `question.options`（复用探索页的多格式兼容解析逻辑）

**文件**：`frontend/src/lib/components/study/SceneTap.svelte`

### 1b. 新建 `SceneMatch.svelte` — SCENE_MATCH 图形配对组件

**参考模板**：同上，`$props({ question, sessionId, onComplete })`。

**交互设计**：
- 渲染 4 种图形卡片（圆形、正方形、三角形、长方形），CSS 绘制
- 题目如"哪个是圆形？"以宠物气泡展示
- 点击选择 → 高亮 → 自动提交
- 图形参数化：优先读 `question.options`，无数据时回退到默认四图形
- 预留扩展：options 格式 `[{ key: 'CIRCLE', label: '圆形', cssShape: 'circle', color: 'sky' }]`

**文件**：`frontend/src/lib/components/study/SceneMatch.svelte`

### 1c. 接入探索页

**文件**：`frontend/src/routes/app/study/[subject]/explore/+page.svelte`

- 在顶部 `SCENE_DRAG` 判断处扩展：`SCENE_TAP` 和 `SCENE_MATCH` 也走独立组件
- 删除原来内联的 SCENE_MATCH 硬编码图形块
- SCENE_TAP 从 MULTIPLE_CHOICE 分支中独立出来

```svelte
{#if question.questionType === 'SCENE_DRAG'}
  <SceneMathTen question={question} {sessionId} onComplete={(result) => handleSceneResult(result)} />
{:else if question.questionType === 'SCENE_TAP'}
  <SceneTap question={question} {sessionId} onComplete={(result) => handleSceneResult(result)} />
{:else if question.questionType === 'SCENE_MATCH'}
  <SceneMatch question={question} {sessionId} onComplete={(result) => handleSceneResult(result)} />
{:else}
  <!-- 现有非场景题型渲染 -->
{/if}
```

---

## 阶段二：扩学科内容

### 2a. 数学：各节点补量

**文件**：`backend/src/main/resources/data.sql`

- `math_intro`：+4 SCENE_TAP（10以内加减变体）+5 SCENE_DRAG（凑十法更多组合：4+?, 3+?, 2+?, 1+?, 0+?）
- `math_addsub20`：+5 SCENE_TAP +2 MATH_INPUT
- `math_geometry`：+4 SCENE_MATCH（颜色识别、大小比较）+2 SCENE_TAP（图形计数）

目标：数学 ~50 题（目前 21）

### 2b. 语文：增加场景化题型

- `chinese_intro`：+3 SCENE_TAP（汉字部首识别，选正确偏旁）
- `chinese_tang`：+2 POEM_SEQUENCE（更多唐诗排序）

### 2c. 英语：增加场景化题型

- `english_intro`：+3 SCENE_MATCH（字母与图片配对）
- `english_vocab`：+2 SCENE_TAP（单词与图片点击）

> 注：语文/英语的新场景题型依赖 `SceneMatch` 支持非图形的配对（字母/图片），阶段一 1b 的参数化设计已覆盖此需求。

---

## 阶段三：修剧情模式

### 问题

`StoryStudyTask.svelte`（256-292 行）有自己内联的题型分支，完全缺失 SCENE_DRAG / SCENE_TAP / SCENE_MATCH。同时它自己的 `parsedOptions` 等解析器比探索页简陋（仅 JSON.parse，无多格式兼容）。

### 方案：补场景题型 + 复用场景组件

**文件**：`frontend/src/lib/components/story/StoryStudyTask.svelte`

1. **引入场景组件**：
   ```ts
   import SceneMathTen from '$lib/components/study/SceneMathTen.svelte';
   import SceneTap from '$lib/components/study/SceneTap.svelte';
   import SceneMatch from '$lib/components/study/SceneMatch.svelte';
   ```

2. **新增 `handleSceneResult` 回调**（参照探索页的 `handleSceneResult`）：
   - 处理场景组件自动提交后的结果
   - 更新 HP、Combo、Boss 状态
   - 推进到下一题或结束

3. **题型分支顶部加入 SCENE_* 判断**：
   ```svelte
   {#if question.questionType === 'SCENE_DRAG'}
     <SceneMathTen question={question} {sessionId} onComplete={handleSceneResult} />
   {:else if question.questionType === 'SCENE_TAP'}
     <SceneTap question={question} {sessionId} onComplete={handleSceneResult} />
   {:else if question.questionType === 'SCENE_MATCH'}
     <SceneMatch question={question} {sessionId} onComplete={handleSceneResult} />
   {:else if question.questionType === 'MULTIPLE_CHOICE'}
     <!-- 现有逻辑 -->
   {/if}
   ```

4. **用 `{#key question.questionId}` 包裹题目区域**，切换题目时强制重建组件（与探索页一致）。

5. **提交按钮条件**：场景组件自动提交，第 294 行的"提交答案"按钮需排除 SCENE_DRAG / SCENE_TAP / SCENE_MATCH（与现有的 POEM_SEQUENCE / VOCAB_MATCH 排除逻辑合并）。

### 无需后端改动

故事关卡已使用同一个 `startSession()` 接口，返回混合题型。问题纯在前端渲染层。

---

## 阶段四：体验打磨

具体条目待娃实际反馈后调整，预设方向：

1. **触摸反馈**：拖拽进入碗区域时加短暂震动式 CSS 效果
2. **音效接入**：SceneTap / SceneMatch 点击时接入 `soundManager.playSFX()`
3. **过渡动画**：确保 `{#key}` 重挂载不产生布局闪烁
4. **无障碍**：新组件添加 `aria-label` 和 `role` 属性
5. **错误恢复**：场景组件 API 失败时重置状态允许重试（SceneMathTen 已实现，新组件复用此模式）

---

## 执行顺序

| 步骤 | 内容 | 涉及文件 | 复杂度 |
|------|------|----------|:---:|
| 1a | 新建 SceneTap.svelte | 1 新文件 | 中 |
| 1b | 新建 SceneMatch.svelte | 1 新文件 | 中 |
| 1c | 接入探索页 | `explore/+page.svelte` | 小 |
| 2a | 数学内容扩充 | `data.sql` | 小 |
| 2b | 语文内容扩充 | `data.sql` | 小 |
| 2c | 英语内容扩充 | `data.sql` | 小 |
| 3 | 剧情模式适配 | `StoryStudyTask.svelte` | 中 |
| 4 | 体验打磨 | 各场景组件 | 小 |

---

## 验证方式

1. **阶段一**：启动数学探索关卡 → SCENE_TAP 显示气泡点击 UI，SCENE_MATCH 显示图形卡片，均自动提交
2. **阶段二**：重置数据库后，新题目在轮换中出现，无连续重复
3. **阶段三**：启动数学故事章节 → SCENE_DRAG/SCENE_TAP/SCENE_MATCH 在剧情弹窗中正常渲染和交互
4. **阶段四**：平板/手机触摸测试，动画流畅，错误恢复正常
