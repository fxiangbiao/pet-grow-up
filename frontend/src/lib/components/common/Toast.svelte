<script lang="ts">
  let { children } = $props();
</script>

<div
  class="fixed top-4 right-4 z-50 pointer-events-none"
  id="toast-slot"
>
  {@render children()}
</div>
