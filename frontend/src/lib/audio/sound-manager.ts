/**
 * Programmatic sound manager using Web Audio API.
 * No external audio files needed — generates tones via oscillators.
 * AudioContext is initialized on first user interaction to comply with autoplay policies.
 *
 * v3 (Sprint A): 9 BGMs (3 per subject × scene), 11 scene SFX, 5 pet emotion sounds.
 */

let ctx: AudioContext | null = null;
let enabled = true;
let bgmGain: GainNode | null = null;
let bgmOscillators: OscillatorNode[] = [];
let currentBgmSubject = '';
let currentBgmScene = '';
let masterVolume = 0.12;

function getContext(): AudioContext {
  if (!ctx) {
    ctx = new AudioContext();
  }
  if (ctx.state === 'suspended') {
    ctx.resume();
  }
  return ctx;
}

function playTone(frequency: number, duration: number, type: OscillatorType = 'sine', volume: number = masterVolume) {
  if (!enabled) return;
  const c = getContext();
  const osc = c.createOscillator();
  const gain = c.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(frequency, c.currentTime);
  gain.gain.setValueAtTime(volume, c.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, c.currentTime + duration);
  osc.connect(gain);
  gain.connect(c.destination);
  osc.start(c.currentTime);
  osc.stop(c.currentTime + duration);
}

function playSequence(notes: Array<{ freq: number; time: number; dur: number; type?: OscillatorType; vol?: number }>) {
  if (!enabled) return;
  const c = getContext();
  notes.forEach(({ freq, time, dur, type = 'sine', vol = masterVolume }) => {
    const osc = c.createOscillator();
    const gain = c.createGain();
    osc.type = type;
    const startTime = c.currentTime + time;
    osc.frequency.setValueAtTime(freq, startTime);
    gain.gain.setValueAtTime(vol, startTime);
    gain.gain.exponentialRampToValueAtTime(0.001, startTime + dur);
    osc.connect(gain);
    gain.connect(c.destination);
    osc.start(startTime);
    osc.stop(startTime + dur);
  });
}

// ── Scale frequencies (all in C4-C5 range for warmth, never piercing) ──
// Natural minor (Aeolian): C D Eb F G Ab Bb — adventurous, slightly tense
const MINOR = [262, 294, 311, 349, 392, 415, 466];
// Harmonic minor: C D Eb F G Ab B — exotic adventure feel
const HARMONIC_MINOR = [262, 294, 311, 349, 392, 415, 494];
// Dorian mode: C D Eb F G A Bb — medieval adventure
const DORIAN = [262, 294, 311, 349, 392, 440, 466];
// Pentatonic for Chinese feel
const PENTATONIC = [262, 294, 330, 392, 440]; // C D E G A

/** Pick a random note from a scale at a given octave offset (0 = C4, 1 = C5) */
function pickNote(scale: number[], octaveOffset: number = 0): number {
  const base = scale[Math.floor(Math.random() * scale.length)];
  return base * Math.pow(2, octaveOffset);
}

/**
 * Helper: create a sustained oscillator connected to bgmGain.
 * Returns the oscillator (caller must add to bgmOscillators).
 */
function startPadOsc(c: AudioContext, freq: number, gain: number, type: OscillatorType = 'sine', detune: number = 0): OscillatorNode {
  const osc = c.createOscillator();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, c.currentTime);
  if (detune) osc.detune.setValueAtTime(detune, c.currentTime);
  const g = c.createGain();
  g.gain.setValueAtTime(gain, c.currentTime);
  osc.connect(g);
  g.connect(bgmGain!);
  osc.start();
  return osc;
}

/**
 * Helper: schedule a plucked note through bgmGain.
 */
function schedulePluck(
  c: AudioContext, freq: number, startTime: number, len: number,
  type: OscillatorType = 'triangle', peakVol: number = 0.08, sustainVol: number = 0.015
): OscillatorNode {
  const osc = c.createOscillator();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, startTime);
  const g = c.createGain();
  g.gain.setValueAtTime(0, startTime);
  g.gain.linearRampToValueAtTime(peakVol, startTime + len * 0.05);
  g.gain.exponentialRampToValueAtTime(sustainVol, startTime + len * 0.4);
  g.gain.linearRampToValueAtTime(0, startTime + len);
  osc.connect(g);
  g.connect(bgmGain!);
  osc.start(startTime);
  osc.stop(startTime + len + 0.1);
  return osc;
}

// ═══════════════════════════════════════════════════════════════
// BGM generators — Soft + Dynamic + Adventurous
//
// Philosophy:
//   - Sine pads only (warm foundation, never harsh)
//   - Triangle plucks for melody (articulate but soft)
//   - Natural minor / Dorian scales (adventure feel)
//   - C3-C5 range (never piercing)
//   - Subtle rhythmic pulse for "动感"
//   - Gentle tension via minor intervals + slow filter movement
// ═══════════════════════════════════════════════════════════════

/**
 * Create a soft rhythmic pulse — low sine wave that gently oscillates in volume.
 * Adds the "dynamic/动感" feel without being intrusive.
 */
function startPulse(c: AudioContext, freq: number, vol: number, speedHz: number): OscillatorNode {
  const osc = c.createOscillator();
  osc.type = 'sine';
  osc.frequency.setValueAtTime(freq, c.currentTime);

  // Volume LFO for subtle "breathing" pulse
  const lfo = c.createOscillator();
  lfo.type = 'sine';
  lfo.frequency.setValueAtTime(speedHz, c.currentTime);
  const lfoGain = c.createGain();
  lfoGain.gain.setValueAtTime(vol * 0.3, c.currentTime);
  lfo.connect(lfoGain);

  const g = c.createGain();
  g.gain.setValueAtTime(vol, c.currentTime);
  lfoGain.connect(g.gain);

  osc.connect(g);
  g.connect(bgmGain!);
  osc.start();
  lfo.start();
  bgmOscillators.push(lfo);
  return osc;
}

// ── Chinese Explore: Pentatonic warmth with flowing melody ──
function playChineseExplore(c: AudioContext) {
  // Warm low pad
  bgmOscillators.push(startPadOsc(c, 131, 0.04)); // C3
  bgmOscillators.push(startPadOsc(c, 196, 0.03)); // G3
  // Gentle pulse
  bgmOscillators.push(startPulse(c, 98, 0.03, 0.5));

  // Flowing pentatonic melody — calm but forward-moving
  const melody = [330, 392, 440, 523, 440, 392, 330, 294, 330, 392, 440, 523, 587, 523, 440, 392];
  const cycle = 20;
  melody.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (cycle / melody.length), cycle / melody.length, 'triangle', 0.05, 0.008));
  });
}

// ── Chinese Pinyin: Light, playful, bubble-like ──
function playChinesePinyin(c: AudioContext) {
  bgmOscillators.push(startPadOsc(c, 165, 0.03)); // E3
  bgmOscillators.push(startPadOsc(c, 247, 0.025)); // B3
  bgmOscillators.push(startPulse(c, 82, 0.025, 0.6));

  // Playful staccato melody — pentatonic with bounce
  const notes = [523, 440, 392, 440, 523, 587, 523, 440, 392, 330, 392, 440, 523, 440, 392, 330, 294, 330];
  const cycle = 14;
  notes.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (cycle / notes.length), cycle / notes.length, 'triangle', 0.045, 0.006));
  });
}

// ── Chinese Char: Elegant, contemplative, guqin-like ──
function playChineseChar(c: AudioContext) {
  bgmOscillators.push(startPadOsc(c, 98, 0.04));  // G2
  bgmOscillators.push(startPadOsc(c, 147, 0.03)); // D3
  bgmOscillators.push(startPadOsc(c, 196, 0.025)); // G3

  // Slow, spacious pentatonic — each note rings
  const notes = [262, 330, 392, 330, 294, 262, 294, 330, 440, 392, 330, 294, 262];
  const cycle = 24;
  notes.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (cycle / notes.length), cycle / notes.length, 'triangle', 0.05, 0.012));
  });
}

// ── Math Explore: Dorian mode arpeggios — medieval adventure quest ──
function playMathExplore(c: AudioContext) {
  // Rich low drone
  bgmOscillators.push(startPadOsc(c, 131, 0.04)); // C3
  bgmOscillators.push(startPadOsc(c, 196, 0.03)); // G3
  bgmOscillators.push(startPulse(c, 65, 0.035, 0.55));

  // Dorian arpeggio — adventurous, forward momentum
  const arp = [262, 330, 392, 440, 392, 330, 262, 294, 349, 440, 349, 294, 262, 330, 392, 466, 440, 392, 330, 262];
  const arpCycle = 16;
  arp.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (arpCycle / arp.length), arpCycle / arp.length, 'triangle', 0.06, 0.01));
  });

  // Occasional tension note (Ab = 415 Hz — minor 6th interval creates adventure tension)
  [3, 7, 11].forEach((beat) => {
    const t = c.currentTime + beat * (arpCycle / 4);
    const osc = c.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(415, t);
    const g = c.createGain();
    g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(0.025, t + 0.3);
    g.gain.exponentialRampToValueAtTime(0.001, t + 1.5);
    osc.connect(g);
    g.connect(bgmGain!);
    osc.start(t);
    osc.stop(t + 1.6);
    bgmOscillators.push(osc);
  });
}

// ── Math Clock: Tick-tock rhythm + dreamy melody ──
function playMathClock(c: AudioContext) {
  bgmOscillators.push(startPadOsc(c, 131, 0.03)); // C3
  bgmOscillators.push(startPadOsc(c, 196, 0.025)); // G3

  // Gentle tick-tock — soft sine clicks, lower frequency
  const beat = 0.9;
  for (let i = 0; i < 28; i++) {
    const t = c.currentTime + i * beat;
    const osc = c.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(i % 2 === 0 ? 660 : 520, t);
    const g = c.createGain();
    g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(0.025, t + 0.015);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.1);
    osc.connect(g);
    g.connect(bgmGain!);
    osc.start(t);
    osc.stop(t + 0.12);
    bgmOscillators.push(osc);
  }

  // Dreamy chimes on the hour
  [0, 4, 8, 12, 16, 20].forEach((beatIdx) => {
    const t = c.currentTime + beatIdx * beat + beat * 0.3;
    bgmOscillators.push(schedulePluck(c, 523, t, 0.7, 'triangle', 0.04, 0.005));
  });
}

// ── Math Shop: Bouncy, cheerful, coin-jingle feel ──
function playMathShop(c: AudioContext) {
  bgmOscillators.push(startPadOsc(c, 165, 0.03)); // E3
  bgmOscillators.push(startPadOsc(c, 247, 0.025)); // B3
  bgmOscillators.push(startPulse(c, 110, 0.03, 0.65));

  // Bouncy major-feel melody (with occasional minor for depth)
  const bouncy = [392, 440, 392, 349, 330, 349, 392, 440, 523, 440, 392, 349, 330, 294, 330, 349, 392];
  const cycle = 12;
  bouncy.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (cycle / bouncy.length), cycle / bouncy.length, 'triangle', 0.05, 0.008));
  });

  // Soft coin sparkles
  for (let i = 0; i < 4; i++) {
    const t = c.currentTime + i * 3.2 + 0.8;
    [784, 988, 1175].forEach((freq, j) => {
      const osc = c.createOscillator();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(freq, t + j * 0.07);
      const g = c.createGain();
      g.gain.setValueAtTime(0, t + j * 0.07);
      g.gain.linearRampToValueAtTime(0.03, t + j * 0.07 + 0.01);
      g.gain.exponentialRampToValueAtTime(0.001, t + j * 0.07 + 0.14);
      osc.connect(g);
      g.connect(bgmGain!);
      osc.start(t + j * 0.07);
      osc.stop(t + j * 0.07 + 0.16);
      bgmOscillators.push(osc);
    });
  }
}

// ── English Explore: Warm ambient + gentle adventure melody ──
function playEnglishExplore(c: AudioContext) {
  // Warm Cmaj7 pad — very soft
  bgmOscillators.push(startPadOsc(c, 131, 0.035)); // C3
  bgmOscillators.push(startPadOsc(c, 165, 0.03));  // E3
  bgmOscillators.push(startPadOsc(c, 196, 0.03));  // G3
  bgmOscillators.push(startPadOsc(c, 247, 0.025)); // B3
  bgmOscillators.push(startPulse(c, 65, 0.03, 0.45));

  // Gentle melody — C4-C5 range, sine + slow attack = never harsh
  const melody = [262, 330, 392, 349, 330, 294, 262, 330, 392, 440, 392, 330, 294, 262, 294, 330];
  const cycle = 28;
  melody.forEach((freq, i) => {
    const osc = c.createOscillator();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(freq, c.currentTime);

    // Subtle vibrato
    const vib = c.createOscillator();
    vib.type = 'sine';
    vib.frequency.setValueAtTime(3.5, c.currentTime);
    const vibGain = c.createGain();
    vibGain.gain.setValueAtTime(2, c.currentTime);
    vib.connect(vibGain);
    vibGain.connect(osc.frequency);
    vib.start();

    const g = c.createGain();
    const t = c.currentTime + i * (cycle / melody.length);
    const len = cycle / melody.length * 1.5;
    g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(0.025, t + 1.2); // very slow attack
    g.gain.setValueAtTime(0.025, t + len - 0.8);
    g.gain.linearRampToValueAtTime(0, t + len);

    osc.connect(g);
    g.connect(bgmGain!);
    osc.start();
    bgmOscillators.push(osc, vib);
  });

  // Occasional tension swell (Ab in C major context — mysterious)
  [4, 12, 20].forEach((noteIdx) => {
    const t = c.currentTime + noteIdx * (cycle / melody.length);
    const osc = c.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(415, t);
    const g = c.createGain();
    g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(0.02, t + 1.5);
    g.gain.linearRampToValueAtTime(0, t + 4);
    osc.connect(g);
    g.connect(bgmGain!);
    osc.start(t);
    osc.stop(t + 4.2);
    bgmOscillators.push(osc);
  });
}

// ── English Letters: ABC-inspired, gentle bell chimes ──
function playEnglishLetters(c: AudioContext) {
  bgmOscillators.push(startPadOsc(c, 131, 0.03)); // C3
  bgmOscillators.push(startPadOsc(c, 196, 0.025)); // G3
  bgmOscillators.push(startPulse(c, 87, 0.025, 0.5));

  // Simple major melody — bell-like triangle, very soft
  const abcMelody = [262, 294, 330, 349, 392, 349, 330, 294, 262, 330, 392, 440, 392, 330, 294, 262];
  const cycle = 18;
  abcMelody.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (cycle / abcMelody.length), cycle / abcMelody.length, 'triangle', 0.04, 0.007));
  });
}

// ── English Vocab: Cheerful groove with light world-music flavor ──
function playEnglishVocab(c: AudioContext) {
  bgmOscillators.push(startPadOsc(c, 147, 0.03)); // D3
  bgmOscillators.push(startPadOsc(c, 220, 0.025)); // A3
  bgmOscillators.push(startPulse(c, 73, 0.03, 0.6));

  // Bouncy melody with dorian flavor
  const groove = [349, 392, 440, 392, 349, 330, 294, 330, 349, 392, 440, 466, 440, 392, 349, 330, 294, 262];
  const cycle = 14;
  groove.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (cycle / groove.length), cycle / groove.length, 'triangle', 0.05, 0.008));
  });

  // Soft bird-like chirps — very gentle, low frequency
  for (let i = 0; i < 3; i++) {
    const t = c.currentTime + i * 4.5 + 1.5;
    const osc = c.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(520 + i * 40, t);
    osc.frequency.exponentialRampToValueAtTime(660 + i * 30, t + 0.08);
    const g = c.createGain();
    g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(0.015, t + 0.03);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.18);
    osc.connect(g);
    g.connect(bgmGain!);
    osc.start(t);
    osc.stop(t + 0.2);
    bgmOscillators.push(osc);
  }
}

export const soundManager = {
  /** Initialize audio context on first user interaction */
  init() {
    if (!ctx) {
      ctx = new AudioContext();
    }
  },

  get enabled() { return enabled; },

  toggle() {
    enabled = !enabled;
    if (!enabled) {
      this.stopBGM();
    }
    return enabled;
  },

  setVolume(v: number) {
    masterVolume = Math.max(0, Math.min(1, v));
  },

  // ============================
  // BGM system (9 tracks: 3 per subject)
  // ============================

  /**
   * Start background music for a subject + optional scene.
   *
   * Subject → default scene:
   *   chinese → explore | pinyin | char
   *   math    → explore | clock | shop
   *   english → explore | letters | vocab
   *
   * Call without `scene` to use the default (explore) track.
   */
  playBGM(subject: string, scene?: string) {
    if (!enabled) return;
    const effectiveScene = scene || 'explore';
    if (currentBgmSubject === subject && currentBgmScene === effectiveScene) return;
    this.stopBGM();
    currentBgmSubject = subject;
    currentBgmScene = effectiveScene;

    const c = getContext();
    bgmGain = c.createGain();
    bgmGain.gain.setValueAtTime(0.04, c.currentTime);
    bgmGain.connect(c.destination);

    if (subject === 'chinese') {
      if (effectiveScene === 'pinyin') {
        playChinesePinyin(c);
      } else if (effectiveScene === 'char' || effectiveScene === 'shizi') {
        playChineseChar(c);
      } else {
        playChineseExplore(c);
      }
    } else if (subject === 'math') {
      if (effectiveScene === 'clock') {
        playMathClock(c);
      } else if (effectiveScene === 'shop') {
        playMathShop(c);
      } else {
        playMathExplore(c);
      }
    } else if (subject === 'english') {
      if (effectiveScene === 'letters') {
        playEnglishLetters(c);
      } else if (effectiveScene === 'vocab') {
        playEnglishVocab(c);
      } else {
        playEnglishExplore(c);
      }
    }
  },

  /** Stop background music */
  stopBGM() {
    bgmOscillators.forEach(osc => {
      try { osc.stop(); } catch { /* already stopped */ }
    });
    bgmOscillators = [];
    currentBgmSubject = '';
    currentBgmScene = '';
    if (bgmGain) {
      try { bgmGain.disconnect(); } catch { /* ignore */ }
      bgmGain = null;
    }
  },

  // ============================
  // Guardian theme — suspenseful but gentle
  // ============================

  playBossTheme() {
    if (!enabled) return;
    // Low drone + slow rising tension — no harsh waves
    playSequence([
      { freq: 65.41, time: 0, dur: 2.5, type: 'sine', vol: 0.05 },
      { freq: 98.00, time: 0, dur: 2.5, type: 'sine', vol: 0.04 },
      { freq: 130.81, time: 0.6, dur: 0.3, type: 'triangle', vol: 0.04 },
      { freq: 155.56, time: 1.2, dur: 0.3, type: 'triangle', vol: 0.04 },
      { freq: 196.00, time: 1.8, dur: 0.4, type: 'triangle', vol: 0.05 },
    ]);
  },

  stopBossTheme() {
    // Boss theme is a one-shot effect, not continuous
  },

  // ============================
  // Standard sound effects
  // ============================

  playCorrect(comboLevel = 0) {
    const baseFreq = 523.25 + Math.min(comboLevel * 30, 200);
    playSequence([
      { freq: baseFreq, time: 0, dur: 0.12, type: 'sine' },
      { freq: baseFreq * 1.25, time: 0.1, dur: 0.25, type: 'sine' },
    ]);
  },

  playWrong() {
    playSequence([
      { freq: 330, time: 0, dur: 0.15, type: 'triangle', vol: 0.06 },
      { freq: 262, time: 0.1, dur: 0.25, type: 'triangle', vol: 0.06 },
      { freq: 196, time: 0.15, dur: 0.2, type: 'sine', vol: 0.04 },
    ]);
  },

  playComplete() {
    playSequence([
      { freq: 523.25, time: 0, dur: 0.12 },
      { freq: 659.25, time: 0.1, dur: 0.12 },
      { freq: 783.99, time: 0.2, dur: 0.12 },
      { freq: 1046.50, time: 0.3, dur: 0.35 },
    ]);
  },

  playCelebrate() {
    playSequence([
      { freq: 523.25, time: 0, dur: 0.1, type: 'triangle' },
      { freq: 659.25, time: 0.08, dur: 0.1, type: 'triangle' },
      { freq: 783.99, time: 0.16, dur: 0.1, type: 'triangle' },
      { freq: 1046.50, time: 0.24, dur: 0.1, type: 'triangle' },
      { freq: 1318.51, time: 0.32, dur: 0.3, type: 'triangle' },
      { freq: 1567.98, time: 0.42, dur: 0.4, type: 'sine', vol: 0.1 },
    ]);
  },

  playClick() {
    playTone(800, 0.05, 'square', 0.05);
  },

  playFeed() {
    playSequence([
      { freq: 523.25, time: 0, dur: 0.1 },
      { freq: 587.33, time: 0.08, dur: 0.1 },
      { freq: 659.25, time: 0.16, dur: 0.2 },
    ]);
  },

  playEvolve() {
    playSequence([
      { freq: 523.25, time: 0, dur: 0.12, type: 'triangle' },
      { freq: 659.25, time: 0.1, dur: 0.12, type: 'triangle' },
      { freq: 783.99, time: 0.2, dur: 0.12, type: 'triangle' },
      { freq: 1046.50, time: 0.3, dur: 0.15, type: 'triangle' },
      { freq: 1318.51, time: 0.4, dur: 0.3, type: 'triangle' },
      { freq: 1567.98, time: 0.5, dur: 0.4, type: 'sine' },
    ]);
  },

  playTreasure() {
    playSequence([
      { freq: 784, time: 0, dur: 0.08, type: 'triangle' },
      { freq: 988, time: 0.06, dur: 0.08, type: 'triangle' },
      { freq: 1175, time: 0.12, dur: 0.08, type: 'triangle' },
      { freq: 1319, time: 0.18, dur: 0.2, type: 'triangle' },
    ]);
  },

  playBossDefeated() {
    playSequence([
      { freq: 523.25, time: 0, dur: 0.15, type: 'triangle' },
      { freq: 659.25, time: 0.12, dur: 0.15, type: 'triangle' },
      { freq: 783.99, time: 0.24, dur: 0.15, type: 'triangle' },
      { freq: 1046.50, time: 0.36, dur: 0.4, type: 'triangle' },
      { freq: 1318.51, time: 0.5, dur: 0.5, type: 'sine' },
    ]);
  },

  playBossChargeUp() {
    if (!enabled) return;
    const c = getContext();
    const osc = c.createOscillator();
    const gain = c.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(65.41, c.currentTime);
    osc.frequency.exponentialRampToValueAtTime(130.81, c.currentTime + 2.5);
    gain.gain.setValueAtTime(0.04, c.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, c.currentTime + 3);
    osc.connect(gain);
    gain.connect(c.destination);
    osc.start(c.currentTime);
    osc.stop(c.currentTime + 3);
    playSequence([
      { freq: 98.00, time: 0.8, dur: 0.1, type: 'triangle', vol: 0.04 },
      { freq: 110.00, time: 1.5, dur: 0.1, type: 'triangle', vol: 0.04 },
      { freq: 130.81, time: 2.0, dur: 0.2, type: 'triangle', vol: 0.05 },
    ]);
  },

  playBossAttack() {
    playSequence([
      { freq: 294, time: 0, dur: 0.1, type: 'triangle', vol: 0.06 },
      { freq: 247, time: 0.08, dur: 0.12, type: 'triangle', vol: 0.05 },
      { freq: 196, time: 0.16, dur: 0.25, type: 'sine', vol: 0.05 },
    ]);
  },

  playBossPhaseChange() {
    playSequence([
      { freq: 440, time: 0, dur: 0.08, type: 'triangle', vol: 0.05 },
      { freq: 523, time: 0.06, dur: 0.08, type: 'triangle', vol: 0.05 },
      { freq: 659, time: 0.12, dur: 0.15, type: 'sine', vol: 0.05 },
    ]);
  },

  playBossShatter() {
    playSequence([
      { freq: 784, time: 0, dur: 0.08, type: 'triangle', vol: 0.06 },
      { freq: 659, time: 0.04, dur: 0.08, type: 'triangle', vol: 0.05 },
      { freq: 523, time: 0.08, dur: 0.1, type: 'triangle', vol: 0.05 },
      { freq: 392, time: 0.12, dur: 0.35, type: 'sine', vol: 0.06 },
    ]);
  },

  playSpiritHappy() {
    const pitch = 600 + Math.random() * 200;
    playSequence([
      { freq: pitch, time: 0, dur: 0.08 },
      { freq: pitch * 1.25, time: 0.06, dur: 0.12 },
    ]);
  },

  playSpiritSad() {
    playSequence([
      { freq: 500, time: 0, dur: 0.12, type: 'sine' },
      { freq: 380, time: 0.1, dur: 0.2, type: 'sine' },
    ]);
  },

  // ============================
  // Scene-specific SFX (Sprint A: 11 new sounds)
  // ============================

  /** Whack-a-mole: mole pops up — short rising slide */
  playMoleAppear() {
    if (!enabled) return;
    const c = getContext();
    const osc = c.createOscillator();
    const gain = c.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(300, c.currentTime);
    osc.frequency.exponentialRampToValueAtTime(600, c.currentTime + 0.15);
    gain.gain.setValueAtTime(0.07, c.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, c.currentTime + 0.2);
    osc.connect(gain);
    gain.connect(c.destination);
    osc.start(c.currentTime);
    osc.stop(c.currentTime + 0.2);
  },

  /** Whack-a-mole: hit the mole — percussive bonk + sparkle */
  playMoleWhack() {
    playSequence([
      { freq: 200, time: 0, dur: 0.08, type: 'square', vol: 0.1 },
      { freq: 800, time: 0.02, dur: 0.05, type: 'sine', vol: 0.06 },
      { freq: 1200, time: 0.06, dur: 0.12, type: 'triangle', vol: 0.08 },
    ]);
  },

  /** Whack-a-mole: miss — gentle spring boing */
  playMoleMiss() {
    playSequence([
      { freq: 400, time: 0, dur: 0.06, type: 'triangle', vol: 0.05 },
      { freq: 280, time: 0.05, dur: 0.15, type: 'sine', vol: 0.06 },
    ]);
  },

  /** Shape puzzle: piece snaps into place — crisp click */
  playPuzzleSnap() {
    playSequence([
      { freq: 1000, time: 0, dur: 0.03, type: 'square', vol: 0.06 },
      { freq: 1400, time: 0.02, dur: 0.06, type: 'triangle', vol: 0.08 },
    ]);
  },

  /** Clock: hand ticks while dragging — mechanical tick */
  playClockTick() {
    playTone(900, 0.04, 'square', 0.04);
  },

  /** Clock: time set correctly — chime ding-dong */
  playClockChime() {
    playSequence([
      { freq: 784, time: 0, dur: 0.4, type: 'triangle', vol: 0.1 },
      { freq: 659, time: 0.15, dur: 0.5, type: 'triangle', vol: 0.1 },
      { freq: 523, time: 0.35, dur: 0.6, type: 'sine', vol: 0.08 },
    ]);
  },

  /** Shop: coin dropped — metallic ping */
  playCoinDrop() {
    playSequence([
      { freq: 1319, time: 0, dur: 0.05, type: 'triangle', vol: 0.08 },
      { freq: 1568, time: 0.03, dur: 0.12, type: 'triangle', vol: 0.1 },
    ]);
  },

  /** Shop: purchase complete — cash register cha-ching */
  playPurchase() {
    playSequence([
      { freq: 988, time: 0, dur: 0.06, type: 'triangle', vol: 0.07 },
      { freq: 1175, time: 0.04, dur: 0.06, type: 'triangle', vol: 0.07 },
      { freq: 1319, time: 0.08, dur: 0.1, type: 'triangle', vol: 0.08 },
      { freq: 1568, time: 0.12, dur: 0.2, type: 'sine', vol: 0.1 },
    ]);
  },

  /** Pinyin bubble: bubble pops — water pop */
  playBubblePop() {
    if (!enabled) return;
    const c = getContext();
    // Short noise burst + high chirp
    const osc = c.createOscillator();
    const gain = c.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(800, c.currentTime);
    osc.frequency.exponentialRampToValueAtTime(200, c.currentTime + 0.12);
    gain.gain.setValueAtTime(0.1, c.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, c.currentTime + 0.15);
    osc.connect(gain);
    gain.connect(c.destination);
    osc.start(c.currentTime);
    osc.stop(c.currentTime + 0.15);
  },

  /** Character build: character combines with glow — magical shimmer */
  playCharGlow() {
    playSequence([
      { freq: 523, time: 0, dur: 0.08, type: 'triangle', vol: 0.05 },
      { freq: 659, time: 0.06, dur: 0.08, type: 'triangle', vol: 0.05 },
      { freq: 784, time: 0.12, dur: 0.08, type: 'triangle', vol: 0.05 },
      { freq: 1047, time: 0.18, dur: 0.25, type: 'sine', vol: 0.08 },
      { freq: 1319, time: 0.24, dur: 0.3, type: 'sine', vol: 0.06 },
    ]);
  },

  /** Memory card: card flips — soft flip sound */
  playCardFlip() {
    playTone(600, 0.06, 'triangle', 0.06);
    setTimeout(() => playTone(500, 0.04, 'triangle', 0.04), 40);
  },

  // ============================
  // Pet emotion sounds (Sprint A: 5 new)
  // ============================

  /** Pet greets player on entering study area — cheerful rising triplet */
  playPetGreet() {
    playSequence([
      { freq: 523, time: 0, dur: 0.1, type: 'triangle', vol: 0.07 },
      { freq: 659, time: 0.08, dur: 0.1, type: 'triangle', vol: 0.07 },
      { freq: 784, time: 0.16, dur: 0.2, type: 'sine', vol: 0.1 },
    ]);
  },

  /** Pet encourages after wrong answer — warm gentle ascending */
  playPetEncourage() {
    playSequence([
      { freq: 349, time: 0, dur: 0.12, type: 'sine', vol: 0.05 },
      { freq: 440, time: 0.1, dur: 0.12, type: 'sine', vol: 0.05 },
      { freq: 523, time: 0.2, dur: 0.25, type: 'triangle', vol: 0.07 },
    ]);
  },

  /** Pet celebrates combo streak — excited "yay" style */
  playPetCelebrate() {
    playSequence([
      { freq: 659, time: 0, dur: 0.07, type: 'triangle', vol: 0.08 },
      { freq: 784, time: 0.05, dur: 0.07, type: 'triangle', vol: 0.08 },
      { freq: 988, time: 0.1, dur: 0.07, type: 'triangle', vol: 0.08 },
      { freq: 1175, time: 0.15, dur: 0.1, type: 'triangle', vol: 0.08 },
      { freq: 1319, time: 0.2, dur: 0.3, type: 'sine', vol: 0.12 },
    ]);
  },

  /** Pet sleepy after long idle — soft yawn + descending */
  playPetSleepy() {
    if (!enabled) return;
    const c = getContext();
    // Gentle yawn: rising then falling
    const osc = c.createOscillator();
    const gain = c.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(440, c.currentTime);
    osc.frequency.linearRampToValueAtTime(520, c.currentTime + 0.3);
    osc.frequency.linearRampToValueAtTime(350, c.currentTime + 0.8);
    gain.gain.setValueAtTime(0.05, c.currentTime);
    gain.gain.setValueAtTime(0.08, c.currentTime + 0.25);
    gain.gain.linearRampToValueAtTime(0, c.currentTime + 1.0);
    osc.connect(gain);
    gain.connect(c.destination);
    osc.start(c.currentTime);
    osc.stop(c.currentTime + 1.0);
  },

  /** Pet eats / enjoys shopping — happy munching */
  playPetEat() {
    playSequence([
      { freq: 600, time: 0, dur: 0.06, type: 'triangle', vol: 0.06 },
      { freq: 700, time: 0.08, dur: 0.06, type: 'triangle', vol: 0.06 },
      { freq: 650, time: 0.16, dur: 0.06, type: 'triangle', vol: 0.06 },
      { freq: 800, time: 0.24, dur: 0.15, type: 'sine', vol: 0.08 },
    ]);
  },
};
