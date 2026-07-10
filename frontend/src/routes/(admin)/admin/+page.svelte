<script lang="ts">
  import { browser } from '$app/environment';
  import { goto } from '$app/navigation';

  $effect(() => {
    if (browser) goto('/admin/questions');
  });
</script>
