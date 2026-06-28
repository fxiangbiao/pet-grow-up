import type { ApiResponse } from '$lib/types/api';

const API_BASE = 'http://localhost:8080/api/v1';

export { API_BASE };

let accessToken: string | null = null;

export function setToken(token: string | null) {
  accessToken = token;
}

export function getToken(): string | null {
  return accessToken;
}

class ApiError extends Error {
  constructor(public code: number, message: string) {
    super(message);
  }
}

async function request<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>)
  };

  if (accessToken) {
    headers['Authorization'] = `Bearer ${accessToken}`;
  }

  // 10-second timeout to prevent hanging requests
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 10000);

  try {
    const res = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers,
      signal: controller.signal
    });
    clearTimeout(timeoutId);

    // 401/403 → clear auth & redirect to login (check BEFORE parsing JSON,
    // because Spring Security returns HTML for auth failures, not JSON)
    if (res.status === 401 || res.status === 403) {
      localStorage.removeItem('auth_user');
      localStorage.removeItem('auth_token');
      setToken(null);
      window.location.href = '/login?expired=1';
      throw new ApiError(res.status, '登录已过期，请重新登录');
    }

    let json: ApiResponse<T>;
    try {
      json = await res.json();
    } catch {
      // Non-JSON response body (e.g. Spring Security HTML error page)
      throw new ApiError(res.status, res.statusText || '请求失败');
    }

    if (!res.ok || json.code !== 200) {
      throw new ApiError(json.code, json.message || '请求失败');
    }

    return json.data;
  } catch (err: any) {
    clearTimeout(timeoutId);
    if (err.name === 'AbortError') {
      throw new ApiError(0, '请求超时，请确认后端服务是否启动');
    }
    throw err;
  }
}

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: 'POST', body: JSON.stringify(body) }),
  put: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: 'PUT', body: JSON.stringify(body) }),
  delete: <T>(path: string) => request<T>(path, { method: 'DELETE' })
};
