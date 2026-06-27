import { api } from './client';
import type { AuthResponse, LoginRequest, RegisterRequest } from '$lib/types/api';

export function login(data: LoginRequest): Promise<AuthResponse> {
  return api.post<AuthResponse>('/auth/login', data);
}

export function register(data: RegisterRequest): Promise<AuthResponse> {
  return api.post<AuthResponse>('/auth/register', data);
}

export function refreshToken(token: string): Promise<AuthResponse> {
  return api.post<AuthResponse>('/auth/refresh', { refreshToken: token });
}
