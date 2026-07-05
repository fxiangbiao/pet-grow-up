<script lang="ts">
  import type { CreateQuestion } from '$lib/api/admin';

  let {
    questionData,
    onUpdate,
  }: {
    questionData: { questionText: string; options: string | null; correctAnswer: string };
    onUpdate?: (data: Partial<CreateQuestion>) => void;
  } = $props();

  let parsed = $derived.by(() => {
    try {
      const arr = questionData.options ? JSON.parse(questionData.options) as { key: string; text: string }[] : [];
      if (arr.length >= 2) return arr;
    } catch { /* fall through */ }
    // Default: 4 empty options
    return [
      { key: 'A', text: '' }, { key: 'B', text: '' },
      { key: 'C', text: '' }, { key: 'D', text: '' }
    ];
  });

  // Use local copy for two-way binding without $effect loop
  let options = $state<{ key: string; text: string }[]>([]);
  let init = $state(false);
  if (!init) {
    init = true;
    options = [...parsed];
  }

  // Sync external changes (e.g. loading saved question) into local state
  $effect(() => {
    const ext = JSON.stringify(parsed);
    const loc = JSON.stringify(options);
    if (ext !== loc) {
      options = [...parsed];
    }
  });

  function syncToParent() {
    // Always save all options including empty ones (user can add blanks then fill them)
    onUpdate?.({ options: JSON.stringify(options) });
  }

  function updateText(idx: number, text: string) {
    options[idx].text = text;
    options = options; // trigger reactivity
    syncToParent();
  }

  function addOption() {
    if (options.length >= 6) return;
    const nextKey = String.fromCharCode(65 + options.length);
    options = [...options, { key: nextKey, text: '' }];
    syncToParent();
  }

  function removeOption(idx: number) {
    if (options.length <= 2) return; // minimum 2 options
    options = options.filter((_, i) => i !== idx);
    // Reassign keys
    options = options.map((o, i) => ({ ...o, key: String.fromCharCode(65 + i) }));
    syncToParent();
  }
</script>

<div class="space-y-4">
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">题目文本</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={questionData.questionText}
           oninput={(e: Event) => onUpdate?.({ questionText: (e.target as HTMLInputElement).value })}/>
  </div>
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-2">选项</label>
    {#each options as opt, i}
      <div class="flex items-center gap-2 mb-1.5">
        <span class="w-6 text-center text-sm font-medium text-gray-500">{opt.key}</span>
        <input type="text" class="flex-1 px-3 py-1 border rounded text-sm"
               value={opt.text}
               oninput={(e: Event) => updateText(i, (e.target as HTMLInputElement).value)}
               placeholder="选项 {opt.key} 文本"/>
        {#if options.length > 2}
          <button onclick={() => removeOption(i)} class="text-red-400 hover:text-red-600 text-sm" title="删除此选项">✕</button>
        {/if}
      </div>
    {/each}
    <div class="flex gap-2 mt-1">
      {#if options.length < 6}
        <button onclick={addOption} class="text-xs text-indigo-500 hover:text-indigo-700">+ 添加选项</button>
      {/if}
      <span class="text-xs text-gray-400">（最少 2 个，最多 6 个）</span>
    </div>
  </div>
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">正确答案</label>
    <select class="px-3 py-1.5 border rounded-lg text-sm" value={questionData.correctAnswer}
            onchange={(e: Event) => onUpdate?.({ correctAnswer: (e.target as HTMLSelectElement).value })}>
      <option value="">选择正确答案...</option>
      {#each options.filter(o => o.text.trim()) as opt}
        <option value={opt.key}>{opt.key}. {opt.text}</option>
      {/each}
    </select>
  </div>
</div>
