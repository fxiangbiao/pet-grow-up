CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nickname VARCHAR(50),
    avatar_url VARCHAR(255),
    current_spirit_id BIGINT DEFAULT NULL,
    total_energy BIGINT NOT NULL DEFAULT 0,
    current_energy BIGINT NOT NULL DEFAULT 0,
    consecutive_study_days INT NOT NULL DEFAULT 0,
    last_study_date DATE DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_username (username),
    INDEX idx_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS spirit_species (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    species_key VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    subject VARCHAR(20) NOT NULL COMMENT 'chinese, math, english',
    description TEXT,
    evolution_stage INT NOT NULL DEFAULT 1 COMMENT '1=basic, 2=intermediate, 3=advanced',
    evolves_from_id BIGINT DEFAULT NULL,
    evolution_energy_cost BIGINT DEFAULT NULL,
    base_affection INT NOT NULL DEFAULT 0,
    sprite_url VARCHAR(255) NOT NULL,
    animation_data JSON DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_species_subject (subject),
    INDEX idx_species_evolution (evolution_stage),
    INDEX idx_species_evolves_from (evolves_from_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS learning_spirit (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    species_id BIGINT NOT NULL,
    nickname VARCHAR(50) DEFAULT NULL,
    current_evolution_stage INT NOT NULL DEFAULT 1,
    experience INT NOT NULL DEFAULT 0,
    happiness INT NOT NULL DEFAULT 100 COMMENT '0-100',
    energy INT NOT NULL DEFAULT 100 COMMENT '0-100',
    affection INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    personality JSON DEFAULT NULL COMMENT '6-dimension scores: {LIVELY, SHY, INDEPENDENT, PLAYFUL, GENTLE, BRAVE}',
    obtained_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (species_id) REFERENCES spirit_species(id),
    INDEX idx_spirit_user (user_id),
    INDEX idx_spirit_active (user_id, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS personality_dimension (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    dimension_key VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(20) NOT NULL,
    description VARCHAR(200)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS energy_transaction (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    amount BIGINT NOT NULL,
    transaction_type VARCHAR(10) NOT NULL COMMENT 'EARN, SPEND',
    source VARCHAR(50) NOT NULL COMMENT 'e.g., study_session, feed, evolve, unlock',
    reference_type VARCHAR(50) DEFAULT NULL,
    reference_id BIGINT DEFAULT NULL,
    balance_after BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_energy_user (user_id),
    INDEX idx_energy_created (user_id, created_at),
    INDEX idx_energy_source (reference_type, reference_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS knowledge_node (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    subject VARCHAR(20) NOT NULL COMMENT 'chinese, math, english',
    node_key VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    difficulty INT NOT NULL DEFAULT 1 COMMENT '1-5',
    grade_level INT NOT NULL DEFAULT 1 COMMENT '1-6对应小学年级',
    parent_node_id BIGINT DEFAULT NULL,
    prerequisite_nodes JSON DEFAULT NULL,
    content_template JSON DEFAULT NULL,
    order_index INT NOT NULL DEFAULT 0,
    UNIQUE KEY uk_subject_node_key (subject, node_key),
    FOREIGN KEY (parent_node_id) REFERENCES knowledge_node(id),
    INDEX idx_knowledge_subject (subject),
    INDEX idx_knowledge_order (subject, order_index)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Safely add grade_level if missing (for existing databases)
SET @sql = IF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'knowledge_node' AND COLUMN_NAME = 'grade_level') = 0,
  'ALTER TABLE knowledge_node ADD COLUMN grade_level INT NOT NULL DEFAULT 1 COMMENT ''1-6对应小学年级''',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS quiz_question (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    knowledge_node_id BIGINT NOT NULL,
    question_type VARCHAR(20) NOT NULL COMMENT 'MULTIPLE_CHOICE, FILL_BLANK, TRUE_FALSE',
    difficulty INT NOT NULL DEFAULT 1 COMMENT '1-5',
    question_text TEXT NOT NULL,
    options JSON DEFAULT NULL COMMENT 'array of {key, text} for multiple choice',
    correct_answer TEXT NOT NULL,
    explanation TEXT,
    points INT NOT NULL DEFAULT 10,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (knowledge_node_id) REFERENCES knowledge_node(id) ON DELETE CASCADE,
    UNIQUE KEY uk_quiz_node_question (knowledge_node_id, question_text(255)),
    INDEX idx_quiz_node (knowledge_node_id),
    INDEX idx_quiz_difficulty (knowledge_node_id, difficulty)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS study_session (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    subject VARCHAR(20) NOT NULL,
    session_type VARCHAR(20) NOT NULL COMMENT 'DAILY, STORY, EXTREME',
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS' COMMENT 'IN_PROGRESS, COMPLETED, ABANDONED',
    difficulty_level INT NOT NULL DEFAULT 1,
    base_reward BIGINT NOT NULL DEFAULT 100,
    total_questions INT NOT NULL DEFAULT 0,
    correct_answers INT NOT NULL DEFAULT 0,
    accuracy DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    actual_duration INT NOT NULL DEFAULT 0 COMMENT 'seconds',
    expected_duration INT NOT NULL DEFAULT 0 COMMENT 'seconds',
    energy_earned BIGINT NOT NULL DEFAULT 0,
    streak_at_time INT NOT NULL DEFAULT 0,
    question_order TEXT DEFAULT NULL COMMENT 'comma-separated pre-shuffled question IDs',
    current_combo INT NOT NULL DEFAULT 0 COMMENT 'current streak of correct answers',
    max_combo INT NOT NULL DEFAULT 0 COMMENT 'max streak achieved in this session',
    boss_defeated BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'whether the boss (last q) was answered correctly',
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_session_user (user_id),
    INDEX idx_session_status (user_id, status),
    INDEX idx_session_date (user_id, started_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS study_record (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    session_id BIGINT NOT NULL,
    knowledge_node_id BIGINT DEFAULT NULL,
    question_id BIGINT DEFAULT NULL,
    question_type VARCHAR(20) DEFAULT NULL,
    content JSON DEFAULT NULL COMMENT 'snapshot of question data',
    user_answer TEXT,
    correct_answer TEXT,
    is_correct BOOLEAN DEFAULT NULL,
    time_spent INT DEFAULT NULL COMMENT 'seconds',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES study_session(id) ON DELETE CASCADE,
    INDEX idx_record_session (session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS subject_world (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    subject VARCHAR(20) NOT NULL,
    world_level INT NOT NULL DEFAULT 1,
    total_stars INT NOT NULL DEFAULT 0,
    map_data JSON DEFAULT NULL COMMENT 'unlocked nodes, star ratings per node',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_subject (user_id, subject),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_subject_world_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS achievement_def (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    achievement_key VARCHAR(50) NOT NULL UNIQUE,
    category VARCHAR(20) NOT NULL COMMENT 'study, subject, spirit, collection, event, social',
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) DEFAULT NULL,
    icon_url VARCHAR(255) DEFAULT NULL,
    rarity VARCHAR(20) NOT NULL DEFAULT 'COMMON' COMMENT 'COMMON, RARE, EPIC, LEGENDARY',
    requirement_type VARCHAR(50) NOT NULL,
    requirement_threshold BIGINT NOT NULL,
    subject VARCHAR(20) DEFAULT NULL,
    reward_energy BIGINT NOT NULL DEFAULT 0,
    reward_item_key VARCHAR(50) DEFAULT NULL,
    reward_title VARCHAR(50) DEFAULT NULL,
    display_order INT NOT NULL DEFAULT 0,
    is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_achievement_category (category),
    INDEX idx_achievement_rarity (rarity),
    INDEX idx_achievement_subject (subject)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_achievement (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    achievement_def_id BIGINT NOT NULL,
    current_value BIGINT NOT NULL DEFAULT 0,
    is_unlocked BOOLEAN NOT NULL DEFAULT FALSE,
    unlocked_at TIMESTAMP NULL,
    notified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_achievement (user_id, achievement_def_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (achievement_def_id) REFERENCES achievement_def(id) ON DELETE CASCADE,
    INDEX idx_user_achievement_user (user_id),
    INDEX idx_user_achievement_unlocked (user_id, is_unlocked)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- Social: Friend System
-- ============================================================

CREATE TABLE IF NOT EXISTS friend_request (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sender_id BIGINT NOT NULL,
    receiver_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING, ACCEPTED, REJECTED',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_friend_request_sender_receiver (sender_id, receiver_id),
    INDEX idx_friend_request_receiver (receiver_id, status),
    INDEX idx_friend_request_sender (sender_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_friend (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    friend_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_friend (user_id, friend_id),
    INDEX idx_user_friend_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- Shop: Item Definitions & User Inventory
-- ============================================================

CREATE TABLE IF NOT EXISTS item_def (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    item_key VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) DEFAULT NULL,
    category VARCHAR(30) NOT NULL COMMENT 'FOOD, TOY, DECORATION, CONSUMABLE',
    effect_type VARCHAR(30) DEFAULT NULL COMMENT 'HAPPINESS, ENERGY, AFFECTION',
    effect_value INT NOT NULL DEFAULT 0,
    price BIGINT NOT NULL DEFAULT 0,
    icon_url VARCHAR(255) DEFAULT NULL,
    is_consumable BOOLEAN NOT NULL DEFAULT TRUE,
    is_purchasable BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_item_category (category),
    INDEX idx_item_display_order (display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_item (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    item_def_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_item (user_id, item_def_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (item_def_id) REFERENCES item_def(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- Daily Challenges
-- ============================================================

CREATE TABLE IF NOT EXISTS daily_challenge_def (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    challenge_type VARCHAR(30) NOT NULL COMMENT 'STUDY_SESSION, ACCURACY, ENERGY_EARN, PERFECT_SESSION',
    description VARCHAR(200) NOT NULL,
    target_value INT NOT NULL DEFAULT 1,
    reward_energy BIGINT NOT NULL DEFAULT 0,
    icon_url VARCHAR(50) DEFAULT NULL,
    display_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_challenge_type (challenge_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_challenge (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    challenge_def_id BIGINT NOT NULL,
    challenge_date DATE NOT NULL,
    progress INT NOT NULL DEFAULT 0,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    reward_claimed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_challenge (user_id, challenge_def_id, challenge_date),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (challenge_def_id) REFERENCES daily_challenge_def(id) ON DELETE CASCADE,
    INDEX idx_user_challenge_date (user_id, challenge_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- Story: Chapters & User Progress
-- ============================================================

CREATE TABLE IF NOT EXISTS story_chapter (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    chapter_number INT NOT NULL UNIQUE,
    title VARCHAR(100) NOT NULL,
    narrative TEXT DEFAULT NULL COMMENT 'Narrative description of the chapter',
    npc_name VARCHAR(50) DEFAULT NULL COMMENT 'NPC appearing in this chapter',
    npc_dialogue TEXT DEFAULT NULL COMMENT 'NPC dialogue text',
    choice_text VARCHAR(200) DEFAULT NULL COMMENT 'Player response text',
    requirement_type VARCHAR(30) DEFAULT NULL COMMENT 'e.g. FIRST_SPIRIT, COMPLETE_STUDY, EVOLVE_SPIRIT, ENERGY_TOTAL, ACCURACY, AFFECTION, STREAK, ACHIEVEMENT_COUNT',
    requirement_value INT NOT NULL DEFAULT 1,
    reward_energy BIGINT NOT NULL DEFAULT 0,
    display_order INT NOT NULL DEFAULT 0,
    INDEX idx_chapter_order (display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- Spirit Accessories (Sprint E)
-- ============================================================
CREATE TABLE IF NOT EXISTS spirit_accessory (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    spirit_id BIGINT NOT NULL,
    slot VARCHAR(20) NOT NULL COMMENT 'head, neck, eyes, effect',
    item_def_id BIGINT NOT NULL,
    equipped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_spirit_slot (spirit_id, slot),
    FOREIGN KEY (spirit_id) REFERENCES learning_spirit(id) ON DELETE CASCADE,
    FOREIGN KEY (item_def_id) REFERENCES item_def(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_story_progress (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    chapter_id BIGINT NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    reward_claimed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_chapter (user_id, chapter_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (chapter_id) REFERENCES story_chapter(id) ON DELETE CASCADE,
    INDEX idx_user_story (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Safely add random event columns on study_session (for existing databases)
SET @sql = IF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'study_session' AND COLUMN_NAME = 'random_event_key') = 0,
  'ALTER TABLE study_session ADD COLUMN random_event_key VARCHAR(50) DEFAULT NULL, ADD COLUMN random_event_bonus_energy BIGINT NOT NULL DEFAULT 0',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS random_event_def (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    event_key VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(300),
    event_type VARCHAR(30) NOT NULL COMMENT 'BONUS_ENERGY, SPIRIT_GIFT, FREE_ITEM, DOUBLE_REWARD, STREAK_BONUS',
    trigger_chance DECIMAL(3,2) NOT NULL DEFAULT 0.10 COMMENT '0.00-1.00 probability',
    min_accuracy DECIMAL(3,2) NOT NULL DEFAULT 0.00 COMMENT 'minimum accuracy to trigger',
    min_streak INT NOT NULL DEFAULT 0 COMMENT 'minimum streak to trigger',
    reward_energy BIGINT NOT NULL DEFAULT 0,
    reward_item_key VARCHAR(50) DEFAULT NULL,
    reward_affection INT NOT NULL DEFAULT 0,
    display_text VARCHAR(200),
    icon_url VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_event_trigger (trigger_chance, min_accuracy)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Safely add login tracking columns if missing (for existing databases)
SET @sql = IF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'last_login_date') = 0,
  'ALTER TABLE users ADD COLUMN last_login_date DATE DEFAULT NULL, ADD COLUMN consecutive_login_days INT NOT NULL DEFAULT 0, ADD COLUMN daily_reward_claimed_date DATE DEFAULT NULL',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Safely add role column if missing (for admin system)
SET @sql = IF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'role') = 0,
  'ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT ''STUDENT''',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS daily_reward_def (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    reward_key VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(200),
    reward_type VARCHAR(30) NOT NULL COMMENT 'ENERGY, ITEM, ACCESSORY',
    reward_value BIGINT COMMENT 'energy amount if reward_type=ENERGY',
    reward_item_key VARCHAR(50) COMMENT 'item_key if reward_type=ITEM or ACCESSORY',
    unlock_day INT NOT NULL COMMENT 'consecutive login day required (1=every day, 3/7/14/30=milestone)',
    icon_url VARCHAR(100),
    display_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_reward_day (unlock_day, reward_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Pet Room Theme Definitions (Sprint F Layer 1)
CREATE TABLE IF NOT EXISTS room_theme_def (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    theme_key VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    icon_url VARCHAR(255),
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pet_room (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    room_style VARCHAR(30) NOT NULL DEFAULT 'cozy_warm' COMMENT 'theme key: cozy_warm, starry_night, forest_green, ancient_study, crystal_hall, ocean_deep',
    slot_data JSON DEFAULT NULL COMMENT '[{"userItemId":N,"itemDefId":N,"itemKey":"...","x":100,"y":200}]',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_pet_room_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



CREATE TABLE IF NOT EXISTS learning_weakness (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    knowledge_node_id BIGINT DEFAULT NULL,
    subject VARCHAR(20) NOT NULL,
    wrong_count INT NOT NULL DEFAULT 1,
    last_wrong_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    mastery_level INT NOT NULL DEFAULT 0 COMMENT '0-100, increases with correct answers',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_node_subject (user_id, knowledge_node_id, subject),
    INDEX idx_user_weakness (user_id, mastery_level ASC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS practice_attempt (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    knowledge_node_id BIGINT NOT NULL,
    question_id BIGINT NOT NULL,
    user_answer VARCHAR(500),
    is_correct BOOLEAN DEFAULT FALSE,
    time_spent INT DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_practice_user_node (user_id, knowledge_node_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS analogy_record (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    knowledge_node_id BIGINT NOT NULL,
    original_question_id BIGINT NOT NULL,
    variant_question_id BIGINT NOT NULL,
    user_answer VARCHAR(500),
    is_correct BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_analogy_user_node (user_id, knowledge_node_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;