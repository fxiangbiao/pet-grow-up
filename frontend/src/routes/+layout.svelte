<script lang="ts">
  import { authStore } from '$lib/stores/auth.svelte';
  import '../app.css';
  import ToastContainer from '$lib/components/common/ToastContainer.svelte';

  let { children } = $props();

  $effect(() => {
    authStore.init();
  });
</script>

<ToastContainer />
{@render children()}
