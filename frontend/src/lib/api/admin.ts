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
};
