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
  parentId: number | null;
  children: WorldNode[];
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

export interface RandomEventInfo {
  eventKey: string;
  name: string;
  description: string;
  eventType: string;
  iconUrl: string;
  displayText: string;
  bonusEnergy: number;
  rewardItemName: string;
  affectionGained: number;
  isDoubleReward: boolean;
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
  randomEvent?: RandomEventInfo | null;
}

// Teaching content types
export interface TeachingCard {
  id: number;
  type: 'intro' | 'concept' | 'steps' | 'example' | 'mnemonic' | 'quiz';
  title: string;
  content?: string;
  steps?: string[];
  spriteAction?: string;
  illustration?: string;
  animation?: string;
  interactive?: string;
}

export interface TeachingContent {
  cards: TeachingCard[];
}

export function getSubjectsProgress(): Promise<SubjectProgress[]> {
  return api.get<SubjectProgress[]>('/study/subjects');
}

export function getWorldMap(subject: string): Promise<WorldMap> {
  return api.get<WorldMap>(`/study/worlds/${subject}`);
}

export function getTeachingContent(nodeId: number): Promise<TeachingContent | null> {
  return api.get<TeachingContent | null>(`/study/nodes/${nodeId}/teaching`);
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


export function generateVariant(nodeId: number, originalQuestionId: number): Promise<any> {
  return api.get<any>(`/study/nodes/${nodeId}/generate-variant?originalQuestionId=${originalQuestionId}`);
}

export function assessExplanation(nodeId: number, text: string): Promise<any> {
  return api.post<any>(`/study/nodes/${nodeId}/explain`, { text });
}
