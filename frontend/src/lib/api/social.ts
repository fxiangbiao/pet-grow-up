import { api } from './client';
import type { FriendDTO, FriendRequestDTO, UserSearchResult, LeaderboardEntry } from '$lib/types/api';

// ---- Friends ----

export function getFriends(): Promise<FriendDTO[]> {
  return api.get<FriendDTO[]>('/social/friends');
}

export function getIncomingRequests(): Promise<FriendRequestDTO[]> {
  return api.get<FriendRequestDTO[]>('/social/friends/requests');
}

export function getSentRequests(): Promise<FriendRequestDTO[]> {
  return api.get<FriendRequestDTO[]>('/social/friends/requests/sent');
}

export function sendFriendRequest(receiverId: number): Promise<null> {
  return api.post<null>('/social/friends/requests', { receiverId });
}

export function acceptFriendRequest(requestId: number): Promise<null> {
  return api.post<null>(`/social/friends/requests/${requestId}/accept`);
}

export function rejectFriendRequest(requestId: number): Promise<null> {
  return api.post<null>(`/social/friends/requests/${requestId}/reject`);
}

export function removeFriend(friendId: number): Promise<null> {
  return api.delete<null>(`/social/friends/${friendId}`);
}

export function searchUsers(q: string): Promise<UserSearchResult[]> {
  return api.get<UserSearchResult[]>(`/social/friends/search?q=${encodeURIComponent(q)}`);
}

// ---- Leaderboard ----

export function getLeaderboard(type: string = 'total_energy', limit: number = 20): Promise<LeaderboardEntry[]> {
  return api.get<LeaderboardEntry[]>(`/social/leaderboard?type=${type}&limit=${limit}`);
}
