<script lang="ts">
  import { browser } from '$app/environment';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { authStore } from '$lib/stores/auth.svelte';
  import '../../app.css';

  let { children } = $props();

  $effect(() => {
    if (browser && !authStore.isAdmin) {
      goto('/app');
    }
  });

  let currentPath = $derived($page.url.pathname);
</script>

<div class="min-h-screen bg-gray-50">
  <!-- Top bar -->
  <header class="bg-white border-b border-gray-200 shadow-sm">
    <div class="flex items-center justify-between px-6 py-3">
      <div class="flex items-center gap-4">
        <h1 class="text-lg font-bold text-gray-800">⚙️ 后台管理</h1>
        <span class="text-xs bg-indigo-100 text-indigo-700 px-2 py-0.5 rounded-full">Admin</span>
      </div>
      <div class="flex items-center gap-4">
        <span class="text-sm text-gray-500">{authStore.user?.nickname || authStore.user?.username}</span>
        <a href="/app" class="text-sm text-indigo-600 hover:text-indigo-800 transition">← 返回前台</a>
      </div>
    </div>
  </header>

  <div class="flex">
    <!-- Sidebar -->
    <nav class="w-56 min-h-[calc(100vh-53px)] bg-white border-r border-gray-200 p-4 flex-shrink-0">
      <div class="space-y-1">
        <a href="/admin/statistics"
           class="block px-3 py-2 rounded-lg text-sm font-medium transition
             {currentPath.startsWith('/admin/statistics') ? 'bg-indigo-50 text-indigo-700' : 'text-gray-600 hover:bg-gray-50'}">
          📊 统计仪表盘
        </a>
        <a href="/admin/questions"
           class="block px-3 py-2 rounded-lg text-sm font-medium transition
             {currentPath.startsWith('/admin/questions') ? 'bg-indigo-50 text-indigo-700' : 'text-gray-600 hover:bg-gray-50'}">
          📝 题库管理
        </a>
        <a href="/admin/nodes"
           class="block px-3 py-2 rounded-lg text-sm font-medium transition
             {currentPath.startsWith('/admin/nodes') ? 'bg-indigo-50 text-indigo-700' : 'text-gray-600 hover:bg-gray-50'}">
          🗂️ 知识节点
        </a>
        <a href="/admin/users"
           class="block px-3 py-2 rounded-lg text-sm font-medium transition
             {currentPath.startsWith('/admin/users') ? 'bg-indigo-50 text-indigo-700' : 'text-gray-600 hover:bg-gray-50'}">
          👥 用户管理
        </a>
        <a href="/admin/items"
           class="block px-3 py-2 rounded-lg text-sm font-medium transition
             {currentPath.startsWith('/admin/items') ? 'bg-indigo-50 text-indigo-700' : 'text-gray-600 hover:bg-gray-50'}">
          🛒 商品管理
        </a>
      </div>
    </nav>

    <!-- Main content -->
    <main class="flex-1 p-6">
      {@render children()}
    </main>
  </div>
</div>
