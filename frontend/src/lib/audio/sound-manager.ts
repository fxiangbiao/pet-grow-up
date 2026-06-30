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
let masterVolume = 0.15;

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

/** Pentatonic scale frequencies (Chinese style) */
const PENTATONIC = [262, 294, 330, 392, 440]; // C D E G A
/** Major scale for magic feel */
const MAJOR = [262, 294, 330, 349, 392, 440, 494, 523];

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

// ── BGM generators per subject/scene ──

function playChineseExplore(c: AudioContext) {
  // Gentle pentatonic pad + slow melody (existing, refined)
  bgmOscillators.push(
    startPadOsc(c, 262, 0.06),
    startPadOsc(c, 392, 0.06),
  );
  const melody = [523, 587, 659, 784, 880, 1047, 880, 784, 659, 587];
  const cycleTime = 16;
  melody.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (cycleTime / melody.length), cycleTime / melody.length, 'triangle', 0.07, 0.01));
  });
}

function playChinesePinyin(c: AudioContext) {
  // Light ABC-song-inspired pentatonic with bubble-like staccato
  bgmOscillators.push(
    startPadOsc(c, 330, 0.05),
    startPadOsc(c, 440, 0.04),
  );
  const notes = [523, 587, 659, 523, 659, 784, 880, 784, 659, 523, 587, 659, 587, 523];
  const cycle = 12;
  notes.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (cycle / notes.length), cycle / notes.length, 'sine', 0.06, 0.008));
  });
}

function playChineseChar(c: AudioContext) {
  // Elegant guqin-style: slow pentatonic with wide reverb-like sustain
  bgmOscillators.push(
    startPadOsc(c, 196, 0.06),
    startPadOsc(c, 294, 0.05),
    startPadOsc(c, 392, 0.04),
  );
  const notes = [330, 392, 440, 523, 440, 392, 330, 294, 262];
  const cycle = 18;
  notes.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (cycle / notes.length), cycle / notes.length, 'triangle', 0.06, 0.012));
  });
}

function playMathExplore(c: AudioContext) {
  // Playful music-box arpeggios (existing, refined)
  bgmOscillators.push(
    startPadOsc(c, 262 * 0.5, 0.05),
    startPadOsc(c, 330 * 0.5, 0.05),
    startPadOsc(c, 392 * 0.5, 0.05),
  );
  const arpNotes = [523, 659, 784, 1047, 784, 659, 523, 392, 523, 659, 784, 880, 784, 659, 523, 392];
  const arpCycle = 12;
  arpNotes.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (arpCycle / arpNotes.length), arpCycle / arpNotes.length, 'triangle', 0.1, 0.015));
  });
}

function playMathClock(c: AudioContext) {
  // Tick-tock rhythm: steady low pulse + clock-like high ticks
  bgmOscillators.push(
    startPadOsc(c, 220, 0.04),
    startPadOsc(c, 330, 0.03),
  );
  // Tick-tock: alternating high clicks every beat
  const beat = 0.8; // seconds per tick (Lento)
  for (let i = 0; i < 30; i++) {
    const t = c.currentTime + i * beat;
    const isTick = i % 2 === 0;
    const freq = isTick ? 1200 : 1000;
    const osc = c.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq, t);
    const g = c.createGain();
    g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(0.04, t + 0.01);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.12);
    osc.connect(g);
    g.connect(bgmGain!);
    osc.start(t);
    osc.stop(t + 0.15);
    bgmOscillators.push(osc);
  }
  // Occasional chime
  [0, 4, 8, 12].forEach((beatIdx) => {
    const t = c.currentTime + beatIdx * beat + beat * 0.3;
    bgmOscillators.push(schedulePluck(c, 880, t, 0.6, 'triangle', 0.05, 0.005));
  });
}

function playMathShop(c: AudioContext) {
  // Lively marketplace: bouncy bass + coin-like high notes
  bgmOscillators.push(
    startPadOsc(c, 165, 0.05),
    startPadOsc(c, 330, 0.03),
  );
  const bouncyNotes = [392, 440, 523, 440, 392, 349, 330, 349, 392, 440, 523, 587, 523, 440, 392];
  const cycle = 10;
  bouncyNotes.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (cycle / bouncyNotes.length), cycle / bouncyNotes.length, 'triangle', 0.07, 0.01));
  });
  // Coin jingles
  for (let i = 0; i < 5; i++) {
    const t = c.currentTime + i * 2.5 + 0.5;
    [1047, 1319, 1568].forEach((freq, j) => {
      const osc = c.createOscillator();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(freq, t + j * 0.06);
      const g = c.createGain();
      g.gain.setValueAtTime(0, t + j * 0.06);
      g.gain.linearRampToValueAtTime(0.04, t + j * 0.06 + 0.01);
      g.gain.exponentialRampToValueAtTime(0.001, t + j * 0.06 + 0.15);
      osc.connect(g);
      g.connect(bgmGain!);
      osc.start(t + j * 0.06);
      osc.stop(t + j * 0.06 + 0.18);
      bgmOscillators.push(osc);
    });
  }
}

function playEnglishExplore(c: AudioContext) {
  // Dreamy Cmaj7 shimmer (existing, refined)
  bgmOscillators.push(
    startPadOsc(c, 262 * 0.5, 0.04),
    startPadOsc(c, 330 * 0.5, 0.04),
    startPadOsc(c, 392 * 0.5, 0.04),
    startPadOsc(c, 494 * 0.5, 0.04),
  );
  // Slow shimmering with vibrato
  [784, 880, 988, 784, 880].forEach((freq, i) => {
    const osc = c.createOscillator();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(freq, c.currentTime);
    const vib = c.createOscillator();
    vib.type = 'sine';
    vib.frequency.setValueAtTime(3.5 + i * 0.7, c.currentTime);
    const vibGain = c.createGain();
    vibGain.gain.setValueAtTime(8, c.currentTime);
    vib.connect(vibGain);
    vibGain.connect(osc.frequency);
    vib.start();
    const g = c.createGain();
    const t = c.currentTime + i * 3.5;
    const len = 6;
    g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(0.06, t + 1.5);
    g.gain.setValueAtTime(0.06, t + len - 1.5);
    g.gain.linearRampToValueAtTime(0, t + len);
    osc.connect(g);
    g.connect(bgmGain!);
    osc.start();
    bgmOscillators.push(osc, vib);
  });
}

function playEnglishLetters(c: AudioContext) {
  // ABC song inspired: simple major scale melody with bell chimes
  bgmOscillators.push(
    startPadOsc(c, 262, 0.05),
    startPadOsc(c, 392, 0.03),
  );
  const abcMelody = [262, 262, 294, 262, 349, 330, 262, 262, 294, 262, 392, 349, 262, 262, 523, 440, 349, 330, 294];
  const cycle = 16;
  abcMelody.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (cycle / abcMelody.length), cycle / abcMelody.length, 'sine', 0.06, 0.01));
  });
}

function playEnglishVocab(c: AudioContext) {
  // Cheerful groove: bouncy bass + happy arpeggios
  bgmOscillators.push(
    startPadOsc(c, 196, 0.05),
    startPadOsc(c, 330, 0.04),
  );
  const groove = [523, 494, 440, 392, 440, 494, 523, 587, 659, 587, 523, 440, 392, 349, 330, 294];
  const cycle = 12;
  groove.forEach((freq, i) => {
    bgmOscillators.push(schedulePluck(c, freq, c.currentTime + i * (cycle / groove.length), cycle / groove.length, 'triangle', 0.07, 0.012));
  });
  // Animal-call-like chirps
  for (let i = 0; i < 4; i++) {
    const t = c.currentTime + i * 3.5 + 1;
    const osc = c.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(1100 + i * 100, t);
    osc.frequency.exponentialRampToValueAtTime(1500 + i * 80, t + 0.08);
    const g = c.createGain();
    g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(0.04, t + 0.02);
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
  // Boss theme — tense, urgent
  // ============================

  playBossTheme() {
    if (!enabled) return;
    playSequence([
      { freq: 65.41, time: 0, dur: 2, type: 'sawtooth', vol: 0.08 },
      { freq: 130.81, time: 0, dur: 0.15, type: 'square', vol: 0.06 },
      { freq: 155.56, time: 0.3, dur: 0.15, type: 'square', vol: 0.06 },
      { freq: 130.81, time: 0.6, dur: 0.15, type: 'square', vol: 0.06 },
      { freq: 185.00, time: 0.9, dur: 0.25, type: 'square', vol: 0.06 },
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
      { freq: 329.63, time: 0, dur: 0.15, type: 'sawtooth', vol: 0.08 },
      { freq: 261.63, time: 0.1, dur: 0.3, type: 'sawtooth', vol: 0.08 },
      { freq: 196.00, time: 0.15, dur: 0.2, type: 'sine', vol: 0.05 },
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
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(65.41, c.currentTime);
    osc.frequency.exponentialRampToValueAtTime(130.81, c.currentTime + 2.5);
    gain.gain.setValueAtTime(0.06, c.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, c.currentTime + 3);
    osc.connect(gain);
    gain.connect(c.destination);
    osc.start(c.currentTime);
    osc.stop(c.currentTime + 3);
    playSequence([
      { freq: 98.00, time: 0.8, dur: 0.08, type: 'square', vol: 0.05 },
      { freq: 110.00, time: 1.5, dur: 0.08, type: 'square', vol: 0.05 },
      { freq: 130.81, time: 2.0, dur: 0.15, type: 'square', vol: 0.07 },
    ]);
  },

  playBossAttack() {
    playSequence([
      { freq: 440, time: 0, dur: 0.08, type: 'sawtooth', vol: 0.1 },
      { freq: 330, time: 0.06, dur: 0.1, type: 'sawtooth', vol: 0.08 },
      { freq: 220, time: 0.12, dur: 0.2, type: 'square', vol: 0.07 },
    ]);
  },

  playBossPhaseChange() {
    playSequence([
      { freq: 523, time: 0, dur: 0.07, type: 'triangle' },
      { freq: 659, time: 0.06, dur: 0.07, type: 'triangle' },
      { freq: 784, time: 0.12, dur: 0.12, type: 'triangle' },
    ]);
  },

  playBossShatter() {
    playSequence([
      { freq: 1319, time: 0, dur: 0.06, type: 'square', vol: 0.08 },
      { freq: 1175, time: 0.03, dur: 0.06, type: 'square', vol: 0.07 },
      { freq: 988, time: 0.06, dur: 0.08, type: 'square', vol: 0.06 },
      { freq: 784, time: 0.09, dur: 0.1, type: 'square', vol: 0.05 },
      { freq: 523, time: 0.12, dur: 0.3, type: 'triangle', vol: 0.06 },
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
