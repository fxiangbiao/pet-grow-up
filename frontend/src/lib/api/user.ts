import { api } from './client';
import type { UserDTO } from '$lib/types/api';

export function getProfile(): Promise<UserDTO> {
  return api.get<UserDTO>('/users/profile');
}
