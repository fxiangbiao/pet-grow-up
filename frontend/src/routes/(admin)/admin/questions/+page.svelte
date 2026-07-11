<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { adminApi, type QuestionFilter, type QuestionRow, type QuestionPage } from '$lib/api/admin';
  import { toastStore } from '$lib/stores/toast.svelte';
  import Pagination from '$lib/components/admin/Pagination.svelte';

  let filter = $state<QuestionFilter>({ page: 1, size: 20 });
  let pageData = $state<QuestionPage | null>(null);
  let loading = $state(false);
  let errorMsg = $state<string | null>(null);
  let confirmDelete = $state<number | null>(null);

  onMount(() => { loadQuestions(); });

  async function loadQuestions() {
    loading = true;
    errorMsg = null;
    try {
      pageData = await adminApi.listQuestions(filter);
      if (!pageData || pageData.items.length === 0) {
        errorMsg = '暂无题目数据。请确认：\n1. 后端服务已启动 (mvn spring-boot:run)\n2. 数据库已初始化 (data.sql 含 502 题)\n3. 检查浏览器控制台 (F12) 是否有网络错误';
      }
    } catch (e: any) {
      errorMsg = e.message || '加载失败';
      pageData = null;
    } finally {
      loading = false;
    }
  }

  function applyFilter(updates: Partial<QuestionFilter>) {
    filter = { ...filter, ...updates, page: 1 };
    loadQuestions();
  }

  function goPage(p: number) {
    filter = { ...filter, page: p };
    loadQuestions();
  }

  async function handleDelete(id: number) {
    try {
      await adminApi.deleteQuestion(id);
      toastStore.success('题目已删除');
      confirmDelete = null;
      loadQuestions();
    } catch (e: any) { toastStore.error(e.message || '删除失败'); }
  }

  function typeLabel(type: string): string {
    const map: Record<string, string> = {
      SCENE_TAP: '泡泡点击', MULTIPLE_CHOICE: '选择题', FILL_BLANK: '填空题',
      SCENE_MATCH: '图形配对', MATH_INPUT: '数字输入', SCENE_CHAR_BUILD: '汉字拼装',
      SCENE_PINYIN: '拼音泡泡', SCENE_DRAG: '拖拽凑十', VOCAB_MATCH: '单词配对',
      SCENE_CLOCK: '拨钟表', SCENE_SHOP: '宠物商店', POEM_SEQUENCE: '诗句排序', SCENE_SHAPE_PUZZLE: '拼图工坊', SCENE_WHACK_MOLE: '打地鼠'
    };
    return map[type] || type;
  }

  function diffStars(d: number): string {
    return '⭐'.repeat(d);
  }

  let totalPages = $derived(pageData ? Math.ceil(pageData.total / pageData.size) : 0);
</script>

<div>
  <div class="flex items-center justify-between mb-4">
    <h2 class="text-xl font-bold text-gray-800">题库管理</h2>
    <div class="flex gap-2">
      <button onclick={() => goto('/admin/questions/new')}
              class="px-4 py-2 bg-indigo-600 text-white text-sm rounded-lg hover:bg-indigo-700 transition">
        ➕ 新建题目
      </button>
    </div>
  </div>

  <!-- Filters -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-4">
    <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-3">
      <select class="px-3 py-1.5 border rounded-lg text-sm" onchange={(e: Event) => applyFilter({ subject: (e.target as HTMLSelectElement).value || undefined })}>
        <option value="">全部学科</option>
        <option value="math">数学</option>
        <option value="chinese">语文</option>
        <option value="english">英语</option>
      </select>
      <select class="px-3 py-1.5 border rounded-lg text-sm" onchange={(e: Event) => { const v = (e.target as HTMLSelectElement).value; applyFilter({ gradeLevel: v ? Number(v) : undefined }); }}>
        <option value="">全部年级</option>
        <option value="1">一年级</option>
        <option value="2">二年级</option>
        <option value="3">三年级</option>
      </select>
      <select class="px-3 py-1.5 border rounded-lg text-sm" onchange={(e: Event) => applyFilter({ questionType: (e.target as HTMLSelectElement).value || undefined })}>
        <option value="">全部题型</option>
        <option value="SCENE_TAP">泡泡点击</option>
        <option value="MULTIPLE_CHOICE">选择题</option>
        <option value="FILL_BLANK">填空题</option>
        <option value="SCENE_MATCH">图形配对</option>
        <option value="MATH_INPUT">数字输入</option>
        <option value="SCENE_CHAR_BUILD">汉字拼装</option>
        <option value="SCENE_PINYIN">拼音泡泡</option>
        <option value="SCENE_DRAG">拖拽凑十</option>
        <option value="VOCAB_MATCH">单词配对</option>
        <option value="SCENE_CLOCK">拨钟表</option>
        <option value="SCENE_SHOP">宠物商店</option>
        <option value="POEM_SEQUENCE">诗句排序</option>
        <option value="SCENE_SHAPE_PUZZLE">拼图工坊</option>
        <option value="SCENE_WHACK_MOLE">打地鼠</option>
      </select>
      <select class="px-3 py-1.5 border rounded-lg text-sm" onchange={(e: Event) => { const v = (e.target as HTMLSelectElement).value; applyFilter({ difficulty: v ? Number(v) : undefined }); }}>
        <option value="">全部难度</option>
        <option value="1">⭐</option><option value="2">⭐⭐</option><option value="3">⭐⭐⭐</option>
        <option value="4">⭐⭐⭐⭐</option><option value="5">⭐⭐⭐⭐⭐</option>
      </select>
      <input type="text" placeholder="搜索题目..." class="px-3 py-1.5 border rounded-lg text-sm col-span-2 lg:col-span-2"
             onkeydown={(e: KeyboardEvent) => { if (e.key === 'Enter') applyFilter({ keyword: (e.target as HTMLInputElement).value || undefined }); }}/>
    </div>
  </div>

  <!-- Table -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
    {#if loading}
      <div class="text-center text-gray-400 py-12">加载中...</div>
    {:else if pageData && pageData.items.length > 0}
      <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b">
          <tr>
            <th class="text-left px-4 py-2 font-medium text-gray-500 w-12">ID</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">题型</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">题目</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">节点</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">学科</th>
            <th class="text-left px-4 py-2 font-medium text-gray-500">年级</th>
            <th class="text-center px-4 py-2 font-medium text-gray-500">难度</th>
            <th class="text-center px-4 py-2 font-medium text-gray-500">操作</th>
          </tr>
        </thead>
        <tbody class="divide-y">
          {#each pageData.items as q}
            <tr class="hover:bg-gray-50">
              <td class="px-4 py-2 text-gray-400">{q.id}</td>
              <td class="px-4 py-2">
                <span class="text-xs bg-indigo-100 text-indigo-700 px-2 py-0.5 rounded-full">{typeLabel(q.questionType)}</span>
              </td>
              <td class="px-4 py-2 max-w-xs truncate">{q.questionText}</td>
              <td class="px-4 py-2 text-xs text-gray-500">{q.knowledgeNodeName || '-'}</td>
              <td class="px-4 py-2 text-xs">{q.subject || '-'}</td>
              <td class="px-4 py-2 text-xs">{q.gradeLevel ? 'G' + q.gradeLevel : '-'}</td>
              <td class="px-4 py-2 text-center text-xs">{diffStars(q.difficulty)}</td>
              <td class="px-4 py-2 text-center">
                <button onclick={() => goto(`/admin/questions/${q.id}`)}
                        class="text-indigo-600 hover:text-indigo-800 text-xs mr-2">编辑</button>
                <button onclick={() => confirmDelete = q.id}
                        class="text-red-500 hover:text-red-700 text-xs">删除</button>
              </td>
            </tr>
          {/each}
        </tbody>
      </table>

      <!-- Pagination -->
      <Pagination page={filter.page ?? 1} totalPages={totalPages} total={pageData.total} {goPage} />
    {:else if errorMsg}
      <div class="text-center py-12 px-4">
        <div class="text-red-500 text-sm whitespace-pre-line bg-red-50 rounded-lg p-4 inline-block text-left max-w-lg">{errorMsg}</div>
      </div>
    {:else}
      <div class="text-center text-gray-400 py-12">暂无题目</div>
    {/if}
  </div>

  <!-- Delete confirmation modal -->
  {#if confirmDelete !== null}
    <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/30" role="dialog">
      <div class="bg-white rounded-xl p-6 shadow-xl max-w-sm mx-4">
        <h3 class="text-lg font-semibold mb-2">确认删除</h3>
        <p class="text-gray-500 text-sm mb-4">确定要删除题目 #{confirmDelete} 吗？此操作不可撤销。</p>
        <div class="flex gap-3 justify-end">
          <button onclick={() => confirmDelete = null} class="px-4 py-2 text-sm border rounded-lg hover:bg-gray-50">取消</button>
          <button onclick={() => handleDelete(confirmDelete!)} class="px-4 py-2 text-sm bg-red-600 text-white rounded-lg hover:bg-red-700">删除</button>
        </div>
      </div>
    </div>
  {/if}
</div>
