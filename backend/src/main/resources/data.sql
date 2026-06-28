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
