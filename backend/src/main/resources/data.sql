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
('chinese', 'chinese_intro', '诗词入门', '了解古诗词的基本格律和韵律', 1, NULL, 1),
('chinese', 'chinese_tang', '唐诗鉴赏', '欣赏唐代著名诗人的代表作品', 2, NULL, 2),
('chinese', 'chinese_song', '宋词赏析', '品味宋代词人的婉约与豪放', 3, NULL, 3);

-- Knowledge Nodes: Math (智慧王国) — 一年级数学（人教2024版）
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, parent_node_id, order_index) VALUES
('math', 'math_intro', '凑十法与10以内', '掌握凑十法、10以内加减法', 1, NULL, 1),
('math', 'math_addsub20', '20以内加减', '掌握20以内进位加法和退位减法', 2, NULL, 2),
('math', 'math_geometry', '认识图形', '认识圆形、正方形、三角形等基本图形', 3, NULL, 3);

-- Knowledge Nodes: English (魔法学院)
INSERT IGNORE INTO knowledge_node (subject, node_key, name, description, difficulty, parent_node_id, order_index) VALUES
('english', 'english_intro', '字母与发音', '掌握26个字母和基础发音', 1, NULL, 1),
('english', 'english_vocab', '词汇积累', '学习日常生活中的常用词汇', 2, NULL, 2),
('english', 'english_grammar', '语法基础', '了解基本语法规则和句型结构', 3, NULL, 3);

-- Quiz Questions: Chinese
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'MULTIPLE_CHOICE', 1, '"床前明月光"的下一句是什么？', '[{"key":"A","text":"疑是地上霜"},{"key":"B","text":"举头望明月"},{"key":"C","text":"低头思故乡"},{"key":"D","text":"处处闻啼鸟"}]', 'A', '出自李白的《静夜思》，全诗为：床前明月光，疑是地上霜。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'MULTIPLE_CHOICE', 1, '下列哪位诗人被称为"诗仙"？', '[{"key":"A","text":"杜甫"},{"key":"B","text":"白居易"},{"key":"C","text":"李白"},{"key":"D","text":"王维"}]', 'C', '李白被称为"诗仙"，杜甫被称为"诗圣"。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'FILL_BLANK', 1, '"春眠不觉晓，处处闻啼鸟"出自哪首诗？', NULL, '春晓', '出自孟浩然的《春晓》。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_tang'), 'MULTIPLE_CHOICE', 2, '王之涣《登鹳雀楼》中"欲穷千里目"的下一句是？', '[{"key":"A","text":"黄河入海流"},{"key":"B","text":"更上一层楼"},{"key":"C","text":"春风不度玉门关"},{"key":"D","text":"一片孤城万仞山"}]', 'B', '全诗：白日依山尽，黄河入海流。欲穷千里目，更上一层楼。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_tang'), 'MULTIPLE_CHOICE', 2, '"独在异乡为异客，每逢佳节倍思亲"是王维在哪个节日所作？', '[{"key":"A","text":"春节"},{"key":"B","text":"重阳节"},{"key":"C","text":"中秋节"},{"key":"D","text":"端午节"}]', 'B', '出自王维《九月九日忆山东兄弟》，九月九日即重阳节。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_tang'), 'TRUE_FALSE', 2, '"大漠孤烟直，长河落日圆"是王维的诗句。', NULL, 'true', '正确，出自王维的《使至塞上》。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_song'), 'MULTIPLE_CHOICE', 3, '苏轼《水调歌头》中"但愿人长久"的下一句是？', '[{"key":"A","text":"千里共婵娟"},{"key":"B","text":"低头思故乡"},{"key":"C","text":"此事古难全"},{"key":"D","text":"月有阴晴圆缺"}]', 'A', '出自苏轼《水调歌头·明月几时有》。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_song'), 'MULTIPLE_CHOICE', 3, '李清照是什么词派的代表人物？', '[{"key":"A","text":"豪放派"},{"key":"B","text":"婉约派"},{"key":"C","text":"花间派"},{"key":"D","text":"边塞派"}]', 'B', '李清照是宋代婉约词派的代表词人。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_song'), 'FILL_BLANK', 3, '"众里寻他千百度，蓦然回首，那人却在，______。"', NULL, '灯火阑珊处', '出自辛弃疾的《青玉案·元夕》。', 10);

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

-- Quiz Questions: English
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'MULTIPLE_CHOICE', 1, '英语字母表中有多少个字母？', '[{"key":"A","text":"24"},{"key":"B","text":"26"},{"key":"C","text":"28"},{"key":"D","text":"25"}]', 'B', '英语字母表共有26个字母。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'MULTIPLE_CHOICE', 1, '"apple"的中文意思是？', '[{"key":"A","text":"香蕉"},{"key":"B","text":"橘子"},{"key":"C","text":"苹果"},{"key":"D","text":"葡萄"}]', 'C', 'apple 意为苹果。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_intro'), 'FILL_BLANK', 1, '英语中"猫"的单词是？', NULL, 'cat', '猫的英文是 cat。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'MULTIPLE_CHOICE', 2, '"beautiful"的反义词是？', '[{"key":"A","text":"handsome"},{"key":"B","text":"ugly"},{"key":"C","text":"pretty"},{"key":"D","text":"lovely"}]', 'B', 'beautiful 意为美丽的，反义词是 ugly（丑陋的）。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'MULTIPLE_CHOICE', 2, '下列哪个是"星期二"的正确缩写？', '[{"key":"A","text":"Mon"},{"key":"B","text":"Tue"},{"key":"C","text":"Wed"},{"key":"D","text":"Thu"}]', 'B', '星期二 Tuesday 的缩写是 Tue。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'TRUE_FALSE', 2, '"Library"的意思是"书店"。', NULL, 'false', 'Library 意为图书馆，书店是 bookstore。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_grammar'), 'MULTIPLE_CHOICE', 3, 'I ___ a student.', '[{"key":"A","text":"is"},{"key":"B","text":"am"},{"key":"C","text":"are"},{"key":"D","text":"be"}]', 'B', '第一人称单数 I 使用 am。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_grammar'), 'MULTIPLE_CHOICE', 3, '下列哪个是过去式？', '[{"key":"A","text":"go"},{"key":"B","text":"going"},{"key":"C","text":"went"},{"key":"D","text":"goes"}]', 'C', 'go 的过去式是 went。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'english_grammar'), 'FILL_BLANK', 3, '"She ___ (read) books every day." 用正确的形式填空。', NULL, 'reads', '第三人称单数一般现在时，动词加 s。', 10);

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

-- ============================================================
-- Subject-Specific Question Types
-- ============================================================
-- Chinese: POEM_SEQUENCE
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'POEM_SEQUENCE', 1, '请将《春晓》的诗句按正确顺序排列', '["春眠不觉晓","处处闻啼鸟","夜来风雨声","花落知多少"]', '1,2,3,4', '这是孟浩然《春晓》的正确顺序。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'POEM_SEQUENCE', 1, '请将《静夜思》的诗句按正确顺序排列', '["举头望明月","床前明月光","低头思故乡","疑是地上霜"]', '2,4,1,3', '床前明月光，疑是地上霜。举头望明月，低头思故乡。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_intro'), 'POEM_SEQUENCE', 1, '请将《登鹳雀楼》的诗句按正确顺序排列', '["更上一层楼","白日依山尽","欲穷千里目","黄河入海流"]', '2,4,3,1', '白日依山尽，黄河入海流。欲穷千里目，更上一层楼。', 10);

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

-- Chinese: POEM_SEQUENCE for chinese_tang
INSERT IGNORE INTO quiz_question (knowledge_node_id, question_type, difficulty, question_text, options, correct_answer, explanation, points) VALUES
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_tang'), 'POEM_SEQUENCE', 2, '请将《悯农》的诗句按正确顺序排列', '["锄禾日当午","汗滴禾下土","谁知盘中餐","粒粒皆辛苦"]', '1,2,3,4', '这是李绅《悯农》的正确顺序。', 10),
((SELECT id FROM knowledge_node WHERE node_key = 'chinese_tang'), 'POEM_SEQUENCE', 2, '请将《望庐山瀑布》的诗句按正确顺序排列', '["疑是银河落九天","飞流直下三千尺","日照香炉生紫烟","遥看瀑布挂前川"]', '3,4,2,1', '日照香炉生紫烟，遥看瀑布挂前川。飞流直下三千尺，疑是银河落九天。', 10);

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
((SELECT id FROM knowledge_node WHERE node_key = 'english_vocab'), 'SCENE_TAP', 2, '哪个颜色是"green"？', '[{"key":"A","text":"绿色"},{"key":"B","text":"蓝色"},{"key":"C","text":"黄色"}]', 'A', 'green = 绿色', 10),
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
