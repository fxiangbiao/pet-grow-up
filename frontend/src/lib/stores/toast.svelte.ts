export interface ToastMessage {
  id: number;
  type: 'success' | 'error' | 'info';
  message: string;
}

let toasts = $state<ToastMessage[]>([]);
let nextId = 0;

export const toastStore = {
  get toasts() { return toasts; },

  show(type: ToastMessage['type'], message: string, duration = 3000) {
    const id = nextId++;
    toasts = [...toasts, { id, type, message }];
    setTimeout(() => {
      toasts = toasts.filter(t => t.id !== id);
    }, duration);
  },

  success(message: string) { this.show('success', message); },
  error(message: string) { this.show('error', message); },
  info(message: string) { this.show('info', message); }
};
