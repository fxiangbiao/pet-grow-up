import { api } from './client';

export interface SubjectProgress {
  subject: string;
  worldLevel: number;
  totalStars: number;
  completedNodes: number;
  totalNodes: number;
  accuracyAverage: number;
}

export interface WorldNode {
  nodeId: number;
  name: string;
  description: string;
  difficulty: number;
  isUnlocked: boolean;
  isCompleted: boolean;
  starRating: number;
}

export interface WorldMap {
  subject: string;
  worldLevel: number;
  nodes: WorldNode[];
}

export interface QuestionDTO {
  sessionId: number;
  questionId: number;
  questionType: string;
  questionText: string;
  options: string | null;
  points: number;
  totalQuestions?: number;
  answeredCount?: number;
}

export interface AnswerResult {
  isCorrect: boolean;
  correctAnswer: string;
  explanation: string;
  pointsEarned: number;
  isSessionComplete: boolean;
  isLastQuestion: boolean;
  nextQuestion: QuestionDTO | null;
  sceneRewardItem?: string;
  sceneRewardCount?: number;
}

export interface SessionResult {
  sessionId: number;
  totalQuestions: number;
  correctAnswers: number;
  accuracy: number;
  energyEarned: number;
  streakMaintained: boolean;
  spiritReaction: string;
  maxCombo: number;
  bossDefeated: boolean;
  comboBonusEnergy: number;
}

export function getSubjectsProgress(): Promise<SubjectProgress[]> {
  return api.get<SubjectProgress[]>('/study/subjects');
}

export function getWorldMap(subject: string): Promise<WorldMap> {
  return api.get<WorldMap>(`/study/worlds/${subject}`);
}

export function startSession(data: {
  subject: string;
  sessionType: string;
  difficultyLevel: number;
  knowledgeNodeId: number;
}): Promise<QuestionDTO> {
  return api.post<QuestionDTO>('/exploration/sessions/start', data);
}

export function submitAnswer(data: {
  sessionId: number;
  questionId: number;
  answer: string;
  timeSpent: number;
}): Promise<AnswerResult> {
  return api.post<AnswerResult>(`/exploration/sessions/${data.sessionId}/submit`, data);
}

export function getSessionResult(sessionId: number, maxCombo: number = 0, bossDefeated: boolean = false): Promise<SessionResult> {
  return api.get<SessionResult>(`/exploration/sessions/${sessionId}/result?maxCombo=${maxCombo}&bossDefeated=${bossDefeated}`);
}
