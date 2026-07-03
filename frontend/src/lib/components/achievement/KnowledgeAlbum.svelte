<script lang="ts">
  // Knowledge album — grid of knowledge node cards grouped by subject
  // Data fetched from the world map API

  import { onMount } from 'svelte';
  import { getWorldMap } from '$lib/api/study';

  type NodeCard = { name: string; subject: string; unlocked: boolean; grade: number };

  let nodes = $state<NodeCard[]>([]);
  let loading = $state(true);
  let selectedSubject = $state('all');

  const subjects = [
    { key: 'all', label: '全部', color: 'bg-gray-100 text-gray-700' },
    { key: 'chinese', label: '语文', color: 'bg-amber-100 text-amber-700' },
    { key: 'math', label: '数学', color: 'bg-blue-100 text-blue-700' },
    { key: 'english', label: '英语', color: 'bg-purple-100 text-purple-700' },
  ];

  onMount(async () => {
    try {
      const allNodes: NodeCard[] = [];
      for (const subj of ['chinese', 'math', 'english']) {
        try {
          const world = await getWorldMap(subj);
          for (const n of (world.nodes || [])) {
            allNodes.push({
              name: n.name || '?',
              subject: subj,
              unlocked: n.isUnlocked ?? true,
              grade: n.difficulty ?? 1,
            });
          }
        } catch { /* skip unavailable subject */ }
      }
      nodes = allNodes;
    } catch { /* silent */ }
    loading = false;
  });

  let filtered = $derived(
    selectedSubject === 'all' ? nodes : nodes.filter(n => n.subject === selectedSubject)
  );
  let unlockedCount = $derived(nodes.filter(n => n.unlocked).length);
</script>

{#if loading}
  <p class="text-gray-400 text-center py-8">加载知识点...</p>
{:else}
  <!-- Subject filter -->
  <div class="flex gap-2 mb-4">
    {#each subjects as s}
      <button
        onclick={() => selectedSubject = s.key}
        class="px-3 py-1.5 rounded-lg text-xs font-medium transition {selectedSubject === s.key ? s.color : 'bg-gray-50 text-gray-500'}"
      >{s.label}</button>
    {/each}
  </div>

  <!-- Progress -->
  <p class="text-xs text-gray-400 mb-4">已点亮 {unlockedCount}/{nodes.length} 个知识点</p>

  <!-- Card grid -->
  {#if filtered.length === 0}
    <p class="text-gray-400 text-center py-12">暂无知识点</p>
  {:else}
    <div class="grid grid-cols-3 sm:grid-cols-4 gap-3">
      {#each filtered as node}
        <div class="p-3 rounded-xl text-center border-2 transition
          {node.unlocked ? 'bg-white border-indigo-200 shadow-sm' : 'bg-gray-100 border-gray-200 opacity-50'}">
          <div class="text-2xl mb-1">
            {node.unlocked ? '⭐' : '🔒'}
          </div>
          <div class="text-xs font-medium text-gray-700 truncate">{node.name}</div>
          <div class="text-[10px] text-gray-400">G{node.grade}</div>
        </div>
      {/each}
    </div>
  {/if}
{/if}
