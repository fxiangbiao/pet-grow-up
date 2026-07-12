<script lang="ts">
  import { authStore } from '$lib/stores/auth.svelte';
  import { onMount } from 'svelte';

  let visible = $state({ hero: false, features: false, subjects: false, cta: false });

  onMount(() => {
    setTimeout(() => (visible.hero = true), 100);

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const section = entry.target.getAttribute('data-section');
            if (section && section in visible) {
              visible[section as keyof typeof visible] = true;
            }
          }
        });
      },
      { threshold: 0.15 }
    );

    document.querySelectorAll('[data-section]').forEach((el) => observer.observe(el));
    return () => observer.disconnect();
  });

  const features = [
    { icon: '🐱', title: '精灵养成', desc: '选择你的专属学习精灵，喂食、装扮、进化，陪伴你成长' },
    { icon: '🗺️', title: '知识冒险', desc: '踏上冒险地图，击败暗水晶，用知识解锁新区域' },
    { icon: '🏆', title: '成就收集', desc: '解锁丰富成就徽章，记录每一个学习里程碑' },
    { icon: '📅', title: '每日挑战', desc: '完成每日任务赢取能量，保持连续学习好习惯' }
  ];

  const subjects = [
    { icon: '📜', name: '诗词大陆', desc: '在古典诗词中漫游，感受汉字之美', color: 'from-amber-400 to-orange-500' },
    { icon: '🔢', name: '智慧王国', desc: '数字与逻辑的王国，锻炼数学思维', color: 'from-blue-400 to-cyan-500' },
    { icon: '🔤', name: '魔法学院', desc: '英语单词的魔法世界，轻松掌握词汇', color: 'from-purple-400 to-pink-500' }
  ];
</script>

<svelte:head>
  <title>Pet Grow Up - 让学习成为一场奇幻冒险</title>
</svelte:head>

<!-- Floating background particles -->
<div class="landing-particles">
  {#each Array(12) as _, i}
    <span style="left: {(i * 8 + 3) % 95}%; animation-delay: {i * 1.2}s; animation-duration: {10 + (i % 4) * 2}s;">
      {['✨', '⭐', '🌟', '💫'][i % 4]}
    </span>
  {/each}
</div>

<div class="min-h-screen bg-gradient-to-b from-indigo-50 via-purple-50 to-pink-50">

  <!-- Hero Section -->
  <section class="relative overflow-hidden pt-16 pb-20 px-4">
    <div class="flex justify-center mb-8">
      <div class="relative">
        <div class="absolute inset-0 rounded-full bg-gradient-to-r from-indigo-400 via-purple-400 to-pink-400 blur-xl opacity-40 animate-breathe"
             style="width: 180px; height: 180px; top: -10px; left: -10px;"></div>
        <div class="relative w-40 h-40 rounded-full bg-gradient-to-br from-indigo-300 via-purple-300 to-pink-300 flex items-center justify-center animate-float shadow-2xl">
          <div class="text-7xl select-none" style="filter: drop-shadow(0 2px 4px rgba(0,0,0,0.15));">🐾</div>
          <div class="absolute -top-2 -right-1 text-2xl animate-sparkle" style="animation-delay: 0s; animation-iteration-count: infinite; animation-duration: 2s;">✨</div>
          <div class="absolute -bottom-1 -left-2 text-xl animate-sparkle" style="animation-delay: 0.8s; animation-iteration-count: infinite; animation-duration: 2.5s;">⭐</div>
          <div class="absolute top-2 -left-4 text-lg animate-sparkle" style="animation-delay: 1.5s; animation-iteration-count: infinite; animation-duration: 3s;">💫</div>
        </div>
      </div>
    </div>

    <div class="text-center max-w-2xl mx-auto transition-all duration-700 {visible.hero ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'}">
      <h1 class="text-5xl md:text-6xl font-bold bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-500 bg-clip-text text-transparent mb-4">
        Pet Grow Up
      </h1>
      <p class="text-xl md:text-2xl text-gray-600 mb-3">
        让学习成为一场奇幻冒险
      </p>
      <p class="text-gray-500 mb-8 max-w-md mx-auto">
        与精灵伙伴一起，在游戏化冒险中掌握语文、数学和英语知识
      </p>

      <div class="flex flex-col sm:flex-row gap-4 justify-center">
        {#if authStore.isAuthenticated}
          <a href="/app"
             class="px-10 py-4 bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 text-white rounded-2xl text-lg font-semibold shadow-lg hover:shadow-xl hover:scale-105 transition-all duration-300 animate-pulse-glow">
            进入世界 &rarr;
          </a>
        {:else}
          <a href="/login"
             class="px-10 py-4 bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 text-white rounded-2xl text-lg font-semibold shadow-lg hover:shadow-xl hover:scale-105 transition-all duration-300 animate-pulse-glow">
            立即开始 &rarr;
          </a>
          <a href="/register"
             class="px-10 py-4 bg-white text-purple-600 rounded-2xl text-lg font-semibold shadow-md hover:shadow-lg hover:scale-105 border border-purple-100 transition-all duration-300">
            免费注册
          </a>
        {/if}
      </div>
    </div>
  </section>

  <!-- Features Section -->
  <section data-section="features"
           class="py-16 px-4 max-w-5xl mx-auto transition-all duration-700 {visible.features ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-12'}">
    <h2 class="text-3xl font-bold text-center text-gray-800 mb-3">核心玩法</h2>
    <p class="text-gray-500 text-center mb-12 max-w-lg mx-auto">不只是学习，更是一场充满乐趣的冒险旅程</p>

    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
      {#each features as feature, i}
        <div class="bg-white/80 backdrop-blur-sm rounded-2xl p-6 shadow-sm hover:shadow-lg hover:-translate-y-1 transition-all duration-300 border border-white/60"
             style="transition-delay: {i * 80}ms">
          <div class="text-4xl mb-4">{feature.icon}</div>
          <h3 class="text-lg font-semibold text-gray-800 mb-2">{feature.title}</h3>
          <p class="text-sm text-gray-500 leading-relaxed">{feature.desc}</p>
        </div>
      {/each}
    </div>
  </section>

  <!-- Subjects Section -->
  <section data-section="subjects"
           class="py-16 px-4 max-w-4xl mx-auto transition-all duration-700 {visible.subjects ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-12'}">
    <h2 class="text-3xl font-bold text-center text-gray-800 mb-3">三大冒险大陆</h2>
    <p class="text-gray-500 text-center mb-12 max-w-lg mx-auto">每个学科都有独特的冒险主题和游戏化关卡</p>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      {#each subjects as subject, i}
        <div class="group relative overflow-hidden rounded-2xl shadow-sm hover:shadow-xl transition-all duration-300 hover:-translate-y-1"
             style="transition-delay: {i * 100}ms">
          <div class="h-32 bg-gradient-to-br {subject.color} flex items-center justify-center">
            <span class="text-5xl group-hover:scale-110 transition-transform duration-300">{subject.icon}</span>
          </div>
          <div class="bg-white p-5">
            <h3 class="text-lg font-semibold text-gray-800 mb-1">{subject.name}</h3>
            <p class="text-sm text-gray-500">{subject.desc}</p>
          </div>
        </div>
      {/each}
    </div>
  </section>

  <!-- Bottom CTA Section -->
  <section data-section="cta"
           class="py-20 px-4 transition-all duration-700 {visible.cta ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-12'}">
    <div class="max-w-2xl mx-auto text-center bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 rounded-3xl p-10 shadow-xl">
      <h2 class="text-3xl font-bold text-white mb-3">准备好开始冒险了吗？</h2>
      <p class="text-white/80 mb-8">选择你的精灵伙伴，踏上知识冒险之旅</p>
      {#if authStore.isAuthenticated}
        <a href="/app"
           class="inline-block px-10 py-4 bg-white text-purple-600 rounded-2xl text-lg font-semibold shadow-lg hover:shadow-xl hover:scale-105 transition-all duration-300">
          进入世界 &rarr;
        </a>
      {:else}
        <a href="/register"
           class="inline-block px-10 py-4 bg-white text-purple-600 rounded-2xl text-lg font-semibold shadow-lg hover:shadow-xl hover:scale-105 transition-all duration-300">
          免费开始冒险 &rarr;
        </a>
      {/if}
    </div>
  </section>

  <!-- Footer -->
  <footer class="py-8 px-4 border-t border-gray-200/50">
    <div class="max-w-5xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4 text-sm text-gray-400">
      <div class="flex items-center gap-2">
        <span class="text-lg">🐾</span>
        <span>Pet Grow Up &copy; 2026</span>
      </div>
      <div class="flex gap-6">
        <span>让学习成为一场奇幻冒险</span>
      </div>
    </div>
  </footer>
</div>

<style>
  .landing-particles {
    position: fixed;
    inset: 0;
    pointer-events: none;
    overflow: hidden;
    z-index: 0;
  }
  .landing-particles span {
    position: absolute;
    font-size: 1.2rem;
    opacity: 0.15;
    animation: float-up-landing 14s linear infinite;
  }
  @keyframes float-up-landing {
    0% { transform: translateY(105vh) rotate(0deg); opacity: 0; }
    10% { opacity: 0.15; }
    90% { opacity: 0.15; }
    100% { transform: translateY(-8vh) rotate(20deg); opacity: 0; }
  }
</style>