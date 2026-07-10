<script lang="ts">
  import type { CreateQuestion } from '$lib/api/admin';

  let {
    questionData,
    onUpdate,
  }: {
    questionData: { questionText: string; correctAnswer: string };
    onUpdate?: (data: Partial<CreateQuestion>) => void;
  } = $props();
</script>

<div class="space-y-4">
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">题目文本</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={questionData.questionText}
           oninput={(e: Event) => onUpdate?.({ questionText: (e.target as HTMLInputElement).value })}
           placeholder="例如：6 + 7 = ?"/>
  </div>
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">正确答案（数字）</label>
    <input type="number" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={Number(questionData.correctAnswer) || ''}
           oninput={(e: Event) => onUpdate?.({ correctAnswer: String((e.target as HTMLInputElement).value) })}
           placeholder="例如：13"/>
  </div>
</div>
