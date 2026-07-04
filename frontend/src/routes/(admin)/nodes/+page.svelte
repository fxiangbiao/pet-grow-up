<script lang="ts">
  import { onMount } from 'svelte';
  import { adminApi, type NodeTreeItem, type CreateNode } from '$lib/api/admin';
  import { toastStore } from '$lib/stores/toast.svelte';

  let allNodes = $state<NodeTreeItem[]>([]);
  let loading = $state(true);
  let activeSubject = $state<string>('math');

  // Modal state
  let showModal = $state(false);
  let editingNode = $state<NodeTreeItem | null>(null);
  let parentNodeId = $state<number | undefined>(undefined);
  let nodeForm = $state<CreateNode>({ subject: 'math', nodeKey: '', name: '', difficulty: 1, gradeLevel: 1, orderIndex: 0 });

  // Expand state
  let expanded = $state<Set<number>>(new Set());

  const subjects = ['math', 'chinese', 'english'];
  const subjectLabels: Record<string, string> = { math: '数学', chinese: '语文', english: '英语' };

  onMount(() => { loadTree(); });

  async function loadTree() {
    loading = true;
    try { allNodes = await adminApi.getNodeTree(); } catch { allNodes = []; }
    finally { loading = false; }
  }

  let filteredNodes = $derived(allNodes.filter(n => n.subject === activeSubject));

  function toggleExpand(id: number) {
    const next = new Set(expanded);
    if (next.has(id)) next.delete(id); else next.add(id);
    expanded = next;
  }

  function openCreate(parentId: number | undefined) {
    editingNode = null;
    parentNodeId = parentId;
    nodeForm = { subject: activeSubject, nodeKey: '', name: '', difficulty: 1, gradeLevel: 1, orderIndex: 0 };
    showModal = true;
  }

  function openEdit(node: NodeTreeItem) {
    editingNode = node;
    parentNodeId = undefined;
    nodeForm = {
      subject: node.subject, nodeKey: node.nodeKey, name: node.name,
      description: node.description || undefined, difficulty: node.difficulty,
      gradeLevel: node.gradeLevel, parentNodeId: node.parentNodeId || undefined,
      orderIndex: node.orderIndex,
    };
    showModal = true;
  }

  async function handleSave() {
    if (!nodeForm.nodeKey || !nodeForm.name) { toastStore.error('请填写必填字段'); return; }
    try {
      if (editingNode) {
        await adminApi.updateNode(editingNode.id, nodeForm);
        toastStore.success('节点已更新');
      } else {
        await adminApi.createNode({ ...nodeForm, parentNodeId, subject: activeSubject });
        toastStore.success('节点已创建');
      }
      showModal = false;
      loadTree();
    } catch (e: any) { toastStore.error(e.message || '保存失败'); }
  }

  async function handleDelete(node: NodeTreeItem) {
    if (!confirm(`确定删除 "${node.name}"？${node.questionCount > 0 ? `\n（该节点有 ${node.questionCount} 道题目）` : ''}${node.children ? '\n（该节点有子节点）' : ''}`)) return;
    try {
      await adminApi.deleteNode(node.id);
      toastStore.success('节点已删除');
      loadTree();
    } catch (e: any) { toastStore.error(e.message || '删除失败'); }
  }

  function diffStars(d: number): string { return '⭐'.repeat(d); }
</script>

<div>
  <div class="flex items-center justify-between mb-4">
    <h2 class="text-xl font-bold text-gray-800">知识节点管理</h2>
    <button onclick={() => openCreate(undefined)}
            class="px-4 py-2 bg-indigo-600 text-white text-sm rounded-lg hover:bg-indigo-700 transition">
      ➕ 新建节点
    </button>
  </div>

  <!-- Subject tabs -->
  <div class="flex gap-1 mb-4">
    {#each subjects as s}
      <button onclick={() => activeSubject = s}
              class="px-4 py-1.5 rounded-lg text-sm font-medium transition
                {activeSubject === s ? 'bg-indigo-600 text-white' : 'bg-white text-gray-600 hover:bg-gray-100 border'}">
        {subjectLabels[s]}
      </button>
    {/each}
  </div>

  <!-- Tree -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
    {#if loading}
      <div class="text-center text-gray-400 py-8">加载中...</div>
    {:else if filteredNodes.length === 0}
      <div class="text-center text-gray-400 py-8">暂无节点，点击上方按钮创建</div>
    {:else}
      {#each filteredNodes as root (root.id)}
        {#snippet renderNode(node: NodeTreeItem, depth: number)}
          <div class="border-b border-gray-50 last:border-0">
            <div class="flex items-center gap-2 py-2 hover:bg-gray-50 rounded px-2"
                 style="padding-left: {depth * 20 + 8}px">
              {#if node.children && node.children.length > 0}
                <button onclick={() => toggleExpand(node.id)}
                        class="text-xs text-gray-400 w-4">{expanded.has(node.id) ? '▼' : '▶'}</button>
              {:else}
                <span class="w-4"></span>
              {/if}
              <span class="font-medium text-sm">{node.name}</span>
              <code class="text-xs bg-gray-100 px-1.5 py-0.5 rounded text-gray-500">{node.nodeKey}</code>
              <span class="text-xs">{diffStars(node.difficulty)}</span>
              <span class="text-xs bg-indigo-100 text-indigo-700 px-1.5 py-0.5 rounded">G{node.gradeLevel}</span>
              <span class="text-xs text-gray-400">{node.questionCount} 题</span>
              <span class="flex-1"></span>
              <button onclick={() => openCreate(node.id)} class="text-xs text-green-500 hover:text-green-700">+子节点</button>
              <button onclick={() => openEdit(node)} class="text-xs text-indigo-500 hover:text-indigo-700 ml-2">编辑</button>
              <button onclick={() => handleDelete(node)} class="text-xs text-red-400 hover:text-red-600 ml-2">删除</button>
            </div>
            {#if node.children && node.children.length > 0 && expanded.has(node.id)}
              {#each node.children as child (child.id)}
                {@render renderNode(child, depth + 1)}
              {/each}
            {/if}
          </div>
        {/snippet}
        {@render renderNode(root, 0)}
      {/each}
    {/if}
  </div>

  <!-- Modal for create/edit -->
  {#if showModal}
    <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/30" role="dialog"
         onclick={() => showModal = false}>
      <div class="bg-white rounded-xl p-6 shadow-xl w-full max-w-lg mx-4" onclick={(e: Event) => e.stopPropagation()}>
        <h3 class="text-lg font-semibold mb-4">{editingNode ? '编辑节点' : '新建节点'}</h3>
        <div class="space-y-3">
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Node Key *</label>
              <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm" bind:value={nodeForm.nodeKey}
                     placeholder="例如：math_intro"/>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">名称 *</label>
              <input type="text" class="w-full px-3 py-1.5 border rounded-lg text-sm" bind:value={nodeForm.name}
                     placeholder="例如：凑十法与10以内"/>
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">描述</label>
            <textarea rows="2" class="w-full px-3 py-1.5 border rounded-lg text-sm" bind:value={nodeForm.description}
                      placeholder="节点描述..."></textarea>
          </div>
          <div class="grid grid-cols-3 gap-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">难度</label>
              <select class="w-full px-3 py-1.5 border rounded-lg text-sm" bind:value={nodeForm.difficulty}>
                <option value="1">⭐</option><option value="2">⭐⭐</option><option value="3">⭐⭐⭐</option>
                <option value="4">⭐⭐⭐⭐</option><option value="5">⭐⭐⭐⭐⭐</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">年级</label>
              <select class="w-full px-3 py-1.5 border rounded-lg text-sm" bind:value={nodeForm.gradeLevel}>
                <option value="1">一年级</option><option value="2">二年级</option><option value="3">三年级</option>
                <option value="4">四年级</option><option value="5">五年级</option><option value="6">六年级</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">排序</label>
              <input type="number" class="w-full px-3 py-1.5 border rounded-lg text-sm" bind:value={nodeForm.orderIndex}/>
            </div>
          </div>
        </div>
        <div class="flex gap-3 justify-end mt-6">
          <button onclick={() => showModal = false} class="px-4 py-2 text-sm border rounded-lg hover:bg-gray-50">取消</button>
          <button onclick={handleSave} class="px-4 py-2 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">保存</button>
        </div>
      </div>
    </div>
  {/if}
</div>
