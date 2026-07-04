<script lang="ts">
  import { authStore } from '$lib/stores/auth.svelte';
  import { spiritStore } from '$lib/stores/spirit.svelte';
  import { soundManager } from '$lib/audio/sound-manager';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import { goto } from '$app/navigation';

  let soundOn = $state(soundManager.enabled);
  let mobileOpen = $state(false);

  function handleLogout() {
    authStore.logout();
    goto('/');
  }

  function toggleSound() {
    soundOn = soundManager.toggle();
  }

  const navLinks = [
    { href: '/app', label: '仪表盘', icon: '🏠' },
    { href: '/app/study', label: '学习', icon: '📚' },
    { href: '/app/spirit', label: '精灵', icon: '🐱' },
    { href: '/app/achievements', label: '成就', icon: '🏆' },
    { href: '/app/social', label: '社交', icon: '👥' },
    { href: '/app/shop', label: '商店', icon: '🛒' },
    { href: '/app/daily', label: '每日', icon: '📅' },
    { href: '/app/story', label: '剧情', icon: '📖' },
    { href: '/app/pet-room', label: '小屋', icon: '🏡' },
  ];
</script>

<nav class="bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-500 shadow-lg">
  <div class="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
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

    <!-- Center: Desktop nav links -->
    <div class="hidden md:flex items-center gap-0.5">
      {#each navLinks as link}
        <a href={link.href}
           class="px-1.5 py-1 text-xs text-white/80 hover:text-white hover:bg-white/10 rounded-md transition-all"
           title={link.label}>
          <span class="lg:hidden">{link.icon}</span>
          <span class="hidden lg:inline">{link.icon} {link.label}</span>
        </a>
      {/each}
    </div>

    <!-- Right: HUD + controls -->
    <div class="flex items-center gap-1.5 flex-shrink-0">
      {#if authStore.user}
        <!-- Energy bar -->
        <div class="hidden sm:flex items-center gap-1 bg-white/15 rounded-lg px-2 py-1">
          <span class="text-yellow-300 text-xs">⚡</span>
          <span class="text-white text-xs font-bold">{authStore.user.currentEnergy}</span>
        </div>

        <!-- Streak -->
        {#if authStore.user.consecutiveStudyDays != null && authStore.user.consecutiveStudyDays > 0}
          <span class="hidden sm:flex items-center gap-0.5 text-orange-200 text-xs bg-white/15 rounded-lg px-1.5 py-1">
            🔥{authStore.user.consecutiveStudyDays}
          </span>
        {/if}

        <!-- Sound toggle -->
        <button onclick={toggleSound}
                class="text-white/70 hover:text-white p-1 rounded-lg hover:bg-white/10 transition flex-shrink-0"
                title={soundOn ? '关闭音效' : '开启音效'}>
          {soundOn ? '🔊' : '🔇'}
        </button>

        <!-- Nickname -->
        <span class="hidden lg:inline text-white/80 text-xs flex-shrink-0">{authStore.user.nickname}</span>

        <!-- Logout -->
        <button onclick={handleLogout}
                class="text-white/60 hover:text-white text-xs px-1.5 py-1 rounded hover:bg-white/10 transition flex-shrink-0">
          退出
        </button>

        <!-- Mobile hamburger -->
        <button onclick={() => mobileOpen = !mobileOpen}
                class="md:hidden text-white p-1 rounded hover:bg-white/10 transition flex-shrink-0">
          <span class="text-xl">{mobileOpen ? '✕' : '☰'}</span>
        </button>
      {/if}
    </div>
  </div>

  <!-- Mobile nav drawer -->
  {#if mobileOpen}
    <div class="md:hidden bg-indigo-700/95 backdrop-blur-sm border-t border-white/10">
      <div class="max-w-6xl mx-auto px-4 py-3 grid grid-cols-4 gap-2">
        {#each navLinks as link}
          <a href={link.href} onclick={() => mobileOpen = false}
             class="flex flex-col items-center gap-1 py-2 px-1 rounded-lg text-white/70 hover:text-white hover:bg-white/10 transition">
            <span class="text-lg">{link.icon}</span>
            <span class="text-[11px]">{link.label}</span>
          </a>
        {/each}
      </div>
    </div>
  {/if}
</nav>
