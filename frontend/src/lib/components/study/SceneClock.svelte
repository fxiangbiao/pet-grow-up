<script lang="ts">
  import { submitAnswer, type QuestionDTO, type AnswerResult } from '$lib/api/study';
  import { soundManager } from '$lib/audio/sound-manager';

  let {
    question,
    sessionId,
    onComplete,
    preview = false
  }: {
    question: QuestionDTO;
    sessionId: number;
    onComplete: (result: AnswerResult) => void;
    preview?: boolean;
  } = $props();

  // ── Clock state ──
  const CLOCK_RADIUS = 120;
  const HOUR_HAND_LENGTH = 55;
  const MINUTE_HAND_LENGTH = 75;
  const CENTER = CLOCK_RADIUS + 20;

  // Parse target hour from question options (e.g., {"hour":7} or {"key":"7"})
  function parseTargetHour(): number {
    const opts = question.options;
    let parsed: any = null;

    if (typeof opts === 'string') {
      try { parsed = JSON.parse(opts); } catch { /* raw string like "7" */ }
    } else if (typeof opts === 'object' && opts !== null) {
      parsed = opts;
    }

    // Check for hour field first (new format)
    if (parsed?.hour !== undefined) {
      return typeof parsed.hour === 'number' ? parsed.hour : parseInt(String(parsed.hour));
    }
    // Check for key field
    if (parsed?.key !== undefined) {
      const match = String(parsed.key).match(/(\d+)/);
      if (match) return parseInt(match[1]);
    }
    // Fallback: try to extract number from raw options
    const raw = typeof opts === 'string' ? opts : JSON.stringify(opts || '');
    const match = raw.match(/(\d+)/);
    return match ? parseInt(match[1]) : 3;
  }

  const targetHour = $state(parseTargetHour());
  // Convert hour to angle: 12=0°, 3=90°, 6=180°, 9=270°
  const targetAngle = $derived(((targetHour % 12) / 12) * 360 - 90);

  let currentAngle = $state(-90); // start at 12 o'clock
  let hourSet = $state<number | null>(null);
  let submitted = $state(false);
  let feedback = $state<'idle' | 'correct' | 'wrong'>('idle');
  let showFeedback = $state(false);
  let dragging = $state(false);

  let clockEl: HTMLDivElement | null = null;
  let tickCount = $state(0);

  // Snap currentAngle to nearest hour
  function nearestHour(angleDeg: number): number {
    let normalized = ((angleDeg + 90) % 360 + 360) % 360;
    let hour = Math.round((normalized / 360) * 12) % 12;
    return hour === 0 ? 12 : hour;
  }

  function snapToHour(hour: number): number {
    return ((hour % 12) / 12) * 360 - 90;
  }

  // ── Pointer events for hand dragging ──
  function getAngleFromPoint(clientX: number, clientY: number): number {
    if (!clockEl) return currentAngle;
    const rect = clockEl.getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    return Math.atan2(clientY - cy, clientX - cx) * (180 / Math.PI);
  }

  function handlePointerDown(e: PointerEvent) {
    if (submitted) return;
    dragging = true;
    clockEl?.setPointerCapture(e.pointerId);
    soundManager.playClockTick();
    tickCount++;
  }

  function handlePointerMove(e: PointerEvent) {
    if (!dragging || submitted) return;
    currentAngle = getAngleFromPoint(e.clientX, e.clientY);
    hourSet = nearestHour(currentAngle);
    // Tick sound on crossing hour boundaries
    if (Math.floor(currentAngle / 30) !== Math.floor((currentAngle - 1) / 30)) {
      soundManager.playClockTick();
      tickCount++;
    }
  }

  function handlePointerUp(_e: PointerEvent) {
    if (!dragging || submitted) return;
    dragging = false;
    // Snap to nearest hour
    const h = hourSet || nearestHour(currentAngle);
    currentAngle = snapToHour(h);
    hourSet = h;

    // Auto-check
    if (h === targetHour) {
      handleCorrect();
    }
  }

  async function handleCorrect() {
    if (preview) return;
    submitted = true;
    soundManager.playClockChime();

    try {
      const result = await submitAnswer({
        sessionId,
        questionId: question.questionId,
        answer: String(targetHour),
        timeSpent: 0
      });
      if (result) {
        feedback = 'correct';
        showFeedback = true;
        soundManager.playCorrect();
        setTimeout(() => {
          try { onComplete(result); } catch (e) { console.error('[Clock] onComplete failed:', e); }
        }, 1500);
      }
    } catch (err) {
      console.error('[Clock] Submit failed:', err);
      submitted = false;
      feedback = 'idle';
      showFeedback = false;
    }
  }

  // ── Clock rendering helpers ──
  function hourMarkers(): Array<{ hour: number; x: number; y: number }> {
    const markers: Array<{ hour: number; x: number; y: number }> = [];
    for (let h = 1; h <= 12; h++) {
      const angleDeg = (h / 12) * 360 - 90;
      const rad = angleDeg * (Math.PI / 180);
      const r = CLOCK_RADIUS - 22;
      markers.push({
        hour: h,
        x: CENTER + r * Math.cos(rad),
        y: CENTER + r * Math.sin(rad),
      });
    }
    return markers;
  }

  function handEndPoint(angleDeg: number, length: number): { x: number; y: number } {
    const rad = angleDeg * (Math.PI / 180);
    return {
      x: CENTER + length * Math.cos(rad),
      y: CENTER + length * Math.sin(rad),
    };
  }

  const hourEnd = $derived(handEndPoint(currentAngle, HOUR_HAND_LENGTH));
  const minuteAngle = $derived(-90); // fixed at 12
  const minuteEnd = $derived(handEndPoint(minuteAngle, MINUTE_HAND_LENGTH));

  // Pet message based on targetHour
  const timeMessages: Record<number, string> = {
    7: '7:00 该起床啦！',
    8: '8:00 上学时间到！',
    12: '12:00 吃午饭咯～',
    3: '3:00 下午活动时间！',
    6: '6:00 吃晚饭啦～',
    9: '9:00 该睡觉了！',
  };

  const svgSize = (CLOCK_RADIUS + 20) * 2;
</script>

<div
  class="relative w-full min-h-[420px] bg-gradient-to-b from-blue-50 to-indigo-100 overflow-hidden select-none rounded-xl"
  style="touch-action: none;"
  role="application"
  aria-label="拨钟表认识时间"
>
  <!-- Hint -->
  <div class="absolute top-3 left-1/2 -translate-x-1/2 text-center z-10">
    <p class="text-lg font-bold text-indigo-800 bg-white/80 rounded-full px-5 py-1.5 shadow-sm">
      🐱「{timeMessages[targetHour] || question.questionText || '拨动时针到正确时间！'}」
    </p>
    {#if hourSet && hourSet !== targetHour}
      <p class="text-sm text-amber-600 mt-1">你拨到了 {hourSet}:00，再试试～</p>
    {/if}
  </div>

  <!-- Clock face — pointermove/pointerup on container so drag works even if pointer leaves the hand -->
  <div
    class="absolute inset-0 flex items-center justify-center"
    bind:this={clockEl}
    onpointermove={handlePointerMove}
    onpointerup={handlePointerUp}
    onpointerleave={handlePointerUp}
  >
    <svg
      width={svgSize}
      height={svgSize}
      viewBox="0 0 {svgSize} {svgSize}"
      class="drop-shadow-xl"
    >
      <!-- Outer ring -->
      <circle cx={CENTER} cy={CENTER} r={CLOCK_RADIUS}
        fill="white" stroke="#6366f1" stroke-width="4" />
      <circle cx={CENTER} cy={CENTER} r={CLOCK_RADIUS - 6}
        fill="none" stroke="#c7d2fe" stroke-width="1" />

      <!-- Hour markers -->
      {#each hourMarkers() as m}
        <text x={m.x} y={m.y} text-anchor="middle" dominant-baseline="central"
          font-size="16" font-weight="bold" fill={targetHour === m.hour ? '#4f46e5' : '#64748b'}
          class:fill-indigo-600={targetHour === m.hour}
          class:fill-slate-500={targetHour !== m.hour}>
          {m.hour}
        </text>
      {/each}

      <!-- Target hint arc -->
      <circle cx={CENTER} cy={CENTER} r={CLOCK_RADIUS - 14}
        fill="none" stroke="#818cf8" stroke-width="3" stroke-dasharray="6 4" opacity="0.4"
        stroke-dashoffset={-(targetAngle * (2 * Math.PI * (CLOCK_RADIUS - 14) / 360))}
        style="transform: rotate({targetAngle + 90}deg); transform-origin: {CENTER}px {CENTER}px;" />

      <!-- Minute hand (fixed at 12) -->
      <line x1={CENTER} y1={CENTER} x2={minuteEnd.x} y2={minuteEnd.y}
        stroke="#94a3b8" stroke-width="3" stroke-linecap="round" opacity="0.6" />

      <!-- Hour hand (draggable) — pointerdown only, move/up handled by container -->
      <line x1={CENTER} y1={CENTER} x2={hourEnd.x} y2={hourEnd.y}
        stroke={dragging ? '#6366f1' : '#1e293b'}
        stroke-width={dragging ? '7' : '6'}
        stroke-linecap="round"
        class="transition-colors duration-150"
        style="cursor: {submitted ? 'default' : 'grab'};"
        onpointerdown={handlePointerDown}
      />

      <!-- Center dot -->
      <circle cx={CENTER} cy={CENTER} r="8" fill="#6366f1" />
      <circle cx={CENTER} cy={CENTER} r="4" fill="white" />

      <!-- Hour hand tip circle -->
      <circle cx={hourEnd.x} cy={hourEnd.y} r="7"
        fill={dragging ? '#6366f1' : '#1e293b'}
        class="transition-colors duration-150"
        style="cursor: {submitted ? 'default' : 'grab'};"
        onpointerdown={handlePointerDown}
      />
    </svg>
  </div>

  <!-- Feedback overlay -->
  {#if showFeedback}
    <div class="absolute inset-0 flex items-center justify-center z-20 pointer-events-none">
      <div class="bg-green-500 text-white text-2xl font-bold px-8 py-4 rounded-2xl shadow-xl animate-bounce-in">
        ✅ {targetHour}:00 对啦！
      </div>
    </div>
  {/if}
</div>

<style lang="postcss">
  @keyframes bounceIn {
    0% { transform: scale(0.3); opacity: 0; }
    50% { transform: scale(1.1); }
    70% { transform: scale(0.9); }
    100% { transform: scale(1); opacity: 1; }
  }
  :global(.animate-bounce-in) {
    animation: bounceIn 0.5s ease-out;
  }
</style>
