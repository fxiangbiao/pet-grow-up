-- Insert spirit species: 3 subjects x 3 evolution stages each = 9 entries
-- Chinese (诗词大陆)
INSERT IGNORE INTO spirit_species (species_key, name, subject, description, evolution_stage, evolves_from_id, evolution_energy_cost, base_affection, sprite_url, animation_data) VALUES
('chinese_basic', '小书仙', 'chinese', '诗词大陆中由文字灵气凝聚而成的小精灵，喜爱在书卷间嬉戏。', 1, NULL, NULL, 30, '/sprites/chinese/basic.svg', '{}'),
('chinese_mid', '诗灵', 'chinese', '掌握了大量诗词精华的文韵精灵，周身环绕着诗句的光晕。', 2, NULL, 500, 50, '/sprites/chinese/mid.svg', '{}'),
('chinese_advanced', '文圣', 'chinese', '诗词大陆的至高存在，一言一行皆成诗章，智慧如海。', 3, NULL, 2000, 80, '/sprites/chinese/advanced.svg', '{}');

-- Math (智慧王国)
INSERT IGNORE INTO spirit_species (species_key, name, subject, description, evolution_stage, evolves_from_id, evolution_energy_cost, base_affection, sprite_url, animation_data) VALUES
('math_basic', '智慧猫', 'math', '智慧王国中由逻辑火花幻化的小猫，对数字有着天生的敏感。', 1, NULL, NULL, 30, '/sprites/math/basic.svg', '{}'),
('math_mid', '数学龙', 'math', '掌握了大量数学定理的智慧精灵，双翼上绘满几何图案。', 2, NULL, 500, 50, '/sprites/math/mid.svg', '{}'),
('math_advanced', '逻辑神', 'math', '智慧之塔的守护者，目光所及皆可化为公式与定理。', 3, NULL, 2000, 80, '/sprites/math/advanced.svg', '{}');

-- English (魔法学院)
INSERT IGNORE INTO spirit_species (species_key, name, subject, description, evolution_stage, evolves_from_id, evolution_energy_cost, base_affection, sprite_url, animation_data) VALUES
('english_basic', '小巫师', 'english', '魔法学院的新生，手中的魔法杖由字母拼成，充满好奇。', 1, NULL, NULL, 30, '/sprites/english/basic.svg', '{}'),
('english_mid', '魔法鸦', 'english', '精通多种魔咒的魔法生物，羽翼上闪烁着单词的光芒。', 2, NULL, 500, 50, '/sprites/english/mid.svg', '{}'),
('english_advanced', '大魔导师', 'english', '魔法学院的院长，掌握了英语魔法的终极奥秘。', 3, NULL, 2000, 80, '/sprites/english/advanced.svg', '{}');

-- Update evolution costs to match earning rates (~100-200 per session)
UPDATE spirit_species SET evolution_energy_cost = 500 WHERE evolution_stage = 2;
UPDATE spirit_species SET evolution_energy_cost = 2000 WHERE evolution_stage = 3;

-- Update evolution chains (use derived table to bypass MySQL can't-update-same-table restriction)
UPDATE spirit_species SET evolves_from_id = (SELECT t.id FROM (SELECT id FROM spirit_species WHERE species_key = 'chinese_basic') t) WHERE species_key = 'chinese_mid';
UPDATE spirit_species SET evolves_from_id = (SELECT t.id FROM (SELECT id FROM spirit_species WHERE species_key = 'chinese_mid') t) WHERE species_key = 'chinese_advanced';
UPDATE spirit_species SET evolves_from_id = (SELECT t.id FROM (SELECT id FROM spirit_species WHERE species_key = 'math_basic') t) WHERE species_key = 'math_mid';
UPDATE spirit_species SET evolves_from_id = (SELECT t.id FROM (SELECT id FROM spirit_species WHERE species_key = 'math_mid') t) WHERE species_key = 'math_advanced';
UPDATE spirit_species SET evolves_from_id = (SELECT t.id FROM (SELECT id FROM spirit_species WHERE species_key = 'english_basic') t) WHERE species_key = 'english_mid';
UPDATE spirit_species SET evolves_from_id = (SELECT t.id FROM (SELECT id FROM spirit_species WHERE species_key = 'english_mid') t) WHERE species_key = 'english_advanced';

-- Knowledge Nodes: Chinese (诗词大陆)
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, parent_node_id, order_index) VALUES
('chinese', 'chinese_intro', '语文入门', '认识拼音字母和基础汉字，朗读儿歌和古诗', 1, NULL, 1);

-- Knowledge Nodes: Math (智慧王国) — 一年级数学（人教2024版）
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, parent_node_id, order_index) VALUES
('math', 'math_intro', '凑十法与10以内', '掌握凑十法、10以内加减法', 1, NULL, 1),
('math', 'math_addsub20', '20以内加减', '掌握20以内进位加法和退位减法', 2, NULL, 2),
('math', 'math_geometry', '认识图形', '认识圆形、正方形、三角形等基本图形', 3, NULL, 3);

-- Knowledge Nodes: English (魔法学院)
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, parent_node_id, order_index) VALUES
('english', 'english_intro', '字母与发音', '掌握26个字母和基础发音', 1, NULL, 1),
('english', 'english_vocab', '词汇积累', '学习日常生活中的常用词汇', 2, NULL, 2);

-- Quiz Questions: Chinese (Sprint A: old poetry questions removed — see Sprint A pinyin/shizi/kewen sections below)

-- Quiz Questions: Math (一年级数学 — 人教2024版)
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
-- 凑十法（场景化拖拽）
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_DRAG', 1, '凑十法：8 + ? = 10', NULL, '2', '拖2个苹果到碗里！8+2=10', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_DRAG', 1, '凑十法：7 + ? = 10', NULL, '3', '拖3个能量块！7+3=10', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_DRAG', 1, '凑十法：6 + ? = 10', NULL, '4', '再拖4个就满啦！6+4=10', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_DRAG', 1, '凑十法：9 + ? = 10', NULL, '1', '还差1个！9+1=10', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_DRAG', 1, '凑十法：5 + ? = 10', NULL, '5', '正好一半！5+5=10', 10),
-- 10以内加减（点击操作）
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_TAP', 1, '3 + 2 = ?', '[{"key":"A","text":"4"},{"key":"B","text":"5"},{"key":"C","text":"6"}]', 'B', '3+2=5，伸出3根手指再加2根', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_TAP', 1, '7 - 4 = ?', '[{"key":"A","text":"2"},{"key":"B","text":"3"},{"key":"C","text":"4"}]', 'B', '7-4=3，7去掉4还剩3', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_TAP', 1, '6 + 3 = ?', '[{"key":"A","text":"8"},{"key":"B","text":"9"},{"key":"C","text":"10"}]', 'B', '6+3=9', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_TAP', 1, '10 - 5 = ?', '[{"key":"A","text":"4"},{"key":"B","text":"5"},{"key":"C","text":"6"}]', 'B', '10-5=5', 10),
-- 20以内加减（点击操作）
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'SCENE_TAP', 2, '9 + 6 = ?', '[{"key":"A","text":"14"},{"key":"B","text":"15"},{"key":"C","text":"16"}]', 'B', '9+6=15，把9凑成10，再加剩下的5', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'SCENE_TAP', 2, '8 + 7 = ?', '[{"key":"A","text":"14"},{"key":"B","text":"15"},{"key":"C","text":"16"}]', 'B', '8+7=15，8和2凑成10，加剩下的5', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'SCENE_TAP', 2, '15 - 8 = ?', '[{"key":"A","text":"6"},{"key":"B","text":"7"},{"key":"C","text":"8"}]', 'B', '15-8=7，用破十法：10-8=2，2+5=7', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'SCENE_TAP', 2, '13 - 6 = ?', '[{"key":"A","text":"6"},{"key":"B","text":"7"},{"key":"C","text":"8"}]', 'B', '13-6=7，破十法：10-6=4，4+3=7', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'SCENE_TAP', 2, '12 + 5 = ?', '[{"key":"A","text":"16"},{"key":"B","text":"17"},{"key":"C","text":"18"}]', 'B', '12+5=17，十位不变个位加', 10),
-- 认识图形（配对操作）
((SELECT id FROM knowledge_node WHERE node_key = 'math_geometry'), 'SCENE_MATCH', 3, '哪个是圆形？', NULL, 'CIRCLE', '圆圆的，没有角的就是圆形', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_geometry'), 'SCENE_MATCH', 3, '哪个是正方形？', NULL, 'SQUARE', '四条边一样长，四个角一样大', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_geometry'), 'SCENE_MATCH', 3, '哪个是三角形？', NULL, 'TRIANGLE', '三条边、三个角', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_geometry'), 'SCENE_MATCH', 3, '哪个是长方形？', NULL, 'RECTANGLE', '对边相等，四个角一样大', 10);

-- Quiz Questions: English (Sprint A: grammar + too-advanced vocab removed — see Sprint A letters/vocab sections)
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'MULTIPLE_CHOICE', 1, '"apple"的中文意思是？', '[{"key":"A","text":"香蕉"},{"key":"B","text":"橘子"},{"key":"C","text":"苹果"},{"key":"D","text":"葡萄"}]', 'C', 'apple 意为苹果。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'FILL_BLANK', 1, '英语中"猫"的单词是？', NULL, 'cat', '猫的英文是 cat。', 10);

-- Achievement definitions
INSERT IGNORE INTO achievement_def (achievement_key, category, name, description, icon_url, rarity, requirement_type, requirement_threshold, subject, reward_energy, reward_item_key, reward_title, display_order, is_hidden) VALUES
('first_study', 'STUDY', '初次探索', '完成第一次学习探险', '/badges/study/first_study.png', 'COMMON', 'SESSION_COUNT', 1, NULL, 100, NULL, NULL, 1, FALSE),
('complete_10_sessions', 'STUDY', '勤奋学子', '累计完成10次学习探险', '/badges/study/sessions_10.png', 'RARE', 'SESSION_COUNT', 10, NULL, 500, NULL, '勤奋学子', 2, FALSE),
('streak_3_days', 'STUDY', '坚持三天', '连续学习3天', '/badges/study/streak_3.png', 'COMMON', 'STREAK_DAYS', 3, NULL, 200, NULL, NULL, 3, FALSE),
('streak_7_days', 'STUDY', '一周达人', '连续学习7天', '/badges/study/streak_7.png', 'RARE', 'STREAK_DAYS', 7, NULL, 500, NULL, '一周达人', 4, FALSE),
('total_500_energy', 'STUDY', '能量初盈', '累计获得500学习能量', '/badges/study/energy_500.png', 'COMMON', 'TOTAL_ENERGY', 500, NULL, 200, NULL, NULL, 5, FALSE),
('perfect_session', 'STUDY', '完美答卷', '在一次探险中答对所有题目', '/badges/study/perfect.png', 'RARE', 'PERFECT_SESSION', 1, NULL, 300, NULL, '完美学者', 6, FALSE),
('chinese_10_poems', 'SUBJECT', '诗词入门', '在诗词大陆完成10次探险', '/badges/subject/chinese_10.png', 'RARE', 'SUBJECT_MILESTONE', 10, 'chinese', 300, NULL, '诗词学徒', 7, FALSE),
('math_10_problems', 'SUBJECT', '逻辑新秀', '在智慧王国完成10次探险', '/badges/subject/math_10.png', 'RARE', 'SUBJECT_MILESTONE', 10, 'math', 300, NULL, '逻辑学徒', 8, FALSE),
('english_10_words', 'SUBJECT', '魔法学徒', '在魔法学院完成10次探险', '/badges/subject/english_10.png', 'RARE', 'SUBJECT_MILESTONE', 10, 'english', 300, NULL, '魔法学徒', 9, FALSE),
('first_evolution', 'SPIRIT', '初次进化', '让精灵完成第一次进化', '/badges/spirit/evolution.png', 'EPIC', 'FIRST_EVOLUTION', 1, NULL, 1000, NULL, '进化先驱', 10, FALSE),
('all_subjects_tried', 'COLLECTION', '三界探险', '在所有学科世界中进行过探险', '/badges/collection/all_subjects.png', 'EPIC', 'ALL_SUBJECTS_TRIED', 3, NULL, 500, NULL, '三界旅者', 11, FALSE),
('daily_checkin_7', 'EVENT', '签到达人', '连续签到7天', '/badges/event/checkin_7.png', 'RARE', 'STREAK_DAYS', 7, NULL, 300, NULL, NULL, 12, FALSE);

-- Personality dimensions
INSERT IGNORE INTO personality_dimension (dimension_key, name, description) VALUES
('LIVELY', '活泼', '充满活力，喜欢快速反应和积极互动'),
('SHY', '害羞', '性格内向，喜欢安静的学习环境'),
('INDEPENDENT', '独立', '善于独立思考，不需要太多外部激励'),
('PLAYFUL', '调皮', '喜欢尝试不同的学习方法，偶尔也会犯错'),
('GENTLE', '温柔', '有耐心，态度温和，适合长期稳定的学习'),
('BRAVE', '勇敢', '敢于挑战难题，面对失败也不会轻易放弃');

-- ============================================================
-- Shop: Item Definitions
-- ============================================================
INSERT IGNORE INTO item_def (item_key, name, description, category, effect_type, effect_value, price, icon_url, is_consumable, is_purchasable, display_order) VALUES
('energy_candy', '能量糖', '恢复精灵20点精力', 'FOOD', 'ENERGY', 20, 30, NULL, TRUE, TRUE, 1),
('happy_cake', '快乐蛋糕', '增加精灵25点快乐度', 'FOOD', 'HAPPINESS', 25, 40, NULL, TRUE, TRUE, 2),
('affection_gift', '亲密度礼盒', '提升10点亲密度', 'TOY', 'AFFECTION', 10, 50, NULL, TRUE, TRUE, 3),
('mixed_treat', '什锦点心', '增加10点快乐度', 'FOOD', 'HAPPINESS', 10, 20, NULL, TRUE, TRUE, 4),
('energy_candy_plus', '大力能量糖', '恢复精灵40点精力', 'FOOD', 'ENERGY', 40, 60, NULL, TRUE, TRUE, 5),
('shiny_star', '闪亮星星', '增加15点快乐度', 'TOY', 'HAPPINESS', 15, 35, NULL, TRUE, TRUE, 6);

-- Sprint E: Accessories (permanent cosmetics, is_consumable=false)
INSERT IGNORE INTO item_def (item_key, name, description, category, effect_type, effect_value, price, icon_url, is_consumable, is_purchasable, display_order) VALUES
-- Head (4)
('acc_hat_red', '小红帽', '一顶可爱的红色小帽子', 'ACCESSORY', 'COSMETIC', 0, 80, '🎩', FALSE, TRUE, 20),
('acc_bow_pink', '粉色蝴蝶结', '漂亮的粉色蝴蝶结，戴在头上超可爱', 'ACCESSORY', 'COSMETIC', 0, 80, '🎀', FALSE, TRUE, 21),
('acc_flower_ring', '花环', '鲜花编成的花环，小精灵的最爱', 'ACCESSORY', 'COSMETIC', 0, 120, '🌸', FALSE, TRUE, 22),
('acc_graduation_cap', '学士帽', '聪明的象征！戴上它我就是学霸', 'ACCESSORY', 'COSMETIC', 0, 200, '🎓', FALSE, TRUE, 23),
-- Neck (4)
('acc_scarf_blue', '蓝围巾', '温暖的天蓝色围巾', 'ACCESSORY', 'COSMETIC', 0, 80, '🧣', FALSE, TRUE, 24),
('acc_bowtie', '小领结', '绅士必备的红色小领结', 'ACCESSORY', 'COSMETIC', 0, 100, '👔', FALSE, TRUE, 25),
('acc_star_necklace', '星星项链', '闪闪发光的星星吊坠', 'ACCESSORY', 'COSMETIC', 0, 150, '⭐', FALSE, TRUE, 26),
('acc_perseverance_scarf', '毅力围巾', '连续学习7天的证明！金色传说围巾', 'ACCESSORY', 'COSMETIC', 0, 0, '🏅', FALSE, FALSE, 27),
-- Eyes (2)
('acc_round_glasses', '圆框眼镜', '复古圆框眼镜，知识分子的气质', 'ACCESSORY', 'COSMETIC', 0, 120, '👓', FALSE, TRUE, 28),
('acc_star_shades', '星星墨镜', '酷炫的星星形状墨镜，回头率100%', 'ACCESSORY', 'COSMETIC', 0, 180, '🕶️', FALSE, TRUE, 29),
-- Effect (2)
('acc_effect_gold', '金色星光', '答题时散发金色星光粒子', 'ACCESSORY', 'COSMETIC', 0, 250, '✨', FALSE, TRUE, 30),
('acc_effect_rainbow', '彩虹流光', '答题时散发彩虹流光粒子！超级稀有', 'ACCESSORY', 'COSMETIC', 0, 500, '🌈', FALSE, TRUE, 31);

-- ============================================================
-- Subject-Specific Question Types
-- ============================================================

-- Math: MATH_INPUT (一年级 20以内加减)
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'MATH_INPUT', 2, '6 + 7 = ?', NULL, '13', '6+7=13，6和4凑成10，加剩下的3', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'MATH_INPUT', 2, '9 + 4 = ?', NULL, '13', '9+4=13，9和1凑成10，加剩下的3', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'MATH_INPUT', 2, '14 - 9 = ?', NULL, '5', '14-9=5，平十法：14-4=10，10-5=5', 10);

-- English: VOCAB_MATCH
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'VOCAB_MATCH', 1, '请将左边的英文单词与右边的中文释义配对', '{"left":[{"id":"A","text":"apple"},{"id":"B","text":"book"},{"id":"C","text":"cat"}],"right":[{"id":"1","text":"书"},{"id":"2","text":"猫"},{"id":"3","text":"苹果"}]}', 'A3,B1,C2', 'apple=苹果, book=书, cat=猫', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'VOCAB_MATCH', 1, '请将左边的英文单词与右边的中文释义配对', '{"left":[{"id":"A","text":"dog"},{"id":"B","text":"fish"},{"id":"C","text":"bird"}],"right":[{"id":"1","text":"鸟"},{"id":"2","text":"狗"},{"id":"3","text":"鱼"}]}', 'A2,B3,C1', 'dog=狗, fish=鱼, bird=鸟', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'VOCAB_MATCH', 1, '请将左边的英文单词与右边的中文释义配对', '{"left":[{"id":"A","text":"red"},{"id":"B","text":"blue"},{"id":"C","text":"green"}],"right":[{"id":"1","text":"绿色"},{"id":"2","text":"红色"},{"id":"3","text":"蓝色"}]}', 'A2,B3,C1', 'red=红色, blue=蓝色, green=绿色', 10);

-- ============================================================
-- Sprint 2: Expanded Content
-- ============================================================

-- Math: More SCENE_DRAG (凑十法) for math_intro
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_DRAG', 1, '凑十法：4 + ? = 10', NULL, '6', '拖6个苹果到碗里！4+6=10', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_DRAG', 1, '凑十法：3 + ? = 10', NULL, '7', '拖7个苹果到碗里！3+7=10', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_DRAG', 1, '凑十法：2 + ? = 10', NULL, '8', '拖8个苹果到碗里！2+8=10', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_DRAG', 1, '凑十法：1 + ? = 10', NULL, '9', '拖9个苹果到碗里！1+9=10', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_DRAG', 1, '凑十法：0 + ? = 10', NULL, '10', '拖10个苹果到碗里！0+10=10', 10);

-- Math: More SCENE_TAP (10以内加减) for math_intro
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_TAP', 1, '5 + 4 = ?', '[{"key":"A","text":"8"},{"key":"B","text":"9"},{"key":"C","text":"10"}]', 'B', '5+4=9', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_TAP', 1, '9 - 3 = ?', '[{"key":"A","text":"5"},{"key":"B","text":"6"},{"key":"C","text":"7"}]', 'B', '9-3=6', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_TAP', 1, '8 - 2 = ?', '[{"key":"A","text":"5"},{"key":"B","text":"6"},{"key":"C","text":"7"}]', 'B', '8-2=6', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_intro'), 'SCENE_TAP', 1, '4 + 5 = ?', '[{"key":"A","text":"8"},{"key":"B","text":"9"},{"key":"C","text":"10"}]', 'B', '4+5=9', 10);

-- Math: More SCENE_TAP (20以内加减) for math_addsub20
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'SCENE_TAP', 2, '7 + 8 = ?', '[{"key":"A","text":"14"},{"key":"B","text":"15"},{"key":"C","text":"16"}]', 'B', '7+8=15，7和3凑成10，加剩下的5', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'SCENE_TAP', 2, '6 + 5 = ?', '[{"key":"A","text":"10"},{"key":"B","text":"11"},{"key":"C","text":"12"}]', 'B', '6+5=11，6和4凑成10，加剩下的1', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'SCENE_TAP', 2, '17 - 9 = ?', '[{"key":"A","text":"7"},{"key":"B","text":"8"},{"key":"C","text":"9"}]', 'B', '17-9=8，破十法：10-9=1，1+7=8', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'SCENE_TAP', 2, '11 - 3 = ?', '[{"key":"A","text":"7"},{"key":"B","text":"8"},{"key":"C","text":"9"}]', 'B', '11-3=8，破十法：10-3=7，7+1=8', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'SCENE_TAP', 2, '14 + 3 = ?', '[{"key":"A","text":"16"},{"key":"B","text":"17"},{"key":"C","text":"18"}]', 'B', '14+3=17，十位不变个位加', 10);

-- Math: More MATH_INPUT for math_addsub20
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'MATH_INPUT', 2, '8 + 5 = ?', NULL, '13', '8+5=13，8和2凑成10，加剩下的3', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_addsub20'), 'MATH_INPUT', 2, '16 - 7 = ?', NULL, '9', '16-7=9，破十法：10-7=3，3+6=9', 10);

-- Math: More SCENE_MATCH for math_geometry (color + size matching)
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_geometry'), 'SCENE_MATCH', 3, '哪个是红色的圆形？', '[{"key":"RED_CIRCLE","label":"红色圆形","cssShape":"circle","color":"rose"},{"key":"BLUE_SQUARE","label":"蓝色正方形","cssShape":"square","color":"sky"},{"key":"GREEN_TRIANGLE","label":"绿色三角形","cssShape":"triangle","color":"emerald"},{"key":"YELLOW_RECTANGLE","label":"黄色长方形","cssShape":"rectangle","color":"amber"}]', 'RED_CIRCLE', '红色+圆形=红色圆形', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_geometry'), 'SCENE_MATCH', 3, '哪个是绿色的三角形？', '[{"key":"RED_CIRCLE","label":"红色圆形","cssShape":"circle","color":"rose"},{"key":"BLUE_SQUARE","label":"蓝色正方形","cssShape":"square","color":"sky"},{"key":"GREEN_TRIANGLE","label":"绿色三角形","cssShape":"triangle","color":"emerald"},{"key":"YELLOW_RECTANGLE","label":"黄色长方形","cssShape":"rectangle","color":"amber"}]', 'GREEN_TRIANGLE', '绿色+三角形=绿色三角形', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_geometry'), 'SCENE_MATCH', 3, '哪个是蓝色的正方形？', '[{"key":"RED_CIRCLE","label":"红色圆形","cssShape":"circle","color":"rose"},{"key":"BLUE_SQUARE","label":"蓝色正方形","cssShape":"square","color":"sky"},{"key":"GREEN_TRIANGLE","label":"绿色三角形","cssShape":"triangle","color":"emerald"},{"key":"YELLOW_RECTANGLE","label":"黄色长方形","cssShape":"rectangle","color":"amber"}]', 'BLUE_SQUARE', '蓝色+正方形=蓝色正方形', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_geometry'), 'SCENE_MATCH', 3, '哪个是黄色的长方形？', '[{"key":"RED_CIRCLE","label":"红色圆形","cssShape":"circle","color":"rose"},{"key":"BLUE_SQUARE","label":"蓝色正方形","cssShape":"square","color":"sky"},{"key":"GREEN_TRIANGLE","label":"绿色三角形","cssShape":"triangle","color":"emerald"},{"key":"YELLOW_RECTANGLE","label":"黄色长方形","cssShape":"rectangle","color":"amber"}]', 'YELLOW_RECTANGLE', '黄色+长方形=黄色长方形', 10);

-- Math: More SCENE_TAP for math_geometry (图形计数)
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_geometry'), 'SCENE_TAP', 3, '一个正方形有( )条边？', '[{"key":"A","text":"3"},{"key":"B","text":"4"},{"key":"C","text":"5"}]', 'B', '正方形有4条一样长的边', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_geometry'), 'SCENE_TAP', 3, '一个三角形有( )个角？', '[{"key":"A","text":"2"},{"key":"B","text":"3"},{"key":"C","text":"4"}]', 'B', '三角形有3个角', 10);

-- Chinese: SCENE_TAP (汉字部首识别) for chinese_intro
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'SCENE_TAP', 1, '"河"字的偏旁是什么？', '[{"key":"A","text":"氵"},{"key":"B","text":"亻"},{"key":"C","text":"口"}]', 'A', '河是水字旁（氵），表示和水有关', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'SCENE_TAP', 1, '"花"字的偏旁是什么？', '[{"key":"A","text":"木"},{"key":"B","text":"艹"},{"key":"C","text":"火"}]', 'B', '花是草字头（艹），表示和植物有关', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'SCENE_TAP', 1, '"打"字的偏旁是什么？', '[{"key":"A","text":"口"},{"key":"B","text":"氵"},{"key":"C","text":"扌"}]', 'C', '打是提手旁（扌），表示和手有关', 10);

-- English: SCENE_MATCH (letter-to-picture) for english_intro
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'SCENE_MATCH', 1, '点击图片："A for ___"', '[{"key":"APPLE","label":"🍎 Apple","cssShape":"circle","color":"rose"},{"key":"BOOK","label":"📖 Book","cssShape":"square","color":"sky"},{"key":"CAT","label":"🐱 Cat","cssShape":"triangle","color":"amber"},{"key":"DOG","label":"🐶 Dog","cssShape":"rectangle","color":"emerald"}]', 'APPLE', 'A is for Apple 🍎', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'SCENE_MATCH', 1, '点击图片："B for ___"', '[{"key":"APPLE","label":"🍎 Apple","cssShape":"circle","color":"rose"},{"key":"BOOK","label":"📖 Book","cssShape":"square","color":"sky"},{"key":"CAT","label":"🐱 Cat","cssShape":"triangle","color":"amber"},{"key":"DOG","label":"🐶 Dog","cssShape":"rectangle","color":"emerald"}]', 'BOOK', 'B is for Book 📖', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'SCENE_MATCH', 1, '点击图片："C for ___"', '[{"key":"APPLE","label":"🍎 Apple","cssShape":"circle","color":"rose"},{"key":"BOOK","label":"📖 Book","cssShape":"square","color":"sky"},{"key":"CAT","label":"🐱 Cat","cssShape":"triangle","color":"amber"},{"key":"DOG","label":"🐶 Dog","cssShape":"rectangle","color":"emerald"}]', 'CAT', 'C is for Cat 🐱', 10);

-- English: SCENE_TAP (word-to-picture) for english_vocab
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'SCENE_TAP', 2, '哪个是"太阳"的英文？', '[{"key":"A","text":"sun"},{"key":"B","text":"moon"},{"key":"C","text":"star"}]', 'A', '太阳的英文是 sun', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'SCENE_TAP', 2, '哪个是"水"的英文？', '[{"key":"A","text":"fire"},{"key":"B","text":"water"},{"key":"C","text":"earth"}]', 'B', '水的英文是 water', 10);

-- ============================================================
-- Sprint A: New Knowledge Nodes (Chinese rebuild + Math expansion + English fix)
-- ============================================================

-- Chinese: New Grade 1 nodes (pinyin, shizi, kewen) — replace old poetry
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, parent_node_id, order_index) VALUES
('chinese', 'chinese_pinyin', '拼音入门', '学习声母、韵母和声调，听音识字母', 1, NULL, 4),
('chinese', 'chinese_shizi', '识字基础', '认识一年级上100个常用汉字，掌握偏旁部首', 1, NULL, 5),
('chinese', 'chinese_kewen', '课文朗读', '朗读儿歌和课文，背诵经典篇目', 2, NULL, 6);

-- Math: New topic nodes (fill Grade 1 curriculum gaps)
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, parent_node_id, order_index) VALUES
('math', 'math_count', '数一数', '认识1-20各数，练习数数和写数', 1, NULL, 4),
('math', 'math_compare', '比多少', '比较大小、多少、高矮、长短', 1, NULL, 5),
('math', 'math_1to5', '1~5的认识', '认识1~5各数，掌握基数和序数', 1, NULL, 6),
('math', 'math_6to10', '6~10的认识', '认识6~10各数，理解数位和组成', 1, NULL, 7),
('math', 'math_11to20', '11~20的认识', '认识11~20各数，理解十位和个位', 1, NULL, 8),
('math', 'math_clock', '认识钟表', '认识整时（1:00-12:00），会拨钟表', 2, NULL, 9),
('math', 'math_money', '认识人民币', '认识元币（1元/5元/10元），简单金额计算', 2, NULL, 10),
('math', 'math_pattern', '找规律', '发现颜色、形状、数字的简单排列规律', 2, NULL, 11);

-- English: New topic node (letters + fix vocab alignment)
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, parent_node_id, order_index) VALUES
('english', 'english_letters', '字母与发音', '认识26个字母大小写，听音选字母', 1, NULL, 5);

-- ============================================================
-- Sprint A: Chinese — 拼音入门 (chinese_pinyin) ~20 questions
-- ============================================================

-- SCENE_PINYIN: 听音选拼音字母
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_PINYIN', 1, '听发音，哪个是声母 b？', '[{"key":"b","text":"b"},{"key":"p","text":"p"},{"key":"d","text":"d"},{"key":"m","text":"m"},{"key":"f","text":"f"},{"key":"t","text":"t"}]', 'b', 'b 是双唇不送气清塞音，发音时双唇闭合然后突然打开', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_PINYIN', 1, '听发音，哪个是声母 p？', '[{"key":"b","text":"b"},{"key":"p","text":"p"},{"key":"d","text":"d"},{"key":"q","text":"q"},{"key":"f","text":"f"},{"key":"t","text":"t"}]', 'p', 'p 是双唇送气清塞音，发音时双唇闭合然后用力送气', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_PINYIN', 1, '听发音，哪个是声母 m？', '[{"key":"n","text":"n"},{"key":"m","text":"m"},{"key":"l","text":"l"},{"key":"h","text":"h"},{"key":"w","text":"w"},{"key":"f","text":"f"}]', 'm', 'm 是双唇鼻音，发音时双唇闭合气流从鼻腔出来', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_PINYIN', 1, '听发音，哪个是声母 d？', '[{"key":"b","text":"b"},{"key":"t","text":"t"},{"key":"d","text":"d"},{"key":"g","text":"g"},{"key":"k","text":"k"},{"key":"p","text":"p"}]', 'd', 'd 是舌尖中不送气清塞音', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_PINYIN', 1, '听发音，哪个是声母 t？', '[{"key":"d","text":"d"},{"key":"t","text":"t"},{"key":"l","text":"l"},{"key":"n","text":"n"},{"key":"g","text":"g"},{"key":"k","text":"k"}]', 't', 't 是舌尖中送气清塞音', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_PINYIN', 1, '听发音，哪个是声母 n？', '[{"key":"m","text":"m"},{"key":"l","text":"l"},{"key":"n","text":"n"},{"key":"r","text":"r"},{"key":"h","text":"h"},{"key":"f","text":"f"}]', 'n', 'n 是舌尖中鼻音', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_PINYIN', 1, '听发音，哪个是声母 l？', '[{"key":"n","text":"n"},{"key":"r","text":"r"},{"key":"l","text":"l"},{"key":"m","text":"m"},{"key":"d","text":"d"},{"key":"t","text":"t"}]', 'l', 'l 是舌尖中边音', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_PINYIN', 1, '听发音，哪个是声母 g？', '[{"key":"k","text":"k"},{"key":"h","text":"h"},{"key":"g","text":"g"},{"key":"d","text":"d"},{"key":"b","text":"b"},{"key":"p","text":"p"}]', 'g', 'g 是舌根不送气清塞音', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_PINYIN', 1, '听发音，哪个是声母 k？', '[{"key":"g","text":"g"},{"key":"k","text":"k"},{"key":"h","text":"h"},{"key":"t","text":"t"},{"key":"d","text":"d"},{"key":"p","text":"p"}]', 'k', 'k 是舌根送气清塞音', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_PINYIN', 1, '听发音，哪个是声母 h？', '[{"key":"g","text":"g"},{"key":"k","text":"k"},{"key":"h","text":"h"},{"key":"f","text":"f"},{"key":"m","text":"m"},{"key":"n","text":"n"}]', 'h', 'h 是舌根清擦音', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_PINYIN', 1, '听发音，哪个是声母 j？', '[{"key":"q","text":"q"},{"key":"x","text":"x"},{"key":"j","text":"j"},{"key":"zh","text":"zh"},{"key":"ch","text":"ch"},{"key":"sh","text":"sh"}]', 'j', 'j 是舌面不送气清塞擦音', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_PINYIN', 1, '听发音，哪个是声母 zh？', '[{"key":"z","text":"z"},{"key":"c","text":"c"},{"key":"zh","text":"zh"},{"key":"ch","text":"ch"},{"key":"sh","text":"sh"},{"key":"s","text":"s"}]', 'zh', 'zh 是舌尖后不送气清塞擦音（翘舌音）', 10);

-- SCENE_TAP: 听音选字母 (pinyin character recognition)
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_TAP', 1, '下面哪个是韵母 a？', '[{"key":"A","text":"a"},{"key":"B","text":"o"},{"key":"C","text":"e"}]', 'A', 'a 是开口呼韵母，嘴巴张得大大的', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_TAP', 1, '下面哪个是韵母 i？', '[{"key":"A","text":"u"},{"key":"B","text":"ü"},{"key":"C","text":"i"}]', 'C', 'i 是齐齿呼韵母，牙齿对齐', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_TAP', 1, '下面哪个是韵母 u？', '[{"key":"A","text":"u"},{"key":"B","text":"ü"},{"key":"C","text":"o"}]', 'A', 'u 是合口呼韵母，嘴巴圆圆的', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_TAP', 1, '"ba" 的声母是？', '[{"key":"A","text":"a"},{"key":"B","text":"b"},{"key":"C","text":"ba"}]', 'B', 'ba 的声母是 b，韵母是 a', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_TAP', 1, '"ma" 的韵母是？', '[{"key":"A","text":"m"},{"key":"B","text":"a"},{"key":"C","text":"ma"}]', 'B', 'ma 的声母是 m，韵母是 a', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_TAP', 1, '一声（阴平）的符号是？', '[{"key":"A","text":"ˊ"},{"key":"B","text":"ˇ"},{"key":"C","text":"ˉ"}]', 'C', '一声用横线ˉ表示，又高又平', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_TAP', 1, '三声（上声）的符号是？', '[{"key":"A","text":"ˉ"},{"key":"B","text":"ˇ"},{"key":"C","text":"ˋ"}]', 'B', '三声用ˇ表示，先降后升', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pinyin'), 'SCENE_TAP', 1, '"妈"的拼音声调是几声？', '[{"key":"A","text":"一声"},{"key":"B","text":"二声"},{"key":"C","text":"三声"}]', 'A', 'mā（妈）是一声，又高又平', 10);

-- ============================================================
-- Sprint A: Chinese — 识字基础 (chinese_shizi) ~25 questions
-- ============================================================

-- SCENE_CHAR_BUILD: 汉字工坊组装汉字
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_CHAR_BUILD', 1, '拼一拼：亻+ 门 = ？', '{"radical":"亻","phonetic":"门","targetChar":"们"}', '们', '亻（单人旁）+ 门 = 们，表示多人', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_CHAR_BUILD', 1, '拼一拼：氵+ 可 = ？', '{"radical":"氵","phonetic":"可","targetChar":"河"}', '河', '氵（三点水）+ 可 = 河，表示河流', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_CHAR_BUILD', 1, '拼一拼：口 + 十 = ？', '{"radical":"口","phonetic":"十","targetChar":"叶"}', '叶', '口 + 十 = 叶，表示叶子', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_CHAR_BUILD', 1, '拼一拼：木 + 几 = ？', '{"radical":"木","phonetic":"几","targetChar":"机"}', '机', '木 + 几 = 机，表示机器', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_CHAR_BUILD', 1, '拼一拼：女 + 马 = ？', '{"radical":"女","phonetic":"马","targetChar":"妈"}', '妈', '女 + 马 = 妈，表示妈妈', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_CHAR_BUILD', 1, '拼一拼：扌+ 丁 = ？', '{"radical":"扌","phonetic":"丁","targetChar":"打"}', '打', '扌（提手旁）+ 丁 = 打，表示击打', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_CHAR_BUILD', 1, '拼一拼：日 + 月 = ？', '{"radical":"日","phonetic":"月","targetChar":"明"}', '明', '日 + 月 = 明，表示明亮', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_CHAR_BUILD', 1, '拼一拼：女 + 子 = ？', '{"radical":"女","phonetic":"子","targetChar":"好"}', '好', '女 + 子 = 好，表示美好', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_CHAR_BUILD', 1, '拼一拼：亻+ 尔 = ？', '{"radical":"亻","phonetic":"尔","targetChar":"你"}', '你', '亻+ 尔 = 你，表示第二人称', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_CHAR_BUILD', 1, '拼一拼：氵+ 工 = ？', '{"radical":"氵","phonetic":"工","targetChar":"江"}', '江', '氵+ 工 = 江，表示江河', 10);

-- SCENE_TAP: 认字选择
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '下面哪个字是"大"？', '[{"key":"A","text":"大"},{"key":"B","text":"太"},{"key":"C","text":"天"}]', 'A', '大就是大小的大，一个人张开双臂的样子', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '下面哪个字是"小"？', '[{"key":"A","text":"少"},{"key":"B","text":"小"},{"key":"C","text":"水"}]', 'B', '小就是大小的小', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '下面哪个字是"上"？', '[{"key":"A","text":"下"},{"key":"B","text":"上"},{"key":"C","text":"中"}]', 'B', '上表示位置在高处，向上的方向', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '"山"字有几笔？', '[{"key":"A","text":"2笔"},{"key":"B","text":"3笔"},{"key":"C","text":"4笔"}]', 'B', '山字3笔：竖、竖折、竖', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '"水"字有几笔？', '[{"key":"A","text":"3笔"},{"key":"B","text":"4笔"},{"key":"C","text":"5笔"}]', 'B', '水字4笔：竖钩、横撇、撇、捺', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '下面哪个字和"日"有关？', '[{"key":"A","text":"明"},{"key":"B","text":"河"},{"key":"C","text":"打"}]', 'A', '明字含有"日"，表示光亮', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '"人"加一笔变成什么字？', '[{"key":"A","text":"大"},{"key":"B","text":"八"},{"key":"C","text":"入"}]', 'A', '人上面加一横就是大', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '"一"加一笔变成什么字？', '[{"key":"A","text":"三"},{"key":"B","text":"二"},{"key":"C","text":"十"}]', 'B', '一上面再加一横就是二', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '下面哪个字是"火"？', '[{"key":"A","text":"水"},{"key":"B","text":"火"},{"key":"C","text":"木"}]', 'B', '火是火焰的形状，人字加两点', 10);

-- SCENE_MATCH: 翻牌配对（字图配对）
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_MATCH', 1, '哪个是"日"？', '[{"key":"RI","label":"日","cssShape":"circle","color":"amber"},{"key":"YUE","label":"月","cssShape":"circle","color":"sky"},{"key":"SHAN","label":"山","cssShape":"triangle","color":"emerald"},{"key":"SHUI","label":"水","cssShape":"circle","color":"teal"}]', 'RI', '日代表太阳，圆圆的是太阳', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_MATCH', 1, '哪个是"月"？', '[{"key":"RI","label":"日","cssShape":"circle","color":"amber"},{"key":"YUE","label":"月","cssShape":"circle","color":"sky"},{"key":"SHAN","label":"山","cssShape":"triangle","color":"emerald"},{"key":"SHUI","label":"水","cssShape":"circle","color":"teal"}]', 'YUE', '月代表月亮，弯弯的是月亮', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_MATCH', 1, '哪个是"山"？', '[{"key":"RI","label":"日","cssShape":"circle","color":"amber"},{"key":"YUE","label":"月","cssShape":"circle","color":"sky"},{"key":"SHAN","label":"山","cssShape":"triangle","color":"emerald"},{"key":"SHUI","label":"水","cssShape":"circle","color":"teal"}]', 'SHAN', '山像三角形一样尖尖的', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_MATCH', 1, '哪个是"田"？', '[{"key":"TIAN","label":"田","cssShape":"square","color":"emerald"},{"key":"MU","label":"木","cssShape":"rectangle","color":"teal"},{"key":"HUO","label":"火","cssShape":"triangle","color":"rose"},{"key":"TU","label":"土","cssShape":"square","color":"amber"}]', 'TIAN', '田像一块块方方的田地', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_MATCH', 1, '哪个是"木"？', '[{"key":"TIAN","label":"田","cssShape":"square","color":"emerald"},{"key":"MU","label":"木","cssShape":"rectangle","color":"teal"},{"key":"HUO","label":"火","cssShape":"triangle","color":"rose"},{"key":"TU","label":"土","cssShape":"square","color":"amber"}]', 'MU', '木像一棵树，有树干和树枝', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_MATCH', 1, '哪个是"火"？', '[{"key":"TIAN","label":"田","cssShape":"square","color":"emerald"},{"key":"MU","label":"木","cssShape":"rectangle","color":"teal"},{"key":"HUO","label":"火","cssShape":"triangle","color":"rose"},{"key":"TU","label":"土","cssShape":"square","color":"amber"}]', 'HUO', '火像燃烧的火苗，上面尖尖的', 10);

-- ============================================================
-- Sprint A: Chinese — 课文朗读 (chinese_kewen) ~7 questions
-- ============================================================
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'SCENE_TAP', 2, '"一去二三里，烟村四五家"是几年级的课文？', '[{"key":"A","text":"一年级"},{"key":"B","text":"二年级"},{"key":"C","text":"三年级"}]', 'A', '这是一年级上册的课文《一去二三里》', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'SCENE_TAP', 2, '"鹅鹅鹅，曲项向天歌"的作者是？', '[{"key":"A","text":"李白"},{"key":"B","text":"骆宾王"},{"key":"C","text":"孟浩然"}]', 'B', '《咏鹅》是骆宾王7岁时写的诗', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'FILL_BLANK', 2, '"春眠不觉晓，处处闻______。" 请填空', NULL, '啼鸟', '出自孟浩然《春晓》：春眠不觉晓，处处闻啼鸟。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'FILL_BLANK', 2, '"______依山尽，黄河入海流。" 请填空', NULL, '白日', '出自王之涣《登鹳雀楼》：白日依山尽，黄河入海流。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'POEM_SEQUENCE', 2, '请将《静夜思》的诗句按正确顺序排列', '["床前明月光","疑是地上霜","举头望明月","低头思故乡"]', '1,2,3,4', '李白《静夜思》：床前明月光，疑是地上霜。举头望明月，低头思故乡。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'POEM_SEQUENCE', 2, '请将《春晓》的诗句按正确顺序排列', '["春眠不觉晓","处处闻啼鸟","夜来风雨声","花落知多少"]', '1,2,3,4', '孟浩然《春晓》：春眠不觉晓，处处闻啼鸟。夜来风雨声，花落知多少。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'FILL_BLANK', 2, '"举头望明月，低头思______。" 请填空', NULL, '故乡', '出自李白《静夜思》：举头望明月，低头思故乡。', 10);

-- ============================================================
-- Sprint A: Math — 数一数 (math_count) ~5 questions
-- ============================================================
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_count'), 'SCENE_TAP', 1, '数一数：🐱🐱🐱 有几只小猫？', '[{"key":"A","text":"2"},{"key":"B","text":"3"},{"key":"C","text":"4"}]', 'B', '一个一个数：1、2、3，有3只小猫', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_count'), 'SCENE_TAP', 1, '数一数：🍎🍎🍎🍎🍎 有几个苹果？', '[{"key":"A","text":"4"},{"key":"B","text":"5"},{"key":"C","text":"6"}]', 'B', '数到5：1、2、3、4、5', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_count'), 'SCENE_TAP', 1, '数一数：⭐⭐⭐⭐⭐⭐⭐ 有几颗星星？', '[{"key":"A","text":"6"},{"key":"B","text":"7"},{"key":"C","text":"8"}]', 'B', '一颗一颗数：有7颗星星', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_count'), 'SCENE_TAP', 1, '下面哪个数字是"10"？', '[{"key":"A","text":"01"},{"key":"B","text":"10"},{"key":"C","text":"100"}]', 'B', '10由一个"1"和一个"0"组成', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_count'), 'SCENE_TAP', 1, '一共有多少只蝴蝶？🦋🦋🦋🦋🦋🦋🦋🦋', '[{"key":"A","text":"7"},{"key":"B","text":"8"},{"key":"C","text":"9"}]', 'B', '一行一行数：有8只蝴蝶', 10);

-- ============================================================
-- Sprint A: Math — 比多少 (math_compare) ~5 questions
-- ============================================================
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_compare'), 'SCENE_TAP', 1, '🍎🍎🍎 vs 🍊🍊🍊🍊 哪个多？', '[{"key":"A","text":"苹果多"},{"key":"B","text":"橘子多"},{"key":"C","text":"一样多"}]', 'B', '苹果3个，橘子4个，4>3，橘子更多', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_compare'), 'SCENE_TAP', 1, '5 和 8 谁更大？', '[{"key":"A","text":"5大"},{"key":"B","text":"8大"},{"key":"C","text":"一样大"}]', 'B', '8在5的后面，所以8>5', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_compare'), 'SCENE_TAP', 1, '2 < ? 空格里可以填几？', '[{"key":"A","text":"1"},{"key":"B","text":"2"},{"key":"C","text":"3"}]', 'C', '2<3，3大于2', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_compare'), 'SCENE_TAP', 1, '7 > ? 空格里可以填几？', '[{"key":"A","text":"8"},{"key":"B","text":"5"},{"key":"C","text":"9"}]', 'B', '7>5，7比5大', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_compare'), 'SCENE_TAP', 1, '🐶🐶🐶🐶 vs 🐱🐱🐱🐱 谁多？', '[{"key":"A","text":"狗多"},{"key":"B","text":"猫多"},{"key":"C","text":"一样多"}]', 'C', '4=4，一样多', 10);

-- ============================================================
-- Sprint A: Math — 1~5认识 (math_1to5) ~5 questions
-- ============================================================
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_1to5'), 'SCENE_TAP', 1, '1 + 2 = ?', '[{"key":"A","text":"2"},{"key":"B","text":"3"},{"key":"C","text":"4"}]', 'B', '1+2=3，伸出1根手指再加2根', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_1to5'), 'SCENE_TAP', 1, '4 - 1 = ?', '[{"key":"A","text":"2"},{"key":"B","text":"3"},{"key":"C","text":"4"}]', 'B', '4-1=3，4个拿走1个还剩3个', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_1to5'), 'SCENE_TAP', 1, '3 + 2 = ?', '[{"key":"A","text":"4"},{"key":"B","text":"5"},{"key":"C","text":"6"}]', 'B', '3+2=5', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_1to5'), 'SCENE_TAP', 1, '5 - 3 = ?', '[{"key":"A","text":"1"},{"key":"B","text":"2"},{"key":"C","text":"3"}]', 'B', '5-3=2，5个拿走3个还剩2个', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_1to5'), 'SCENE_TAP', 1, '第3只小动物是什么？🐶🐱🐰🐹🐻', '[{"key":"A","text":"🐱"},{"key":"B","text":"🐰"},{"key":"C","text":"🐹"}]', 'B', '从左往右数：第1🐶、第2🐱、第3🐰', 10);

-- ============================================================
-- Sprint A: Math — 6~10认识 (math_6to10) ~5 questions
-- ============================================================
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_6to10'), 'SCENE_TAP', 1, '6可以分成 3 和 几？', '[{"key":"A","text":"2"},{"key":"B","text":"3"},{"key":"C","text":"4"}]', 'B', '3+3=6，6可以分成3和3', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_6to10'), 'SCENE_TAP', 1, '8 - 4 = ?', '[{"key":"A","text":"3"},{"key":"B","text":"4"},{"key":"C","text":"5"}]', 'B', '8-4=4', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_6to10'), 'SCENE_TAP', 1, '7 + 2 = ?', '[{"key":"A","text":"8"},{"key":"B","text":"9"},{"key":"C","text":"10"}]', 'B', '7+2=9', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_6to10'), 'SCENE_TAP', 1, '10 - 3 = ?', '[{"key":"A","text":"6"},{"key":"B","text":"7"},{"key":"C","text":"8"}]', 'B', '10-3=7', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_6to10'), 'SCENE_TAP', 1, '9 的相邻数是？', '[{"key":"A","text":"7和8"},{"key":"B","text":"8和10"},{"key":"C","text":"10和11"}]', 'B', '9的前面是8，后面是10', 10);

-- ============================================================
-- Sprint A: Math — 11~20认识 (math_11to20) ~5 questions
-- ============================================================
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_11to20'), 'SCENE_TAP', 1, '15 是由几个十和几个一组成的？', '[{"key":"A","text":"1个十和5个一"},{"key":"B","text":"5个十和1个一"},{"key":"C","text":"1个十和1个一"}]', 'A', '15的十位是1（1个十），个位是5（5个一）', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_11to20'), 'SCENE_TAP', 1, '1个十和3个一组成？', '[{"key":"A","text":"10"},{"key":"B","text":"13"},{"key":"C","text":"31"}]', 'B', '1个十=10，3个一=3，10+3=13', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_11to20'), 'SCENE_TAP', 1, '18 的十位上的数字是？', '[{"key":"A","text":"1"},{"key":"B","text":"8"},{"key":"C","text":"18"}]', 'A', '18的十位是1，个位是8', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_11to20'), 'SCENE_TAP', 1, '10 + 7 = ?', '[{"key":"A","text":"16"},{"key":"B","text":"17"},{"key":"C","text":"18"}]', 'B', '10+7=17，1个十加7个一', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_11to20'), 'SCENE_TAP', 1, '20 里面有几个十？', '[{"key":"A","text":"1个"},{"key":"B","text":"2个"},{"key":"C","text":"0个"}]', 'B', '20=2个十+0个一', 10);

-- ============================================================
-- Sprint A: Math — 认识钟表 (math_clock) ~8 questions (SCENE_CLOCK)
-- ============================================================
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_clock'), 'SCENE_CLOCK', 2, '请把时针拨到 7:00', '{"hour":7}', '7', '7:00 该起床啦！时针指向7，分针指向12', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_clock'), 'SCENE_CLOCK', 2, '请把时针拨到 8:00', '{"hour":8}', '8', '8:00 上学啦！时针指向8，分针指向12', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_clock'), 'SCENE_CLOCK', 2, '请把时针拨到 12:00', '{"hour":12}', '12', '12:00 吃午饭啦！时针和分针都指向12', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_clock'), 'SCENE_CLOCK', 2, '请把时针拨到 3:00', '{"hour":3}', '3', '3:00 下午活动时间！时针指向3', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_clock'), 'SCENE_CLOCK', 2, '请把时针拨到 6:00', '{"hour":6}', '6', '6:00 吃晚饭啦！时针指向6', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_clock'), 'SCENE_CLOCK', 2, '请把时针拨到 9:00', '{"hour":9}', '9', '9:00 该睡觉了！时针指向9', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_clock'), 'SCENE_CLOCK', 2, '请把时针拨到 1:00', '{"hour":1}', '1', '1:00 午休时间！时针指向1', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_clock'), 'SCENE_CLOCK', 2, '请把时针拨到 4:00', '{"hour":4}', '4', '4:00 放学啦！时针指向4', 10);

-- ============================================================
-- Sprint A: Math — 认识人民币 (math_money) ~6 questions (SCENE_SHOP)
-- ============================================================
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_money'), 'SCENE_SHOP', 2, '请付 3 元买苹果', '{"price":3,"itemName":"苹果"}', '3', '拿出3张1元或选择合适的纸币凑3元', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_money'), 'SCENE_SHOP', 2, '请付 5 元买面包', '{"price":5,"itemName":"面包"}', '5', '可以付1张5元或5张1元', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_money'), 'SCENE_SHOP', 2, '请付 8 元买铅笔盒', '{"price":8,"itemName":"铅笔盒"}', '8', '可以付5元+1元+1元+1元=8元', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_money'), 'SCENE_SHOP', 2, '请付 10 元买故事书', '{"price":10,"itemName":"故事书"}', '10', '可以付1张10元', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_money'), 'SCENE_SHOP', 2, '请付 6 元买彩笔', '{"price":6,"itemName":"彩笔"}', '6', '5元+1元=6元', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_money'), 'SCENE_SHOP', 2, '请付 4 元买橡皮', '{"price":4,"itemName":"橡皮"}', '4', '1元+1元+1元+1元=4元', 10);

-- ============================================================
-- Sprint A: Math — 找规律 (math_pattern) ~5 questions (SCENE_MATCH)
-- ============================================================
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_pattern'), 'SCENE_MATCH', 2, '🔴🔵🔴🔵🔴？下一个是什么颜色？', '[{"key":"RED","label":"🔴 红色","cssShape":"circle","color":"rose"},{"key":"BLUE","label":"🔵 蓝色","cssShape":"circle","color":"sky"}]', 'BLUE', '规律是红蓝交替：红蓝红蓝红→下一个是蓝', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_pattern'), 'SCENE_MATCH', 2, '⬜🟨⬜🟨⬜？下一个是什么？', '[{"key":"WHITE","label":"⬜ 白色","cssShape":"square","color":"sky"},{"key":"YELLOW","label":"🟨 黄色","cssShape":"square","color":"amber"}]', 'YELLOW', '规律是白黄交替', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_pattern'), 'SCENE_MATCH', 2, '🔺🔺🟢🔺🔺🟢🔺？下一个是什么？', '[{"key":"TRI","label":"🔺 三角形","cssShape":"triangle","color":"rose"},{"key":"CIRC","label":"🟢 圆形","cssShape":"circle","color":"emerald"}]', 'TRI', '规律是两个三角形一个圆形：🔺🔺🟢/🔺🔺🟢/🔺→下一个是🔺', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_pattern'), 'SCENE_MATCH', 2, '1 2 1 2 1？接下来是什么数字？', '[{"key":"ONE","label":"1","cssShape":"circle","color":"rose"},{"key":"TWO","label":"2","cssShape":"circle","color":"sky"}]', 'TWO', '规律是1、2交替', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_pattern'), 'SCENE_MATCH', 2, '⭐🌙⭐🌙⭐🌙？接下来是什么？', '[{"key":"STAR","label":"⭐ 星星","cssShape":"circle","color":"amber"},{"key":"MOON","label":"🌙 月亮","cssShape":"circle","color":"violet"}]', 'STAR', '规律是星星月亮交替：星星月亮星星月亮星星月亮→下一个是星星', 10);

-- ============================================================
-- Sprint A: English — 字母与发音 (english_letters) ~18 questions
-- ============================================================

-- SCENE_MATCH: 字母选图 (letter-to-picture matching)
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_MATCH', 1, 'A is for ___?', '[{"key":"APPLE","label":"🍎 Apple","cssShape":"circle","color":"rose"},{"key":"BALL","label":"⚽ Ball","cssShape":"circle","color":"sky"},{"key":"CAR","label":"🚗 Car","cssShape":"circle","color":"amber"},{"key":"DOG","label":"🐶 Dog","cssShape":"circle","color":"emerald"}]', 'APPLE', 'A is for Apple — 苹果', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_MATCH', 1, 'B is for ___?', '[{"key":"APPLE","label":"🍎 Apple","cssShape":"circle","color":"rose"},{"key":"BALL","label":"⚽ Ball","cssShape":"circle","color":"sky"},{"key":"CAR","label":"🚗 Car","cssShape":"circle","color":"amber"},{"key":"DOG","label":"🐶 Dog","cssShape":"circle","color":"emerald"}]', 'BALL', 'B is for Ball — 球', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_MATCH', 1, 'C is for ___?', '[{"key":"APPLE","label":"🍎 Apple","cssShape":"circle","color":"rose"},{"key":"BALL","label":"⚽ Ball","cssShape":"circle","color":"sky"},{"key":"CAR","label":"🚗 Car","cssShape":"circle","color":"amber"},{"key":"DOG","label":"🐶 Dog","cssShape":"circle","color":"emerald"}]', 'CAR', 'C is for Car — 汽车', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_MATCH', 1, 'D is for ___?', '[{"key":"APPLE","label":"🍎 Apple","cssShape":"circle","color":"rose"},{"key":"BALL","label":"⚽ Ball","cssShape":"circle","color":"sky"},{"key":"CAR","label":"🚗 Car","cssShape":"circle","color":"amber"},{"key":"DOG","label":"🐶 Dog","cssShape":"circle","color":"emerald"}]', 'DOG', 'D is for Dog — 狗', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_MATCH', 1, 'E is for ___?', '[{"key":"EGG","label":"🥚 Egg","cssShape":"circle","color":"amber"},{"key":"FISH","label":"🐟 Fish","cssShape":"circle","color":"sky"},{"key":"GOAT","label":"🐐 Goat","cssShape":"circle","color":"emerald"},{"key":"HAT","label":"🎩 Hat","cssShape":"circle","color":"violet"}]', 'EGG', 'E is for Egg — 鸡蛋', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_MATCH', 1, 'F is for ___?', '[{"key":"EGG","label":"🥚 Egg","cssShape":"circle","color":"amber"},{"key":"FISH","label":"🐟 Fish","cssShape":"circle","color":"sky"},{"key":"GOAT","label":"🐐 Goat","cssShape":"circle","color":"emerald"},{"key":"HAT","label":"🎩 Hat","cssShape":"circle","color":"violet"}]', 'FISH', 'F is for Fish — 鱼', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_MATCH', 1, 'G is for ___?', '[{"key":"EGG","label":"🥚 Egg","cssShape":"circle","color":"amber"},{"key":"FISH","label":"🐟 Fish","cssShape":"circle","color":"sky"},{"key":"GOAT","label":"🐐 Goat","cssShape":"circle","color":"emerald"},{"key":"HAT","label":"🎩 Hat","cssShape":"circle","color":"violet"}]', 'GOAT', 'G is for Goat — 山羊', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_MATCH', 1, 'H is for ___?', '[{"key":"EGG","label":"🥚 Egg","cssShape":"circle","color":"amber"},{"key":"FISH","label":"🐟 Fish","cssShape":"circle","color":"sky"},{"key":"GOAT","label":"🐐 Goat","cssShape":"circle","color":"emerald"},{"key":"HAT","label":"🎩 Hat","cssShape":"circle","color":"violet"}]', 'HAT', 'H is for Hat — 帽子', 10);

-- SCENE_TAP: 听音选字母 + 选单词
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_TAP', 1, '下面哪个是大写字母 A？', '[{"key":"A","text":"A"},{"key":"B","text":"a"},{"key":"C","text":"B"}]', 'A', '大写 A 像一座尖尖的山', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_TAP', 1, '下面哪个是小写字母 b？', '[{"key":"A","text":"d"},{"key":"B","text":"p"},{"key":"C","text":"b"}]', 'C', '小写 b 圆圈在右边', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_TAP', 1, '下面哪个是小写字母 d？', '[{"key":"A","text":"b"},{"key":"B","text":"d"},{"key":"C","text":"q"}]', 'B', '小写 d 圆圈在左边', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_TAP', 1, '"cat" 的第一个字母是？', '[{"key":"A","text":"a"},{"key":"B","text":"c"},{"key":"C","text":"t"}]', 'B', 'cat 以字母 c 开头', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_TAP', 1, '哪个字母在大写字母表里排第一？', '[{"key":"A","text":"A"},{"key":"B","text":"B"},{"key":"C","text":"Z"}]', 'A', 'A 是字母表的第一个字母', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_TAP', 1, '"dog" 的最后一个字母是？', '[{"key":"A","text":"d"},{"key":"B","text":"o"},{"key":"C","text":"g"}]', 'C', 'dog 以字母 g 结尾', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_TAP', 1, '下面哪个是字母 M？', '[{"key":"A","text":"N"},{"key":"B","text":"M"},{"key":"C","text":"W"}]', 'B', 'M 像两座山连在一起', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_letters'), 'SCENE_TAP', 1, '下面哪个是字母 W？', '[{"key":"A","text":"M"},{"key":"B","text":"V"},{"key":"C","text":"W"}]', 'C', 'W 像倒过来的 M，像波浪', 10);

-- ============================================================
-- Sprint A: English — 词汇扩充 (english_intro + english_vocab) ~14 questions
-- ============================================================

-- SCENE_MATCH: 单词选图
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'SCENE_MATCH', 1, 'Which one is "sun"?', '[{"key":"SUN","label":"☀️ sun","cssShape":"circle","color":"amber"},{"key":"MOON","label":"🌙 moon","cssShape":"circle","color":"violet"},{"key":"STAR","label":"⭐ star","cssShape":"circle","color":"sky"},{"key":"CLOUD","label":"☁️ cloud","cssShape":"circle","color":"teal"}]', 'SUN', 'sun = 太阳 ☀️', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'SCENE_MATCH', 1, 'Which one is "book"?', '[{"key":"BOOK","label":"📖 book","cssShape":"rectangle","color":"sky"},{"key":"PEN","label":"🖊️ pen","cssShape":"rectangle","color":"amber"},{"key":"BAG","label":"🎒 bag","cssShape":"rectangle","color":"emerald"},{"key":"DESK","label":"🪑 desk","cssShape":"rectangle","color":"rose"}]', 'BOOK', 'book = 书 📖', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'SCENE_MATCH', 1, 'Which one is "eye"?', '[{"key":"EAR","label":"👂 ear","cssShape":"circle","color":"rose"},{"key":"EYE","label":"👁️ eye","cssShape":"circle","color":"sky"},{"key":"NOSE","label":"👃 nose","cssShape":"triangle","color":"amber"},{"key":"MOUTH","label":"👄 mouth","cssShape":"circle","color":"pink"}]', 'EYE', 'eye = 眼睛 👁️', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'SCENE_MATCH', 1, 'Which one is "hand"?', '[{"key":"HEAD","label":"🗣️ head","cssShape":"circle","color":"amber"},{"key":"HAND","label":"✋ hand","cssShape":"circle","color":"sky"},{"key":"FOOT","label":"🦶 foot","cssShape":"rectangle","color":"emerald"},{"key":"ARM","label":"💪 arm","cssShape":"rectangle","color":"rose"}]', 'HAND', 'hand = 手 ✋', 10);

-- SCENE_TAP: 选单词 + 学校/身体主题
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'SCENE_TAP', 2, '哪个是"学校"的英文？', '[{"key":"A","text":"school"},{"key":"B","text":"home"},{"key":"C","text":"park"}]', 'A', '学校的英文是 school', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'SCENE_TAP', 2, '哪个是"老师"的英文？', '[{"key":"A","text":"student"},{"key":"B","text":"teacher"},{"key":"C","text":"doctor"}]', 'B', '老师的英文是 teacher', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'SCENE_TAP', 2, '"head" 的中文意思是？', '[{"key":"A","text":"手"},{"key":"B","text":"脚"},{"key":"C","text":"头"}]', 'C', 'head = 头', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'SCENE_TAP', 2, '"mouth" 的中文意思是？', '[{"key":"A","text":"眼睛"},{"key":"B","text":"嘴巴"},{"key":"C","text":"耳朵"}]', 'B', 'mouth = 嘴巴', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'SCENE_TAP', 2, '哪个颜色是"green"？', '[{"key":"A","text":"绿色","color":"green"},{"key":"B","text":"蓝色","color":"blue"},{"key":"C","text":"黄色","color":"yellow"}]', 'A', 'green = 绿色', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'SCENE_TAP', 2, '"I ___ a boy." 填什么？', '[{"key":"A","text":"am"},{"key":"B","text":"is"},{"key":"C","text":"are"}]', 'A', 'I 后面用 am', 10);

-- VOCAB_MATCH: 主题配对
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'VOCAB_MATCH', 2, '请将左边的英文单词与右边的中文释义配对（学校主题）', '{"left":[{"id":"A","text":"pencil"},{"id":"B","text":"eraser"},{"id":"C","text":"ruler"}],"right":[{"id":"1","text":"尺子"},{"id":"2","text":"铅笔"},{"id":"3","text":"橡皮"}]}', 'A2,B3,C1', 'pencil=铅笔, eraser=橡皮, ruler=尺子', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'VOCAB_MATCH', 2, '请将左边的英文单词与右边的中文释义配对（身体主题）', '{"left":[{"id":"A","text":"nose"},{"id":"B","text":"ear"},{"id":"C","text":"hair"}],"right":[{"id":"1","text":"头发"},{"id":"2","text":"鼻子"},{"id":"3","text":"耳朵"}]}', 'A2,B3,C1', 'nose=鼻子, ear=耳朵, hair=头发', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'VOCAB_MATCH', 2, '请将左边的英文单词与右边的中文释义配对（食物主题）', '{"left":[{"id":"A","text":"milk"},{"id":"B","text":"bread"},{"id":"C","text":"egg"}],"right":[{"id":"1","text":"鸡蛋"},{"id":"2","text":"牛奶"},{"id":"3","text":"面包"}]}', 'A2,B3,C1', 'milk=牛奶, bread=面包, egg=鸡蛋', 10);

-- FILL_BLANK: 简单拼写
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'FILL_BLANK', 2, '请拼写"狗"的英文单词', NULL, 'dog', '狗的英文是 d-o-g', 10);

-- ============================================================
-- Daily Challenge Definitions
-- ============================================================
INSERT IGNORE INTO daily_challenge_def (challenge_type, description, target_value, reward_energy, icon_url, display_order) VALUES
('STUDY_SESSION', '完成 3 次学习探险', 3, 30, '📚', 1),
('ACCURACY', '单次准确率达到 80% 以上', 80, 20, '🎯', 2),
('ENERGY_EARN', '当日累计获得 100 能量', 100, 25, '⚡', 3),
('PERFECT_SESSION', '完成一次满分答题（全部正确）', 1, 40, '💯', 4);

-- ============================================================
-- Story Chapters
-- ============================================================
INSERT IGNORE INTO story_chapter (chapter_number, title, narrative, npc_name, npc_dialogue, choice_text, requirement_type, requirement_value, reward_energy, display_order) VALUES
(1, '初遇·学习能量',
 '你缓缓睁开眼，发现自己站在一片星光璀璨的虚空中。脚下是无尽的星海，头顶是流转的能量漩涡。一个温暖的声音在耳边响起……',
 '向导精灵',
 '欢迎你，被选中的学习守护者！我是学习能量宇宙的向导精灵。你看到了吗？那些黯淡的星星——知识黑洞正在吞噬我们的世界。学习精灵们正在消失，只有你能拯救它们。准备好了吗？',
 '我准备好了！告诉我该怎么做！',
 'FIRST_SPIRIT', 1, 50, 1),

(2, '诗词大陆之门',
 '你来到了诗词大陆。空气中弥漫着墨香，远处传来朗朗书声。但大陆的边缘正在被黑暗侵蚀，诗人们的力量在减弱……',
 '李白',
 '「床前明月光，疑是地上霜。」哈哈，小友，你来了！我是李白。这片大陆的文韵之力正在消散，需要真正的学习者来重新激活它。去完成诗词的挑战吧，让诗句重新响彻天地！',
 '我会用学习唤醒诗词之力！',
 'COMPLETE_STUDY', 1, 30, 2),

(3, '智慧王国召唤',
 '智慧王国的城门缓缓打开，映入眼帘的是由几何图形构成的宏伟建筑。但城市的逻辑之光在闪烁不定……',
 '智慧老人',
 '欢迎来到智慧王国，年轻的学习者。我是智慧老人。你看，那些逻辑之塔的光芒正在减弱。只有通过数学的考验，才能让智慧之火重新燃烧。去解开那些谜题吧！',
 '让我用逻辑点亮智慧之光！',
 'COMPLETE_STUDY', 1, 30, 3),

(4, '魔法学院来信',
 '一封由星光凝结的信件飘到你面前。信纸上的文字闪烁着紫色的光芒，那是魔法学院的召唤……',
 '梅林导师',
 '亲爱的学习守护者，我是魔法学院院长梅林。魔法学院的魔力之源正在枯竭，咒语书上的文字在消失。请来帮助我们，用英语的力量重新充能魔法阵。每学会一个单词，就是一道新的咒语！',
 '我这就来学习魔法！',
 'COMPLETE_STUDY', 1, 30, 4),

(5, '能量的秘密',
 '你体内的学习能量在涌动。向导精灵出现在你面前，表情严肃而温和……',
 '向导精灵',
 '你已经感受到了吧？每次学习时，你都在产生学习能量。这些能量不仅让你成长，也维系着整个学习能量宇宙的运转。你已经积累了相当可观的能量，继续加油，更多奥秘在等待着你！',
 '原来学习就是在创造能量！',
 'ENERGY_TOTAL', 200, 40, 5),

(6, '第一次进化',
 '你的精灵突然浑身发光，温暖的光芒笼罩了你们。一种奇妙的变化正在发生……',
 '精灵伙伴',
 '（精灵用欢快的声音与你心灵对话）谢谢你一直以来的照顾！我感觉到了力量在增长，就像破茧成蝶一样。这是进化的力量——是你的学习让我获得了新生！我们一起继续成长吧！',
 '太棒了！我们继续一起成长！',
 'EVOLVE_SPIRIT', 1, 50, 6),

(7, '诗词的韵律',
 '你回到诗词大陆，发现之前被黑暗侵蚀的区域开始恢复生机。一个清雅的声音传来……',
 '李清照',
 '「常记溪亭日暮，沉醉不知归路。」小友，你的努力没有白费。诗词的力量正在净化这片土地。但还有更深处的黑暗需要驱散，用你更高的准确率来唤醒更强大的诗词之力吧！',
 '我会追求更高的准确率！',
 'ACCURACY', 80, 35, 7),

(8, '逻辑的钥匙',
 '智慧王国的逻辑之塔重新亮起了光芒。毕达哥拉斯在塔顶向你招手……',
 '毕达哥拉斯',
 '万物皆数！你的数学能力正在唤醒智慧王国的核心。逻辑之塔的光芒越亮，知识宝库的大门就越接近开启。继续磨炼你的逻辑思维，完美的解答是打开宝库的钥匙！',
 '用完美解答开启知识宝库！',
 'ACCURACY', 80, 35, 8),

(9, '魔法的咒语',
 '魔法学院的魔法阵重新开始运转，紫色的光芒在脉络中流淌。梅林导师微笑着点头……',
 '梅林导师',
 'Excellent！你的英语学习正在重新充能魔法阵。每个正确的单词都是一道咒语，每句流畅的句子都是一次施法。继续练习，当你的准确率达到巅峰时，我们就能封印最大的黑暗裂缝！',
 '我要掌握最强的魔法咒语！',
 'ACCURACY', 80, 35, 9),

(10, '羁绊的证明',
 '你的精灵依偎在你身边，温暖的能量在你们之间流淌。一种无形的羁绊在变得越发牢固……',
 '精灵伙伴',
 '（精灵温柔地看着你）感受到了吗？我们之间的羁绊越来越深了。你的每一次关心、每一次喂养，都在让这份联系变得更加牢固。感谢你一直以来的陪伴，我也会一直守护你的学习之旅！',
 '我们是永远的伙伴！',
 'AFFECTION', 50, 40, 10),

(11, '连续的力量',
 '一道耀眼的金光从天而降。向导精灵惊讶地望着天空……',
 '向导精灵',
 '不可思议！你已经连续学习了 5 天！这种持续的力量产生了共振，正在唤醒远古守护者。看，那是什么！——一座古老的殿堂从虚空中浮现。持续学习的力量，真的可以创造奇迹！',
 '我会坚持下去的！',
 'STREAK', 5, 60, 11),

(12, '新的征程',
 '三位 NPC 齐聚一堂，他们身后是被暂时封印的知识黑洞。精灵站在你肩头，骄傲地昂着头……',
 '向导精灵',
 '黑暗暂时退去了，但更大的挑战正在远方酝酿。你已经证明了自己是一名真正的学习守护者——你拯救了精灵，点亮了三个世界，创造了连续学习的奇迹。但这只是开始，更多的冒险在等待着你！',
 '我准备好了！新的征程开始了！',
 'ACHIEVEMENT_COUNT', 3, 80, 12);

-- ============================================================
-- Sprint A follow-up: Restore Grade 1 poems + text comprehension + more characters
-- ============================================================

-- ── 古诗恢复：一年级必背古诗 ──

-- 悯农（李绅）— Grade 1 poem
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'POEM_SEQUENCE', 2, '请将《悯农》的诗句按正确顺序排列', '["锄禾日当午","汗滴禾下土","谁知盘中餐","粒粒皆辛苦"]', '1,2,3,4', '李绅《悯农》：锄禾日当午，汗滴禾下土。谁知盘中餐，粒粒皆辛苦。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'FILL_BLANK', 2, '"谁知盘中餐，______。" 请填空', NULL, '粒粒皆辛苦', '出自李绅《悯农》，告诉我们要珍惜粮食。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'MULTIPLE_CHOICE', 2, '"锄禾日当午"中的"禾"指的是什么？', '[{"key":"A","text":"水稻"},{"key":"B","text":"小麦"},{"key":"C","text":"谷类作物的统称"},{"key":"D","text":"树木"}]', 'C', '禾是谷类作物的统称，农民在田里给庄稼锄草。', 10);

-- 画（王维）
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'FILL_BLANK', 2, '"远看山有色，近听水无声。春去花还在，______。"', NULL, '人来鸟不惊', '出自王维《画》，描写一幅山水画。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'MULTIPLE_CHOICE', 2, '《画》这首诗描写的是什么？', '[{"key":"A","text":"真实的山"},{"key":"B","text":"一幅画"},{"key":"C","text":"一条河"},{"key":"D","text":"一座花园"}]', 'B', '这首诗描写的是一幅山水画中的景物。', 10);

-- 咏鹅（骆宾王）— fill in blank
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'FILL_BLANK', 2, '"鹅鹅鹅，______。白毛浮绿水，红掌拨清波。"', NULL, '曲项向天歌', '出自骆宾王7岁时写的《咏鹅》。', 10);

-- ── 课文理解：一年级课文 ──

INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'MULTIPLE_CHOICE', 1, '"一去二三里，烟村四五家"一共有几座房子？', '[{"key":"A","text":"二三座"},{"key":"B","text":"四五座"},{"key":"C","text":"七八座"}]', 'B', '烟村四五家，就是四五户人家。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'MULTIPLE_CHOICE', 1, '《小小的船》中，"弯弯的月儿小小的船"，月儿像什么？', '[{"key":"A","text":"香蕉"},{"key":"B","text":"小船"},{"key":"C","text":"钩子"}]', 'B', '弯弯的月亮像一只小小的船。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'FILL_BLANK', 1, '"小小的船"指的是______。', NULL, '月亮', '弯弯的月儿像小小的船，所以小小的船指的是月亮。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'MULTIPLE_CHOICE', 1, '《四季》中，"草芽尖尖"描写的是哪个季节？', '[{"key":"A","text":"春天"},{"key":"B","text":"夏天"},{"key":"C","text":"秋天"}]', 'A', '草芽尖尖，他对小鸟说：我是春天。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'MULTIPLE_CHOICE', 1, '《四季》中，哪个季节"雪人大肚子一挺"？', '[{"key":"A","text":"秋天"},{"key":"B","text":"冬天"},{"key":"C","text":"春天"}]', 'B', '雪人大肚子一挺，他顽皮地说：我就是冬天。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'FILL_BLANK', 1, '《四季》中，谷穗弯弯，他鞠着躬说：我是______。', NULL, '秋天', '谷穗弯弯代表秋天丰收的季节。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'MULTIPLE_CHOICE', 2, '《日月明》中，"日月明"表示什么意思？', '[{"key":"A","text":"太阳和月亮"},{"key":"B","text":"太阳和月亮组成\"明\"字"},{"key":"C","text":"明天"}]', 'B', '日+月=明，表示光明、明亮。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_kewen'), 'FILL_BLANK', 2, '"魚羊鲜，______。" 请填下一个字', NULL, '小土尘', '《日月明》：日月明，魚羊鲜，小土尘，小大尖。', 10);

-- ── 识字辨字：更多汉字练习 ──

INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '"天"字有几笔？', '[{"key":"A","text":"3笔"},{"key":"B","text":"4笔"},{"key":"C","text":"5笔"}]', 'B', '天字4笔：横、横、撇、捺。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '"木"字加一笔变成什么字？', '[{"key":"A","text":"本"},{"key":"B","text":"林"},{"key":"C","text":"森"}]', 'A', '木下面加一横就是"本"，表示树根。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '下面哪个字是"目"（眼睛）？', '[{"key":"A","text":"日"},{"key":"B","text":"目"},{"key":"C","text":"口"}]', 'B', '目比日多一横，表示眼睛，目字里面的两横像眼珠。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '"休"字的意思是什么？', '[{"key":"A","text":"休息"},{"key":"B","text":"跑步"},{"key":"C","text":"吃饭"}]', 'A', '亻（人）+ 木（树）= 休，人靠在树上休息。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '"从"字由两个什么字组成？', '[{"key":"A","text":"两个人"},{"key":"B","text":"两个木"},{"key":"C","text":"两个口"}]', 'A', '从=人+人，一个人跟着另一个人，表示跟从。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '"林"字的意思是什么？', '[{"key":"A","text":"一棵树"},{"key":"B","text":"很多树"},{"key":"C","text":"一块石头"}]', 'B', '两个木组成林，表示很多树木。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_TAP', 1, '下面哪个字和"手"有关？', '[{"key":"A","text":"江"},{"key":"B","text":"打"},{"key":"C","text":"河"}]', 'B', '打是提手旁（扌），表示和手有关的动作，如打鼓、打球。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_CHAR_BUILD', 1, '拼一拼：日 + 十 = ？', '{"radical":"日","phonetic":"十","targetChar":"早"}', '早', '日 + 十 = 早，表示早晨。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_shizi'), 'SCENE_CHAR_BUILD', 1, '拼一拼：口 + 马 = ？', '{"radical":"口","phonetic":"马","targetChar":"吗"}', '吗', '口 + 马 = 吗，表示疑问语气。', 10);

-- ── 综合练习（chinese_intro 补充）──

INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'MULTIPLE_CHOICE', 1, '下面哪个是整体认读音节？', '[{"key":"A","text":"ba"},{"key":"B","text":"zhi"},{"key":"C","text":"an"}]', 'B', 'zhi是整体认读音节，不能拼读，直接读。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'SCENE_TAP', 1, '"云"字有几笔？', '[{"key":"A","text":"3笔"},{"key":"B","text":"4笔"},{"key":"C","text":"5笔"}]', 'B', '云字4笔：横、横、撇折、点。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'SCENE_TAP', 1, '"风"的第二笔是什么？', '[{"key":"A","text":"撇"},{"key":"B","text":"横折钩"},{"key":"C","text":"点"}]', 'B', '风字笔顺：撇、横折钩、撇、点。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'SCENE_TAP', 1, '下面哪个字是"鸟"？', '[{"key":"A","text":"乌"},{"key":"B","text":"鸟"},{"key":"C","text":"马"}]', 'B', '鸟字里面有一点像眼睛，乌没有点（乌鸦太黑看不见眼睛）。', 10);


-- ============================================================
-- Sprint B: Grade 1-3 Knowledge Node Expansion
-- ============================================================

-- Chinese G1: 笔画与笔顺 + 古诗启蒙
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, grade_level, parent_node_id, order_index) VALUES
('chinese', 'chinese_bihua', '笔画与笔顺', '学习汉字基本笔画和笔顺规则，正确书写常用字', 1, 1, NULL, 5),
('chinese', 'chinese_gushi1', '古诗启蒙', '背诵理解一年级必背古诗，感受古诗韵律美', 2, 1, NULL, 6);

-- Chinese G2: 偏旁部首、多音字、词语搭配、阅读理解、古诗积累
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, grade_level, parent_node_id, order_index) VALUES
('chinese', 'chinese_pianpang', '偏旁部首', '认识常用偏旁部首，理解部首与字义的关系', 3, 2, NULL, 7),
('chinese', 'chinese_duoyinzi', '多音字', '掌握常见多音字的读音和用法区别', 3, 2, NULL, 8),
('chinese', 'chinese_ciyu', '词语搭配', '学习词语的正确搭配，积累形容词和量词', 3, 2, NULL, 9),
('chinese', 'chinese_yuedu1', '阅读理解', '阅读短文并理解主要内容，提取关键信息', 4, 2, NULL, 10),
('chinese', 'chinese_gushi2', '古诗积累', '背诵理解二年级必背古诗，体会诗人情感', 3, 2, NULL, 11);

-- Chinese G3: 成语故事、修辞手法、段落理解、习作入门
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, grade_level, parent_node_id, order_index) VALUES
('chinese', 'chinese_chengyu', '成语故事', '学习经典成语及其背后的寓言故事', 4, 3, NULL, 12),
('chinese', 'chinese_xiuci', '修辞手法', '认识比喻、拟人等修辞手法并尝试运用', 4, 3, NULL, 13),
('chinese', 'chinese_duanluo', '段落理解', '理解段落结构和中心句，概括段落大意', 5, 3, NULL, 14),
('chinese', 'chinese_xizuo', '习作入门', '学习观察和记录，尝试写简单的日记和小作文', 5, 3, NULL, 15);

-- Math G2: 表内乘法、表内除法、100以内加减、长度单位、角的认识、混合运算
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, grade_level, parent_node_id, order_index) VALUES
('math', 'math_chengfa', '表内乘法', '理解乘法含义，熟记1-9乘法口诀表', 3, 2, NULL, 12),
('math', 'math_chufa', '表内除法', '理解除法含义，掌握表内除法运算', 3, 2, NULL, 13),
('math', 'math_100addsub', '100以内加减', '掌握100以内加减法竖式计算', 3, 2, NULL, 14),
('math', 'math_length', '长度单位', '认识米、厘米，学会用尺子测量物体长度', 3, 2, NULL, 15),
('math', 'math_angle', '角的初步认识', '认识锐角、直角、钝角，会比较角的大小', 4, 2, NULL, 16),
('math', 'math_mixed', '混合运算', '掌握加减乘除混合运算的运算顺序', 4, 2, NULL, 17);

-- Math G3: 万以内加减、多位数乘法、分数初步、面积周长、年月日、小数初步
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, grade_level, parent_node_id, order_index) VALUES
('math', 'math_10000', '万以内加减', '掌握万以内数的加减法，理解进位退位', 4, 3, NULL, 18),
('math', 'math_multidigit', '多位数乘法', '掌握两位数乘一位数和两位数乘两位数的笔算', 5, 3, NULL, 19),
('math', 'math_fraction', '分数初步', '认识分数，理解几分之一和几分之几的含义', 4, 3, NULL, 20),
('math', 'math_area', '面积与周长', '理解周长和面积概念，计算长方形正方形的周长面积', 5, 3, NULL, 21),
('math', 'math_calendar', '年月日', '认识年月日，掌握24时计时法和时间计算', 4, 3, NULL, 22),
('math', 'math_decimal', '小数初步', '认识小数，掌握一位小数的加减法', 4, 3, NULL, 23);

-- English G1: 日常用语、颜色数字身体
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, grade_level, parent_node_id, order_index) VALUES
('english', 'english_daily', '日常用语', '学习问候、告别、感谢等日常交际用语', 1, 1, NULL, 4),
('english', 'english_colors', '颜色与数字', '认识颜色、数字、身体部位的英文表达', 1, 1, NULL, 5);

-- English G2: 自然拼读、常用短语、情景对话、动物与自然
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, grade_level, parent_node_id, order_index) VALUES
('english', 'english_phonics', '自然拼读', '学习字母与发音的对应规律，见词能读', 3, 2, NULL, 6),
('english', 'english_phrases', '常用短语', '积累常用短语和固定搭配，丰富表达', 3, 2, NULL, 7),
('english', 'english_dialogue', '情景对话', '在购物、问路、用餐等情景中进行简单对话', 3, 2, NULL, 8),
('english', 'english_animals', '动物与自然', '学习动物、天气、季节等主题词汇', 3, 2, NULL, 9);

-- English G3: 简单句型、短文阅读、语法入门、书写练习
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, grade_level, parent_node_id, order_index) VALUES
('english', 'english_sentences', '简单句型', '掌握陈述句、疑问句、祈使句等基本句型', 4, 3, NULL, 10),
('english', 'english_reading', '短文阅读', '阅读简短英文故事，理解大意并回答问题', 5, 3, NULL, 11),
('english', 'english_grammar', '语法入门', '学习名词单复数、be动词、现在进行时等', 4, 3, NULL, 12),
('english', 'english_writing', '书写练习', '学习正确书写字母单词，尝试写简单句子', 4, 3, NULL, 13);

-- ============================================================
-- Sprint B: Chinese G1-G3 Questions (~100 new questions)
-- ============================================================

-- ── G1: 笔画与笔顺 (chinese_bihua) ~10 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_bihua'), 'SCENE_TAP', 1, '"十"字有几笔？', '[{"key":"A","text":"1笔"},{"key":"B","text":"2笔"},{"key":"C","text":"3笔"}]', 'B', '十字2笔：横、竖。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_bihua'), 'SCENE_TAP', 1, '"人"字的第一笔是什么？', '[{"key":"A","text":"横"},{"key":"B","text":"竖"},{"key":"C","text":"撇"}]', 'C', '人字笔顺：撇、捺。先撇后捺。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_bihua'), 'SCENE_TAP', 1, '"口"字有几笔？', '[{"key":"A","text":"3笔"},{"key":"B","text":"4笔"},{"key":"C","text":"5笔"}]', 'A', '口字3笔：竖、横折、横。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_bihua'), 'SCENE_TAP', 1, '汉字笔顺规则："先横后竖"，下面哪个字符合？', '[{"key":"A","text":"十"},{"key":"B","text":"人"},{"key":"C","text":"八"}]', 'A', '十字先写横再写竖，符合先横后竖规则。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_bihua'), 'SCENE_TAP', 1, '"山"字有几笔？', '[{"key":"A","text":"3笔"},{"key":"B","text":"4笔"},{"key":"C","text":"5笔"}]', 'A', '山字3笔：竖、竖折、竖。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_bihua'), 'SCENE_TAP', 1, '"火"字的笔顺是什么？', '[{"key":"A","text":"点、撇、撇、捺"},{"key":"B","text":"撇、点、撇、捺"},{"key":"C","text":"点、撇、捺、撇"}]', 'A', '火字笔顺：左点、右撇、中间撇、捺。先两边后中间。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_bihua'), 'SCENE_TAP', 1, '"月"字有几笔？', '[{"key":"A","text":"3笔"},{"key":"B","text":"4笔"},{"key":"C","text":"5笔"}]', 'B', '月字4笔：撇、横折钩、横、横。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_bihua'), 'FILL_BLANK', 1, '"上"字一共有______笔。', NULL, '3', '上字3笔：竖、横、横。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_bihua'), 'SCENE_TAP', 1, '下面哪个字的笔顺是"从左到右"？', '[{"key":"A","text":"八"},{"key":"B","text":"水"},{"key":"C","text":"川"}]', 'A', '八字先左撇后右捺，符合从左到右规则。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_bihua'), 'SCENE_TAP', 1, '"田"字有几笔？', '[{"key":"A","text":"4笔"},{"key":"B","text":"5笔"},{"key":"C","text":"6笔"}]', 'B', '田字5笔：竖、横折、横、竖、横。', 10);

-- ── G1: 古诗启蒙 (chinese_gushi1) ~10 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi1'), 'FILL_BLANK', 2, '"离离原上草，一岁一______。"', NULL, '枯荣', '出自白居易《赋得古原草送别》：离离原上草，一岁一枯荣。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi1'), 'FILL_BLANK', 2, '"野火烧不尽，______。"', NULL, '春风吹又生', '小草生命力顽强，野火都烧不尽，春天来了又会长出来。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi1'), 'MULTIPLE_CHOICE', 2, '"春眠不觉晓，处处闻啼鸟"是哪位诗人写的？', '[{"key":"A","text":"李白"},{"key":"B","text":"孟浩然"},{"key":"C","text":"白居易"}]', 'B', '《春晓》是唐代诗人孟浩然的作品。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi1'), 'MULTIPLE_CHOICE', 2, '"举头望明月"的下一句是？', '[{"key":"A","text":"低头思故乡"},{"key":"B","text":"疑是地上霜"},{"key":"C","text":"床前明月光"}]', 'A', '李白《静夜思》：举头望明月，低头思故乡。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi1'), 'MULTIPLE_CHOICE', 2, '"夜来风雨声"的上一句是？', '[{"key":"A","text":"处处闻啼鸟"},{"key":"B","text":"春眠不觉晓"},{"key":"C","text":"花落知多少"}]', 'A', '《春晓》：春眠不觉晓，处处闻啼鸟。夜来风雨声，花落知多少。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi1'), 'FILL_BLANK', 2, '"______依山尽，黄河入海流。欲穷千里目，更上一层楼。"', NULL, '白日', '王之涣《登鹳雀楼》，写诗人登高望远的壮阔景象。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi1'), 'POEM_SEQUENCE', 2, '请将《登鹳雀楼》的诗句按正确顺序排列', '["白日依山尽","黄河入海流","欲穷千里目","更上一层楼"]', '1,2,3,4', '王之涣《登鹳雀楼》：白日依山尽，黄河入海流。欲穷千里目，更上一层楼。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi1'), 'MULTIPLE_CHOICE', 2, '"锄禾日当午"中"锄禾"是什么意思？', '[{"key":"A","text":"收割庄稼"},{"key":"B","text":"在田里除草"},{"key":"C","text":"种植禾苗"}]', 'B', '锄禾意为在田里给庄稼锄草松土。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi1'), 'FILL_BLANK', 2, '"______依山尽，黄河入海流。" 请填前两个字', NULL, '白日', '出自王之涣《登鹳雀楼》。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi1'), 'SCENE_TAP', 2, '《悯农》告诉我们什么道理？', '[{"key":"A","text":"要早起干活"},{"key":"B","text":"要珍惜粮食"},{"key":"C","text":"要多吃饭"}]', 'B', '谁知盘中餐，粒粒皆辛苦——告诉我们要珍惜粮食。', 10);

-- ── G2: 偏旁部首 (chinese_pianpang) ~10 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pianpang'), 'SCENE_TAP', 3, '下面哪个字带"氵"（三点水）？', '[{"key":"A","text":"江"},{"key":"B","text":"红"},{"key":"C","text":"打"}]', 'A', '江是氵（三点水），表示和水有关。红是纟，打是扌。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pianpang'), 'SCENE_TAP', 3, '"亻"（单人旁）的字通常和什么有关？', '[{"key":"A","text":"水"},{"key":"B","text":"人"},{"key":"C","text":"树木"}]', 'B', '亻是单人旁，表示和人有关，如：你、他、们、休。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pianpang'), 'SCENE_TAP', 3, '"火"字旁的字通常和什么有关？', '[{"key":"A","text":"水"},{"key":"B","text":"火"},{"key":"C","text":"土"}]', 'B', '火字旁的字通常和火有关，如：灯、烧、烤、灭。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pianpang'), 'SCENE_TAP', 3, '下面哪个字的偏旁是"木"？', '[{"key":"A","text":"打"},{"key":"B","text":"林"},{"key":"C","text":"江"}]', 'B', '林的偏旁是木，两个木组成林，表示树木多。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pianpang'), 'SCENE_TAP', 3, '"月"字旁的字通常和什么有关？', '[{"key":"A","text":"月亮"},{"key":"B","text":"身体部位"},{"key":"C","text":"时间"}]', 'B', '月字旁（肉月旁）和身体有关，如：腿、脚、肚、胖。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pianpang'), 'FILL_BLANK', 3, '"妈"字的偏旁是______。', NULL, '女字旁', '妈的偏旁是女（女字旁），如：妈、姐、妹、奶。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pianpang'), 'SCENE_TAP', 3, '下面哪个字带"艹"（草字头）？', '[{"key":"A","text":"草"},{"key":"B","text":"早"},{"key":"C","text":"澡"}]', 'A', '草是艹字头，和植物有关。早是日字头，澡是氵。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pianpang'), 'SCENE_TAP', 3, '"饣"（食字旁）的字通常和什么有关？', '[{"key":"A","text":"说话"},{"key":"B","text":"食物"},{"key":"C","text":"金钱"}]', 'B', '食字旁和食物饮食有关，如：饭、饱、饿、饺。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pianpang'), 'SCENE_TAP', 3, '"扌"（提手旁）的字通常和什么有关？', '[{"key":"A","text":"脚"},{"key":"B","text":"手"},{"key":"C","text":"眼睛"}]', 'B', '提手旁的字和手部动作有关，如：打、拍、拉、抱。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_pianpang'), 'SCENE_CHAR_BUILD', 3, '拼一拼：口 + 十 = ？猜猜这是什么字？', '{"radical":"口","phonetic":"十","targetChar":"叶"}', '叶', '口 + 十 = 叶（叶子），口的框+十字。', 10);

-- ── G2: 多音字 (chinese_duoyinzi) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duoyinzi'), 'SCENE_TAP', 3, '"长大"的"长"读什么？', '[{"key":"A","text":"cháng"},{"key":"B","text":"zhǎng"},{"key":"C","text":"chàng"}]', 'B', '长大的长读zhǎng，表示成长；长短的长读cháng。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duoyinzi'), 'SCENE_TAP', 3, '"快乐"的"乐"读什么？', '[{"key":"A","text":"lè"},{"key":"B","text":"yuè"},{"key":"C","text":"yào"}]', 'A', '快乐的乐读lè；音乐的乐读yuè。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duoyinzi'), 'SCENE_TAP', 3, '在"种子"一词中，"种"读什么？', '[{"key":"A","text":"zhǒng"},{"key":"B","text":"zhòng"},{"key":"C","text":"chóng"}]', 'A', '种子的种读zhǒng；种地的种读zhòng。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duoyinzi'), 'SCENE_TAP', 3, '"重"在"重要"中读什么？', '[{"key":"A","text":"zhòng"},{"key":"B","text":"chóng"},{"key":"C","text":"zòng"}]', 'A', '重要的重读zhòng；重复的重读chóng。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duoyinzi'), 'FILL_BLANK', 3, '"觉"在"睡觉"中读______。', NULL, 'jiào', '睡觉的觉读jiào；感觉的觉读jué。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duoyinzi'), 'SCENE_TAP', 3, '"好"在"爱好"中读什么？', '[{"key":"A","text":"hǎo"},{"key":"B","text":"hào"},{"key":"C","text":"háo"}]', 'B', '爱好的好读hào；好人的好读hǎo。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duoyinzi'), 'SCENE_TAP', 3, '"了"在"了解"中读什么？', '[{"key":"A","text":"le"},{"key":"B","text":"liǎo"},{"key":"C","text":"liào"}]', 'B', '了解的了读liǎo；走了的了读le（轻声）。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duoyinzi'), 'MULTIPLE_CHOICE', 3, '下面哪个"行"的读音和其他不同？', '[{"key":"A","text":"行走"},{"key":"B","text":"银行"},{"key":"C","text":"步行"}]', 'B', '银行的行读háng，行走和步行的行读xíng。', 10);

-- ── G2: 词语搭配 (chinese_ciyu) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_ciyu'), 'SCENE_TAP', 3, '"一（ ）马"，量词应该填什么？', '[{"key":"A","text":"只"},{"key":"B","text":"匹"},{"key":"C","text":"头"}]', 'B', '马的量词是"匹"：一匹马。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_ciyu'), 'SCENE_TAP', 3, '下面哪个词语搭配是正确的？', '[{"key":"A","text":"明亮的教室"},{"key":"B","text":"明亮的月亮"},{"key":"C","text":"明亮的花朵"}]', 'A', '明亮修饰教室最合适；月亮用"皎洁"，花朵用"鲜艳"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_ciyu'), 'FILL_BLANK', 3, '一条______（填合适的词）', NULL, '鱼', '条用于长条形的东西：一条鱼、一条路、一条河。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_ciyu'), 'SCENE_TAP', 3, '"一（ ）书"，量词应该填什么？', '[{"key":"A","text":"张"},{"key":"B","text":"本"},{"key":"C","text":"支"}]', 'B', '书的量词是"本"：一本书。张用于纸，支用于笔。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_ciyu'), 'SCENE_TAP', 3, '下面哪个词语搭配是正确的？', '[{"key":"A","text":"飞快地跑步"},{"key":"B","text":"飞快地睡觉"},{"key":"C","text":"飞快地坐着"}]', 'A', '飞快地+动作：跑步可以飞快，睡觉和坐着不行。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_ciyu'), 'SCENE_TAP', 3, '"一（ ）牛奶"，量词应该填什么？', '[{"key":"A","text":"个"},{"key":"B","text":"杯"},{"key":"C","text":"条"}]', 'B', '牛奶的量词是"杯"：一杯牛奶。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_ciyu'), 'MULTIPLE_CHOICE', 3, '下面哪个词是形容人"高兴"的？', '[{"key":"A","text":"愁眉苦脸"},{"key":"B","text":"眉开眼笑"},{"key":"C","text":"无精打采"}]', 'B', '眉开眼笑形容非常高兴；愁眉苦脸是忧愁，无精打采是没精神。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_ciyu'), 'FILL_BLANK', 3, '（ ）的阳光 （填一个字）', NULL, '温暖', '温暖的阳光是常用的词语搭配。', 10);

-- ── G2: 阅读理解 (chinese_yuedu1) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_yuedu1'), 'MULTIPLE_CHOICE', 4, '阅读：小兔子白白的，红眼睛，短尾巴，爱吃萝卜和青菜。小兔子喜欢吃什么？', '[{"key":"A","text":"肉"},{"key":"B","text":"萝卜和青菜"},{"key":"C","text":"水果"}]', 'B', '短文说小兔子"爱吃萝卜和青菜"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_yuedu1'), 'MULTIPLE_CHOICE', 4, '阅读：春天来了，小草从土里钻出来，花儿开了，小鸟在树上唱歌。这段话描写的是哪个季节？', '[{"key":"A","text":"春天"},{"key":"B","text":"夏天"},{"key":"C","text":"秋天"}]', 'A', '文中明确说"春天来了"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_yuedu1'), 'FILL_BLANK', 4, '阅读：小明每天早早起床，先刷牙洗脸，然后吃早饭，最后背起书包去上学。小明起床后第一件事是______。', NULL, '刷牙洗脸', '文中小明起床后先刷牙洗脸。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_yuedu1'), 'MULTIPLE_CHOICE', 4, '阅读：下雨了，小蚂蚁急忙往高处搬家，小燕子飞得很低。要下雨时，小蚂蚁会做什么？', '[{"key":"A","text":"搬家到高处"},{"key":"B","text":"在低处玩耍"},{"key":"C","text":"躲在树叶下"}]', 'A', '小蚂蚁"急忙往高处搬家"——防止被水淹。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_yuedu1'), 'SCENE_TAP', 4, '阅读：小马过河时，松鼠说水很深，老牛说水很浅。这个故事告诉我们什么？', '[{"key":"A","text":"不要相信别人"},{"key":"B","text":"要亲自试一试"},{"key":"C","text":"河水很危险"}]', 'B', '《小马过河》告诉我们：遇到问题要自己动脑筋，亲自试一试。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_yuedu1'), 'MULTIPLE_CHOICE', 4, '阅读：熊猫是我们的国宝，它喜欢吃竹子，生活在四川的竹林里。熊猫生活在哪里？', '[{"key":"A","text":"森林"},{"key":"B","text":"四川的竹林"},{"key":"C","text":"动物园"}]', 'B', '文中说熊猫"生活在四川的竹林里"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_yuedu1'), 'FILL_BLANK', 4, '阅读：秋天到了，树叶黄了，一片片叶子从树上落下来。这段话描写的季节是______。', NULL, '秋天', '文中明确说"秋天到了"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_yuedu1'), 'SCENE_TAP', 4, '阅读一段话时，最能概括这段话意思的句子叫什么？', '[{"key":"A","text":"结尾句"},{"key":"B","text":"中心句"},{"key":"C","text":"过渡句"}]', 'B', '中心句能够概括一段话的主要意思。', 10);

-- ── G2: 古诗积累 (chinese_gushi2) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi2'), 'FILL_BLANK', 3, '"儿童散学归来早，忙趁东风放______。"', NULL, '纸鸢', '出自高鼎《村居》，纸鸢就是风筝。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi2'), 'MULTIPLE_CHOICE', 3, '"不知细叶谁裁出，二月春风似剪刀"描写的是什么树？', '[{"key":"A","text":"松树"},{"key":"B","text":"柳树"},{"key":"C","text":"桃树"}]', 'B', '出自贺知章《咏柳》：碧玉妆成一树高，万条垂下绿丝绦。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi2'), 'FILL_BLANK', 3, '"______生紫烟，遥看瀑布挂前川。" 请填前三个字', NULL, '日照香炉', '出自李白《望庐山瀑布》：日照香炉生紫烟，遥看瀑布挂前川。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi2'), 'POEM_SEQUENCE', 3, '请将《村居》的诗句按正确顺序排列', '["草长莺飞二月天","拂堤杨柳醉春烟","儿童散学归来早","忙趁东风放纸鸢"]', '1,2,3,4', '高鼎《村居》描写春天孩子们放风筝的快乐场景。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi2'), 'MULTIPLE_CHOICE', 3, '《望庐山瀑布》的作者是谁？', '[{"key":"A","text":"杜甫"},{"key":"B","text":"李白"},{"key":"C","text":"王维"}]', 'B', '《望庐山瀑布》是李白的代表作之一，描写庐山瀑布的壮观。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi2'), 'FILL_BLANK', 3, '"两个黄鹂鸣翠柳，一行______上青天。"', NULL, '白鹭', '出自杜甫《绝句》：两个黄鹂鸣翠柳，一行白鹭上青天。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi2'), 'MULTIPLE_CHOICE', 3, '"草长莺飞二月天"描写的是哪个季节？', '[{"key":"A","text":"春天"},{"key":"B","text":"夏天"},{"key":"C","text":"冬天"}]', 'A', '二月是春天，草长莺飞描写春天的生机。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_gushi2'), 'MULTIPLE_CHOICE', 3, '"飞流直下三千尺"的下一句是？', '[{"key":"A","text":"疑是银河落九天"},{"key":"B","text":"日照香炉生紫烟"},{"key":"C","text":"遥看瀑布挂前川"}]', 'A', '李白《望庐山瀑布》：飞流直下三千尺，疑是银河落九天。', 10);

-- ── G3: 成语故事 (chinese_chengyu) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_chengyu'), 'MULTIPLE_CHOICE', 4, '"守株待兔"这个故事告诉我们什么？', '[{"key":"A","text":"要多种树"},{"key":"B","text":"不能心存侥幸不劳而获"},{"key":"C","text":"兔子很笨"}]', 'B', '守株待兔讲农夫捡到撞死的兔子后就天天等，讽刺不劳而获。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_chengyu'), 'MULTIPLE_CHOICE', 4, '"画蛇添足"是什么意思？', '[{"key":"A","text":"画一条没有脚的蛇"},{"key":"B","text":"做了多余的事反而不恰当"},{"key":"C","text":"蛇本来有脚"}]', 'B', '画蛇添足比喻做了多余的事，反而把事情弄糟。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_chengyu'), 'MULTIPLE_CHOICE', 4, '"亡羊补牢"中"牢"是什么意思？', '[{"key":"A","text":"监狱"},{"key":"B","text":"牢固"},{"key":"C","text":"羊圈"}]', 'C', '牢指羊圈。亡羊补牢：羊丢了才修羊圈，比喻出了问题及时补救。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_chengyu'), 'MULTIPLE_CHOICE', 4, '下面哪个成语形容一个人"眼界狭小"？', '[{"key":"A","text":"高瞻远瞩"},{"key":"B","text":"坐井观天"},{"key":"C","text":"一望无际"}]', 'B', '坐井观天：坐在井底看天，比喻眼界狭小，见识有限。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_chengyu'), 'MULTIPLE_CHOICE', 4, '"拔苗助长"告诉我们什么道理？', '[{"key":"A","text":"种田要用力拔"},{"key":"B","text":"做事情不能急于求成"},{"key":"C","text":"禾苗长得太慢"}]', 'B', '拔苗助长（揠苗助长）比喻违反规律急于求成，反而坏事。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_chengyu'), 'FILL_BLANK', 4, '"掩耳盗铃"的意思是捂住耳朵去______，比喻自己欺骗自己。', NULL, '偷铃铛', '掩耳盗铃：捂着耳朵偷铃铛以为自己听不见别人也听不见。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_chengyu'), 'MULTIPLE_CHOICE', 4, '下面哪个成语和"狐狸"有关？', '[{"key":"A","text":"画龙点睛"},{"key":"B","text":"狐假虎威"},{"key":"C","text":"守株待兔"}]', 'B', '狐假虎威：狐狸假借老虎的威风吓唬其他动物，比喻借他人势力欺人。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_chengyu'), 'MULTIPLE_CHOICE', 4, '"井底之蛙"的近义词是？', '[{"key":"A","text":"见多识广"},{"key":"B","text":"坐井观天"},{"key":"C","text":"高瞻远瞩"}]', 'B', '井底之蛙和坐井观天都是比喻眼界狭小、见识有限。', 10);

-- ── G3: 修辞手法 (chinese_xiuci) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xiuci'), 'SCENE_TAP', 4, '"弯弯的月亮像小船"使用了什么修辞手法？', '[{"key":"A","text":"拟人"},{"key":"B","text":"比喻"},{"key":"C","text":"夸张"}]', 'B', '用"像"把月亮比作小船，是比喻手法。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xiuci'), 'SCENE_TAP', 4, '"小鸟在树上唱歌"使用了什么修辞手法？', '[{"key":"A","text":"比喻"},{"key":"B","text":"拟人"},{"key":"C","text":"排比"}]', 'B', '小鸟不会唱歌，把小鸟当成人来写，是拟人。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xiuci'), 'SCENE_TAP', 4, '"太阳像个大火球"把太阳比作什么？', '[{"key":"A","text":"月亮"},{"key":"B","text":"大火球"},{"key":"C","text":"星星"}]', 'B', '用"像"把太阳比作大火球，突出太阳的炽热和形状。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xiuci'), 'SCENE_TAP', 4, '下面哪个句子用了"拟人"？', '[{"key":"A","text":"花儿红红的"},{"key":"B","text":"花儿笑弯了腰"},{"key":"C","text":"花儿像火一样红"}]', 'B', '花儿笑弯了腰——把花当成人来写，会"笑"，是拟人。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xiuci'), 'SCENE_TAP', 4, '"飞流直下三千尺"用了什么修辞手法？', '[{"key":"A","text":"比喻"},{"key":"B","text":"拟人"},{"key":"C","text":"夸张"}]', 'C', '三千尺不是真实高度，是夸张手法，极言瀑布之高。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xiuci'), 'FILL_BLANK', 4, '"春天像个害羞的小姑娘"这句话把春天比作______。', NULL, '害羞的小姑娘', '用"像"连接，是比喻句，把春天比作害羞的小姑娘。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xiuci'), 'MULTIPLE_CHOICE', 4, '下面哪个是比喻句？', '[{"key":"A","text":"小明长得像他爸爸"},{"key":"B","text":"弯弯的月亮像小船"},{"key":"C","text":"我好像在哪儿见过你"}]', 'B', 'A是比较（同类），B是比喻（不同类但相似），C是推测。比喻是用不同类但有相似点的事物打比方。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xiuci'), 'SCENE_TAP', 4, '"星星在夜空中眨眼睛"用了什么修辞？', '[{"key":"A","text":"比喻"},{"key":"B","text":"拟人"},{"key":"C","text":"排比"}]', 'B', '星星不会眨眼睛，把星星当成人来写，是拟人。', 10);

-- ── G3: 段落理解 (chinese_duanluo) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duanluo'), 'MULTIPLE_CHOICE', 5, '阅读：西沙群岛是鸟的天下。岛上有一片茂密的树林，树林里栖息着各种海鸟。这段话的中心句是？', '[{"key":"A","text":"岛上有一片茂密的树林"},{"key":"B","text":"西沙群岛是鸟的天下"},{"key":"C","text":"树林里栖息着各种海鸟"}]', 'B', '中心句是第一句"西沙群岛是鸟的天下"，后面都是具体说明。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duanluo'), 'MULTIPLE_CHOICE', 5, '阅读：秋天的雨有一盒五彩缤纷的颜料。它把黄色给了银杏树，红色给了枫树，金黄色给了田野。这段话主要写什么？', '[{"key":"A","text":"秋天的雨"},{"key":"B","text":"五彩缤纷的颜色"},{"key":"C","text":"银杏树"}]', 'B', '中心意思是秋天的雨带来了五彩缤纷的颜色，后面举例说明。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duanluo'), 'FILL_BLANK', 5, '一个段落中，能概括段落主要意思的句子叫做______。', NULL, '中心句', '中心句是段落的核心，其他句子围绕它展开说明。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duanluo'), 'SCENE_TAP', 5, '以下哪个是"总—分"结构的段落？', '[{"key":"A","text":"先具体描写再总结"},{"key":"B","text":"先总说再具体分说"},{"key":"C","text":"按时间顺序叙述"}]', 'B', '总—分结构：先用一句话概括（总），再用几句话具体说明（分）。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duanluo'), 'MULTIPLE_CHOICE', 5, '阅读：海底的动物各有各的活动方法。海参靠肌肉伸缩爬行，每小时只能前进四米。梭子鱼每小时能游几十千米。乌贼能喷水后退。这段话的中心句是？', '[{"key":"A","text":"海参靠肌肉伸缩爬行"},{"key":"B","text":"海底的动物各有各的活动方法"},{"key":"C","text":"梭子鱼每小时能游几十千米"}]', 'B', '第一句是中心句，后面用海参、梭子鱼、乌贼三个例子说明不同的活动方法。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duanluo'), 'FILL_BLANK', 5, '阅读时要抓住段落的______句，它通常在一段的开头或结尾。', NULL, '中心', '中心句概括一段话的主要内容，通常在段首或段尾。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duanluo'), 'SCENE_TAP', 5, '下面哪种方法是理解段落的最好方式？', '[{"key":"A","text":"只看开头和结尾"},{"key":"B","text":"找出中心句并理解支撑内容"},{"key":"C","text":"只读懂每一句话"}]', 'B', '最好的方法是找出中心句，理解它如何被其他句子支撑和展开。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_duanluo'), 'MULTIPLE_CHOICE', 5, '阅读：赵州桥非常雄伟。桥长五十多米，有九米多宽，中间行车马，两旁走人。这段的中心意思是？', '[{"key":"A","text":"桥的长度"},{"key":"B","text":"桥的宽度"},{"key":"C","text":"赵州桥非常雄伟"}]', 'C', '中心句是"赵州桥非常雄伟"，长度和宽度都是支撑雄伟的具体数据。', 10);

-- ── G3: 习作入门 (chinese_xizuo) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xizuo'), 'SCENE_TAP', 5, '写日记时，第一行应该写什么？', '[{"key":"A","text":"天气"},{"key":"B","text":"日期和星期"},{"key":"C","text":"标题"}]', 'B', '日记格式：第一行写日期、星期和天气，然后另起一行写正文。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xizuo'), 'SCENE_TAP', 5, '写作文的三个基本步骤是什么？', '[{"key":"A","text":"开头、中间、结尾"},{"key":"B","text":"审题、写作、修改"},{"key":"C","text":"看书、写字、画画"}]', 'B', '写作基本步骤：先审题明确写什么，再写作，最后修改检查。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xizuo'), 'SCENE_TAP', 5, '下面哪个是观察事物的正确顺序？', '[{"key":"A","text":"从整体到局部"},{"key":"B","text":"从局部到整体"},{"key":"C","text":"都可以，但要按一定顺序"}]', 'C', '观察要有顺序，可以从整体到局部、从上到下、从远到近等。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xizuo'), 'SCENE_TAP', 5, '写"我的妈妈"时，下面哪个内容最好？', '[{"key":"A","text":"写妈妈长什么样和一件感人的事"},{"key":"B","text":"只写妈妈的名字和年龄"},{"key":"C","text":"写所有家人的信息"}]', 'A', '写人作文要抓住人物特点（外貌）加上具体事例来体现人物品质。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xizuo'), 'MULTIPLE_CHOICE', 5, '一篇完整的作文通常包括几个部分？', '[{"key":"A","text":"2个：开头和结尾"},{"key":"B","text":"3个：开头、中间、结尾"},{"key":"C","text":"1个：想到什么写什么"}]', 'B', '完整的作文结构：开头（引入）、中间（详细展开）、结尾（总结）。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xizuo'), 'SCENE_TAP', 5, '写"一件难忘的事"，最重要的是什么？', '[{"key":"A","text":"字数很多"},{"key":"B","text":"把事情的经过写清楚"},{"key":"C","text":"用很多好词好句"}]', 'B', '记事作文最重要的是把时间、地点、人物、起因、经过、结果写清楚。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xizuo'), 'FILL_BLANK', 5, '写作文时，要把时间、______、人物、起因、经过、结果写清楚，这叫"六要素"。', NULL, '地点', '记事作文六要素：时间、地点、人物、起因、经过、结果。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_xizuo'), 'SCENE_TAP', 5, '修改作文时，主要检查什么？', '[{"key":"A","text":"字写得好看不好看"},{"key":"B","text":"错别字、病句和内容是否通顺"},{"key":"C","text":"有没有用彩色笔"}]', 'B', '修改作文重点：检查错别字、病句、语句是否通顺、内容是否完整。', 10);

-- ============================================================
-- Sprint B: Math G2-G3 Questions (~100 new questions)
-- ============================================================

-- ── G2: 表内乘法 (math_chengfa) ~10 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_chengfa'), 'SCENE_TAP', 3, '3 × 4 = ?', '[{"key":"A","text":"7"},{"key":"B","text":"12"},{"key":"C","text":"15"}]', 'B', '3×4表示3个4相加：4+4+4=12，或背口诀"三四十二"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chengfa'), 'SCENE_TAP', 3, '5 × 6 = ?', '[{"key":"A","text":"25"},{"key":"B","text":"30"},{"key":"C","text":"35"}]', 'B', '5×6=30，口诀"五六三十"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chengfa'), 'SCENE_TAP', 3, '4 × 8 = ?', '[{"key":"A","text":"24"},{"key":"B","text":"28"},{"key":"C","text":"32"}]', 'C', '4×8=32，口诀"四八三十二"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chengfa'), 'SCENE_TAP', 3, '7 × 7 = ?', '[{"key":"A","text":"42"},{"key":"B","text":"49"},{"key":"C","text":"56"}]', 'B', '7×7=49，口诀"七七四十九"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chengfa'), 'SCENE_TAP', 3, '9 × 3 = ?', '[{"key":"A","text":"27"},{"key":"B","text":"30"},{"key":"C","text":"36"}]', 'A', '9×3=27，口诀"三九二十七"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chengfa'), 'MATH_INPUT', 3, '6 × 7 = ?', NULL, '42', '6×7=42，口诀"六七四十二"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chengfa'), 'SCENE_TAP', 3, '小明有3排铅笔，每排5支，一共有多少支？', '[{"key":"A","text":"8支"},{"key":"B","text":"15支"},{"key":"C","text":"10支"}]', 'B', '3×5=15，或者5+5+5=15。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chengfa'), 'SCENE_TAP', 3, '8 × 2 和 2 × 8 的结果一样吗？', '[{"key":"A","text":"不一样"},{"key":"B","text":"一样"},{"key":"C","text":"不确定"}]', 'B', '乘法交换律：8×2=16，2×8=16，结果相同。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chengfa'), 'MATH_INPUT', 3, '5 × 8 = ?', NULL, '40', '5×8=40，口诀"五八四十"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chengfa'), 'SCENE_TAP', 3, '5 × 0 = ?', '[{"key":"A","text":"5"},{"key":"B","text":"0"},{"key":"C","text":"1"}]', 'B', '任何数乘以0都等于0。', 10);

-- ── G2: 表内除法 (math_chufa) ~10 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_chufa'), 'SCENE_TAP', 3, '12 ÷ 3 = ?', '[{"key":"A","text":"3"},{"key":"B","text":"4"},{"key":"C","text":"5"}]', 'B', '12÷3=4，想口诀"三四十二"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chufa'), 'SCENE_TAP', 3, '20 ÷ 5 = ?', '[{"key":"A","text":"3"},{"key":"B","text":"4"},{"key":"C","text":"5"}]', 'B', '20÷5=4，想口诀"四五二十"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chufa'), 'SCENE_TAP', 3, '把18个苹果平均分给3个小朋友，每人几个？', '[{"key":"A","text":"5个"},{"key":"B","text":"6个"},{"key":"C","text":"7个"}]', 'B', '18÷3=6，每人6个苹果。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chufa'), 'SCENE_TAP', 3, '36 ÷ 6 = ?', '[{"key":"A","text":"5"},{"key":"B","text":"6"},{"key":"C","text":"7"}]', 'B', '36÷6=6，口诀"六六三十六"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chufa'), 'MATH_INPUT', 3, '24 ÷ 4 = ?', NULL, '6', '24÷4=6，口诀"四六二十四"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chufa'), 'SCENE_TAP', 3, '有45颗糖，每袋装5颗，可以装几袋？', '[{"key":"A","text":"7袋"},{"key":"B","text":"8袋"},{"key":"C","text":"9袋"}]', 'C', '45÷5=9，口诀"五九四十五"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chufa'), 'SCENE_TAP', 3, '8 ÷ 1 = ?', '[{"key":"A","text":"1"},{"key":"B","text":"8"},{"key":"C","text":"0"}]', 'B', '任何数除以1都等于它本身。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chufa'), 'SCENE_TAP', 3, '30 ÷ 5 = ?', '[{"key":"A","text":"5"},{"key":"B","text":"6"},{"key":"C","text":"7"}]', 'B', '30÷5=6，口诀"五六三十"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chufa'), 'SCENE_TAP', 3, '0 ÷ 9 = ?', '[{"key":"A","text":"0"},{"key":"B","text":"9"},{"key":"C","text":"不能算"}]', 'A', '0除以任何非0数都等于0。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_chufa'), 'MATH_INPUT', 3, '63 ÷ 9 = ?', NULL, '7', '63÷9=7，口诀"七九六十三"。', 10);

-- ── G2: 100以内加减 (math_100addsub) ~10 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_100addsub'), 'SCENE_TAP', 3, '45 + 38 = ?', '[{"key":"A","text":"73"},{"key":"B","text":"83"},{"key":"C","text":"93"}]', 'B', '45+38=83。个位：5+8=13写3进1；十位：4+3+1=8。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_100addsub'), 'SCENE_TAP', 3, '72 - 29 = ?', '[{"key":"A","text":"43"},{"key":"B","text":"53"},{"key":"C","text":"47"}]', 'A', '72-29=43。个位2-9不够借1：12-9=3；十位6-2=4。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_100addsub'), 'SCENE_TAP', 3, '56 + 27 = ?', '[{"key":"A","text":"73"},{"key":"B","text":"83"},{"key":"C","text":"93"}]', 'B', '56+27=83。个位6+7=13进1，十位5+2+1=8。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_100addsub'), 'SCENE_TAP', 3, '91 - 45 = ?', '[{"key":"A","text":"36"},{"key":"B","text":"46"},{"key":"C","text":"56"}]', 'B', '91-45=46。个位1-5不够借1：11-5=6；十位8-4=4。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_100addsub'), 'MATH_INPUT', 3, '34 + 59 = ?', NULL, '93', '34+59=93。个位4+9=13进1；十位3+5+1=9。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_100addsub'), 'SCENE_TAP', 3, '100 - 64 = ?', '[{"key":"A","text":"26"},{"key":"B","text":"36"},{"key":"C","text":"46"}]', 'B', '100-64=36。100-60=40，40-4=36。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_100addsub'), 'SCENE_TAP', 3, '小红有58元，买书花了35元，还剩多少？', '[{"key":"A","text":"13元"},{"key":"B","text":"23元"},{"key":"C","text":"33元"}]', 'B', '58-35=23元。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_100addsub'), 'MATH_INPUT', 3, '87 - 39 = ?', NULL, '48', '87-39=48。个位7-9不够借1：17-9=8；十位7-3=4。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_100addsub'), 'SCENE_TAP', 3, '24 + 69 = ?', '[{"key":"A","text":"83"},{"key":"B","text":"93"},{"key":"C","text":"103"}]', 'B', '24+69=93。个位4+9=13进1；十位2+6+1=9。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_100addsub'), 'SCENE_TAP', 3, '65 + 17 - 23 = ?', '[{"key":"A","text":"49"},{"key":"B","text":"59"},{"key":"C","text":"69"}]', 'B', '65+17=82，82-23=59。', 10);

-- ── G2: 长度单位 (math_length) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_length'), 'SCENE_TAP', 3, '1米 = ( )厘米？', '[{"key":"A","text":"10"},{"key":"B","text":"100"},{"key":"C","text":"1000"}]', 'B', '1米=100厘米。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_length'), 'SCENE_TAP', 3, '小明的身高约120( )？', '[{"key":"A","text":"米"},{"key":"B","text":"厘米"},{"key":"C","text":"毫米"}]', 'B', '二年级小朋友身高大约120厘米，即1米20厘米。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_length'), 'SCENE_TAP', 3, '一支铅笔大约长15( )？', '[{"key":"A","text":"厘米"},{"key":"B","text":"米"},{"key":"C","text":"千米"}]', 'A', '铅笔长度约15厘米。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_length'), 'SCENE_TAP', 3, '3米 = ( )厘米？', '[{"key":"A","text":"30"},{"key":"B","text":"300"},{"key":"C","text":"3000"}]', 'B', '1米=100厘米，3米=3×100=300厘米。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_length'), 'SCENE_TAP', 3, '教室的门大约高2( )？', '[{"key":"A","text":"厘米"},{"key":"B","text":"米"},{"key":"C","text":"毫米"}]', 'B', '门的标准高度约2米。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_length'), 'SCENE_TAP', 3, '200厘米 = ( )米？', '[{"key":"A","text":"2"},{"key":"B","text":"20"},{"key":"C","text":"0.2"}]', 'A', '100厘米=1米，200÷100=2米。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_length'), 'SCENE_TAP', 3, '下面哪个最长？', '[{"key":"A","text":"1米"},{"key":"B","text":"90厘米"},{"key":"C","text":"1米20厘米"}]', 'C', 'A=100cm, B=90cm, C=120cm，所以C最长。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_length'), 'MATH_INPUT', 3, '一条绳子长5米，剪去200厘米，还剩( )厘米。', NULL, '300', '5米=500厘米，500-200=300厘米。', 10);

-- ── G2: 角的初步认识 (math_angle) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_angle'), 'SCENE_TAP', 4, '三角板上有几个直角？', '[{"key":"A","text":"0个"},{"key":"B","text":"1个"},{"key":"C","text":"2个"}]', 'B', '标准三角板（等腰直角三角形）有1个直角和2个锐角。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_angle'), 'SCENE_TAP', 4, '比直角小的角叫什么？', '[{"key":"A","text":"钝角"},{"key":"B","text":"锐角"},{"key":"C","text":"平角"}]', 'B', '锐角 < 直角(90°) < 钝角。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_angle'), 'SCENE_TAP', 4, '比直角大的角叫什么？', '[{"key":"A","text":"锐角"},{"key":"B","text":"钝角"},{"key":"C","text":"直角"}]', 'B', '钝角比直角大，比平角小。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_angle'), 'SCENE_TAP', 4, '正方形有( )个直角？', '[{"key":"A","text":"2"},{"key":"B","text":"4"},{"key":"C","text":"0"}]', 'B', '正方形四个角都是直角。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_angle'), 'SCENE_TAP', 4, '用放大镜看一个角，角的大小会？', '[{"key":"A","text":"变大"},{"key":"B","text":"变小"},{"key":"C","text":"不变"}]', 'C', '角的大小由两条边张开的程度决定，与边的长短无关。放大镜不改变角的大小。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_angle'), 'SCENE_TAP', 4, '上午9时，时针和分针组成什么角？', '[{"key":"A","text":"锐角"},{"key":"B","text":"直角"},{"key":"C","text":"钝角"}]', 'B', '9时整，时针指9，分针指12，正好形成直角。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_angle'), 'MULTIPLE_CHOICE', 4, '两条边张开得越大，角就越？', '[{"key":"A","text":"大"},{"key":"B","text":"小"},{"key":"C","text":"不变"}]', 'A', '角的大小由两条边张开的程度决定，张得越大角越大。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_angle'), 'SCENE_TAP', 4, '下午3时，时针和分针组成什么角？', '[{"key":"A","text":"直角"},{"key":"B","text":"锐角"},{"key":"C","text":"钝角"}]', 'A', '3时整时针指3分针指12，形成直角。', 10);

-- ── G2: 混合运算 (math_mixed) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_mixed'), 'SCENE_TAP', 4, '3 + 4 × 2 = ?', '[{"key":"A","text":"14"},{"key":"B","text":"11"},{"key":"C","text":"10"}]', 'B', '先乘后加：4×2=8，3+8=11。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_mixed'), 'SCENE_TAP', 4, '(8 - 3) × 5 = ?', '[{"key":"A","text":"25"},{"key":"B","text":"40"},{"key":"C","text":"5"}]', 'A', '先算括号：8-3=5，再乘：5×5=25。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_mixed'), 'SCENE_TAP', 4, '12 ÷ 3 + 7 = ?', '[{"key":"A","text":"5"},{"key":"B","text":"11"},{"key":"C","text":"9"}]', 'B', '先除后加：12÷3=4，4+7=11。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_mixed'), 'SCENE_TAP', 4, '20 - 3 × 4 = ?', '[{"key":"A","text":"68"},{"key":"B","text":"8"},{"key":"C","text":"28"}]', 'B', '先乘后减：3×4=12，20-12=8。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_mixed'), 'SCENE_TAP', 4, '18 ÷ (6 - 3) = ?', '[{"key":"A","text":"3"},{"key":"B","text":"6"},{"key":"C","text":"9"}]', 'B', '先算括号：6-3=3，再除：18÷3=6。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_mixed'), 'MATH_INPUT', 4, '5 × 6 - 14 = ?', NULL, '16', '先乘后减：5×6=30，30-14=16。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_mixed'), 'SCENE_TAP', 4, '混合运算的规则是什么？', '[{"key":"A","text":"从左到右"},{"key":"B","text":"先乘除后加减，有括号先算括号"},{"key":"C","text":"先加减后乘除"}]', 'B', '运算顺序：括号优先，然后乘除，最后加减。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_mixed'), 'MATH_INPUT', 4, '(15 + 9) ÷ 6 = ?', NULL, '4', '先括号：15+9=24，再除：24÷6=4。', 10);

-- ── G3: 万以内加减 (math_10000) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_10000'), 'SCENE_TAP', 4, '234 + 567 = ?', '[{"key":"A","text":"791"},{"key":"B","text":"801"},{"key":"C","text":"811"}]', 'B', '234+567=801。个位4+7=11进1；十位3+6+1=10进1；百位2+5+1=8。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_10000'), 'SCENE_TAP', 4, '1000 - 456 = ?', '[{"key":"A","text":"444"},{"key":"B","text":"544"},{"key":"C","text":"644"}]', 'B', '1000-456=544。借位计算：1000-400=600，600-56=544。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_10000'), 'SCENE_TAP', 4, '3456 + 1289 = ?', '[{"key":"A","text":"4635"},{"key":"B","text":"4745"},{"key":"C","text":"4645"}]', 'B', '3456+1289=4745。各位相加注意进位。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_10000'), 'SCENE_TAP', 4, '5000 - 2345 = ?', '[{"key":"A","text":"2655"},{"key":"B","text":"2755"},{"key":"C","text":"2555"}]', 'A', '5000-2345=2655。借位减法。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_10000'), 'MATH_INPUT', 4, '1899 + 276 = ?', NULL, '2175', '1899+276=2175。个位9+6=15进1；十位9+7+1=17进1；百位8+2+1=11进1；千位1+1=2。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_10000'), 'SCENE_TAP', 4, '最大的三位数加最小的四位数是多少？', '[{"key":"A","text":"1999"},{"key":"B","text":"2000"},{"key":"C","text":"1000"}]', 'A', '999+1000=1999。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_10000'), 'SCENE_TAP', 4, '比3000少1的数是多少？', '[{"key":"A","text":"3001"},{"key":"B","text":"2999"},{"key":"C","text":"2900"}]', 'B', '3000-1=2999。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_10000'), 'MATH_INPUT', 4, '4600 - 1785 = ?', NULL, '2815', '4600-1785=2815。', 10);

-- ── G3: 多位数乘法 (math_multidigit) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_multidigit'), 'SCENE_TAP', 5, '23 × 3 = ?', '[{"key":"A","text":"69"},{"key":"B","text":"66"},{"key":"C","text":"96"}]', 'A', '23×3=69。3×3=9（个位），20×3=60（十位），60+9=69。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_multidigit'), 'SCENE_TAP', 5, '45 × 2 = ?', '[{"key":"A","text":"80"},{"key":"B","text":"90"},{"key":"C","text":"100"}]', 'B', '45×2=90。5×2=10，40×2=80，80+10=90。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_multidigit'), 'SCENE_TAP', 5, '12 × 4 = ?', '[{"key":"A","text":"36"},{"key":"B","text":"48"},{"key":"C","text":"84"}]', 'B', '12×4=48。2×4=8，10×4=40，40+8=48。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_multidigit'), 'MATH_INPUT', 5, '31 × 6 = ?', NULL, '186', '31×6=186。1×6=6，30×6=180，180+6=186。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_multidigit'), 'SCENE_TAP', 5, '13 × 13 = ?', '[{"key":"A","text":"169"},{"key":"B","text":"159"},{"key":"C","text":"179"}]', 'A', '13×13=169。13×10=130，13×3=39，130+39=169。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_multidigit'), 'MATH_INPUT', 5, '24 × 5 = ?', NULL, '120', '24×5=120。20×5=100，4×5=20，100+20=120。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_multidigit'), 'SCENE_TAP', 5, '一个班有24人，3个班一共有多少人？', '[{"key":"A","text":"62人"},{"key":"B","text":"72人"},{"key":"C","text":"82人"}]', 'B', '24×3=72。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_multidigit'), 'MATH_INPUT', 5, '15 × 8 = ?', NULL, '120', '15×8=120。10×8=80，5×8=40，80+40=120。', 10);

-- ── G3: 分数初步 (math_fraction) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_fraction'), 'SCENE_TAP', 4, '把一个蛋糕平均分成4份，每份是这个蛋糕的几分之一？', '[{"key":"A","text":"1/2"},{"key":"B","text":"1/3"},{"key":"C","text":"1/4"}]', 'C', '平均分成4份，每份是1/4。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_fraction'), 'SCENE_TAP', 4, '1/2 和 1/4 谁大？', '[{"key":"A","text":"1/2大"},{"key":"B","text":"1/4大"},{"key":"C","text":"一样大"}]', 'A', '分子相同（都是1），分母越小分数越大。1/2 > 1/4。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_fraction'), 'SCENE_TAP', 4, '把一张纸对折两次，每份是这张纸的几分之一？', '[{"key":"A","text":"1/2"},{"key":"B","text":"1/4"},{"key":"C","text":"1/8"}]', 'B', '对折1次=1/2，对折2次=1/4。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_fraction'), 'SCENE_TAP', 4, '小明吃了一块蛋糕的3/8，还剩几分之几？', '[{"key":"A","text":"4/8"},{"key":"B","text":"5/8"},{"key":"C","text":"6/8"}]', 'B', '1=8/8，8/8-3/8=5/8。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_fraction'), 'SCENE_TAP', 4, '2/8 = ( )/4', '[{"key":"A","text":"1"},{"key":"B","text":"2"},{"key":"C","text":"4"}]', 'A', '2/8=1/4，分子分母同时除以2。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_fraction'), 'FILL_BLANK', 4, '分数的分母表示把一个整体平均分成的______。', NULL, '份数', '分母表示平均分的份数，分子表示取了多少份。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_fraction'), 'SCENE_TAP', 4, '3/6 ○ 3/8，○里应填？', '[{"key":"A","text":">"},{"key":"B","text":"<"},{"key":"C","text":"="}]', 'A', '分子相同（都是3），分母越小分数越大。6<8，所以3/6>3/8。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_fraction'), 'MATH_INPUT', 4, '1/5 + 2/5 = ( )/( ) (填 分子/分母)', NULL, '3/5', '分母相同直接加分子：1+2=3，结果是3/5。', 10);

-- ── G3: 面积与周长 (math_area) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_area'), 'SCENE_TAP', 5, '一个长方形长5米、宽3米，周长是多少？', '[{"key":"A","text":"15米"},{"key":"B","text":"16米"},{"key":"C","text":"8米"}]', 'B', '周长=(5+3)×2=16米。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_area'), 'SCENE_TAP', 5, '一个正方形边长4厘米，面积是多少？', '[{"key":"A","text":"8平方厘米"},{"key":"B","text":"16平方厘米"},{"key":"C","text":"12平方厘米"}]', 'B', '正方形面积=边长×边长=4×4=16平方厘米。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_area'), 'SCENE_TAP', 5, '一个长方形长6米、宽4米，面积是多少？', '[{"key":"A","text":"20平方米"},{"key":"B","text":"24平方米"},{"key":"C","text":"10平方米"}]', 'B', '长方形面积=长×宽=6×4=24平方米。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_area'), 'SCENE_TAP', 5, '周长和面积的关系是？', '[{"key":"A","text":"一样"},{"key":"B","text":"周长是边长和，面积是面的大小"},{"key":"C","text":"没有区别"}]', 'B', '周长是图形一周的长度（边界），面积是图形表面的大小。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_area'), 'MATH_INPUT', 5, '正方形边长7分米，周长是( )分米。', NULL, '28', '正方形周长=边长×4=7×4=28分米。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_area'), 'SCENE_TAP', 5, '1平方米 = ( )平方分米？', '[{"key":"A","text":"10"},{"key":"B","text":"100"},{"key":"C","text":"1000"}]', 'B', '1米=10分米，1平方米=10×10=100平方分米。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_area'), 'SCENE_TAP', 5, '面积相等的两个长方形，周长一定相等吗？', '[{"key":"A","text":"一定相等"},{"key":"B","text":"不一定相等"},{"key":"C","text":"一定不相等"}]', 'B', '例如4×4=16和2×8=16面积相等，但周长分别为16和20。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_area'), 'MATH_INPUT', 5, '长方形长8厘米宽5厘米，面积是( )平方厘米。', NULL, '40', '面积=8×5=40平方厘米。', 10);

-- ── G3: 年月日 (math_calendar) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_calendar'), 'SCENE_TAP', 4, '闰年2月有多少天？', '[{"key":"A","text":"28天"},{"key":"B","text":"29天"},{"key":"C","text":"30天"}]', 'B', '平年2月28天，闰年2月29天。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_calendar'), 'SCENE_TAP', 4, '一年有多少个月？', '[{"key":"A","text":"10个"},{"key":"B","text":"12个"},{"key":"C","text":"24个"}]', 'B', '一年有12个月。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_calendar'), 'SCENE_TAP', 4, '大月有多少天？', '[{"key":"A","text":"30天"},{"key":"B","text":"31天"},{"key":"C","text":"28天"}]', 'B', '大月（1、3、5、7、8、10、12月）有31天。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_calendar'), 'SCENE_TAP', 4, '2024年是不是闰年？', '[{"key":"A","text":"是"},{"key":"B","text":"不是"},{"key":"C","text":"不确定"}]', 'A', '2024÷4=506（整除），所以2024年是闰年。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_calendar'), 'SCENE_TAP', 4, '下午3时用24时计时法怎么表示？', '[{"key":"A","text":"3:00"},{"key":"B","text":"15:00"},{"key":"C","text":"13:00"}]', 'B', '下午时间+12=24时计时法：3+12=15时。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_calendar'), 'SCENE_TAP', 4, '从上午9时到下午2时，经过了几个小时？', '[{"key":"A","text":"5小时"},{"key":"B","text":"7小时"},{"key":"C","text":"6小时"}]', 'A', '14时-9时=5小时。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_calendar'), 'MULTIPLE_CHOICE', 4, '下面哪个月是小月（30天）？', '[{"key":"A","text":"1月"},{"key":"B","text":"4月"},{"key":"C","text":"8月"}]', 'B', '4月是小月30天；1月和8月都是大月31天。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_calendar'), 'SCENE_TAP', 4, '一个星期有几天？', '[{"key":"A","text":"5天"},{"key":"B","text":"6天"},{"key":"C","text":"7天"}]', 'C', '一星期有7天：周一至周日。', 10);

-- ── G3: 小数初步 (math_decimal) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'math_decimal'), 'SCENE_TAP', 4, '0.5 + 0.3 = ?', '[{"key":"A","text":"0.8"},{"key":"B","text":"0.2"},{"key":"C","text":"0.53"}]', 'A', '0.5+0.3=0.8。小数点对齐，5+3=8（十分位）。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_decimal'), 'SCENE_TAP', 4, '1.2 - 0.7 = ?', '[{"key":"A","text":"0.5"},{"key":"B","text":"1.5"},{"key":"C","text":"0.6"}]', 'A', '1.2-0.7=0.5。十分位：2-7不够，借1变12-7=5，个位：0-0=0。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_decimal'), 'SCENE_TAP', 4, '3.6 + 2.4 = ?', '[{"key":"A","text":"5.0"},{"key":"B","text":"6.0"},{"key":"C","text":"5.10"}]', 'B', '3.6+2.4=6.0。十分位6+4=10进1，个位3+2+1=6。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_decimal'), 'SCENE_TAP', 4, '0.7 = ( )/10', '[{"key":"A","text":"7"},{"key":"B","text":"70"},{"key":"C","text":"1/7"}]', 'A', '一位小数表示十分之几：0.7=7/10。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_decimal'), 'MATH_INPUT', 4, '2.5 + 1.8 = ?', NULL, '4.3', '2.5+1.8=4.3。十分位5+8=13进1，个位2+1+1=4。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_decimal'), 'SCENE_TAP', 4, '5角用小数表示是多少元？', '[{"key":"A","text":"0.5元"},{"key":"B","text":"0.05元"},{"key":"C","text":"5.0元"}]', 'A', '1元=10角，5角=0.5元。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_decimal'), 'SCENE_TAP', 4, '比较大小：0.9 ○ 1.1', '[{"key":"A","text":">"},{"key":"B","text":"<"},{"key":"C","text":"="}]', 'B', '0.9 < 1.1。先比较整数部分：0 < 1。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'math_decimal'), 'MATH_INPUT', 4, '4.0 - 2.3 = ?', NULL, '1.7', '4.0-2.3=1.7。十分位0-3不够借1：10-3=7，个位3-2=1。', 10);

-- ============================================================
-- Sprint B: English G1-G3 Questions (~100 new questions)
-- ============================================================

-- ── G1: 日常用语 (english_daily) ~10 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_daily'), 'SCENE_TAP', 1, '早上见到老师，应该说什么？', '[{"key":"A","text":"Goodbye"},{"key":"B","text":"Good morning"},{"key":"C","text":"Good night"}]', 'B', 'Good morning = 早上好。Goodbye是再见，Good night是晚安。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_daily'), 'SCENE_TAP', 1, '"Hello"的中文意思是？', '[{"key":"A","text":"再见"},{"key":"B","text":"你好"},{"key":"C","text":"谢谢"}]', 'B', 'Hello = 你好，是最常用的问候语。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_daily'), 'SCENE_TAP', 1, '别人帮助了你，你应该说什么？', '[{"key":"A","text":"Sorry"},{"key":"B","text":"Thank you"},{"key":"C","text":"Excuse me"}]', 'B', 'Thank you = 谢谢你。Sorry是对不起，Excuse me是打扰一下。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_daily'), 'SCENE_TAP', 1, '"How are you?" 的回答是什么？', '[{"key":"A","text":"How are you?"},{"key":"B","text":"I am fine, thank you"},{"key":"C","text":"Goodbye"}]', 'B', 'How are you? 是"你好吗？"，标准回答：I am fine, thank you.', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_daily'), 'MULTIPLE_CHOICE', 1, '"Goodbye"是什么意思？', '[{"key":"A","text":"你好"},{"key":"B","text":"再见"},{"key":"C","text":"谢谢"}]', 'B', 'Goodbye = 再见。Bye是简略说法。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_daily'), 'FILL_BLANK', 1, '"请坐"用英语说是 Please ______ down.', NULL, 'sit', 'Sit down = 坐下。Please sit down = 请坐。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_daily'), 'SCENE_TAP', 1, '你想知道别人的名字，应该问？', '[{"key":"A","text":"How are you?"},{"key":"B","text":"What is your name?"},{"key":"C","text":"Where are you?"}]', 'B', 'What is your name? = 你叫什么名字？', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_daily'), 'FILL_BLANK', 1, '"对不起"的英文是______。', NULL, 'Sorry', 'Sorry表示对不起、抱歉。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_daily'), 'SCENE_TAP', 1, '"Nice to meet you"是什么意思？', '[{"key":"A","text":"再见"},{"key":"B","text":"很高兴认识你"},{"key":"C","text":"你好吗"}]', 'B', 'Nice to meet you = 很高兴认识你，用于初次见面。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_daily'), 'MULTIPLE_CHOICE', 1, '"See you"是什么意思？', '[{"key":"A","text":"看见你"},{"key":"B","text":"再见"},{"key":"C","text":"你好"}]', 'B', 'See you = 再见。See you later = 待会见。', 10);

-- ── G1: 颜色与数字身体 (english_colors) ~12 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_colors'), 'SCENE_TAP', 1, '"red"是什么颜色？', '[{"key":"A","text":"蓝色"},{"key":"B","text":"红色"},{"key":"C","text":"绿色"}]', 'B', 'red = 红色。blue = 蓝色，green = 绿色。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_colors'), 'SCENE_TAP', 1, '数字"5"的英文是？', '[{"key":"A","text":"four"},{"key":"B","text":"five"},{"key":"C","text":"six"}]', 'B', '5 = five。4 = four，6 = six。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_colors'), 'SCENE_TAP', 1, '"eye"的中文意思是？', '[{"key":"A","text":"耳朵"},{"key":"B","text":"眼睛"},{"key":"C","text":"鼻子"}]', 'B', 'eye = 眼睛。ear = 耳朵，nose = 鼻子。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_colors'), 'FILL_BLANK', 1, '天空的颜色是______。', NULL, 'blue', 'blue表示蓝色，天空是蓝色的。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_colors'), 'SCENE_TAP', 1, '"three"是数字几？', '[{"key":"A","text":"2"},{"key":"B","text":"3"},{"key":"C","text":"4"}]', 'B', 'three = 3。two = 2，four = 4。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_colors'), 'SCENE_MATCH', 1, 'Match the color: Which one is "yellow"?', '[{"key":"RED","label":"🔴 Red","cssShape":"circle","color":"rose"},{"key":"YELLOW","label":"🟡 Yellow","cssShape":"circle","color":"amber"},{"key":"BLUE","label":"🔵 Blue","cssShape":"circle","color":"sky"},{"key":"GREEN","label":"🟢 Green","cssShape":"circle","color":"emerald"}]', 'YELLOW', 'yellow = 黄色 🟡', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_colors'), 'SCENE_TAP', 1, '"mouth"的中文意思是？', '[{"key":"A","text":"手"},{"key":"B","text":"嘴巴"},{"key":"C","text":"脚"}]', 'B', 'mouth = 嘴巴。hand = 手，foot = 脚。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_colors'), 'SCENE_TAP', 1, '数字"10"的英文是？', '[{"key":"A","text":"ten"},{"key":"B","text":"one"},{"key":"C","text":"two"}]', 'A', '10 = ten。one = 1，two = 2。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_colors'), 'VOCAB_MATCH', 1, '请将英文数字与中文配对', '{"left":[{"id":"A","text":"one"},{"id":"B","text":"seven"},{"id":"C","text":"nine"}],"right":[{"id":"1","text":"七"},{"id":"2","text":"一"},{"id":"3","text":"九"}]}', 'A2,B1,C3', 'one=一, seven=七, nine=九', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_colors'), 'FILL_BLANK', 1, '草地的颜色是______。', NULL, 'green', 'green表示绿色，草地是绿色的。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_colors'), 'SCENE_TAP', 1, '"black"和"white"是什么颜色？', '[{"key":"A","text":"红色和蓝色"},{"key":"B","text":"黑色和白色"},{"key":"C","text":"绿色和黄色"}]', 'B', 'black = 黑色，white = 白色。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_colors'), 'MULTIPLE_CHOICE', 1, 'How many fingers do you have on one hand?', '[{"key":"A","text":"Five"},{"key":"B","text":"Ten"},{"key":"C","text":"Three"}]', 'A', '一只手有5根手指：one hand has five fingers。', 10);

-- ── G2: 自然拼读 (english_phonics) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_phonics'), 'SCENE_TAP', 3, '字母"a"在"cat"中发什么音？', '[{"key":"A","text":"/æ/ (短音a)"},{"key":"B","text":"/eɪ/ (长音a)"},{"key":"C","text":"/ɑ:/ (长音ar)"}]', 'A', 'cat中a发短音/æ/，类似的还有hat, bat, map。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phonics'), 'SCENE_TAP', 3, '哪个单词中"ee"发长音/i:/？', '[{"key":"A","text":"bed"},{"key":"B","text":"see"},{"key":"C","text":"pet"}]', 'B', 'see中ee发长音/i:/。相同发音的还有bee, tree, feet。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phonics'), 'SCENE_TAP', 3, '字母"c"在"cat"中发什么音？', '[{"key":"A","text":"/s/"},{"key":"B","text":"/k/"},{"key":"C","text":"/tʃ/"}]', 'B', 'c在a/o/u前发/k/：cat, cup, cot。在e/i/y前发/s/：cent, city。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phonics'), 'SCENE_TAP', 3, '哪个单词和"pig"中的"i"发音相同？', '[{"key":"A","text":"bike"},{"key":"B","text":"big"},{"key":"C","text":"like"}]', 'B', 'pig和big中i都发短音/ɪ/。bike中i发长音/aɪ/。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phonics'), 'SCENE_TAP', 3, '"sh"在"ship"中发什么音？', '[{"key":"A","text":"/s/"},{"key":"B","text":"/h/"},{"key":"C","text":"/ʃ/ (类似"湿")"}]', 'C', 'sh组合发/ʃ/音，类似中文"湿"。ship, fish, shop。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phonics'), 'SCENE_TAP', 3, '哪个单词和"name"中的"a"发音相同？', '[{"key":"A","text":"cat"},{"key":"B","text":"cake"},{"key":"C","text":"bag"}]', 'B', 'name和cake中a都发长音/eɪ/（开音节）。cat中a发短音/æ/。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phonics'), 'FILL_BLANK', 3, '字母组合"ch"在"chair"中发______音。', NULL, '/tʃ/', 'ch通常发/tʃ/音，类似中文"吃"。chair, child, lunch。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phonics'), 'SCENE_TAP', 3, '哪个单词中"th"的发音不同于其他？', '[{"key":"A","text":"think"},{"key":"B","text":"this"},{"key":"C","text":"thank"}]', 'B', 'this中th发浊音/ð/，think和thank中th发清音/θ/。', 10);

-- ── G2: 常用短语 (english_phrases) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_phrases'), 'SCENE_TAP', 3, '"get up"是什么意思？', '[{"key":"A","text":"睡觉"},{"key":"B","text":"起床"},{"key":"C","text":"坐下"}]', 'B', 'get up = 起床。go to bed = 睡觉。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phrases'), 'SCENE_TAP', 3, '"go to school"是什么意思？', '[{"key":"A","text":"回家"},{"key":"B","text":"去公园"},{"key":"C","text":"去上学"}]', 'C', 'go to school = 去上学。go home = 回家。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phrases'), 'MULTIPLE_CHOICE', 3, '"have breakfast"的意思是？', '[{"key":"A","text":"吃午饭"},{"key":"B","text":"吃早饭"},{"key":"C","text":"吃晚饭"}]', 'B', 'breakfast = 早饭，lunch = 午饭，dinner = 晚饭。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phrases'), 'SCENE_TAP', 3, '"wash hands"应该什么时候做？', '[{"key":"A","text":"睡觉前"},{"key":"B","text":"吃饭前"},{"key":"C","text":"都可以"}]', 'C', 'wash hands = 洗手。吃饭前和上厕所后都应该洗手。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phrases'), 'VOCAB_MATCH', 3, '请将英文短语与中文配对', '{"left":[{"id":"A","text":"brush teeth"},{"id":"B","text":"do homework"},{"id":"C","text":"read books"}],"right":[{"id":"1","text":"做作业"},{"id":"2","text":"刷牙"},{"id":"3","text":"读书"}]}', 'A2,B1,C3', 'brush teeth=刷牙, do homework=做作业, read books=读书', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phrases'), 'FILL_BLANK', 3, '"watch TV" 的中文意思是______。', NULL, '看电视', 'watch TV = 看电视。watch表示观看移动的画面。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phrases'), 'SCENE_TAP', 3, '"put on" 用在什么场合？', '[{"key":"A","text":"脱衣服"},{"key":"B","text":"穿衣服"},{"key":"C","text":"吃东西"}]', 'B', 'put on = 穿上、戴上（衣物）。take off = 脱下。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_phrases'), 'SCENE_TAP', 3, '"I like ___ basketball." 空格处填什么？', '[{"key":"A","text":"play"},{"key":"B","text":"playing"},{"key":"C","text":"plays"}]', 'B', 'like + doing：like playing basketball（喜欢打篮球）。', 10);

-- ── G2: 情景对话 (english_dialogue) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_dialogue'), 'MULTIPLE_CHOICE', 3, 'A: "What is your name?" B: "______"', '[{"key":"A","text":"I am fine"},{"key":"B","text":"My name is Tom"},{"key":"C","text":"I am ten"}]', 'B', '问名字用What is your name?，回答My name is + 名字。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_dialogue'), 'MULTIPLE_CHOICE', 3, 'A: "How old are you?" B: "______"', '[{"key":"A","text":"I am fine"},{"key":"B","text":"I am eight"},{"key":"C","text":"My name is Amy"}]', 'B', '问年龄用How old are you?，回答I am + 数字。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_dialogue'), 'SCENE_TAP', 3, '你想买一个苹果，应该怎么说？', '[{"key":"A","text":"I want an apple"},{"key":"B","text":"I am an apple"},{"key":"C","text":"You are an apple"}]', 'A', 'I want... = 我想要...。购物时常用。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_dialogue'), 'MULTIPLE_CHOICE', 3, 'A: "Where is the book?" B: "______"', '[{"key":"A","text":"It is on the desk"},{"key":"B","text":"It is red"},{"key":"C","text":"I like books"}]', 'A', '问地点用Where，回答用方位词（on, in, under）。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_dialogue'), 'FILL_BLANK', 3, '"Can I help you?" 的意思是______。', NULL, '需要帮忙吗/你要买什么', '在商店里，店员常说Can I help you?表示"您需要什么？"', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_dialogue'), 'SCENE_TAP', 3, 'A: "Do you like apples?" B喜欢苹果: "______"', '[{"key":"A","text":"Yes, I do"},{"key":"B","text":"No, I am not"},{"key":"C","text":"Yes, I can"}]', 'A', 'Do you like...?回答：Yes, I do. / No, I do not.', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_dialogue'), 'MULTIPLE_CHOICE', 3, '你想知道时间，应该怎么问？', '[{"key":"A","text":"What time is it?"},{"key":"B","text":"What color is it?"},{"key":"C","text":"How are you?"}]', 'A', 'What time is it? = 几点了？回答：It is + 时间。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_dialogue'), 'FILL_BLANK', 3, 'A: "Thank you!" B: "You are ______."', NULL, 'welcome', 'You are welcome = 不客气。是Thank you的标准回答。', 10);

-- ── G2: 动物与自然 (english_animals) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_animals'), 'SCENE_TAP', 3, '"elephant"是什么动物？', '[{"key":"A","text":"猫"},{"key":"B","text":"大象"},{"key":"C","text":"狗"}]', 'B', 'elephant = 大象，是陆地上最大的哺乳动物。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_animals'), 'SCENE_TAP', 3, '"sunny"是什么天气？', '[{"key":"A","text":"下雨"},{"key":"B","text":"晴天"},{"key":"C","text":"下雪"}]', 'B', 'sunny = 晴天。rainy = 下雨，snowy = 下雪。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_animals'), 'VOCAB_MATCH', 3, '请将动物英文与中文配对', '{"left":[{"id":"A","text":"rabbit"},{"id":"B","text":"monkey"},{"id":"C","text":"panda"}],"right":[{"id":"1","text":"猴子"},{"id":"2","text":"熊猫"},{"id":"3","text":"兔子"}]}', 'A3,B1,C2', 'rabbit=兔子, monkey=猴子, panda=熊猫', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_animals'), 'SCENE_TAP', 3, '"spring"是哪个季节？', '[{"key":"A","text":"春天"},{"key":"B","text":"夏天"},{"key":"C","text":"秋天"}]', 'A', 'spring = 春天。summer = 夏天，autumn/fall = 秋天，winter = 冬天。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_animals'), 'FILL_BLANK', 3, '"It is hot. I want to eat ice cream." 这是什么季节？______', NULL, 'summer', 'hot + ice cream = summer（夏天）。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_animals'), 'SCENE_TAP', 3, 'Which animal can fly?', '[{"key":"A","text":"Dog"},{"key":"B","text":"Bird"},{"key":"C","text":"Fish"}]', 'B', 'Bird can fly. 鸟会飞。Dog是狗，Fish是鱼。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_animals'), 'SCENE_TAP', 3, '"tiger"是什么动物？', '[{"key":"A","text":"狮子"},{"key":"B","text":"老虎"},{"key":"C","text":"熊"}]', 'B', 'tiger = 老虎。lion = 狮子，bear = 熊。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_animals'), 'SCENE_MATCH', 3, 'Which animal lives in water?', '[{"key":"FISH","label":"🐟 Fish","cssShape":"circle","color":"sky"},{"key":"BIRD","label":"🐦 Bird","cssShape":"circle","color":"amber"},{"key":"CAT","label":"🐱 Cat","cssShape":"circle","color":"rose"},{"key":"DOG","label":"🐶 Dog","cssShape":"circle","color":"emerald"}]', 'FISH', 'Fish lives in water. 鱼生活在水里。', 10);

-- ── G3: 简单句型 (english_sentences) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_sentences'), 'SCENE_TAP', 4, '下面哪个是疑问句？', '[{"key":"A","text":"I am a student"},{"key":"B","text":"Are you a student?"},{"key":"C","text":"You are a student"}]', 'B', '疑问句以be动词/助动词开头，句末用问号。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_sentences'), 'SCENE_TAP', 4, '"She ___ a teacher." 空格处填什么？', '[{"key":"A","text":"am"},{"key":"B","text":"is"},{"key":"C","text":"are"}]', 'B', 'she/he/it用is，I用am，you/we/they用are。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_sentences'), 'SCENE_TAP', 4, '"I ___ like apples." (否定句) 空格填什么？', '[{"key":"A","text":"do not"},{"key":"B","text":"is not"},{"key":"C","text":"am not"}]', 'A', '行为动词否定用do not（缩写don''t）。I do not like = I don''t like。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_sentences'), 'SCENE_TAP', 4, '"There ___ three books on the desk."', '[{"key":"A","text":"is"},{"key":"B","text":"are"},{"key":"C","text":"am"}]', 'B', 'There are + 复数名词。There is + 单数名词。three books是复数。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_sentences'), 'MULTIPLE_CHOICE', 4, '下面哪个句子的语序正确？', '[{"key":"A","text":"I like very much apples"},{"key":"B","text":"I like apples very much"},{"key":"C","text":"Like I apples very much"}]', 'B', '英语基本语序：主语+谓语+宾语+状语。I(主) like(谓) apples(宾) very much(状)。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_sentences'), 'FILL_BLANK', 4, '"Can you swim?" 的肯定回答是：Yes, I ______。', NULL, 'can', 'Can开头的一般疑问句，回答也用can：Yes, I can. / No, I cannot.', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_sentences'), 'SCENE_TAP', 4, '把 "I am a boy" 变成一般疑问句：', '[{"key":"A","text":"Am I a boy?"},{"key":"B","text":"Are you a boy?"},{"key":"C","text":"Is I a boy?"}]', 'B', 'I am变一般疑问句要变成Are you...?。Are you a boy? 你是男孩吗？', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_sentences'), 'SCENE_TAP', 4, '"They ___ playing football now."', '[{"key":"A","text":"is"},{"key":"B","text":"are"},{"key":"C","text":"am"}]', 'B', '现在进行时：be + doing。They用are playing。', 10);

-- ── G3: 短文阅读 (english_reading) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_reading'), 'MULTIPLE_CHOICE', 5, '阅读：Tom is a boy. He is eight years old. He likes playing football. How old is Tom?', '[{"key":"A","text":"Seven"},{"key":"B","text":"Eight"},{"key":"C","text":"Nine"}]', 'B', '文中说He is eight years old，Tom 8岁。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_reading'), 'MULTIPLE_CHOICE', 5, '阅读：Amy has a cat. The cat is white. It likes fish. What color is the cat?', '[{"key":"A","text":"Black"},{"key":"B","text":"White"},{"key":"C","text":"Brown"}]', 'B', '文中说The cat is white，猫是白色的。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_reading'), 'FILL_BLANK', 5, '阅读：It is Sunday today. The weather is sunny. We go to the park. 今天星期______。', NULL, '日', 'Sunday = 星期日。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_reading'), 'MULTIPLE_CHOICE', 5, '阅读：Mike gets up at 7:00. He goes to school at 8:00. He likes math. What subject does Mike like?', '[{"key":"A","text":"English"},{"key":"B","text":"Math"},{"key":"C","text":"Chinese"}]', 'B', '文中说He likes math，Mike喜欢数学。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_reading'), 'MULTIPLE_CHOICE', 5, '阅读：There is a big tree in the garden. Three birds are in the tree. How many birds?', '[{"key":"A","text":"Two"},{"key":"B","text":"Three"},{"key":"C","text":"Four"}]', 'B', 'Three birds are in the tree. 有3只鸟。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_reading'), 'SCENE_TAP', 5, '阅读短文时，遇到不认识的单词应该怎么做？', '[{"key":"A","text":"跳过不管"},{"key":"B","text":"根据上下文猜测意思"},{"key":"C","text":"停止阅读"}]', 'B', '遇到生词时，可以根据上下文（周围的句子）猜测词义。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_reading'), 'MULTIPLE_CHOICE', 5, '阅读：Lily has two apples and three bananas. She gives one apple to Tom. How many apples does Lily have now?', '[{"key":"A","text":"One"},{"key":"B","text":"Two"},{"key":"C","text":"Three"}]', 'A', '原来有2个苹果，给了Tom 1个，还剩1个。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_reading'), 'FILL_BLANK', 5, '阅读：I love my family. My father is a doctor. My mother is a ______. She works in a school. 妈妈是做什么的？', NULL, 'teacher', '在学校工作的是teacher（老师）。', 10);

-- ── G3: 语法入门 (english_grammar) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_grammar'), 'SCENE_TAP', 4, '"apple"的复数是？', '[{"key":"A","text":"apples"},{"key":"B","text":"applees"},{"key":"C","text":"applies"}]', 'A', '一般情况下名词复数直接加s：apple→apples。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_grammar'), 'SCENE_TAP', 4, '"He ___ reading a book now." 空格填什么？', '[{"key":"A","text":"is"},{"key":"B","text":"are"},{"key":"C","text":"am"}]', 'A', '现在进行时：主语+be(am/is/are)+动词ing。He用is。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_grammar'), 'SCENE_TAP', 4, '"This is ___ apple." 空格填什么？', '[{"key":"A","text":"a"},{"key":"B","text":"an"},{"key":"C","text":"the"}]', 'B', 'apple以元音音素开头，用an。a用于辅音音素开头的词。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_grammar'), 'SCENE_TAP', 4, '"I ___ a student." 空格填什么？', '[{"key":"A","text":"am"},{"key":"B","text":"is"},{"key":"C","text":"are"}]', 'A', 'be动词用法：I用am，he/she/it用is，you/we/they用are。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_grammar'), 'MULTIPLE_CHOICE', 4, '"box"的复数是什么？', '[{"key":"A","text":"boxs"},{"key":"B","text":"boxes"},{"key":"C","text":"boxies"}]', 'B', '以s/x/sh/ch结尾的名词，复数加es：box→boxes。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_grammar'), 'SCENE_TAP', 4, '"I am ___ (run) now." 用正确形式填空：', '[{"key":"A","text":"run"},{"key":"B","text":"running"},{"key":"C","text":"runs"}]', 'B', '现在进行时用be+动词ing：run双写n加ing→running。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_grammar'), 'SCENE_TAP', 4, '下面哪个是不可数名词？', '[{"key":"A","text":"apple"},{"key":"B","text":"water"},{"key":"C","text":"book"}]', 'B', 'water是不可数名词（不能说a water），apple和book是可数的。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_grammar'), 'FILL_BLANK', 4, '"child"的复数形式是______。', NULL, 'children', 'child的复数是不规则变化children，不是childs。', 10);

-- ── G3: 书写练习 (english_writing) ~8 questions ──
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_writing'), 'SCENE_TAP', 4, '英文句子开头第一个字母应该用什么形式？', '[{"key":"A","text":"小写"},{"key":"B","text":"大写"},{"key":"C","text":"都可以"}]', 'B', '英文句子首字母必须大写。专有名词（人名地名）首字母也要大写。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_writing'), 'SCENE_TAP', 4, '英文中的人名"I"（我）永远用什么形式？', '[{"key":"A","text":"小写i"},{"key":"B","text":"大写I"},{"key":"C","text":"取决于位置"}]', 'B', 'I（我）在任何位置都大写，这是英语书写的特殊规则。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_writing'), 'FILL_BLANK', 4, '英文句子的末尾通常用______号。', NULL, '句', '英语陈述句句末用句号(period/full stop .)，疑问句用问号(?)。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_writing'), 'SCENE_TAP', 4, '下面哪个句子书写正确？', '[{"key":"A","text":"my name is tom"},{"key":"B","text":"My name is Tom"},{"key":"C","text":"My Name Is Tom"}]', 'B', '句子首字母和人名首字母大写，其余单词不大写。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_writing'), 'SCENE_TAP', 4, '英文中，星期几的首字母要？', '[{"key":"A","text":"小写"},{"key":"B","text":"大写"},{"key":"C","text":"没有规定"}]', 'B', '星期（Monday, Sunday等）和月份（January等）首字母要大写。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_writing'), 'SCENE_TAP', 4, '"China"中C大写的原因是什么？', '[{"key":"A","text":"它是句子的开头"},{"key":"B","text":"它是国家名字（专有名词）"},{"key":"C","text":"没有特别原因"}]', 'B', '国家、城市、人名等专有名词的首字母需要大写。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_writing'), 'MULTIPLE_CHOICE', 4, '当你写"My name is lily."时有什么错误？', '[{"key":"A","text":"My不应该大写"},{"key":"B","text":"lily应该大写为Lily"},{"key":"C","text":"is不应该小写"}]', 'B', '人名Lily是专有名词，首字母必须大写。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_writing'), 'SCENE_TAP', 4, '英语单词之间留多大的空格？', '[{"key":"A","text":"不留空格"},{"key":"B","text":"留一个字母的宽度"},{"key":"C","text":"随意"}]', 'B', '英语单词之间要留大约一个字母"o"宽度的空格，确保清晰可读。', 10);

-- ============================================================
-- Sprint B: Story Chapters 13-24 (Grades 2-3 Expansion)
-- ============================================================
INSERT IGNORE INTO story_chapter (chapter_number, title, narrative, npc_name, npc_dialogue, choice_text, requirement_type, requirement_value, reward_energy, display_order) VALUES

-- ── Grade 2 arc: Deeper into the worlds ──

(13, '笔画的力量',
 '诗词大陆的深处，古老的文碑上刻满了奇妙的汉字笔画。每一笔都蕴含着文韵之力，等待着被唤醒……',
 '李白',
 '「横竖撇捺折，五笔定乾坤。」小友，你已经掌握了基础，现在是时候学习汉字的筋骨了。每一个字都是由笔画组成的，掌握了笔画和笔顺，你就能写出端正有力的汉字！去练习笔画吧！',
 '让我来掌握汉字的筋骨！',
 'COMPLETE_STUDY', 1, 40, 13),

(14, '乘法的魔法',
 '智慧王国的中心广场上，一座巨大的乘法表石碑在发光。智慧老人站在碑前，眼中闪烁着期待的光芒……',
 '智慧老人',
 '乘法是数学的魔法！当你掌握了乘法口诀，计算就会变得像变魔术一样快。同样的数多次相加，不如用乘法一步到位。准备好了吗？让我们一起探索乘法的奥秘！',
 '我要学会乘法的魔法！',
 'COMPLETE_STUDY', 1, 40, 14),

(15, '魔法拼读',
 '魔法学院的图书馆里，一本古老的拼读书在发光。翻开书页，字母们跳动着，发出奇妙的声音……',
 '梅林导师',
 'Welcome back！英语的魔力藏在字母的发音里。当你掌握了自然拼读，看到单词就能读出来，听到发音就能写出单词。这是通往流利英语的第一把钥匙！',
 '我要掌握拼读的魔法！',
 'COMPLETE_STUDY', 1, 40, 15),

(16, '部首的秘密',
 '诗词大陆的密林深处，有一棵巨大的"汉字树"。树上挂满了偏旁部首，每一个都代表着一类事物的密码……',
 '李清照',
 '「三点水旁的字都与水有关，草字头的字都与植物有关。」偏旁部首是汉字的密码本。掌握了它，你就能猜出不认识的字的意思，甚至读音！让我们一起去发现部首的秘密吧！',
 '我要破解汉字的密码！',
 'ACCURACY', 85, 45, 16),

(17, '除法的智慧',
 '智慧王国的分配广场上，一群数字正在排队等着被公平分配。毕达哥拉斯拿着他的数学权杖……',
 '毕达哥拉斯',
 '除法是公平的艺术！把东西平均分给每个人，这就是除法的意义。它和乘法是好朋友——你知道6÷3=2，因为3×2=6。用你的准确率来证明你掌握了这公平的艺术吧！',
 '我要学会公平分配！',
 'ACCURACY', 85, 45, 17),

(18, '对话的桥梁',
 '魔法学院的交流大厅里，来自不同世界的学生们正在用英语对话。空气中充满了欢笑和语言的魔力……',
 '梅林导师',
 'Language is a bridge！语言是沟通的桥梁。学会了日常对话，你就能和来自世界各地的人交朋友。去练习情景对话吧，把英语变成你真正的交流工具！',
 '我要用英语和世界对话！',
 'ACCURACY', 85, 45, 18),

-- ── Grade 3 arc: Mastering the worlds ──

(19, '成语的智慧',
 '诗词大陆的智者殿堂中，一本金光闪闪的成语宝典从虚空中浮现。每一页都藏着一个古老的寓言故事……',
 '李白',
 '「守株待兔、拔苗助长、亡羊补牢……」成语是中华文化的智慧结晶。短短四个字，背后往往藏着一个深刻的道理。学习成语，就是学习古人几千年的智慧！',
 '我要探寻成语的智慧！',
 'COMPLETE_STUDY', 1, 50, 19),

(20, '万数长征',
 '智慧王国的大数之塔高耸入云，每一层都有一个四位数的谜题。攀登到塔顶，就能看到整个数学世界的全貌……',
 '智慧老人',
 '从一百到一千，从一千到一万！数的世界比你想象的更广阔。万以内的加减法，是通往更高级数学的阶梯。一步一个脚印，征服这些大数吧！',
 '我要征服万数长征！',
 'COMPLETE_STUDY', 1, 50, 20),

(21, '句型的力量',
 '魔法学院的高塔之顶，一本句型大全在风中翻页。每一页都记载着一种强大的表达方式……',
 '梅林导师',
 '掌握句型，你就掌握了英语表达的框架。陈述句、疑问句、祈使句、感叹句——不同的句型表达不同的意思。学会了它们，你就能说出完整的、正确的英文句子！',
 '我要掌握句型的力量！',
 'COMPLETE_STUDY', 1, 50, 21),

(22, '修辞的艺术',
 '诗词大陆的花园里，花儿们在微笑，柳树在舞蹈，整个花园仿佛活了过来。这，就是修辞的魔力……',
 '李清照',
 '「比喻让文字有了画面，拟人让万物有了生命。」修辞手法是让作文变得生动有趣的法宝。你想让你的作文像花园一样精彩吗？那就要学会运用修辞！',
 '我要让文字变得生动有趣！',
 'ENERGY_TOTAL', 500, 55, 22),

(23, '分数与小数',
 '智慧王国的分数之桥和十进制喷泉交相辉映。一半、四分之一、零点五……新的数学概念在眼前展开……',
 '毕达哥拉斯',
 '整数之外还有更精细的世界！半个蛋糕用分数表示是1/2，用小数表示是0.5。分数和小数是一对好朋友，它们让数学变得更加精确和丰富。',
 '我要探索分数和小数的世界！',
 'STREAK', 7, 60, 23),

(24, '阅读大冒险',
 '三个世界的交界处，一座宏伟的图书馆拔地而起。馆中藏有中英文的经典文章，每一篇都是一次新的冒险……',
 '向导精灵',
 '恭喜你，守护者！你已经成长为一名经验丰富的学习者了。现在，真正的阅读大冒险开始了。中文的段落理解、英文的短文阅读——用你的阅读理解能力去征服这座图书馆吧！知识将为你打开更广阔的世界！',
 '让我开启阅读的大冒险！',
 'ACHIEVEMENT_COUNT', 5, 80, 24);

-- ========================
-- Daily Reward Definitions (Sprint F)
-- ========================
INSERT IGNORE INTO daily_reward_def (reward_key, name, description, reward_type, reward_value, reward_item_key, unlock_day, icon_url, display_order) VALUES
('daily_energy_30', '30能量', '获得30点学习能量', 'ENERGY', 30, NULL, 1, '⚡', 1),
('daily_item_food', '随机食物', '获得一个随机食物', 'ITEM', NULL, 'RANDOM_FOOD', 1, '🍬', 2),
('daily_energy_10', '10能量', '获得10点学习能量', 'ENERGY', 10, NULL, 1, '⚡', 3),
('streak3_energy', '3天奖励·100能量', '连续3天登录奖励', 'ENERGY', 100, NULL, 3, '🔥', 10),
('streak7_scarf', '7天奖励·毅力围巾', '连续7天登录获得毅力围巾', 'ACCESSORY', NULL, 'acc_perseverance_scarf', 7, '🏅', 11),
('streak14_energy', '14天奖励·300能量', '连续14天登录奖励', 'ENERGY', 300, NULL, 14, '💎', 12),
('streak30_energy', '30天奖励·500能量', '连续30天登录奖励', 'ENERGY', 500, NULL, 30, '👑', 13);

-- ========================
-- Random Event Definitions (Sprint F)
-- ========================
INSERT IGNORE INTO random_event_def (event_key, name, description, event_type, trigger_chance, min_accuracy, min_streak, reward_energy, reward_item_key, reward_affection, display_text, icon_url) VALUES
('spirit_birthday', '精灵生日派对', '今天精灵特别开心，额外获得能量奖励！', 'BONUS_ENERGY', 0.08, 0.0, 0, 50, NULL, 5, '精灵突然拿出一个小蛋糕！"主人，今天是我的生日哦~"', '🎂'),
('spirit_gratitude', '精灵感谢日', '精灵感谢你最近的努力学习，送上一份小礼物', 'SPIRIT_GIFT', 0.10, 0.6, 3, 0, 'energy_candy', 10, '精灵害羞地递给你一个小盒子..."谢谢你每天陪我学习！"', '🎁'),
('double_reward', '能量加倍！', '守护者对你的表现印象深刻，决定加倍奖励', 'DOUBLE_REWARD', 0.05, 0.8, 0, 0, NULL, 0, '守护者拍了拍手："表现太棒了！今天的奖励翻倍！"', '✨'),
('streak_bonus', '坚持的回报', '连续学习的额外嘉奖，精灵更加信任你', 'STREAK_BONUS', 0.15, 0.0, 7, 30, NULL, 5, '"坚持这么久，你真的很厉害！"精灵自豪地看着你', '🔥'),
('free_gacha', '免费扭蛋券', '恭喜获得一次免费扭蛋机会！', 'FREE_ITEM', 0.03, 0.7, 3, 0, NULL, 3, '从天而降一张扭蛋券！"快去试试手气吧！"', '🎰'),
('affection_boost', '好感爆发', '精灵对你的好感大幅提升', 'SPIRIT_GIFT', 0.12, 0.5, 0, 0, NULL, 15, '精灵突然跳到你身上蹭了蹭..."最喜欢主人了！"', '💕');

-- ========================
-- Decoration Items for Pet Room (Sprint F)
-- ========================
INSERT IGNORE INTO item_def (item_key, name, description, category, effect_type, effect_value, price, icon_url, is_consumable, is_purchasable, display_order) VALUES
('deco_bed_small', '小床', '一张舒适的小床，精灵可以在这里休息', 'DECORATION', 'COSMETIC', 0, 100, '🛏️', FALSE, TRUE, 60),
('deco_sofa', '小沙发', '软软的沙发，精灵最喜欢窝在这里', 'DECORATION', 'COSMETIC', 0, 120, '🛋️', FALSE, TRUE, 61),
('deco_lamp', '小夜灯', '温馨的小夜灯，让小屋不再黑暗', 'DECORATION', 'COSMETIC', 0, 60, '💡', FALSE, TRUE, 62),
('deco_bookshelf', '小书架', '装满故事书的小书架', 'DECORATION', 'COSMETIC', 0, 150, '📚', FALSE, TRUE, 63),
('deco_rug_round', '圆形地毯', '软绵绵的圆形地毯', 'DECORATION', 'COSMETIC', 0, 80, '🟤', FALSE, TRUE, 64),
('deco_plant', '盆栽', '一盆绿色的小植物，净化空气', 'DECORATION', 'COSMETIC', 0, 50, '🪴', FALSE, TRUE, 65),
('deco_window', '小窗户', '一扇能看到星星的小窗户', 'DECORATION', 'COSMETIC', 0, 90, '🪟', FALSE, TRUE, 66),
('deco_poster', '学习海报', '墙上贴着"好好学习，天天向上"的海报', 'DECORATION', 'COSMETIC', 0, 40, '📜', FALSE, TRUE, 67),
('deco_toy_ball', '玩具球', '一颗彩色的玩具球', 'DECORATION', 'COSMETIC', 0, 30, '⚽', FALSE, TRUE, 68),
('deco_star_mobile', '星星挂饰', '挂在屋顶的星星挂饰，会轻轻摇晃', 'DECORATION', 'COSMETIC', 0, 70, '⭐', FALSE, TRUE, 69),
('deco_table', '小桌子', '一张小桌子，可以放东西', 'DECORATION', 'COSMETIC', 0, 100, '🪑', FALSE, TRUE, 70),
('deco_clock', '挂钟', '可爱的猫咪挂钟', 'DECORATION', 'COSMETIC', 0, 60, '🕐', FALSE, TRUE, 71);

-- Sprint F Layer 1: Room theme definitions
INSERT IGNORE INTO room_theme_def (theme_key, name, description, icon_url, is_default, sort_order) VALUES
('cozy_warm', '温馨暖居', '温暖舒适的默认小屋，每个小精灵最初的港湾', '🏠', TRUE, 1),
('starry_night', '星空夜语', '深蓝夜空下繁星点点，伴你进入梦乡', '🌌', FALSE, 2),
('forest_green', '翠林幽居', '绿意盎然的森林小屋，萤火虫在夜空中舞动', '🌿', FALSE, 3),
('ancient_study', '古风书房', '笔墨纸砚，书香四溢的古雅书房', '📜', FALSE, 4),
('crystal_hall', '水晶殿堂', '晶莹剔透的梦幻宫殿，闪耀着魔法光芒', '💎', FALSE, 5),
('ocean_deep', '深海小屋', '蔚蓝深海中的静谧小屋，与鱼群为伴', '🌊', FALSE, 6);

-- Sprint F Layer 1: Room theme items (purchasable in shop / gacha)
INSERT IGNORE INTO item_def (item_key, name, description, category, sub_category, price_energy, price_points, icon_url, is_consumable, is_shop_available, sort_order) VALUES
('theme_starry_night', '星空小屋主题', '解锁星空夜语房间主题（可随时切换）', 'ROOM_THEME', NULL, 200, 0, '🌌', FALSE, TRUE, 90),
('theme_forest_green', '森林小屋主题', '解锁翠林幽居房间主题（可随时切换）', 'ROOM_THEME', NULL, 200, 0, '🌿', FALSE, TRUE, 91),
('theme_crystal_hall', '水晶殿堂主题', '解锁水晶殿堂房间主题（可随时切换）', 'ROOM_THEME', NULL, 500, 0, '💎', FALSE, TRUE, 92),
('theme_ancient_study', '古风书房主题', '解锁古风书房房间主题（成就奖励）', 'ROOM_THEME', NULL, 0, 0, '📜', FALSE, FALSE, 93),
('theme_ocean_deep', '深海小屋主题', '解锁深海小屋房间主题（扭蛋限定）', 'ROOM_THEME', NULL, 0, 0, '🌊', FALSE, FALSE, 94);

-- Seed admin user (password: admin123)
INSERT IGNORE INTO users (username, email, password_hash, nickname, role, total_energy, current_energy)
VALUES ('admin', 'admin@petgrowup.com', '$2a$10$uKwLfEt7E6iyoy1NxTAKWuoGlmLpQsm/pbwaM1L1XcAQ9Kp7xNa5a', '系统管理员', 'ADMIN', 0, 0);
