// Web Speech API - Speech Recognition wrapper
const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;

export const isSpeechRecognitionSupported = !!SpeechRecognition;

let recognition: any = null;

export function createRecognition(lang: string = 'zh-CN') {
  if (!SpeechRecognition) return null;
  const rec = new SpeechRecognition();
  rec.lang = lang;
  rec.interimResults = true;
  rec.continuous = false;
  rec.maxAlternatives = 1;
  return rec;
}

export function startListening(
  lang: string = 'zh-CN',
  onResult: (text: string, isFinal: boolean) => void,
  onError?: (error: string) => void,
  onEnd?: () => void
): (() => void) | null {
  if (!SpeechRecognition) {
    onError?.('Speech recognition not supported');
    return null;
  }

  recognition = createRecognition(lang);
  if (!recognition) return null;

  recognition.onresult = (event: any) => {
    let transcript = '';
    let isFinal = false;
    for (let i = event.resultIndex; i < event.results.length; i++) {
      transcript += event.results[i][0].transcript;
      isFinal = event.results[i].isFinal;
    }
    onResult(transcript, isFinal);
  };

  recognition.onerror = (event: any) => {
    onError?.(event.error);
  };

  recognition.onend = () => {
    onEnd?.();
  };

  try {
    recognition.start();
  } catch (e) {
    onError?.('Failed to start recognition');
  }

  return () => {
    try { recognition?.stop(); } catch {}
  };
}

export function stopListening() {
  try { recognition?.stop(); } catch {}
}