/**
 * Programmatic sound manager using Web Audio API.
 * No external audio files needed — generates tones via oscillators.
 * AudioContext is initialized on first user interaction to comply with autoplay policies.
 *
 * v2: Added BGM (per-subject ambient loops), boss theme, enhanced effects.
 */

let ctx: AudioContext | null = null;
let enabled = true;
let bgmGain: GainNode | null = null;
let bgmOscillators: OscillatorNode[] = [];
let currentBgmSubject = '';
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
  // Subject-specific BGM
  // ============================

  /**
   * Start background music for a subject.
   * Each subject has a distinct musical style:
   * - chinese: pentatonic ambient (古典五声音阶)
   * - math: electronic arpeggiated
   * - english: magical shimmer
   */
  playBGM(subject: string) {
    if (!enabled) return;
    if (currentBgmSubject === subject) return;
    this.stopBGM();
    currentBgmSubject = subject;

    const c = getContext();
    bgmGain = c.createGain();
    bgmGain.gain.setValueAtTime(0.035, c.currentTime); // very quiet ambient
    bgmGain.connect(c.destination);

    if (subject === 'chinese') {
      // Pentatonic ambient — slow cycling through notes
      for (let i = 0; i < 3; i++) {
        const osc = c.createOscillator();
        osc.type = 'sine';
        const baseFreq = PENTATONIC[i % PENTATONIC.length];
        osc.frequency.setValueAtTime(baseFreq * 0.5, c.currentTime);

        // Slow LFO-style pitch drift
        const lfo = c.createOscillator();
        lfo.frequency.setValueAtTime(0.05 + i * 0.02, c.currentTime);
        const lfoGain = c.createGain();
        lfoGain.gain.setValueAtTime(3 + i * 2, c.currentTime);
        lfo.connect(lfoGain);
        lfoGain.connect(osc.frequency);
        lfo.start();

        const noteGain = c.createGain();
        noteGain.gain.setValueAtTime(0.15, c.currentTime);
        osc.connect(noteGain);
        noteGain.connect(bgmGain);
        osc.start();
        bgmOscillators.push(osc, lfo);
      }
    } else if (subject === 'math') {
      // Arpeggiated tech — short repeating pulses
      const pulseRate = 4; // Hz
      for (let i = 0; i < 4; i++) {
        const osc = c.createOscillator();
        osc.type = 'square';
        const freqIdx = (i * 2) % MAJOR.length;
        osc.frequency.setValueAtTime(MAJOR[freqIdx] * 0.25, c.currentTime);

        const ampEnv = c.createGain();
        ampEnv.gain.setValueAtTime(0, c.currentTime);
        // Pulse modulation
        const lfo = c.createOscillator();
        lfo.type = 'sawtooth';
        lfo.frequency.setValueAtTime(pulseRate + i * 0.5, c.currentTime);
        const lfoGain = c.createGain();
        lfoGain.gain.setValueAtTime(0.12, c.currentTime);
        lfo.connect(lfoGain);
        lfoGain.connect(ampEnv.gain);
        lfo.start();

        osc.connect(ampEnv);
        ampEnv.connect(bgmGain);
        osc.start();
        bgmOscillators.push(osc, lfo);
      }
    } else if (subject === 'english') {
      // Magical shimmer — high soft tones with vibrato
      for (let i = 0; i < 5; i++) {
        const osc = c.createOscillator();
        osc.type = 'triangle';
        const freq = 300 + i * 100;
        osc.frequency.setValueAtTime(freq * 1.5, c.currentTime);

        // Vibrato
        const vib = c.createOscillator();
        vib.frequency.setValueAtTime(5 + i * 0.5, c.currentTime);
        const vibGain = c.createGain();
        vibGain.gain.setValueAtTime(15, c.currentTime);
        vib.connect(vibGain);
        vibGain.connect(osc.frequency);
        vib.start();

        const noteGain = c.createGain();
        noteGain.gain.setValueAtTime(0.1, c.currentTime);
        osc.connect(noteGain);
        noteGain.connect(bgmGain);
        osc.start();
        bgmOscillators.push(osc, vib);
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
    // Low rumble + urgent high pulses
    playSequence([
      { freq: 65.41, time: 0, dur: 2, type: 'sawtooth', vol: 0.08 },  // low C2 rumble
      { freq: 130.81, time: 0, dur: 0.15, type: 'square', vol: 0.06 }, // C3 stab
      { freq: 155.56, time: 0.3, dur: 0.15, type: 'square', vol: 0.06 }, // Eb3
      { freq: 130.81, time: 0.6, dur: 0.15, type: 'square', vol: 0.06 },
      { freq: 185.00, time: 0.9, dur: 0.25, type: 'square', vol: 0.06 }, // F#3
    ]);
  },

  /** Stop boss theme (just stop BGM, same pool) */
  stopBossTheme() {
    // Boss theme is a one-shot effect, not continuous
  },

  // ============================
  // Enhanced sound effects
  // ============================

  /** Ascending two-note: C5 → E5 (pitch increases with combo) */
  playCorrect(comboLevel = 0) {
    const baseFreq = 523.25 + Math.min(comboLevel * 30, 200); // pitch climbs with combo
    playSequence([
      { freq: baseFreq, time: 0, dur: 0.12, type: 'sine' },
      { freq: baseFreq * 1.25, time: 0.1, dur: 0.25, type: 'sine' },
    ]);
  },

  /** Descending two-note with extra rumble */
  playWrong() {
    playSequence([
      { freq: 329.63, time: 0, dur: 0.15, type: 'sawtooth', vol: 0.08 },
      { freq: 261.63, time: 0.1, dur: 0.3, type: 'sawtooth', vol: 0.08 },
      { freq: 196.00, time: 0.15, dur: 0.2, type: 'sine', vol: 0.05 }, // low thud
    ]);
  },

  /** Ascending arpeggio: C5 → E5 → G5 → C6 */
  playComplete() {
    playSequence([
      { freq: 523.25, time: 0, dur: 0.12 },
      { freq: 659.25, time: 0.1, dur: 0.12 },
      { freq: 783.99, time: 0.2, dur: 0.12 },
      { freq: 1046.50, time: 0.3, dur: 0.35 },
    ]);
  },

  /** Bright arpeggio with triangle wave — richer for celebrations */
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

  /** Short click sound */
  playClick() {
    playTone(800, 0.05, 'square', 0.05);
  },

  /** Light ascending: C5 → D5 → E5 */
  playFeed() {
    playSequence([
      { freq: 523.25, time: 0, dur: 0.1 },
      { freq: 587.33, time: 0.08, dur: 0.1 },
      { freq: 659.25, time: 0.16, dur: 0.2 },
    ]);
  },

  /** Grand ascending arpeggio with harmonics */
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

  /** Treasure found sound — bright sparkle */
  playTreasure() {
    playSequence([
      { freq: 784, time: 0, dur: 0.08, type: 'triangle' },
      { freq: 988, time: 0.06, dur: 0.08, type: 'triangle' },
      { freq: 1175, time: 0.12, dur: 0.08, type: 'triangle' },
      { freq: 1319, time: 0.18, dur: 0.2, type: 'triangle' },
    ]);
  },

  /** Boss defeated — triumphant fanfare */
  playBossDefeated() {
    playSequence([
      { freq: 523.25, time: 0, dur: 0.15, type: 'triangle' },
      { freq: 659.25, time: 0.12, dur: 0.15, type: 'triangle' },
      { freq: 783.99, time: 0.24, dur: 0.15, type: 'triangle' },
      { freq: 1046.50, time: 0.36, dur: 0.4, type: 'triangle' },
      { freq: 1318.51, time: 0.5, dur: 0.5, type: 'sine' },
    ]);
  },

  /** Boss charge-up: low frequency ramp for tension */
  playBossChargeUp() {
    if (!enabled) return;
    const c = getContext();
    // Low rumble that rises in pitch over 2.5s
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
    // Stabs at intervals for urgency
    playSequence([
      { freq: 98.00, time: 0.8, dur: 0.08, type: 'square', vol: 0.05 },
      { freq: 110.00, time: 1.5, dur: 0.08, type: 'square', vol: 0.05 },
      { freq: 130.81, time: 2.0, dur: 0.15, type: 'square', vol: 0.07 },
    ]);
  },

  /** Boss attacks player: harsh descending stab */
  playBossAttack() {
    playSequence([
      { freq: 440, time: 0, dur: 0.08, type: 'sawtooth', vol: 0.1 },
      { freq: 330, time: 0.06, dur: 0.1, type: 'sawtooth', vol: 0.08 },
      { freq: 220, time: 0.12, dur: 0.2, type: 'square', vol: 0.07 },
    ]);
  },

  /** Boss phase transition: quick ascending signal */
  playBossPhaseChange() {
    playSequence([
      { freq: 523, time: 0, dur: 0.07, type: 'triangle' },
      { freq: 659, time: 0.06, dur: 0.07, type: 'triangle' },
      { freq: 784, time: 0.12, dur: 0.12, type: 'triangle' },
    ]);
  },

  /** Boss shatter: glass-break-like descending cluster */
  playBossShatter() {
    playSequence([
      { freq: 1319, time: 0, dur: 0.06, type: 'square', vol: 0.08 },
      { freq: 1175, time: 0.03, dur: 0.06, type: 'square', vol: 0.07 },
      { freq: 988, time: 0.06, dur: 0.08, type: 'square', vol: 0.06 },
      { freq: 784, time: 0.09, dur: 0.1, type: 'square', vol: 0.05 },
      { freq: 523, time: 0.12, dur: 0.3, type: 'triangle', vol: 0.06 },
    ]);
  },

  /** Spirit happy chirp: short rising tone */
  playSpiritHappy() {
    const pitch = 600 + Math.random() * 200;
    playSequence([
      { freq: pitch, time: 0, dur: 0.08 },
      { freq: pitch * 1.25, time: 0.06, dur: 0.12 },
    ]);
  },

  /** Spirit sad: descending slide */
  playSpiritSad() {
    playSequence([
      { freq: 500, time: 0, dur: 0.12, type: 'sine' },
      { freq: 380, time: 0.1, dur: 0.2, type: 'sine' },
    ]);
  },
};
