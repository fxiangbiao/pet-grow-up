<script lang="ts">
  import type { CreateQuestion } from '$lib/api/admin';

  let {
    questionData,
    onUpdate,
  }: {
    questionData: CreateQuestion;
    onUpdate?: (data: Partial<CreateQuestion>) => void;
  } = $props();

  let leftItems = $state<{ id: string; text: string }[]>([]);
  let rightItems = $state<{ id: string; text: string }[]>([]);
  let pairs = $state('');

  // Parse existing options JSON
  $effect(() => {
    try {
      if (questionData.options) {
        const opts = JSON.parse(questionData.options);
        leftItems = opts.left || [];
        rightItems = opts.right || [];
        pairs = questionData.correctAnswer || '';
      }
    } catch { /* ignore */ }
  });

  function syncOptions() {
    const opts = JSON.stringify({ left: leftItems, right: rightItems });
    onUpdate?.({ options: opts, correctAnswer: pairs });
  }

  function addLeft() {
    const id = String.fromCharCode(65 + leftItems.length); // A, B, C...
    leftItems = [...leftItems, { id, text: '' }];
    syncOptions();
  }
  function removeLeft(idx: number) {
    leftItems = leftItems.filter((_, i) => i !== idx);
    // Reassign IDs
    leftItems = leftItems.map((item, i) => ({ ...item, id: String.fromCharCode(65 + i) }));
    syncOptions();
  }
  function updateLeftText(idx: number, text: string) {
    leftItems = leftItems.map((item, i) => i === idx ? { ...item, text } : item);
    syncOptions();
  }

  function addRight() {
    const id = String(rightItems.length + 1);
    rightItems = [...rightItems, { id, text: '' }];
    syncOptions();
  }
  function removeRight(idx: number) {
    rightItems = rightItems.filter((_, i) => i !== idx);
    rightItems = rightItems.map((item, i) => ({ ...item, id: String(i + 1) }));
    syncOptions();
  }
  function updateRightText(idx: number, text: string) {
    rightItems = rightItems.map((item, i) => i === idx ? { ...item, text } : item);
    syncOptions();
  }
</script>

<div class="space-y-4">
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">题目文本</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={questionData.questionText}
           oninput={(e: Event) => onUpdate?.({ questionText: (e.target as HTMLInputElement).value })}
           placeholder='例如：请将左边的英文单词与右边的中文释义配对'/>
  </div>

  <div class="grid grid-cols-2 gap-6">
    <!-- Left side -->
    <div>
      <div class="flex items-center justify-between mb-2">
        <label class="text-sm font-medium text-gray-700">左侧列表</label>
        <button onclick={addLeft} class="text-xs text-indigo-600 hover:text-indigo-800">+ 添加</button>
      </div>
      <div class="space-y-1.5">
        {#each leftItems as item, idx}
          <div class="flex items-center gap-1.5">
            <span class="text-xs font-mono bg-gray-100 px-1.5 py-0.5 rounded w-7 text-center">{item.id}</span>
            <input type="text" class="flex-1 px-2 py-1 border rounded text-sm"
                   value={item.text} placeholder="文本"
                   oninput={(e: Event) => updateLeftText(idx, (e.target as HTMLInputElement).value)}/>
            <button onclick={() => removeLeft(idx)} class="text-red-400 hover:text-red-600 text-xs">✕</button>
          </div>
        {/each}
      </div>
    </div>

    <!-- Right side -->
    <div>
      <div class="flex items-center justify-between mb-2">
        <label class="text-sm font-medium text-gray-700">右侧列表</label>
        <button onclick={addRight} class="text-xs text-indigo-600 hover:text-indigo-800">+ 添加</button>
      </div>
      <div class="space-y-1.5">
        {#each rightItems as item, idx}
          <div class="flex items-center gap-1.5">
            <span class="text-xs font-mono bg-gray-100 px-1.5 py-0.5 rounded w-7 text-center">{item.id}</span>
            <input type="text" class="flex-1 px-2 py-1 border rounded text-sm"
                   value={item.text} placeholder="文本"
                   oninput={(e: Event) => updateRightText(idx, (e.target as HTMLInputElement).value)}/>
            <button onclick={() => removeRight(idx)} class="text-red-400 hover:text-red-600 text-xs">✕</button>
          </div>
        {/each}
      </div>
    </div>
  </div>

  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">正确答案（配对关系，逗号分隔）</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm font-mono"
           value={pairs}
           oninput={(e: Event) => { pairs = (e.target as HTMLInputElement).value; syncOptions(); }}
           placeholder='例如：A3,B1,C2（表示 A↔3、B↔1、C↔2 配对）'/>
    <p class="text-xs text-gray-400 mt-1">格式：左侧ID+右侧ID，多组用逗号分隔</p>
  </div>
</div>
