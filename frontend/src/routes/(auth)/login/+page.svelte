<script lang="ts">
  import { authStore } from '$lib/stores/auth.svelte';
  import { login } from '$lib/api/auth';
  import { goto } from '$app/navigation';

  let username = $state('');
  let password = $state('');
  let error = $state('');
  let fieldErrors = $state<Record<string, string>>({});
  let loading = $state(false);
  let showPassword = $state(false);
  let rememberMe = $state(false);

  let expired = $state(typeof window !== 'undefined' && window.location.search.includes('expired=1'));

  function validate(): boolean {
    const errors: Record<string, string> = {};
    if (!username.trim()) errors.username = '请输入用户名';
    else if (username.trim().length < 3) errors.username = '用户名至少3个字符';
    if (!password) errors.password = '请输入密码';
    else if (password.length < 6) errors.password = '密码至少6个字符';
    fieldErrors = errors;
    return Object.keys(errors).length === 0;
  }

  async function handleSubmit(e: Event) {
    e.preventDefault();
    error = '';
    if (!validate()) return;
    loading = true;

    try {
      const result = await login({ username, password });
      authStore.login(result.user, result.accessToken);
      goto('/app');
    } catch (err: any) {
      error = err.message || '登录失败，请重试';
    } finally {
      loading = false;
    }
  }
</script>

<svelte:head>
  <title>登录 - Pet Grow Up</title>
</svelte:head>

<div class="bg-white rounded-2xl shadow-xl p-8 animate-slide-up">
  <h1 class="text-3xl font-bold text-center text-gray-800 mb-2">欢迎回来</h1>
  <p class="text-center text-gray-500 mb-8">登录继续你的冒险旅程</p>

  {#if expired}
    <div class="bg-amber-50 text-amber-700 px-4 py-3 rounded-lg mb-4 text-sm flex items-center gap-2">
      <span>⏰</span>
      <span>登录已过期，请重新登录</span>
    </div>
  {/if}

  {#if error}
    <div class="bg-red-50 text-red-600 px-4 py-3 rounded-lg mb-4 text-sm flex items-center gap-2">
      <span>❗</span>
      <span>{error}</span>
    </div>
  {/if}

  <form onsubmit={handleSubmit} class="space-y-5">
    <div>
      <label for="username" class="block text-sm font-medium text-gray-700 mb-1">用户名</label>
      <div class="relative">
        <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-lg">👤</span>
        <input
          id="username"
          type="text"
          bind:value={username}
          required
          autofocus
          class={['w-full pl-10 pr-4 py-2.5 border rounded-xl focus:ring-2 focus:ring-blue-500 outline-none transition',
            fieldErrors.username ? 'border-red-300 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'
          ].join(' ')}
          placeholder="请输入用户名"
        />
      </div>
      {#if fieldErrors.username}
        <p class="text-red-500 text-xs mt-1 flex items-center gap-1"><span>❗</span>{fieldErrors.username}</p>
      {/if}
    </div>

    <div>
      <label for="password" class="block text-sm font-medium text-gray-700 mb-1">密码</label>
      <div class="relative">
        <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-lg">🔒</span>
        <input
          id="password"
          type={showPassword ? 'text' : 'password'}
          bind:value={password}
          required
          class={['w-full pl-10 pr-12 py-2.5 border rounded-xl focus:ring-2 focus:ring-blue-500 outline-none transition',
            fieldErrors.password ? 'border-red-300 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'
          ].join(' ')}
          placeholder="请输入密码"
        />
        <button
          type="button"
          onclick={() => showPassword = !showPassword}
          class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition text-lg"
          tabindex="-1"
        >
          {showPassword ? '🙈' : '👁️'}
        </button>
      </div>
      {#if fieldErrors.password}
        <p class="text-red-500 text-xs mt-1 flex items-center gap-1"><span>❗</span>{fieldErrors.password}</p>
      {/if}
    </div>

    <!-- Remember me -->
    <div class="flex items-center justify-between">
      <label class="flex items-center gap-2 cursor-pointer select-none">
        <input type="checkbox" bind:checked={rememberMe}
               class="w-4 h-4 text-blue-500 border-gray-300 rounded focus:ring-blue-500" />
        <span class="text-sm text-gray-600">记住我</span>
      </label>
    </div>

    <button
      type="submit"
      disabled={loading}
      class="w-full py-3 bg-gradient-to-r from-blue-500 to-indigo-500 text-white rounded-xl font-semibold hover:from-blue-600 hover:to-indigo-600 disabled:opacity-50 disabled:cursor-not-allowed transition shadow-sm"
    >
      {loading ? '登录中...' : '登录'}
    </button>
  </form>

  <p class="text-center text-sm text-gray-500 mt-6">
    还没有账号？
    <a href="/register" class="text-blue-500 hover:text-blue-600 font-medium">立即注册</a>
  </p>
</div>