<script lang="ts">
  import type { CreateQuestion } from '$lib/api/admin';

  let {
    questionData,
    onUpdate,
  }: {
    questionData: { questionText: string; options: string | null; correctAnswer: string };
    onUpdate?: (data: Partial<CreateQuestion>) => void;
  } = $props();

  let options = $state<{ key: string; text: string }[]>([]);
  let parsed = $derived.by(() => {
    try {
      return questionData.options ? JSON.parse(questionData.options) as { key: string; text: string }[] : [];
    } catch { return []; }
  });

  $effect(() => {
    const arr = parsed;
    if (arr.length > 0) options = arr;
    else options = [
      { key: 'A', text: '' }, { key: 'B', text: '' },
      { key: 'C', text: '' }, { key: 'D', text: '' }
    ];
  });

  function updateOptions() {
    onUpdate?.({ options: JSON.stringify(options.filter(o => o.text.trim())) });
  }

  function addOption() {
    const nextKey = String.fromCharCode(65 + options.length);
    options = [...options, { key: nextKey, text: '' }];
    updateOptions();
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
               oninput={(e: Event) => { options[i].text = (e.target as HTMLInputElement).value; updateOptions(); }}
               placeholder="选项 {opt.key} 文本"/>
      </div>
    {/each}
    {#if options.length < 6}
      <button onclick={addOption} class="text-xs text-indigo-500 hover:text-indigo-700 mt-1">+ 添加选项</button>
    {/if}
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
