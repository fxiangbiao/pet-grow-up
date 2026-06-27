import { api } from './client';
import type { ChapterDTO } from '$lib/types/api';

export interface StudyResult {
  passed: boolean;
  totalQuestions: number;
  correctAnswers: number;
  accuracy: number;
  maxCombo: number;
  bossDefeated: boolean;
  treasuresFound: number;
  finalHp: number;
}

export function getChapters(): Promise<ChapterDTO[]> {
  return api.get<ChapterDTO[]>('/story/chapters');
}

export function completeChapter(chapterId: number): Promise<null> {
  return api.post<null>(`/story/chapters/${chapterId}/complete`);
}

export function claimChapterReward(chapterId: number): Promise<null> {
  return api.post<null>(`/story/chapters/${chapterId}/claim`);
}

export function checkStoryConditions(): Promise<null> {
  return api.post<null>('/story/check');
}
