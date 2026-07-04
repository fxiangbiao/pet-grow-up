<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { adminApi, type CreateQuestion } from '$lib/api/admin';
  import QuestionFormShell from '$lib/components/admin/editors/QuestionFormShell.svelte';
  import { toastStore } from '$lib/stores/toast.svelte';

  let isNew = $derived($page.params.id === 'new');
  let questionId = $derived(isNew ? null : Number($page.params.id));
  let loading = $state(false);
  let saving = $state(false);

  let formData = $state<CreateQuestion>({
    knowledgeNodeId: 0,
    questionType: 'SCENE_TAP',
    difficulty: 1,
    questionText: '',
    options: '',
    correctAnswer: '',
    explanation: '',
    points: 10,
  });

  onMount(() => {
    if (!isNew && questionId) loadQuestion(questionId);
  });

  async function loadQuestion(id: number) {
    loading = true;
    try {
      const q = await adminApi.getQuestion(id) as any;
      formData = {
        knowledgeNodeId: q.knowledgeNodeId,
        questionType: q.questionType,
        difficulty: q.difficulty,
        questionText: q.questionText,
        options: q.options,
        correctAnswer: q.correctAnswer,
        explanation: q.explanation,
        points: q.points,
      };
    } catch {
      toastStore.error('加载题目失败');
      goto('/admin/questions');
    } finally { loading = false; }
  }

  function handleUpdate(partial: Partial<CreateQuestion>) {
    formData = { ...formData, ...partial };
  }

  async function handleSave() {
    if (!formData.questionText || !formData.correctAnswer || !formData.knowledgeNodeId) {
      toastStore.error('请填写必填字段');
      return;
    }
    saving = true;
    try {
      if (isNew) {
        await adminApi.createQuestion(formData);
        toastStore.success('题目已创建');
        goto('/admin/questions');
      } else if (questionId) {
        await adminApi.updateQuestion(questionId, formData);
        toastStore.success('题目已更新');
      }
    } catch (e: any) { toastStore.error(e.message || '保存失败'); }
    finally { saving = false; }
  }
</script>

<div>
  <div class="flex items-center justify-between mb-4">
    <div class="flex items-center gap-3">
      <button onclick={() => goto('/admin/questions')} class="text-gray-400 hover:text-gray-600">← 返回</button>
      <h2 class="text-xl font-bold text-gray-800">{isNew ? '新建题目' : '编辑题目 #' + questionId}</h2>
    </div>
    <button onclick={handleSave} disabled={saving}
            class="px-4 py-2 bg-indigo-600 text-white text-sm rounded-lg hover:bg-indigo-700 transition disabled:opacity-50">
      {saving ? '保存中...' : '💾 保存'}
    </button>
  </div>

  {#if loading}
    <div class="text-center text-gray-400 py-12">加载中...</div>
  {:else}
    <QuestionFormShell questionData={formData} onUpdate={handleUpdate} />
  {/if}
</div>
