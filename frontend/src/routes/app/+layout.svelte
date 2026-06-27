<script lang="ts">
  import { authStore } from '$lib/stores/auth.svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { browser } from '$app/environment';
  import { fly } from 'svelte/transition';
  import NavBar from '$lib/components/layout/NavBar.svelte';
  import ToastContainer from '$lib/components/common/ToastContainer.svelte';
  import { soundManager } from '$lib/audio/sound-manager';

  let { children } = $props();

  function handleInteraction() {
    soundManager.init();
  }

  const publicRoutes = ['/app/spirit/choose'];

  $effect(() => {
    if (browser && !authStore.isAuthenticated) {
      goto('/login');
    }
  });

  $effect(() => {
    if (browser && authStore.isAuthenticated && !authStore.hasSpirit) {
      const path = $page.url.pathname;
      if (!publicRoutes.includes(path)) {
        goto('/app/spirit/choose');
      }
    }
  });
</script>

{#if authStore.isAuthenticated}
  <div role="presentation" class="min-h-screen bg-gray-50" onclick={handleInteraction}>
    <NavBar />
    <main class="max-w-6xl mx-auto px-4 py-6">
      {#key $page.url.pathname}
        <div transition:fly={{ y: 20, duration: 300, opacity: 0 }}>
          {@render children()}
        </div>
      {/key}
    </main>
  </div>
{/if}

<ToastContainer />
