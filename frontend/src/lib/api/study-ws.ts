import { getAccessToken } from '$lib/stores/auth.svelte';
import { API_BASE } from '$lib/api/client';

type MessageHandler = (data: any) => void;

interface PendingSubscribe {
  topic: string;
  handler: MessageHandler;
}

let client: any = null;
let connected = false;
let pending: PendingSubscribe[] = [];
let reconnectTimer: ReturnType<typeof setTimeout> | null = null;

function getSockJs(): Promise<any> {
  return import('sockjs-client');
}

function getStompJs(): Promise<any> {
  return import('@stomp/stompjs');
}

export async function connect(): Promise<void> {
  if (connected) return;

  const [SockJS, { Client }] = await Promise.all([getSockJs(), getStompJs()]);

  const token = getAccessToken();
  const wsBase = API_BASE.replace('/api/v1', '');
  const socket = new SockJS.default(`${wsBase}/ws/study`);

  client = new Client({
    webSocketFactory: () => socket,
    connectHeaders: token ? { Authorization: `Bearer ${token}` } : {},
    debug: () => {},
    reconnectDelay: 5000,
    onConnect: () => {
      connected = true;
      for (const p of pending) {
        subscribeTopic(p.topic, p.handler);
      }
      pending = [];
    },
    onDisconnect: () => {
      connected = false;
    },
    onStompError: () => {
      connected = false;
      scheduleReconnect();
    },
  });

  client.activate();
}

function scheduleReconnect() {
  if (reconnectTimer) clearTimeout(reconnectTimer);
  reconnectTimer = setTimeout(() => {
    connect();
  }, 5000);
}

function subscribeTopic(topic: string, handler: MessageHandler): (() => void) | null {
  if (!client || !connected) {
    pending.push({ topic, handler });
    return null;
  }
  const subscription = client.subscribe(topic, (message: any) => {
    try {
      handler(JSON.parse(message.body));
    } catch {
      handler(message.body);
    }
  });
  return () => {
    try { subscription.unsubscribe(); } catch {}
  };
}

export function subscribeToSession(sessionId: number, handlers: {
  onProgress?: (data: any) => void;
  onComplete?: (data: any) => void;
}): () => void {
  connect();

  const unsubs: (() => void)[] = [];

  if (handlers.onProgress) {
    const unsub = subscribeTopic(`/topic/session/${sessionId}/progress`, handlers.onProgress);
    if (unsub) unsubs.push(unsub);
  }

  if (handlers.onComplete) {
    const unsub = subscribeTopic(`/topic/session/${sessionId}/complete`, handlers.onComplete);
    if (unsub) unsubs.push(unsub);
  }

  return () => {
    unsubs.forEach(fn => fn());
  };
}

export function disconnect(): void {
  if (reconnectTimer) clearTimeout(reconnectTimer);
  if (client) {
    try { client.deactivate(); } catch {}
    client = null;
  }
  connected = false;
  pending = [];
}
