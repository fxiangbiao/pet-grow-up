<script lang="ts">
  import type { CreateQuestion } from '$lib/api/admin';

  let {
    questionData,
    onUpdate,
  }: {
    questionData: CreateQuestion;
    onUpdate?: (data: Partial<CreateQuestion>) => void;
  } = $props();

  let hour = $state(7);

  // Parse existing options JSON
  $effect(() => {
    try {
      if (questionData.options) {
        const opts = JSON.parse(questionData.options);
        hour = opts.hour || 7;
      } else if (questionData.correctAnswer) {
        hour = parseInt(questionData.correctAnswer) || 7;
      }
    } catch { /* ignore */ }
  });

  function sync() {
    onUpdate?.({ options: JSON.stringify({ hour }), correctAnswer: String(hour) });
  }

  function setHour(h: number) { hour = h; sync(); }
</script>

<div class="space-y-3">
  <p class="text-xs text-gray-400">拨钟表题型：学生把时针拨到指定时间</p>
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">题目文本</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={questionData.questionText}
           oninput={(e: Event) => onUpdate?.({ questionText: (e.target as HTMLInputElement).value })}
           placeholder='例如：请把时针拨到 7:00'/>
  </div>
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-2">目标时间（整点）</label>
    <div class="flex gap-2 flex-wrap">
      {#each Array.from({ length: 12 }, (_, i) => i + 1) as h}
        <button onclick={() => setHour(h)}
                class="w-12 h-12 rounded-full text-sm font-medium border-2 transition
                  {h === hour ? 'bg-indigo-600 text-white border-indigo-600' : 'bg-white text-gray-700 border-gray-300 hover:border-indigo-400'}">
          {h}
        </button>
      {/each}
    </div>
    <p class="text-xs text-gray-500 mt-2">选中：{hour}:00</p>
  </div>
</div>
