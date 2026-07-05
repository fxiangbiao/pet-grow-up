<script lang="ts">
  import type { CreateQuestion } from '$lib/api/admin';

  let {
    questionData,
    onUpdate,
  }: {
    questionData: CreateQuestion;
    onUpdate?: (data: Partial<CreateQuestion>) => void;
  } = $props();

  let radical = $state('');
  let phonetic = $state('');
  let targetChar = $state('');

  // Parse existing options JSON on mount / when questionData changes
  $effect(() => {
    try {
      if (questionData.options) {
        const opts = JSON.parse(questionData.options);
        radical = opts.radical || '';
        phonetic = opts.phonetic || '';
        targetChar = opts.targetChar || '';
      }
    } catch { /* ignore */ }
  });

  function syncOptions() {
    const opts = JSON.stringify({ radical, phonetic, targetChar });
    onUpdate?.({ options: opts, correctAnswer: targetChar });
  }

  function updateRadical(v: string) { radical = v; syncOptions(); }
  function updatePhonetic(v: string) { phonetic = v; syncOptions(); }
  function updateTargetChar(v: string) { targetChar = v; syncOptions(); }
</script>

<div class="space-y-3">
  <p class="text-xs text-gray-400">汉字拼装题型：学生将声旁和形旁组合成目标汉字</p>
  <div class="grid grid-cols-3 gap-3">
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">偏旁/部首</label>
      <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
             value={radical}
             oninput={(e: Event) => updateRadical((e.target as HTMLInputElement).value)}
             placeholder='例如：亻'/>
    </div>
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">声旁/部件</label>
      <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
             value={phonetic}
             oninput={(e: Event) => updatePhonetic((e.target as HTMLInputElement).value)}
             placeholder='例如：门'/>
    </div>
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">目标汉字</label>
      <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
             value={targetChar}
             oninput={(e: Event) => updateTargetChar((e.target as HTMLInputElement).value)}
             placeholder='例如：们'/>
    </div>
  </div>
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">题目文本</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={questionData.questionText}
           oninput={(e: Event) => onUpdate?.({ questionText: (e.target as HTMLInputElement).value })}
           placeholder='例如：拼一拼：亻+ 门 = ？'/>
  </div>
  <p class="text-xs text-gray-400">预览：{radical} + {phonetic} = {targetChar}</p>
</div>
