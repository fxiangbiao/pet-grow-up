<script lang="ts">
  import { getWorldMap } from '$lib/api/study';
  import type { WorldNode } from '$lib/api/study';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import KnowledgeTree from '$lib/components/study/KnowledgeTree.svelte';

  let loading = $state(true);
  let nodes = $state<WorldNode[]>([]);
  let subject = $derived($page.params.subject as string);

  const subjectLabels: Record<string, string> = {
    chinese: '诗词大陆', math: '智慧王国', english: '魔法学院'
  };
  const subjectEmojis: Record<string, string> = {
    chinese: '📜', math: '🔢', english: '🔤'
  };

  $effect(() => {
    getWorldMap(subject).then(data => {
      nodes = data.nodes;
      loading = false;
    });
  });

  function startExploration(nodeId: number) {
    goto(`/app/study/${subject}/explore?nodeId=${nodeId}`);
  }

  // Count total stats
  const totalNodes = $derived(nodes.reduce((sum, n) => sum + 1 + (n.children?.length || 0), 0));
  const completedNodes = $derived(nodes.reduce((sum, n) =>
    sum + (n.isCompleted ? 1 : 0) + (n.children?.filter(c => c.isCompleted).length || 0), 0));
</script>

<svelte:head>
  <title>{subjectLabels[subject] || subject} - Pet Grow Up</title>
</svelte:head>

<div class="animate-slide-up">
  <button onclick={() => goto('/app/study')} class="text-gray-500 hover:text-gray-700 mb-4 flex items-center gap-1">
    ← 返回学科选择
  </button>

  <div class="flex items-center justify-between mb-4">
    <div class="flex items-center gap-3">
      <span class="text-4xl">{subjectEmojis[subject] || '🌍'}</span>
      <div>
        <h1 class="text-2xl font-bold text-gray-800">{subjectLabels[subject] || subject}</h1>
        <p class="text-gray-500 text-sm">已点亮 {completedNodes}/{totalNodes} 个知识点</p>
      </div>
    </div>
  </div>

  {#if loading}
    <div class="text-center text-gray-500 py-12">
      <div class="inline-block w-8 h-8 border-4 border-blue-200 border-t-blue-500 rounded-full animate-spin"></div>
      <p class="mt-2">加载知识树中...</p>
    </div>
  {:else if nodes.length === 0}
    <div class="text-center py-12 text-gray-500">暂无可用节点</div>
  {:else}
    <KnowledgeTree {nodes} {subject} onNodeClick={startExploration} />
  {/if}
</div>
