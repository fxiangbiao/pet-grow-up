<script lang="ts">
  import type { CreateQuestion } from '$lib/api/admin';

  let {
    questionData,
    onUpdate,
    typeLabel = '',
  }: {
    questionData: CreateQuestion;
    onUpdate?: (data: Partial<CreateQuestion>) => void;
    typeLabel?: string;
  } = $props();
</script>

<div class="space-y-4">
  {#if typeLabel}
    <p class="text-xs text-gray-400">题型 {typeLabel} 使用通用编辑器</p>
  {/if}
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">题目文本</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={questionData.questionText}
           oninput={(e: Event) => onUpdate?.({ questionText: (e.target as HTMLInputElement).value })}/>
  </div>
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">选项 (JSON)</label>
    <textarea rows="3" class="w-full px-3 py-1.5 border rounded-lg text-sm font-mono"
              value={questionData.options || ''}
              oninput={(e: Event) => onUpdate?.({ options: (e.target as HTMLTextAreaElement).value })}
              placeholder="JSON options array"></textarea>
  </div>
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">正确答案</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={questionData.correctAnswer}
           oninput={(e: Event) => onUpdate?.({ correctAnswer: (e.target as HTMLInputElement).value })}/>
  </div>
</div>
