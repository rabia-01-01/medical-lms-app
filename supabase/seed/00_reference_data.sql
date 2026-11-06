-- 15. INITIAL REFERENCE SEED DATA (Section 10.4)
-- ----------------------------------------------------------------------------

-- Seed Official Dual Tracks
INSERT INTO public.exam_tracks (code, display_name, authority_name, official_website, status)
VALUES 
    ('NEET_UG', 'NEET-UG', 'National Testing Agency (NTA)', 'https://neet.nta.nic.in', 'ACTIVE'),
    ('IMAT', 'IMAT', 'Ministero dell Universita e della Ricerca (MUR)', 'https://www.universitaly.it', 'ACTIVE')
ON CONFLICT (code) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    authority_name = EXCLUDED.authority_name,
    status = 'ACTIVE';

-- Seed NEET-UG 2026 Reference Version
WITH track_neet AS (SELECT id FROM public.exam_tracks WHERE code = 'NEET_UG' LIMIT 1)
INSERT INTO public.exam_versions (id, exam_track_id, exam_year, academic_cycle, version_number, status, official_source_url)
SELECT 
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid,
    id,
    2026,
    '2026',
    1,
    'VERIFIED',
    'https://neet.nta.nic.in'
FROM track_neet
ON CONFLICT (exam_track_id, exam_year, version_number) DO NOTHING;

-- Seed NEET-UG 2026 Scoring Policy (+4, -1, 0, 720 Max)
INSERT INTO public.exam_scoring_policies (id, exam_version_id, policy_code, correct_marks, incorrect_marks, unanswered_marks, maximum_raw_score, policy_json)
VALUES (
    'b2c3d4e5-f6a7-8901-bcde-f12345678901'::uuid,
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid,
    'NEET_STANDARD_2026',
    4.00,
    -1.00,
    0.00,
    720.00,
    '{"dropped_item_full_credit": true, "multiple_keys_supported": true}'::jsonb
)
ON CONFLICT (exam_version_id, policy_code) DO NOTHING;

-- Seed NEET-UG 2026 Sections (Physics 45, Chemistry 45, Biology 90)
INSERT INTO public.exam_sections (exam_version_id, scoring_policy_id, code, name, display_order, question_count, option_count)
VALUES 
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 'b2c3d4e5-f6a7-8901-bcde-f12345678901'::uuid, 'NEET_PHY', 'Physics', 1, 45, 4),
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 'b2c3d4e5-f6a7-8901-bcde-f12345678901'::uuid, 'NEET_CHEM', 'Chemistry', 2, 45, 4),
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 'b2c3d4e5-f6a7-8901-bcde-f12345678901'::uuid, 'NEET_BIO', 'Biology', 3, 90, 4)
ON CONFLICT (exam_version_id, code) DO NOTHING;

-- Seed IMAT 2026/27 Reference Version
WITH track_imat AS (SELECT id FROM public.exam_tracks WHERE code = 'IMAT' LIMIT 1)
INSERT INTO public.exam_versions (id, exam_track_id, exam_year, academic_cycle, version_number, status, official_source_url)
SELECT 
    'c3d4e5f6-a7b8-9012-cdef-123456789012'::uuid,
    id,
    2026,
    '2026/2027',
    1,
    'VERIFIED',
    'https://www.universitaly.it'
FROM track_imat
ON CONFLICT (exam_track_id, exam_year, version_number) DO NOTHING;

-- Seed IMAT 2026/27 Scoring Policy (+1.5, -0.4, 0, 90 Max)
INSERT INTO public.exam_scoring_policies (id, exam_version_id, policy_code, correct_marks, incorrect_marks, unanswered_marks, maximum_raw_score, policy_json)
VALUES (
    'd4e5f6a7-b8c9-0123-defa-234567890123'::uuid,
    'c3d4e5f6-a7b8-9012-cdef-123456789012'::uuid,
    'IMAT_STANDARD_2026_27',
    1.50,
    -0.40,
    0.00,
    90.00,
    '{"options_count": 5}'::jsonb
)
ON CONFLICT (exam_version_id, policy_code) DO NOTHING;

-- Seed IMAT 2026/27 Sections (4, 5, 23, 15, 13 questions; 5 options)
INSERT INTO public.exam_sections (exam_version_id, scoring_policy_id, code, name, display_order, question_count, option_count)
VALUES 
    ('c3d4e5f6-a7b8-9012-cdef-123456789012'::uuid, 'd4e5f6a7-b8c9-0123-defa-234567890123'::uuid, 'IMAT_READING', 'Reading Skills and General Knowledge', 1, 4, 5),
    ('c3d4e5f6-a7b8-9012-cdef-123456789012'::uuid, 'd4e5f6a7-b8c9-0123-defa-234567890123'::uuid, 'IMAT_LOGIC', 'Logical Reasoning and Problem Solving', 2, 5, 5),
    ('c3d4e5f6-a7b8-9012-cdef-123456789012'::uuid, 'd4e5f6a7-b8c9-0123-defa-234567890123'::uuid, 'IMAT_BIO', 'Biology', 3, 23, 5),
    ('c3d4e5f6-a7b8-9012-cdef-123456789012'::uuid, 'd4e5f6a7-b8c9-0123-defa-234567890123'::uuid, 'IMAT_CHEM', 'Chemistry', 4, 15, 5),
    ('c3d4e5f6-a7b8-9012-cdef-123456789012'::uuid, 'd4e5f6a7-b8c9-0123-defa-234567890123'::uuid, 'IMAT_MATH_PHYS', 'Physics and Mathematics', 5, 13, 5)
ON CONFLICT (exam_version_id, code) DO NOTHING;
