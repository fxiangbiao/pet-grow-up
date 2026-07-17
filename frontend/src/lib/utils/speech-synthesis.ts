// Web Speech API - Speech Synthesis wrapper

export const isSpeechSynthesisSupported = 'speechSynthesis' in window;

let currentUtterance: SpeechSynthesisUtterance | null = null;

export function speak(
  text: string,
  options: {
    lang?: string;
    rate?: number;
    pitch?: number;
    onEnd?: () => void;
    onStart?: () => void;
  } = {}
) {
  if (!isSpeechSynthesisSupported) return;

  // Cancel any ongoing speech
  window.speechSynthesis.cancel();

  const utterance = new SpeechSynthesisUtterance(text);
  utterance.lang = options.lang || 'zh-CN';
  utterance.rate = options.rate || 1.1; // Slightly faster for child-friendly
  utterance.pitch = options.pitch || 1.3; // Slightly higher pitch

  utterance.onstart = () => options.onStart?.();
  utterance.onend = () => {
    currentUtterance = null;
    options.onEnd?.();
  };

  currentUtterance = utterance;
  window.speechSynthesis.speak(utterance);
}

export function stopSpeaking() {
  window.speechSynthesis.cancel();
  currentUtterance = null;
}

export function isSpeaking(): boolean {
  return window.speechSynthesis.speaking;
}