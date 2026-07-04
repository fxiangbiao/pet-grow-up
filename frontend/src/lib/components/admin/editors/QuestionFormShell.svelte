<script lang="ts">
  import type { CreateQuestion, NodeTreeItem } from '$lib/api/admin';
  import { adminApi } from '$lib/api/admin';
  import MultipleChoiceEditor from './MultipleChoiceEditor.svelte';
  import FillBlankEditor from './FillBlankEditor.svelte';
  import MathInputEditor from './MathInputEditor.svelte';
  import PoemSequenceEditor from './PoemSequenceEditor.svelte';
  import GenericEditor from './GenericEditor.svelte';

  let {
    questionData,
    onUpdate,
  }: {
    questionData: CreateQuestion;
    onUpdate?: (data: Partial<CreateQuestion>) => void;
  } = $props();

  let nodes = $state<NodeTreeItem[]>([]);
  let nodeOptions = $derived(flattenNodes(nodes));

  function flattenNodes(items: NodeTreeItem[], prefix = ''): { id: number; label: string }[] {
    let result: { id: number; label: string }[] = [];
    for (const n of items) {
      result.push({ id: n.id, label: prefix + n.name + ' [' + n.subject + ' G' + n.gradeLevel + ']' });
      if (n.children) result.push(...flattenNodes(n.children, prefix + '  '));
    }
    return result;
  }

  // Load nodes on mount
  let loaded = $state(false);
  if (!loaded) {
    loaded = true;
    adminApi.getNodeTree().then(n => nodes = n).catch(() => nodes = []);
  }

  function update(field: string, value: any) {
    onUpdate?.({ [field]: value });
  }

  const typeOptions: Record<string, string> = {
    SCENE_TAP: '泡泡点击', MULTIPLE_CHOICE: '选择题', FILL_BLANK: '填空题',
    SCENE_MATCH: '图形配对', MATH_INPUT: '数字输入', SCENE_CHAR_BUILD: '汉字拼装',
    SCENE_PINYIN: '拼音泡泡', SCENE_DRAG: '拖拽凑十', VOCAB_MATCH: '单词配对',
    SCENE_CLOCK: '拨钟表', SCENE_SHOP: '宠物商店', POEM_SEQUENCE: '诗句排序'
  };
</script>

<div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 space-y-4">
  <!-- Meta fields -->
  <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">知识节点 *</label>
      <select class="w-full px-3 py-1.5 border rounded-lg text-sm"
              value={questionData.knowledgeNodeId || ''}
              onchange={(e: Event) => update('knowledgeNodeId', Number((e.target as HTMLSelectElement).value))}>
        <option value="">选择节点...</option>
        {#each nodeOptions as n}
          <option value={n.id}>{n.label}</option>
        {/each}
      </select>
    </div>
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">题型</label>
      <select class="w-full px-3 py-1.5 border rounded-lg text-sm"
              value={questionData.questionType}
              onchange={(e: Event) => update('questionType', (e.target as HTMLSelectElement).value)}>
        {#each Object.entries(typeOptions) as [key, label]}
          <option value={key}>{label}</option>
        {/each}
      </select>
    </div>
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">难度</label>
      <select class="w-full px-3 py-1.5 border rounded-lg text-sm"
              value={questionData.difficulty ?? 1}
              onchange={(e: Event) => update('difficulty', Number((e.target as HTMLSelectElement).value))}>
        <option value="1">⭐</option><option value="2">⭐⭐</option>
        <option value="3">⭐⭐⭐</option><option value="4">⭐⭐⭐⭐</option><option value="5">⭐⭐⭐⭐⭐</option>
      </select>
    </div>
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">分值</label>
      <input type="number" min="1" class="w-full px-3 py-1.5 border rounded-lg text-sm"
             value={questionData.points ?? 10}
             onchange={(e: Event) => update('points', Number((e.target as HTMLInputElement).value))}/>
    </div>
  </div>

  <!-- Type-specific editor -->
  <div class="border-t pt-4">
    {#if questionData.questionType === 'MULTIPLE_CHOICE' || questionData.questionType === 'SCENE_TAP'}
      <MultipleChoiceEditor questionData={questionData as any} onUpdate={onUpdate} />
    {:else if questionData.questionType === 'FILL_BLANK'}
      <FillBlankEditor questionData={questionData as any} onUpdate={onUpdate} />
    {:else if questionData.questionType === 'MATH_INPUT'}
      <MathInputEditor questionData={questionData as any} onUpdate={onUpdate} />
    {:else if questionData.questionType === 'POEM_SEQUENCE'}
      <PoemSequenceEditor questionData={questionData as any} onUpdate={onUpdate} />
    {:else}
      <GenericEditor questionData={questionData as any} onUpdate={onUpdate}
        typeLabel={typeOptions[questionData.questionType] || questionData.questionType} />
    {/if}
  </div>

  <!-- Explanation -->
  <div class="border-t pt-4">
    <label class="block text-sm font-medium text-gray-700 mb-1">解释</label>
    <textarea rows="2" class="w-full px-3 py-1.5 border rounded-lg text-sm"
              value={questionData.explanation || ''}
              oninput={(e: Event) => update('explanation', (e.target as HTMLTextAreaElement).value)}
              placeholder="答题后的解释说明..."></textarea>
  </div>
</div>
