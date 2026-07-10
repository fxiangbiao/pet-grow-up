<script lang="ts">
  import type { CreateQuestion } from '$lib/api/admin';

  let {
    questionData,
    onUpdate,
  }: {
    questionData: { questionText: string; options: string | null; correctAnswer: string };
    onUpdate?: (data: Partial<CreateQuestion>) => void;
  } = $props();

  // Normalize external data — same pattern as MultipleChoiceEditor to avoid $effect loops
  let parsedLines = $derived.by(() => {
    try {
      const arr = questionData.options ? JSON.parse(questionData.options) : [];
      return Array.isArray(arr) ? arr : [];
    } catch { return []; }
  });

  let parsedCorrectAnswer = $derived(questionData.correctAnswer || '');

  let lines = $state<string[]>([]);
  let correctOrder = $state<string>('');
  let init = $state(false);

  if (!init) {
    init = true;
    lines = [...parsedLines];
    correctOrder = parsedCorrectAnswer;
  }

  // Sync from parent (e.g., loading saved question) — compare stringified outputs
  // so both sides go through the same serialisation path
  $effect(() => {
    const extLines = JSON.stringify(parsedLines);
    const locLines = JSON.stringify(lines);
    if (extLines !== locLines) {
      lines = [...parsedLines];
    }
    if (correctOrder !== parsedCorrectAnswer) {
      correctOrder = parsedCorrectAnswer;
    }
  });

  function syncToParent() {
    onUpdate?.({ options: JSON.stringify(lines), correctAnswer: correctOrder });
  }

  function addLine() {
    lines = [...lines, ''];
    syncToParent();
  }

  function updateLine(idx: number, text: string) {
    lines[idx] = text;
    lines = lines;
    syncToParent();
  }

  function removeLine(idx: number) {
    lines = lines.filter((_, j) => j !== idx);
    syncToParent();
  }
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
               oninput={(e: Event) => updateLine(i, (e.target as HTMLInputElement).value)}
               placeholder="诗句行"/>
        <button onclick={() => removeLine(i)}
                class="text-red-400 hover:text-red-600 text-xs">✕</button>
      </div>
    {/each}
    <button onclick={addLine} class="text-xs text-indigo-500 hover:text-indigo-700 mt-1">+ 添加行</button>
  </div>
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">正确顺序（逗号分隔的索引，从 1 开始）</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={correctOrder}
           oninput={(e: Event) => { correctOrder = (e.target as HTMLInputElement).value; syncToParent(); }}
           placeholder="例如：1,2,3,4"/>
  </div>
</div>
