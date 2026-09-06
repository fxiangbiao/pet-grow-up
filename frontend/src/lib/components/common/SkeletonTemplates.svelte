<script lang="ts">
  import Skeleton from './Skeleton.svelte';
</script>

<!-- Dashboard Skeleton -->
{#if name === 'dashboard'}
  <div class="space-y-6 animate-slide-up">
    <!-- Hero card skeleton -->
    <div class="bg-gradient-to-br from-indigo-100 via-purple-100 to-pink-100 rounded-2xl shadow-lg p-6">
      <div class="flex items-start justify-between">
        <div class="flex-1 space-y-3">
          <Skeleton type="text" width="200px" lines={1} height="1.5rem" />
          <Skeleton type="text" width="160px" lines={1} />
          <div class="flex gap-3 mt-4">
            <Skeleton type="card" width="120px" height="60px" />
            <Skeleton type="card" width="120px" height="60px" />
            <Skeleton type="card" width="120px" height="60px" />
          </div>
        </div>
        <Skeleton type="circle" width="80px" />
      </div>
    </div>
    <!-- Nav cards skeleton -->
    <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-8 gap-4">
      {#each Array(8) as _}
        <div class="bg-white rounded-2xl shadow-sm p-6 space-y-3">
          <Skeleton type="card" width="48px" height="48px" rounded="rounded-xl" />
          <Skeleton type="text" width="80%" lines={1} />
          <Skeleton type="text" width="60%" lines={1} />
        </div>
      {/each}
    </div>
  </div>

<!-- Spirit List Skeleton -->
{:else if name === 'spirits'}
  <div class="animate-slide-up">
    <Skeleton type="text" width="150px" lines={1} height="1.75rem" className="mb-6" />
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {#each Array(3) as _}
        <div class="bg-white rounded-2xl shadow-sm p-5 border border-gray-100 space-y-3">
          <div class="flex items-center justify-between">
            <Skeleton type="circle" width="56px" />
            <Skeleton type="card" width="50px" height="24px" rounded="rounded-full" />
          </div>
          <Skeleton type="text" width="60%" lines={1} />
          <Skeleton type="text" width="40%" lines={1} />
          <div class="space-y-2 mt-3">
            <Skeleton type="text" width="100%" lines={1} />
            <Skeleton type="text" width="100%" lines={1} />
          </div>
        </div>
      {/each}
    </div>
  </div>

<!-- Study Map Skeleton -->
{:else if name === 'study'}
  <div class="animate-slide-up">
    <Skeleton type="text" width="200px" lines={1} height="1.75rem" className="mb-2" />
    <Skeleton type="text" width="280px" lines={1} className="mb-8" />
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      {#each Array(3) as _}
        <div class="rounded-2xl overflow-hidden shadow-sm">
          <Skeleton type="card" width="100%" height="160px" rounded="rounded-none" />
          <div class="bg-white p-4">
            <Skeleton type="text" width="100%" lines={1} />
          </div>
        </div>
      {/each}
    </div>
  </div>

<!-- Achievement List Skeleton -->
{:else if name === 'achievements'}
  <div class="space-y-6 animate-slide-up">
    <div class="bg-white rounded-2xl shadow-sm p-6 space-y-4">
      <div class="flex items-center justify-between">
        <div>
          <Skeleton type="text" width="180px" lines={1} height="1.5rem" />
          <Skeleton type="text" width="240px" lines={1} className="mt-1" />
        </div>
        <Skeleton type="text" width="60px" lines={1} height="2rem" />
      </div>
      <Skeleton type="card" width="100%" height="8px" rounded="rounded-full" />
    </div>
    <div class="flex gap-2">
      {#each Array(5) as _}
        <Skeleton type="card" width="80px" height="36px" rounded="rounded-xl" />
      {/each}
    </div>
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      {#each Array(6) as _}
        <div class="bg-white rounded-2xl shadow-sm p-5 space-y-3">
          <div class="flex items-center gap-3">
            <Skeleton type="circle" width="40px" />
            <div class="flex-1 space-y-2">
              <Skeleton type="text" width="80%" lines={1} />
              <Skeleton type="text" width="60%" lines={1} />
            </div>
          </div>
          <Skeleton type="card" width="100%" height="8px" rounded="rounded-full" />
        </div>
      {/each}
    </div>
  </div>

<!-- Shop Skeleton -->
{:else if name === 'shop'}
  <div class="space-y-6 animate-slide-up">
    <div class="bg-white rounded-2xl shadow-sm p-6 space-y-3">
      <Skeleton type="text" width="120px" lines={1} height="1.5rem" />
      <Skeleton type="text" width="240px" lines={1} />
    </div>
    <div class="flex gap-2">
      {#each Array(3) as _}
        <Skeleton type="card" width="100px" height="40px" rounded="rounded-xl" />
      {/each}
    </div>
    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
      {#each Array(8) as _}
        <div class="bg-white rounded-2xl shadow-sm p-4 space-y-3">
          <Skeleton type="card" width="100%" height="100px" rounded="rounded-xl" />
          <Skeleton type="text" width="80%" lines={1} />
          <Skeleton type="text" width="50%" lines={1} />
          <Skeleton type="card" width="100%" height="36px" rounded="rounded-xl" />
        </div>
      {/each}
    </div>
  </div>

<!-- Daily Challenge Skeleton -->
{:else if name === 'daily'}
  <div class="max-w-xl mx-auto space-y-6 animate-slide-up">
    <div class="bg-white rounded-2xl shadow-sm p-6 space-y-3">
      <Skeleton type="text" width="150px" lines={1} height="1.5rem" />
      <Skeleton type="text" width="200px" lines={1} />
      <Skeleton type="text" width="220px" lines={1} />
    </div>
    <div class="space-y-3">
      {#each Array(4) as _}
        <div class="bg-white rounded-2xl shadow-sm p-5 space-y-3">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <Skeleton type="circle" width="40px" />
              <div class="space-y-2">
                <Skeleton type="text" width="180px" lines={1} />
                <Skeleton type="text" width="100px" lines={1} />
              </div>
            </div>
            <Skeleton type="card" width="60px" height="28px" rounded="rounded-full" />
          </div>
          <Skeleton type="card" width="100%" height="8px" rounded="rounded-full" />
        </div>
      {/each}
    </div>
  </div>

{:else}
  <div class="flex items-center justify-center py-12">
    <Skeleton type="text" width="100px" lines={1} />
  </div>
{/if}