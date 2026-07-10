// frontend/src/lib/api/admin.ts
import { api } from './client';

const BASE = '/admin';

export interface QuestionFilter {
  subject?: string;
  gradeLevel?: number;
  questionType?: string;
  knowledgeNodeId?: number;
  difficulty?: number;
  keyword?: string;
  page?: number;
  size?: number;
}

export interface QuestionRow {
  id: number;
  questionType: string;
  difficulty: number;
  questionText: string;
  options: string | null;
  correctAnswer: string;
  explanation: string | null;
  points: number;
  knowledgeNodeId: number;
  knowledgeNodeName: string | null;
  subject: string | null;
  gradeLevel: number | null;
  createdAt: string;
}

export interface QuestionPage {
  items: QuestionRow[];
  total: number;
  page: number;
  size: number;
}

export interface CreateQuestion {
  knowledgeNodeId: number;
  questionType: string;
  difficulty?: number;
  questionText: string;
  options?: string;
  correctAnswer: string;
  explanation?: string;
  points?: number;
}

export interface NodeTreeItem {
  id: number;
  nodeKey: string;
  name: string;
  description: string | null;
  difficulty: number;
  gradeLevel: number;
  orderIndex: number;
  subject: string;
  parentNodeId: number | null;
  questionCount: number;
  children: NodeTreeItem[] | null;
}

export interface CreateNode {
  subject: string;
  nodeKey: string;
  name: string;
  description?: string;
  difficulty?: number;
  gradeLevel?: number;
  parentNodeId?: number;
  prerequisiteNodes?: string;
  orderIndex?: number;
}

export interface ReorderNodes {
  parentNodeId?: number;
  subject: string;
  orderedNodeIds: number[];
}

export interface BatchImportResult {
  successCount: number;
  errorCount: number;
  errors: string[];
}

// ---- User management ----

export interface UserFilter {
  role?: string;
  keyword?: string;
  page?: number;
  size?: number;
}

export interface UserRow {
  id: number;
  username: string;
  email: string;
  nickname: string | null;
  avatarUrl: string | null;
  role: string;
  currentEnergy: number;
  totalEnergy: number;
  consecutiveStudyDays: number;
  lastStudyDate: string | null;
  lastLoginDate: string | null;
  createdAt: string;
}

export interface UserPage {
  items: UserRow[];
  total: number;
  page: number;
  size: number;
}

// ---- Item management ----

export interface ItemFilter {
  category?: string;
  keyword?: string;
  page?: number;
  size?: number;
}

export interface ItemRow {
  id: number;
  itemKey: string;
  name: string;
  description: string | null;
  category: string;
  effectType: string | null;
  effectValue: number;
  price: number;
  iconUrl: string | null;
  isConsumable: boolean;
  isPurchasable: boolean;
  displayOrder: number;
  createdAt: string;
}

export interface ItemPage {
  items: ItemRow[];
  total: number;
  page: number;
  size: number;
}

export interface CreateItemDef {
  itemKey: string;
  name: string;
  description?: string;
  category: string;
  effectType?: string;
  effectValue?: number;
  price?: number;
  iconUrl?: string;
  isConsumable?: boolean;
  isPurchasable?: boolean;
  displayOrder?: number;
}

// ---- Statistics ----

export interface Overview {
  totalUsers: number;
  totalStudents: number;
  totalAdmins: number;
  totalQuestions: number;
  totalStudySessions: number;
  totalEnergyEarned: number;
  totalEnergySpent: number;
  todayActiveUsers: number;
}

export interface TimeSeriesPoint {
  date: string;
  value: number;
}

export interface StudyStats {
  dailySessions: TimeSeriesPoint[];
  dailyActiveUsers: TimeSeriesPoint[];
  avgAccuracy: TimeSeriesPoint[];
}

export interface SourceBreakdown {
  source: string;
  totalAmount: number;
  count: number;
}

export interface EnergyStats {
  dailyEarned: TimeSeriesPoint[];
  dailySpent: TimeSeriesPoint[];
  bySource: SourceBreakdown[];
}

export interface AchievementStatRow {
  key: string;
  name: string;
  category: string;
  rarity: string;
  unlockedCount: number;
  totalUsers: number;
  unlockRate: number;
}

export interface AchievementStats {
  achievements: AchievementStatRow[];
}

function buildQuery(filter: QuestionFilter): string {
  const params = new URLSearchParams();
  if (filter.subject) params.set('subject', filter.subject);
  if (filter.gradeLevel) params.set('gradeLevel', String(filter.gradeLevel));
  if (filter.questionType) params.set('questionType', filter.questionType);
  if (filter.knowledgeNodeId) params.set('knowledgeNodeId', String(filter.knowledgeNodeId));
  if (filter.difficulty) params.set('difficulty', String(filter.difficulty));
  if (filter.keyword) params.set('keyword', filter.keyword);
  params.set('page', String(filter.page ?? 1));
  params.set('size', String(filter.size ?? 20));
  return params.toString();
}

export const adminApi = {
  // Questions
  listQuestions: (filter: QuestionFilter = {}) =>
    api.get<QuestionPage>(`${BASE}/questions?${buildQuery(filter)}`),

  getQuestion: (id: number) =>
    api.get<CreateQuestion & { id: number }>(`${BASE}/questions/${id}`),

  createQuestion: (data: CreateQuestion) =>
    api.post<{ id: number }>(`${BASE}/questions`, data),

  updateQuestion: (id: number, data: Partial<CreateQuestion>) =>
    api.put<void>(`${BASE}/questions/${id}`, data),

  deleteQuestion: (id: number) =>
    api.delete<void>(`${BASE}/questions/${id}`),

  batchImport: (questions: CreateQuestion[]) =>
    api.post<BatchImportResult>(`${BASE}/questions/batch-import`, questions),

  // Knowledge Nodes
  getNodeTree: () =>
    api.get<NodeTreeItem[]>(`${BASE}/nodes/tree`),

  getNode: (id: number) =>
    api.get<CreateNode & { id: number }>(`${BASE}/nodes/${id}`),

  createNode: (data: CreateNode) =>
    api.post<{ id: number }>(`${BASE}/nodes`, data),

  updateNode: (id: number, data: Partial<CreateNode>) =>
    api.put<void>(`${BASE}/nodes/${id}`, data),

  deleteNode: (id: number) =>
    api.delete<void>(`${BASE}/nodes/${id}`),

  reorderNodes: (data: ReorderNodes) =>
    api.put<void>(`${BASE}/nodes/reorder`, data),

  // Users
  listUsers: (filter: UserFilter = {}) => {
    const params = new URLSearchParams();
    if (filter.role) params.set('role', filter.role);
    if (filter.keyword) params.set('keyword', filter.keyword);
    params.set('page', String(filter.page ?? 1));
    params.set('size', String(filter.size ?? 20));
    return api.get<UserPage>(`${BASE}/users?${params.toString()}`);
  },

  getUser: (id: number) =>
    api.get<UserRow>(`${BASE}/users/${id}`),

  updateUserRole: (id: number, role: string) =>
    api.put<void>(`${BASE}/users/${id}/role`, { role }),

  resetUserPassword: (id: number, newPassword?: string) =>
    api.post<void>(`${BASE}/users/${id}/reset-password`, newPassword ? { newPassword } : {}),

  // Items
  listItems: (filter: ItemFilter = {}) => {
    const params = new URLSearchParams();
    if (filter.category) params.set('category', filter.category);
    if (filter.keyword) params.set('keyword', filter.keyword);
    params.set('page', String(filter.page ?? 1));
    params.set('size', String(filter.size ?? 20));
    return api.get<ItemPage>(`${BASE}/items?${params.toString()}`);
  },

  getItem: (id: number) =>
    api.get<CreateItemDef & { id: number }>(`${BASE}/items/${id}`),

  createItem: (data: CreateItemDef) =>
    api.post<{ id: number }>(`${BASE}/items`, data),

  updateItem: (id: number, data: Partial<CreateItemDef>) =>
    api.put<void>(`${BASE}/items/${id}`, data),

  deleteItem: (id: number) =>
    api.delete<void>(`${BASE}/items/${id}`),

  // Statistics
  getOverview: () =>
    api.get<Overview>(`${BASE}/statistics/overview`),

  getStudyStats: (days = 7) =>
    api.get<StudyStats>(`${BASE}/statistics/study?days=${days}`),

  getEnergyStats: (days = 7) =>
    api.get<EnergyStats>(`${BASE}/statistics/energy?days=${days}`),

  getAchievementStats: () =>
    api.get<AchievementStats>(`${BASE}/statistics/achievements`),
};
