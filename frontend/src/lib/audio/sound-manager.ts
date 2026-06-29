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
  // Subject-specific BGM (procedural music box / cartoon style)
  // ============================

  /**
   * Start background music for a subject.
   * Uses only sine & triangle waves for warm, pleasant tones — no harsh square/sawtooth.
   *
   * Style per subject:
   * - chinese: gentle pentatonic melody with soft harmonic pads
   * - math: playful music-box arpeggios with bell-like tones
   * - english: dreamy ambient with slow shimmering chords
   */
  playBGM(subject: string) {
    if (!enabled) return;
    if (currentBgmSubject === subject) return;
    this.stopBGM();
    currentBgmSubject = subject;

    const c = getContext();
    bgmGain = c.createGain();
    bgmGain.gain.setValueAtTime(0.04, c.currentTime); // quiet ambient level
    bgmGain.connect(c.destination);

    if (subject === 'chinese') {
      // ── Gentle pentatonic melody loop ──
      // Soft sine-wave harmonic pad (root + fifth)
      for (let oct = 0; oct < 2; oct++) {
        [262, 392].forEach(freq => {
          const osc = c.createOscillator();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(freq * (0.5 + oct * 0.5), c.currentTime);
          const g = c.createGain();
          g.gain.setValueAtTime(0.06, c.currentTime);
          osc.connect(g);
          g.connect(bgmGain);
          osc.start();
          bgmOscillators.push(osc);
        });
      }

      // Slow pentatonic melody cycle (C D E G A C')
      const melody = [523, 587, 659, 784, 880, 1047, 880, 784, 659, 587];
      const cycleTime = 16; // seconds per full loop
      melody.forEach((freq, i) => {
        const osc = c.createOscillator();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(freq, c.currentTime + i * (cycleTime / melody.length));
        // Each note fades in/out smoothly
        const g = c.createGain();
        const noteStart = c.currentTime + i * (cycleTime / melody.length);
        const noteLen = cycleTime / melody.length;
        g.gain.setValueAtTime(0, noteStart);
        g.gain.linearRampToValueAtTime(0.07, noteStart + noteLen * 0.2);
        g.gain.setValueAtTime(0.07, noteStart + noteLen * 0.7);
        g.gain.linearRampToValueAtTime(0, noteStart + noteLen);
        osc.connect(g);
        g.connect(bgmGain);
        osc.start(noteStart);
        osc.stop(noteStart + noteLen + 0.1);
        bgmOscillators.push(osc);
      });

    } else if (subject === 'math') {
      // ── Playful music-box arpeggios ──
      // Soft bell-like pad
      [262, 330, 392].forEach((freq, i) => {
        const osc = c.createOscillator();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq * 0.5, c.currentTime);
        const g = c.createGain();
        g.gain.setValueAtTime(0.05, c.currentTime);
        osc.connect(g);
        g.connect(bgmGain);
        osc.start();
        bgmOscillators.push(osc);
      });

      // Ascending/descending arpeggio loop — music box style
      const arpNotes = [523, 659, 784, 1047, 784, 659, 523, 392, 523, 659, 784, 880, 784, 659, 523, 392];
      const arpCycle = 12; // seconds
      arpNotes.forEach((freq, i) => {
        const osc = c.createOscillator();
        osc.type = 'triangle'; // soft, bell-like
        osc.frequency.setValueAtTime(freq, c.currentTime + i * (arpCycle / arpNotes.length));

        const g = c.createGain();
        const t = c.currentTime + i * (arpCycle / arpNotes.length);
        const len = arpCycle / arpNotes.length;
        // Pluck-like envelope: quick attack, fast decay, quiet sustain
        g.gain.setValueAtTime(0, t);
        g.gain.linearRampToValueAtTime(0.1, t + len * 0.05);
        g.gain.exponentialRampToValueAtTime(0.015, t + len * 0.4);
        g.gain.linearRampToValueAtTime(0, t + len);

        osc.connect(g);
        g.connect(bgmGain);
        osc.start(t);
        osc.stop(t + len + 0.1);
        bgmOscillators.push(osc);
      });

    } else if (subject === 'english') {
      // ── Dreamy ambient with slow shimmering chords ──
      // Gentle chord pad: Cmaj7 (C E G B)
      [262, 330, 392, 494].forEach(freq => {
        const osc = c.createOscillator();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq * 0.5, c.currentTime);
        const g = c.createGain();
        g.gain.setValueAtTime(0.04, c.currentTime);
        osc.connect(g);
        g.connect(bgmGain);
        osc.start();
        bgmOscillators.push(osc);
      });

      // Slow shimmering high notes with gentle vibrato
      [784, 880, 988, 784, 880].forEach((freq, i) => {
        const osc = c.createOscillator();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(freq, c.currentTime);

        // Soft vibrato
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
        g.connect(bgmGain);
        osc.start();
        bgmOscillators.push(osc, vib);
      });
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
