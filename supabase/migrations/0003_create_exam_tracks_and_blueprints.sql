-- 3. EXAM TRACKS, ANNUAL CYCLES & OFFICIAL SCORING POLICIES (Section 10.2, 10.4)
-- ----------------------------------------------------------------------------

-- 3.1 Exam Tracks (Strictly NEET_UG and IMAT only)
CREATE TABLE IF NOT EXISTS public.exam_tracks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code exam_track_code NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    authority_name TEXT NOT NULL,
    official_website TEXT NULL,
    status account_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 3.2 Exam Versions (Annual Official Examination Blueprints)
CREATE TABLE IF NOT EXISTS public.exam_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_track_id UUID NOT NULL REFERENCES public.exam_tracks(id) ON DELETE RESTRICT,
    exam_year INTEGER NOT NULL,
    academic_cycle TEXT NOT NULL, -- e.g. '2026' for NEET, '2026/2027' for IMAT
    version_number INTEGER NOT NULL DEFAULT 1,
    status exam_version_status NOT NULL DEFAULT 'DRAFT',
    official_source_url TEXT NULL,
    source_published_at DATE NULL,
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_exam_track_year_version UNIQUE (exam_track_id, exam_year, version_number)
);

-- 3.3 Exam Scoring Policies (Exact Decimal Arithmetic; No Floats)
CREATE TABLE IF NOT EXISTS public.exam_scoring_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_version_id UUID NOT NULL REFERENCES public.exam_versions(id) ON DELETE CASCADE,
    policy_code TEXT NOT NULL, -- e.g. 'NEET_STANDARD_2026', 'IMAT_STANDARD_2026_27'
    correct_marks NUMERIC(6,2) NOT NULL,    -- +4.00 for NEET; +1.50 for IMAT
    incorrect_marks NUMERIC(6,2) NOT NULL,  -- -1.00 for NEET; -0.40 for IMAT
    unanswered_marks NUMERIC(6,2) NOT NULL DEFAULT 0.00,
    maximum_raw_score NUMERIC(7,2) NOT NULL, -- 720 for NEET; 90 for IMAT
    policy_json JSONB NOT NULL DEFAULT '{"invalid_item_full_credit": true}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_version_policy_code UNIQUE (exam_version_id, policy_code)
);

-- 3.4 Exam Sections (Official Section / Subject Structure)
CREATE TABLE IF NOT EXISTS public.exam_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_version_id UUID NOT NULL REFERENCES public.exam_versions(id) ON DELETE CASCADE,
    scoring_policy_id UUID REFERENCES public.exam_scoring_policies(id) ON DELETE SET NULL,
    code TEXT NOT NULL, -- e.g. 'PHYSICS', 'CHEMISTRY', 'BIOLOGY' or 'IMAT_SEC_1'
    name TEXT NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 1,
    question_count INTEGER NOT NULL, -- e.g. NEET: 45, 45, 90; IMAT: 4, 5, 23, 15, 13
    duration_seconds INTEGER NULL,  -- Optional section-level timer
    option_count INTEGER NOT NULL DEFAULT 4, -- 4 for NEET; 5 for IMAT
    language_code TEXT NOT NULL DEFAULT 'en',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_version_section_code UNIQUE (exam_version_id, code)
);

-- 3.5 Exam Language Options
CREATE TABLE IF NOT EXISTS public.exam_language_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_version_id UUID NOT NULL REFERENCES public.exam_versions(id) ON DELETE CASCADE,
    language_code TEXT NOT NULL, -- 'en', 'hi', 'it', etc.
    language_name TEXT NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_version_language UNIQUE (exam_version_id, language_code)
);

-- 3.6 Exam Source Documents (Information Bulletins & Decrees)
CREATE TABLE IF NOT EXISTS public.exam_source_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_version_id UUID NOT NULL REFERENCES public.exam_versions(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    document_type TEXT NOT NULL, -- 'BULLETIN', 'DECREE', 'SYLLABUS_NOTIFICATION'
    storage_path TEXT NOT NULL,
    checksum_sha256 TEXT NULL,
    verified_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 3.7 Exam Configuration Reviews
CREATE TABLE IF NOT EXISTS public.exam_configuration_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_version_id UUID NOT NULL REFERENCES public.exam_versions(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    review_status TEXT NOT NULL, -- 'APPROVED', 'CHANGES_REQUESTED'
    notes TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- ----------------------------------------------------------------------------
