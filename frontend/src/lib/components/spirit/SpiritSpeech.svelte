<script lang="ts">
  // Independent speech bubble component with optional typewriter effect.
  // Extracted from SpiritAvatar to be reusable by SpiritGreeting, etc.

  let {
    quote,
    personality = 'cheerful',
    show = true,
    typewriter = false,
    typewriterSpeed = 40
  }: {
    quote: string;
    personality?: 'cheerful' | 'gentle' | 'tsundere' | 'brave' | 'weakness';
    show?: boolean;
    typewriter?: boolean;
    typewriterSpeed?: number;
  } = $props();

  let displayedText = $state('');
  let cursorVisible = $state(true);
  let twDone = $state(false);

  // Typewriter effect
  $effect(() => {
    if (!typewriter || !show || !quote) {
      displayedText = quote;
      twDone = true;
      return;
    }

    displayedText = '';
    twDone = false;
    let idx = 0;
    const interval = setInterval(() => {
      if (idx < quote.length) {
        displayedText = quote.substring(0, idx + 1);
        idx++;
      } else {
        twDone = true;
        clearInterval(interval);
      }
    }, typewriterSpeed);

    return () => clearInterval(interval);
  });

  // Blink cursor
  $effect(() => {
    if (!twDone) return;
    const blink = setInterval(() => { cursorVisible = !cursorVisible; }, 500);
    return () => clearInterval(blink);
  });

  const bubbleColors: Record<string, string> = {
    cheerful: 'bg-gradient-to-r from-amber-50 to-orange-50 border-amber-300',
    gentle: 'bg-gradient-to-r from-pink-50 to-rose-50 border-pink-300',
    tsundere: 'bg-gradient-to-r from-violet-50 to-purple-50 border-purple-300',
    brave: 'bg-gradient-to-r from-red-50 to-orange-50 border-red-300',
    weakness: 'bg-gradient-to-r from-sky-50 to-blue-50 border-sky-300'
  };

  const arrowColors: Record<string, string> = {
    cheerful: 'border-t-amber-50',
    gentle: 'border-t-pink-50',
    tsundere: 'border-t-violet-50',
    brave: 'border-t-red-50',
    weakness: 'border-t-sky-50'
  };
</script>

{#if show && quote}
  <div class="relative inline-block animate-fade-in">
    <div class="px-3 py-1.5 rounded-2xl shadow-sm border text-xs text-gray-800 whitespace-nowrap max-w-[220px]
      {bubbleColors[personality] || bubbleColors.cheerful}">
      {displayedText}
      {#if typewriter && !twDone}
        <span class="inline-block w-0.5 h-3 bg-indigo-400 ml-0.5 align-middle animate-pulse"></span>
      {/if}
    </div>
    <!-- Arrow -->
    <div class="absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-0 h-0
      border-l-4 border-r-4 border-t-4 border-transparent
      {arrowColors[personality] || arrowColors.cheerful}">
    </div>
  </div>
{/if}

<style>
  @keyframes fadeInUp2 {
    0% { opacity: 0; transform: translateY(4px); }
    100% { opacity: 1; transform: translateY(0); }
  }
  :global(.animate-fade-in) {
    animation: fadeInUp2 0.25s ease-out;
  }
</style>
