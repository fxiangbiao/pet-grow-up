export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
  timestamp: string;
}

export interface UserDTO {
  id: number;
  username: string;
  nickname: string;
  avatarUrl: string | null;
  currentEnergy: number;
  currentSpiritId: number | null;
  consecutiveStudyDays?: number;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  expiresIn: number;
  user: UserDTO;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
}

export interface SpiritSpecies {
  id: number;
  speciesKey: string;
  name: string;
  subject: string;
  description: string;
  evolutionStage: number;
  evolutionEnergyCost: number | null;
  spriteUrl: string;
}

export interface PersonalityDTO {
  lively: number;
  shy: number;
  independent: number;
  playful: number;
  gentle: number;
  brave: number;
}

export interface LearningSpirit {
  id: number;
  species: SpiritSpecies;
  nickname: string;
  currentEvolutionStage: number;
  happiness: number;
  energy: number;
  affection: number;
  isActive: boolean;
  personality: PersonalityDTO | null;
}

export interface SpiritDTO extends LearningSpirit {}

export interface SpiritStatus {
  dormancyLevel: number;      // 0=normal, 1=dim, 2=sleeping
  lastStudyDate: string | null;
  daysSinceLastStudy: number;
  personalityType: string;
}

export interface AchievementDef {
  id: number;
  achievementKey: string;
  category: string;
  name: string;
  description: string;
  iconUrl: string | null;
  rarity: string;
  requirementType: string;
  requirementThreshold: number;
  subject: string | null;
  rewardEnergy: number;
  rewardItemKey: string | null;
  rewardTitle: string | null;
  displayOrder: number;
  isHidden: boolean;
}

export interface UserAchievement {
  id: number | null;
  achievementDefId: number;
  definition: AchievementDef;
  currentValue: number;
  isUnlocked: boolean;
  unlockedAt: string | null;
  notified: boolean;
}

export interface AchievementProgress {
  unlocked: UserAchievement[];
  inProgress: UserAchievement[];
  totalCount: number;
  unlockedCount: number;
}

export interface AchievementUnlockEvent {
  userId: number;
  achievement: AchievementDef;
  energyRewarded: number;
  titleGranted: string | null;
}

// ---------- Social ----------

export interface FriendDTO {
  friendId: number;
  nickname: string;
  avatarUrl: string | null;
  totalEnergy: number;
  consecutiveStudyDays: number;
  becameFriendsAt: string;
}

export interface FriendRequestDTO {
  requestId: number;
  userId: number;
  nickname: string;
  avatarUrl: string | null;
  status: string;
  createdAt: string;
}

export interface UserSearchResult {
  userId: number;
  nickname: string;
  avatarUrl: string | null;
  isFriend: boolean;
  hasPendingRequest: boolean;
  isSelf: boolean;
}

export interface LeaderboardEntry {
  rank: number;
  userId: number;
  nickname: string;
  avatarUrl: string | null;
  value: number;
  isCurrentUser: boolean;
}

// ---------- Shop ----------

export interface ItemDef {
  id: number;
  itemKey: string;
  name: string;
  description: string;
  category: string;
  effectType: string;
  effectValue: number;
  price: number;
  iconUrl: string | null;
  isConsumable: boolean;
  displayOrder: number;
}

export interface UserItem {
  id: number;
  itemDef: ItemDef;
  quantity: number;
}

export interface UseItemResult {
  happinessChange: number;
  energyChange: number;
  affectionChange: number;
  itemName: string;
  quantityUsed: number;
}

// ---------- Daily Challenge ----------

export interface DailyChallenge {
  id: number;
  challengeType: string;
  description: string;
  targetValue: number;
  rewardEnergy: number;
  iconUrl: string;
  displayOrder: number;
  progress: number;
  completed: boolean;
  rewardClaimed: boolean;
}

// ---------- Story ----------

export interface ChapterDTO {
  id: number;
  chapterNumber: number;
  title: string;
  narrative: string;
  npcName: string;
  npcDialogue: string;
  choiceText: string;
  requirementType: string;
  requirementValue: number;
  rewardEnergy: number;
  displayOrder: number;
  unlocked: boolean;
  completed: boolean;
  rewardClaimed: boolean;
}
