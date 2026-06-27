<script lang="ts">
  import { authStore } from '$lib/stores/auth.svelte';
  import { register } from '$lib/api/auth';
  import { goto } from '$app/navigation';

  let username = $state('');
  let email = $state('');
  let password = $state('');
  let confirmPassword = $state('');
  let error = $state('');
  let fieldErrors = $state<Record<string, string>>({});
  let loading = $state(false);

  function validate(): boolean {
    const errors: Record<string, string> = {};
    if (!username.trim()) errors.username = '请输入用户名';
    else if (username.trim().length < 3) errors.username = '用户名至少3个字符';
    if (!email.trim()) errors.email = '请输入邮箱';
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) errors.email = '邮箱格式不正确';
    if (!password) errors.password = '请输入密码';
    else if (password.length < 6) errors.password = '密码至少6个字符';
    if (!confirmPassword) errors.confirmPassword = '请确认密码';
    else if (password !== confirmPassword) errors.confirmPassword = '两次密码输入不一致';
    fieldErrors = errors;
    return Object.keys(errors).length === 0;
  }

  async function handleSubmit(e: Event) {
    e.preventDefault();
    error = '';
    if (!validate()) return;
    loading = true;

    try {
      const result = await register({ username, email, password });
      authStore.login(result.user, result.accessToken);
      goto('/app');
    } catch (err: any) {
      error = err.message || '注册失败，请重试';
    } finally {
      loading = false;
    }
  }
</script>

<svelte:head>
  <title>注册 - Pet Grow Up</title>
</svelte:head>

<div class="bg-white rounded-2xl shadow-xl p-8 animate-slide-up">
  <h1 class="text-3xl font-bold text-center text-gray-800 mb-2">创建账号</h1>
  <p class="text-center text-gray-500 mb-8">开始你的学习冒险之旅</p>

  {#if error}
    <div class="bg-red-50 text-red-600 px-4 py-3 rounded-lg mb-4 text-sm">
      {error}
    </div>
  {/if}

  <form onsubmit={handleSubmit} class="space-y-4">
    <div>
      <label for="username" class="block text-sm font-medium text-gray-700 mb-1">用户名</label>
      <input
        id="username"
        type="text"
        bind:value={username}
        required
        class={['w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none transition',
          fieldErrors.username ? 'border-red-300 focus:border-red-500' : 'border-gray-300 focus:border-green-500'
        ].join(' ')}
        placeholder="3-50个字符"
      />
      {#if fieldErrors.username}
        <p class="text-red-500 text-xs mt-1">{fieldErrors.username}</p>
      {/if}
    </div>

    <div>
      <label for="email" class="block text-sm font-medium text-gray-700 mb-1">邮箱</label>
      <input
        id="email"
        type="email"
        bind:value={email}
        required
        class={['w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none transition',
          fieldErrors.email ? 'border-red-300 focus:border-red-500' : 'border-gray-300 focus:border-green-500'
        ].join(' ')}
        placeholder="your@email.com"
      />
      {#if fieldErrors.email}
        <p class="text-red-500 text-xs mt-1">{fieldErrors.email}</p>
      {/if}
    </div>

    <div>
      <label for="password" class="block text-sm font-medium text-gray-700 mb-1">密码</label>
      <input
        id="password"
        type="password"
        bind:value={password}
        required
        class={['w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none transition',
          fieldErrors.password ? 'border-red-300 focus:border-red-500' : 'border-gray-300 focus:border-green-500'
        ].join(' ')}
        placeholder="至少6个字符"
      />
      {#if fieldErrors.password}
        <p class="text-red-500 text-xs mt-1">{fieldErrors.password}</p>
      {/if}
    </div>

    <div>
      <label for="confirm-password" class="block text-sm font-medium text-gray-700 mb-1">确认密码</label>
      <input
        id="confirm-password"
        type="password"
        bind:value={confirmPassword}
        required
        class={['w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none transition',
          fieldErrors.confirmPassword ? 'border-red-300 focus:border-red-500' : 'border-gray-300 focus:border-green-500'
        ].join(' ')}
        placeholder="再次输入密码"
      />
      {#if fieldErrors.confirmPassword}
        <p class="text-red-500 text-xs mt-1">{fieldErrors.confirmPassword}</p>
      {/if}
    </div>

    <button
      type="submit"
      disabled={loading}
      class="w-full py-3 bg-green-500 text-white rounded-lg font-semibold hover:bg-green-600 disabled:opacity-50 disabled:cursor-not-allowed transition"
    >
      {loading ? '注册中...' : '注册'}
    </button>
  </form>

  <p class="text-center text-sm text-gray-500 mt-6">
    已有账号？
    <a href="/login" class="text-green-500 hover:text-green-600">立即登录</a>
  </p>
</div>
