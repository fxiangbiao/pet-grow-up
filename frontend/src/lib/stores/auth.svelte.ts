import { setToken } from '$lib/api/client';
import { getProfile } from '$lib/api/user';
import type { UserDTO } from '$lib/types/api';

let user = $state<UserDTO | null>(null);
let isAuthenticated = $derived(user !== null);
let hasSpirit = $derived(user?.currentSpiritId != null);

function loadFromStorage() {
  if (typeof localStorage === 'undefined') return;
  const stored = localStorage.getItem('auth_user');
  const token = localStorage.getItem('auth_token');
  if (stored && token) {
    user = JSON.parse(stored);
    setToken(token);
  }
}

// Auto-initialize on module load to survive page refreshes
loadFromStorage();

export function getAccessToken(): string | null {
  if (typeof localStorage === 'undefined') return null;
  return localStorage.getItem('auth_token');
}

function saveToStorage(userData: UserDTO, token: string) {
  localStorage.setItem('auth_user', JSON.stringify(userData));
  localStorage.setItem('auth_token', token);
}

function clearStorage() {
  localStorage.removeItem('auth_user');
  localStorage.removeItem('auth_token');
}

export const authStore = {
  get user() { return user; },
  get isAuthenticated() { return isAuthenticated; },
  get hasSpirit() { return hasSpirit; },

  login(userData: UserDTO, token: string) {
    user = userData;
    setToken(token);
    saveToStorage(userData, token);
  },

  logout() {
    user = null;
    setToken(null);
    clearStorage();
    window.location.href = '/login';
  },

  init() {
    loadFromStorage();
  },

  async refreshProfile() {
    try {
      const profile = await getProfile();
      user = profile;
      const token = localStorage.getItem('auth_token');
      if (token) saveToStorage(profile, token);
    } catch {
      // silently fail
    }
  }
};
