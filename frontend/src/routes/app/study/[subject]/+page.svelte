<script lang="ts">
  import { getWorldMap } from '$lib/api/study';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';

  interface WorldNode {
    nodeId: number;
    name: string;
    description: string;
    difficulty: number;
    isUnlocked: boolean;
    isCompleted: boolean;
    starRating: number;
  }

  let loading = $state(true);
  let nodes = $state<WorldNode[]>([]);
  let subject = $derived($page.params.subject as string);

  const subjectLabels: Record<string, string> = {
    chinese: '诗词大陆', math: '智慧王国', english: '魔法学院'
  };
  const subjectEmojis: Record<string, string> = {
    chinese: '📜', math: '🔢', english: '🔤'
  };
  const subjectThemes: Record<string, string> = {
    chinese: 'bg-amber-50 border-amber-200',
    math: 'bg-blue-50 border-blue-200',
    english: 'bg-purple-50 border-purple-200'
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
</script>

<svelte:head>
  <title>{subjectLabels[subject] || subject} - Pet Grow Up</title>
</svelte:head>

<div class="animate-slide-up">
  <button onclick={() => goto('/app/study')} class="text-gray-500 hover:text-gray-700 mb-4 flex items-center gap-1">
    ← 返回学科选择
  </button>

  <div class="flex items-center gap-3 mb-6">
    <span class="text-4xl">{subjectEmojis[subject] || '🌍'}</span>
    <div>
      <h1 class="text-2xl font-bold text-gray-800">{subjectLabels[subject] || subject}</h1>
      <p class="text-gray-500">选择知识点开始探险</p>
    </div>
  </div>

  {#if loading}
    <div class="text-center text-gray-500 py-12">加载中...</div>
  {:else if nodes.length === 0}
    <div class="text-center py-12 text-gray-500">暂无可用节点</div>
  {:else}
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {#each nodes as node}
        <div class={[
          'rounded-2xl border-2 p-5 transition',
          node.isUnlocked
            ? subjectThemes[subject] + ' hover:shadow-md cursor-pointer'
            : 'bg-gray-50 border-gray-200 opacity-60'
        ].join(' ')}
          onclick={node.isUnlocked ? () => startExploration(node.nodeId) : undefined}
          role={node.isUnlocked ? 'button' : undefined}
        >
          <div class="flex items-center justify-between mb-2">
            <span class="text-sm font-medium text-gray-500">Lv.{node.difficulty}</span>
            {#if node.isCompleted}
              <span class="text-yellow-500 text-sm">⭐</span>
            {:else if !node.isUnlocked}
              <span class="text-gray-400 text-sm">🔒</span>
            {:else}
              <span class="text-green-500 text-sm">🔓</span>
            {/if}
          </div>
          <h3 class="font-bold text-gray-800">{node.name}</h3>
          <p class="text-sm text-gray-600 mt-1">{node.description}</p>
        </div>
      {/each}
    </div>
  {/if}
</div>
