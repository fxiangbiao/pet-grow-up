<script lang="ts">
  import type { PersonalityDTO } from '$lib/types/api';

  let { personality, size = 240 }: { personality: PersonalityDTO; size?: number } = $props();

  const labels: { key: keyof PersonalityDTO; label: string }[] = [
    { key: 'lively', label: '活泼' },
    { key: 'shy', label: '害羞' },
    { key: 'independent', label: '独立' },
    { key: 'playful', label: '调皮' },
    { key: 'gentle', label: '温柔' },
    { key: 'brave', label: '勇敢' },
  ];

  const gridLevels = [20, 40, 60, 80, 100];

  const cx = $derived(size / 2);
  const cy = $derived(size / 2);
  const radius = $derived(size * 0.35);

  function angle(index: number): number {
    return (Math.PI / 180) * (90 - index * 60);
  }

  function point(index: number, value: number, r: number, cX: number, cY: number) {
    const a = angle(index);
    const scaled = (value / 100) * r;
    return { x: cX + scaled * Math.cos(a), y: cY - scaled * Math.sin(a) };
  }

  function gridPoint(index: number, level: number, r: number, cX: number, cY: number) {
    const a = angle(index);
    const dist = r * (level / 100);
    return { x: cX + dist * Math.cos(a), y: cY - dist * Math.sin(a) };
  }
</script>

<div class="radar-chart" style="width: {size}px; height: {size}px;">
  <svg width={size} height={size} viewBox="0 0 {size} {size}">
    <!-- Grid rings -->
    {#each gridLevels as level}
      <polygon
        points={labels.map((_, i) => {
          const p = gridPoint(i, level, radius, cx, cy);
          return `${p.x},${p.y}`;
        }).join(' ')}
        fill="none"
        stroke="#e5e7eb"
        stroke-width="1"
      />
    {/each}

    <!-- Axes -->
    {#each labels as _, i}
      <line
        x1={cx}
        y1={cy}
        x2={gridPoint(i, 100, radius, cx, cy).x}
        y2={gridPoint(i, 100, radius, cx, cy).y}
        stroke="#e5e7eb"
        stroke-width="1"
      />
    {/each}

    <!-- Data polygon fill -->
    <polygon
      points={labels.map((l, i) => {
        const p = point(i, personality[l.key] ?? 50, radius, cx, cy);
        return `${p.x},${p.y}`;
      }).join(' ')}
      fill="rgba(99, 102, 241, 0.2)"
      stroke="#6366f1"
      stroke-width="2"
    />

    <!-- Data points -->
    {#each labels as l, i}
      {@const p = point(i, personality[l.key] ?? 50, radius, cx, cy)}
      <circle cx={p.x} cy={p.y} r="4" fill="#6366f1" stroke="white" stroke-width="2" />
    {/each}

    <!-- Labels -->
    {#each labels as l, i}
      {@const lp = gridPoint(i, 100, radius, cx, cy)}
      <text
        x={lp.x + (lp.x - cx) * 0.15}
        y={lp.y + (lp.y - cy) * 0.15 + 4}
        text-anchor="middle"
        class="label"
        fill="#6b7280"
        font-size="11"
      >
        {l.label}
        <tspan x={lp.x + (lp.x - cx) * 0.15} y={lp.y + (lp.y - cy) * 0.15 + 18} fill="#9ca3af" font-size="10">
          {personality[l.key]}
        </tspan>
      </text>
    {/each}
  </svg>
</div>

<style>
  .radar-chart {
    margin: 0 auto;
  }
  .label {
    font-family: system-ui, sans-serif;
  }
</style>
