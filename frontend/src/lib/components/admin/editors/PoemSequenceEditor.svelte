<script lang="ts">
  import type { CreateQuestion } from '$lib/api/admin';

  let {
    questionData,
    onUpdate,
  }: {
    questionData: { questionText: string; options: string | null; correctAnswer: string };
    onUpdate?: (data: Partial<CreateQuestion>) => void;
  } = $props();

  let lines = $state<string[]>([]);
  let correctOrder = $state<string>('');

  $effect(() => {
    try { lines = questionData.options ? JSON.parse(questionData.options) : []; } catch { lines = []; }
    correctOrder = questionData.correctAnswer || '';
  });

  function updateLines() {
    onUpdate?.({ options: JSON.stringify(lines.filter(l => l.trim())) });
  }

  function addLine() { lines = [...lines, '']; }
</script>

<div class="space-y-4">
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">题目文本</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={questionData.questionText}
           oninput={(e: Event) => onUpdate?.({ questionText: (e.target as HTMLInputElement).value })}
           placeholder="例如：请将《静夜思》的诗句按正确顺序排列"/>
  </div>
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-2">诗句行（按显示顺序，非正确顺序）</label>
    {#each lines as line, i}
      <div class="flex items-center gap-2 mb-1.5">
        <span class="text-xs text-gray-400 w-6">{i + 1}.</span>
        <input type="text" class="flex-1 px-3 py-1 border rounded text-sm"
               value={line}
               oninput={(e: Event) => { lines[i] = (e.target as HTMLInputElement).value; updateLines(); }}
               placeholder="诗句行"/>
        <button onclick={() => { lines = lines.filter((_, j) => j !== i); updateLines(); }}
                class="text-red-400 hover:text-red-600 text-xs">✕</button>
      </div>
    {/each}
    <button onclick={addLine} class="text-xs text-indigo-500 hover:text-indigo-700 mt-1">+ 添加行</button>
  </div>
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">正确顺序（逗号分隔的索引，从 1 开始）</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={correctOrder}
           oninput={(e: Event) => { correctOrder = (e.target as HTMLInputElement).value; onUpdate?.({ correctAnswer: correctOrder }); }}
           placeholder="例如：1,2,3,4"/>
  </div>
</div>
