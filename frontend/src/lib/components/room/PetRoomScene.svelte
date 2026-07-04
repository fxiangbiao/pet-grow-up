<script lang="ts">
  import type { PetRoomData, PlacedItem } from '$lib/api/pet-room';
  import SpiritAvatar from '$lib/components/spirit/SpiritAvatar.svelte';
  import { getTheme } from '$lib/room/themes/registry';
  import type { RoomTheme } from '$lib/room/themes/types';
  import { getFurnitureRenderer } from '$lib/room/furniture/registry';
  import type { FurnitureContext } from '$lib/room/furniture/types';

  let {
    room,
    editing = false,
    selectedItemId = null as number | null,
    accessories = [] as { slot: string; iconUrl: string; name: string }[],
    onfurnitureclick,
  }: {
    room: PetRoomData;
    editing?: boolean;
    selectedItemId?: number | null;
    accessories?: { slot: string; iconUrl: string; name: string }[];
    onfurnitureclick?: (item: PlacedItem) => void;
  } = $props();

  let theme = $derived(getTheme(room.roomStyle));
  let furniture = $derived(room.furniture || []);

  // Split furniture: back (wall-mounted, y < floorY) vs front (floor, y >= floorY)
  let floorY = 195;
  let backFurniture = $derived(furniture.filter(f => (f.y ?? 220) < floorY));
  let frontFurniture = $derived(furniture.filter(f => (f.y ?? 220) >= floorY));
  let sortedFront = $derived([...frontFurniture].sort((a, b) => (a.y ?? 220) - (b.y ?? 220)));

  let spiritMood = $derived.by((): 'idle' | 'happy' | 'excited' | 'hurt' => {
    if (!room.activeSpirit) return 'idle';
    const s = room.activeSpirit;
    if (s.happiness >= 80) return 'excited';
    if (s.happiness >= 50) return 'happy';
    return 'idle';
  });

  function renderFurniture(item: PlacedItem): string {
    const renderer = getFurnitureRenderer(item.itemKey);
    if (!renderer) {
      const x = item.x ?? 200;
      const y = item.y ?? 220;
      return `<text x="${x}" y="${y}" font-size="24" text-anchor="middle" dominant-baseline="central">${item.iconUrl || '📦'}</text>`;
    }
    const ctx: FurnitureContext = {
      x: item.x ?? 200,
      y: item.y ?? 220,
      scale: 1.0,
      floorY: 200,
    };
    return renderer(ctx);
  }

  function renderParticles(t: RoomTheme): string {
    switch (t.ambientParticles) {
      case 'stars': {
        let s = '';
        for (let i = 0; i < 12; i++) {
          const px = 20 + ((i * 137 + 53) % 360);
          const py = 10 + ((i * 89 + 31) % 100);
          const r = 0.5 + (i % 3) * 0.5;
          const delay = ((i * 7) / 10) % 3;
          s += `<circle cx="${px}" cy="${py}" r="${r}" fill="#fbbf24" opacity="0.6">
            <animate attributeName="opacity" values="0.2;0.8;0.2" dur="${2 + (i % 3)}s" begin="${delay}s" repeatCount="indefinite"/>
          </circle>`;
        }
        return s;
      }
      case 'fireflies': {
        let s = '';
        for (let i = 0; i < 6; i++) {
          const px = 60 + i * 50;
          const py = 40 + (i % 3) * 50;
          const delay = i * 0.8;
          s += `<circle cx="${px}" cy="${py}" r="2" fill="#fbbf24" opacity="0.7">
            <animate attributeName="cx" values="${px - 12};${px + 12};${px - 12}" dur="${3 + i}s" begin="${delay}s" repeatCount="indefinite"/>
            <animate attributeName="opacity" values="0.2;0.8;0.2" dur="${2 + i * 0.3}s" begin="${delay}s" repeatCount="indefinite"/>
          </circle>`;
        }
        return s;
      }
      case 'petals': {
        let s = '';
        for (let i = 0; i < 8; i++) {
          const px = 30 + i * 45;
          const py = 20 + (i % 3) * 25;
          const delay = i * 0.7;
          s += `<text x="${px}" y="${py}" font-size="6" fill="#f472b6" opacity="0.5">
            🌸
            <animate attributeName="y" values="${py};${py + 200}" dur="${5 + i}s" begin="${delay}s" repeatCount="indefinite"/>
            <animate attributeName="opacity" values="0.5;0.2;0" dur="${5 + i}s" begin="${delay}s" repeatCount="indefinite"/>
          </text>`;
        }
        return s;
      }
      case 'sparkles': {
        let s = '';
        for (let i = 0; i < 10; i++) {
          const px = 30 + i * 36;
          const py = 15 + (i % 4) * 20;
          const delay = i * 0.3;
          s += `<polygon points="${px},${py - 3} ${px + 2},${py} ${px},${py + 3} ${px - 2},${py}"
            fill="#a78bfa" opacity="0.6">
            <animate attributeName="opacity" values="0;0.8;0" dur="${1.5 + (i % 3) * 0.5}s" begin="${delay}s" repeatCount="indefinite"/>
          </polygon>`;
        }
        return s;
      }
      case 'bubbles': {
        let s = '';
        for (let i = 0; i < 5; i++) {
          const px = 60 + i * 65;
          const py = 120 + i * 20;
          const r = 3 + i;
          const delay = i * 1.2;
          s += `<circle cx="${px}" cy="${py}" r="${r}" fill="none" stroke="#7dd3fc" stroke-width="0.8" opacity="0.4">
            <animate attributeName="cy" values="${py};${py - 160}" dur="${5 + i}s" begin="${delay}s" repeatCount="indefinite"/>
            <animate attributeName="opacity" values="0.4;0.1;0" dur="${5 + i}s" begin="${delay}s" repeatCount="indefinite"/>
          </circle>`;
        }
        return s;
      }
      default: return '';
    }
  }
</script>

<div class="relative w-full max-w-lg mx-auto">
  <!-- Room SVG (wall + floor + furniture — spirit is outside, absolutely positioned on top) -->
  <svg viewBox="0 0 400 300" class="w-full rounded-2xl shadow-lg border"
       style="border-color: {theme.colorScheme.primary}33;">

    <!-- Defs -->
    <defs>
      <linearGradient id="wallGrad" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color={theme.wall.gradient[0]}/>
        <stop offset="100%" stop-color={theme.wall.gradient[1]}/>
      </linearGradient>
      <linearGradient id="floorGrad" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color={theme.floor.color}/>
        <stop offset="100%" stop-color={theme.floor.plankColor}/>
      </linearGradient>
      <radialGradient id="lampGlow" cx="50%" cy="0%" r="60%">
        <stop offset="0%" stop-color={theme.lamp.glowColor} stop-opacity="0.6"/>
        <stop offset="100%" stop-color={theme.wall.gradient[1]} stop-opacity="0"/>
      </radialGradient>
    </defs>

    <!-- Wall -->
    <rect x="0" y="0" width="400" height="200" fill="url(#wallGrad)"/>
    <ellipse cx="200" cy="0" rx="180" ry="100" fill="url(#lampGlow)"/>

    <!-- Ambient particles -->
    {@html renderParticles(theme)}

    <!-- Window (only if no window furniture placed) -->
    {#if !furniture.some(f => f.itemKey === 'deco_window')}
      {#if theme.window.style === 'porthole'}
        <circle cx="200" cy="75" r="30" fill={theme.window.glassColor} stroke={theme.window.frameColor} stroke-width="3"/>
        <circle cx="200" cy="75" r="27" fill="none" stroke={theme.window.frameColor} stroke-width="1" opacity="0.5"/>
      {:else if theme.window.style === 'round'}
        <circle cx="200" cy="75" r="35" fill={theme.window.glassColor} stroke={theme.window.frameColor} stroke-width="2.5"/>
        <line x1="200" y1="40" x2="200" y2="110" stroke={theme.window.frameColor} stroke-width="1.5"/>
        <line x1="165" y1="75" x2="235" y2="75" stroke={theme.window.frameColor} stroke-width="1.5"/>
      {:else if theme.window.style === 'square'}
        <rect x="145" y="40" width="110" height="80" fill={theme.window.glassColor} stroke={theme.window.frameColor} stroke-width="2.5" rx="2"/>
        <line x1="200" y1="40" x2="200" y2="120" stroke={theme.window.frameColor} stroke-width="1.5"/>
      {:else}
        <path d="M155,110 L155,50 Q155,40 165,40 L235,40 Q245,40 245,50 L245,110 Z"
              fill={theme.window.glassColor} stroke={theme.window.frameColor} stroke-width="2.5"/>
        <line x1="200" y1="40" x2="200" y2="110" stroke={theme.window.frameColor} stroke-width="2"/>
      {/if}
    {/if}

    <!-- Ceiling lamp (only if no lamp/mobile placed) -->
    {#if !furniture.some(f => f.itemKey === 'deco_lamp' || f.itemKey === 'deco_star_mobile')}
      {#if theme.lamp.style === 'lantern'}
        <line x1="200" y1="0" x2="200" y2="15" stroke="#713f12" stroke-width="1.5"/>
        <rect x="188" y="15" width="24" height="20" rx="3" fill="#dc2626" opacity="0.8"/>
      {:else if theme.lamp.style === 'crystal'}
        <line x1="200" y1="0" x2="200" y2="12" stroke="#c4b5fd" stroke-width="1"/>
        <polygon points="188,12 212,12 206,22 194,22" fill="#a78bfa" opacity="0.7"/>
        <polygon points="190,22 210,22 204,30 196,30" fill="#c4b5fd" opacity="0.5"/>
      {:else if theme.lamp.style === 'mushroom'}
        <line x1="200" y1="0" x2="200" y2="14" stroke="#78716c" stroke-width="1.5"/>
        <ellipse cx="200" cy="18" rx="14" ry="8" fill="#eab308" opacity="0.7"/>
      {:else if theme.lamp.style === 'shell'}
        <line x1="200" y1="0" x2="200" y2="14" stroke="#475569" stroke-width="1"/>
        <path d="M185,14 Q200,8 215,14 Q200,28 185,14 Z" fill="#fbbf24" opacity="0.5"/>
      {:else}
        <line x1="200" y1="0" x2="200" y2="20" stroke={theme.lamp.bodyColor} stroke-width="1.5"/>
        <circle cx="200" cy="22" r="6" fill={theme.lamp.glowColor} stroke={theme.lamp.bodyColor} stroke-width="1"/>
      {/if}
    {/if}

    <!-- Floor -->
    <rect x="0" y="200" width="400" height="100" fill="url(#floorGrad)"/>
    <line x1="0" y1="220" x2="400" y2="220" stroke={theme.floor.plankColor} stroke-width="0.5" opacity="0.5"/>
    <line x1="0" y1="245" x2="400" y2="245" stroke={theme.floor.plankColor} stroke-width="0.5" opacity="0.5"/>
    <rect x="0" y="197" width="400" height="3" fill={theme.floor.baseboardColor}/>

    <!-- Default rug -->
    {#if !furniture.some(f => f.itemKey === 'deco_rug_round')}
      <ellipse cx="200" cy="248" rx="50" ry="12" fill={theme.defaultRug.color} opacity={theme.defaultRug.opacity}/>
    {/if}

    <!-- Back furniture (wall-mounted, y < floorY) -->
    {#each backFurniture as item (item.userItemId ?? item.itemDefId)}
      <g class={editing ? 'cursor-pointer' : ''}
         onclick={() => editing && onfurnitureclick?.(item)}>
        {@html renderFurniture(item)}
        {#if editing && (item.userItemId ?? item.itemDefId) === selectedItemId}
          <rect x={(item.x ?? 200) - 22} y={(item.y ?? 80) - 22} width="44" height="44" fill="none"
                stroke={theme.colorScheme.primary} stroke-width="2" stroke-dasharray="4,3" rx="6">
            <animate attributeName="stroke-opacity" values="1;0.4;1" dur="2s" repeatCount="indefinite"/>
          </rect>
        {/if}
      </g>
    {/each}

    <!-- Front furniture (floor-standing, y >= floorY, sorted by y) -->
    {#each sortedFront as item (item.userItemId ?? item.itemDefId)}
      <g class={editing ? 'cursor-pointer' : ''}
         onclick={() => editing && onfurnitureclick?.(item)}>
        {@html renderFurniture(item)}
        {#if editing && (item.userItemId ?? item.itemDefId) === selectedItemId}
          <rect x={(item.x ?? 200) - 22} y={(item.y ?? 220) - 22} width="44" height="44" fill="none"
                stroke={theme.colorScheme.primary} stroke-width="2" stroke-dasharray="4,3" rx="6">
            <animate attributeName="stroke-opacity" values="1;0.4;1" dur="2s" repeatCount="indefinite"/>
          </rect>
        {/if}
      </g>
    {/each}

    <!-- Room label -->
    <text x="15" y="288" font-size="9" fill={theme.floor.plankColor} font-family="sans-serif">
      {theme.icon} {room.activeSpirit ? room.activeSpirit.nickname + '的小屋' : '温馨小屋'} · {theme.name}
    </text>
  </svg>

  <!-- Spirit overlaid on center (outside SVG — avoids foreignObject/nested-SVG bug) -->
  <div class="absolute pointer-events-none" style="left: 50%; bottom: 22%; transform: translateX(-50%);">
    {#if room.activeSpirit}
      <div class="relative">
        <SpiritAvatar
          species={room.activeSpirit.species}
          evolutionStage={room.activeSpirit.currentEvolutionStage}
          size="lg"
          mood={spiritMood}
          {accessories}
        />
      </div>
    {:else}
      <div class="w-16 h-16"/>
    {/if}
  </div>
</div>
