<script lang="ts">
  import { authStore } from '$lib/stores/auth.svelte';
  import { spiritStore } from '$lib/stores/spirit.svelte';
  import { soundManager } from '$lib/audio/sound-manager';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';

  let soundOn = $state(soundManager.enabled);
  let mobileOpen = $state(false);
  let moreOpen = $state(false);

  let currentPath = $derived($page.url.pathname);

  function handleLogout() {
    authStore.logout();
    goto('/');
  }

  function toggleSound() {
    soundOn = soundManager.toggle();
  }

  // Primary nav - always visible on desktop
  const primaryLinks = [
    { href: '/app', label: '仪表盘', icon: '🏠' },
    { href: '/app/study', label: '学习', icon: '📚' },
    { href: '/app/spirit', label: '精灵', icon: '🐱' },
    { href: '/app/achievements', label: '成就', icon: '🏆' },
  ];

  // Secondary nav - in "more" dropdown
  const secondaryLinks = [
    { href: '/app/social', label: '社交', icon: '👥' },
    { href: '/app/shop', label: '商店', icon: '🛒' },
    { href: '/app/daily', label: '每日', icon: '📅' },
    { href: '/app/pet-room', label: '小屋', icon: '🏡' },
  ];

  // Mobile bottom tab bar items
  const tabLinks = [
    { href: '/app', label: '首页', icon: '🏠' },
    { href: '/app/study', label: '学习', icon: '📚' },
    { href: '/app/spirit', label: '精灵', icon: '🐱' },
    { href: '/app/social', label: '更多', icon: '👥' },
  ];

  let allNavLinks = $derived(
    authStore.isAdmin
      ? [...primaryLinks, ...secondaryLinks, { href: '/admin', label: '管理', icon: '⚙️' }]
      : [...primaryLinks, ...secondaryLinks]
  );

  function isActive(href: string): boolean {
    if (href === '/app') return currentPath === '/app' || currentPath === '/app/';
    return currentPath.startsWith(href);
  }
</script>

<nav aria-label="主导航" class="bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-500 shadow-lg sticky top-0 z-40">
  <div class="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
    <!-- Left: Logo + Spirit avatar -->
    <div class="flex items-center gap-2 flex-shrink-0">
      <a href="/app" class="flex items-center gap-1.5 text-white font-bold text-base">
        <span>🐾</span>
        <span class="hidden lg:inline text-sm">Pet Grow Up</span>
      </a>
      {#if spiritStore.activeSpirit}
        <a href="/app/spirit" class="hidden sm:block -ml-1">
          <SpiritAvatar
            species={spiritStore.activeSpirit.species}
            evolutionStage={spiritStore.activeSpirit.currentEvolutionStage}
            size="sm"
            mood={spiritStore.activeSpirit.happiness >= 80 ? 'excited' : spiritStore.activeSpirit.happiness >= 50 ? 'happy' : 'hurt'}
          />
        </a>
      {/if}
    </div>

    <!-- Center: Desktop primary nav -->
    <div class="hidden md:flex items-center gap-1">
      {#each primaryLinks as link}
        <a href={link.href}
           aria-label={link.label} class="relative px-3 py-2 text-sm rounded-lg transition-all
             {isActive(link.href) ? 'text-white bg-white/20' : 'text-white/70 hover:text-white hover:bg-white/10'}">
          <span class="flex items-center gap-1.5">
            <span aria-hidden="true">{link.icon}</span>
            <span class="hidden lg:inline">{link.label}</span>
          </span>
          {#if isActive(link.href)}
            <span class="absolute bottom-0 left-1/2 -translate-x-1/2 w-6 h-0.5 bg-white rounded-full"></span>
          {/if}
        </a>
      {/each}

      <!-- More dropdown -->
      <div class="relative">
        <button onclick={() => moreOpen = !moreOpen}
                aria-label="更多导航" aria-expanded={moreOpen} class="px-3 py-2 text-sm rounded-lg transition-all flex items-center gap-1
                  {secondaryLinks.some(l => isActive(l.href)) ? 'text-white bg-white/20' : 'text-white/70 hover:text-white hover:bg-white/10'}">
          <span>···</span>
          <span class="hidden lg:inline text-xs">更多</span>
        </button>
        {#if moreOpen}
          <!-- Backdrop to close -->
          <div class="fixed inset-0 z-10" onclick={() => moreOpen = false}></div>
          <!-- Dropdown -->
          <div class="absolute right-0 top-full mt-1 bg-white rounded-xl shadow-xl border border-gray-100 py-2 w-40 z-20">
            {#each secondaryLinks as link}
              <a href={link.href} onclick={() => moreOpen = false}
                 class="flex items-center gap-2.5 px-4 py-2.5 text-sm text-gray-700 hover:bg-indigo-50 hover:text-indigo-600 transition">
                <span aria-hidden="true">{link.icon}</span>
                <span>{link.label}</span>
              </a>
            {/each}
            {#if authStore.isAdmin}
              <div class="border-t border-gray-100 mt-1 pt-1">
                <a href="/admin" onclick={() => moreOpen = false}
                   class="flex items-center gap-2.5 px-4 py-2.5 text-sm text-gray-700 hover:bg-indigo-50 hover:text-indigo-600 transition">
                  <span>⚙️</span>
                  <span>管理</span>
                </a>
              </div>
            {/if}
          </div>
        {/if}
      </div>
    </div>

    <!-- Right: HUD + controls -->
    <div class="flex items-center gap-2 flex-shrink-0">
      {#if authStore.user}
        <!-- Energy bar -->
        <div class="hidden sm:flex items-center gap-1 bg-white/15 rounded-lg px-2.5 py-1.5" title="学习能量">
          <span class="text-yellow-300 text-xs">⚡</span>
          <span class="text-white text-xs font-bold">{authStore.user.currentEnergy}</span>
        </div>

        <!-- Streak -->
        {#if authStore.user.consecutiveStudyDays != null && authStore.user.consecutiveStudyDays > 0}
          <span class="hidden sm:flex items-center gap-0.5 text-orange-200 text-xs bg-white/15 rounded-lg px-2 py-1.5" title="连续学习天数">
            🔥{authStore.user.consecutiveStudyDays}
          </span>
        {/if}

        <!-- Sound toggle -->
        <button onclick={toggleSound}
                class="text-white/70 hover:text-white p-1.5 rounded-lg hover:bg-white/10 transition flex-shrink-0"
                title={soundOn ? '关闭音效' : '开启音效'} aria-label={soundOn ? '关闭音效' : '开启音效'}>
          {soundOn ? '🔊' : '🔇'}
        </button>

        <!-- Nickname -->
        <span class="hidden lg:inline text-white/80 text-xs flex-shrink-0">{authStore.user.nickname}</span>

        <!-- Logout -->
        <button onclick={handleLogout}
                aria-label="退出登录" class="text-white/60 hover:text-white text-xs px-2 py-1.5 rounded-lg hover:bg-white/10 transition flex-shrink-0">
          退出
        </button>

        <!-- Mobile hamburger (hidden - replaced by bottom tab bar) -->
      {/if}
    </div>
  </div>
</nav>

<!-- Mobile bottom tab bar -->
{#if authStore.isAuthenticated}
  <div role="navigation" aria-label="移动端导航" class="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-50 safe-bottom">
    <div class="grid grid-cols-4 h-16">
      {#each tabLinks as link}
        <a href={link.href}
           class="flex flex-col items-center justify-center gap-0.5 transition-colors
             {isActive(link.href) ? 'text-indigo-600' : 'text-gray-400'}">
          <span class="text-xl leading-none">{link.icon}</span>
          <span class="text-[10px] font-medium leading-none">{link.label}</span>
          {#if isActive(link.href)}
            <span class="absolute top-0 left-1/2 -translate-x-1/2 w-8 h-0.5 bg-indigo-600 rounded-full"></span>
          {/if}
        </a>
      {/each}
    </div>
  </div>
{/if}
