<script lang="ts">
  import { authStore } from '$lib/stores/auth.svelte';
</script>

<svelte:head>
  <title>Pet Grow Up - 宠物养成学习系统</title>
</svelte:head>

<div class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-b from-blue-50 to-purple-50">
  <div class="text-center animate-slide-up">
    <h1 class="text-5xl font-bold text-gray-800 mb-4">
      🐾 Pet Grow Up
    </h1>
    <p class="text-xl text-gray-600 mb-8">
      让学习成为一场奇幻冒险
    </p>

    {#if authStore.isAuthenticated}
      <a href="/app"
         class="inline-block px-8 py-3 bg-blue-500 text-white rounded-lg text-lg font-semibold hover:bg-blue-600 transition">
        进入世界
      </a>
    {:else}
      <div class="space-x-4">
        <a href="/login"
           class="inline-block px-8 py-3 bg-blue-500 text-white rounded-lg text-lg font-semibold hover:bg-blue-600 transition">
          登录
        </a>
        <a href="/register"
           class="inline-block px-8 py-3 bg-green-500 text-white rounded-lg text-lg font-semibold hover:bg-green-600 transition">
          注册
        </a>
      </div>
    {/if}
  </div>
</div>
