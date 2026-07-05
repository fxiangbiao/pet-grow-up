<script lang="ts">
  import type { CreateQuestion } from '$lib/api/admin';

  let {
    questionData,
    onUpdate,
  }: {
    questionData: CreateQuestion;
    onUpdate?: (data: Partial<CreateQuestion>) => void;
  } = $props();

  function update(field: string, value: any) {
    onUpdate?.({ [field]: value });
  }
</script>

<div class="space-y-3">
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">题目文本</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={questionData.questionText}
           oninput={(e: Event) => update('questionText', (e.target as HTMLInputElement).value)}
           placeholder='例如：哪个是圆形？'/>
  </div>
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">正确答案（形状标识）</label>
    <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm"
           value={questionData.correctAnswer}
           oninput={(e: Event) => update('correctAnswer', (e.target as HTMLInputElement).value)}
           placeholder='例如：CIRCLE / SQUARE / TRIANGLE / RECTANGLE'/>
    <p class="text-xs text-gray-400 mt-1">前端场景组件根据这个值判断哪个图形是正确答案</p>
  </div>
</div>
