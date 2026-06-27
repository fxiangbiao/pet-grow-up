<script lang="ts">
  let { children } = $props();
</script>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-100 via-purple-50 to-pink-100">
  <div class="w-full max-w-md mx-4">
    {@render children()}
  </div>
</div>
