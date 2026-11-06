-- 7. QUESTION BANK, IMMUTABLE REVISIONS & ADJUDICATIONS (Section 10.2, 10.4)
-- ----------------------------------------------------------------------------

-- 7.1 Question Bank Items (Logical Identity)
CREATE TABLE IF NOT EXISTS public.questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_scope content_scope NOT NULL DEFAULT 'INSTITUTION',
    institution_id UUID REFERENCES public.institutions(id) ON DELETE CASCADE,
    current_version_id UUID NULL,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    archived_at TIMESTAMPTZ NULL,
    CONSTRAINT check_question_ownership CHECK (
        (content_scope = 'PLATFORM' AND institution_id IS NULL) OR
        (content_scope = 'INSTITUTION' AND institution_id IS NOT NULL)
    )
);

-- 7.2 Question Versions (Immutable Version Snapshots)
CREATE TABLE IF NOT EXISTS public.question_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL DEFAULT 1,
    exam_version_id UUID REFERENCES public.exam_versions(id) ON DELETE SET NULL,
    section_id UUID REFERENCES public.exam_sections(id) ON DELETE SET NULL,
    question_type question_type NOT NULL DEFAULT 'SINGLE_SELECT_MCQ',
    question_text TEXT NOT NULL,
    language_code TEXT NOT NULL DEFAULT 'en',
    difficulty difficulty_level NOT NULL DEFAULT 'MEDIUM',
    explanation TEXT NULL,
    diagram_storage_path TEXT NULL,
    diagram_alt_text TEXT NULL,
    source_reference TEXT NULL,
    review_status review_status NOT NULL DEFAULT 'DRAFT',
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_question_version_num UNIQUE (question_id, version_number)
);

-- Connect current_version_id foreign key
ALTER TABLE public.questions
    ADD CONSTRAINT fk_question_current_version
    FOREIGN KEY (current_version_id) REFERENCES public.question_versions(id) ON DELETE SET NULL;

-- 7.3 Question Options (Options 4 for NEET, 5 for IMAT)
CREATE TABLE IF NOT EXISTS public.question_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_version_id UUID NOT NULL REFERENCES public.question_versions(id) ON DELETE CASCADE,
    option_key TEXT NOT NULL, -- 'A', 'B', 'C', 'D', 'E'
    option_text TEXT NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 1,
    is_correct BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_version_option_key UNIQUE (question_version_id, option_key),
    CONSTRAINT unique_version_option_order UNIQUE (question_version_id, display_order)
);

-- 7.4 Question Answer Keys (Strict Confidentiality: Server-Side Scoring Only)
CREATE TABLE IF NOT EXISTS public.question_answer_keys (
    question_version_id UUID PRIMARY KEY REFERENCES public.question_versions(id) ON DELETE CASCADE,
    accepted_option_ids UUID[] NOT NULL,
    resolution_type adjudication_type NOT NULL DEFAULT 'STANDARD',
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 7.5 Question Assets (Clinical Stems, Formulas, Diagrams)
CREATE TABLE IF NOT EXISTS public.question_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_version_id UUID NOT NULL REFERENCES public.question_versions(id) ON DELETE CASCADE,
    asset_type TEXT NOT NULL, -- 'DIAGRAM', 'AUDIO', 'TABLE'
    storage_path TEXT NOT NULL,
    checksum_sha256 TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 7.6 Question Syllabus Mappings
CREATE TABLE IF NOT EXISTS public.question_syllabus_mappings (
    question_version_id UUID NOT NULL REFERENCES public.question_versions(id) ON DELETE CASCADE,
    syllabus_node_id UUID NOT NULL REFERENCES public.syllabus_nodes(id) ON DELETE CASCADE,
    PRIMARY KEY (question_version_id, syllabus_node_id)
);

-- 7.7 Question Reviews (Faculty Workflow)
CREATE TABLE IF NOT EXISTS public.question_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_version_id UUID NOT NULL REFERENCES public.question_versions(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    review_status review_status NOT NULL,
    comments TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 7.8 Question Sources
CREATE TABLE IF NOT EXISTS public.question_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    source_type TEXT NOT NULL, -- 'PAST_PAPER', 'ORIGINAL', 'INSTITUTE_MOCK'
    source_name TEXT NOT NULL,
    citation_url TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 7.9 Question Adjudications (Official Challenge & Answer-Key Corrections)
CREATE TABLE IF NOT EXISTS public.question_adjudications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_version_id UUID NOT NULL REFERENCES public.question_versions(id) ON DELETE CASCADE,
    exam_version_id UUID NOT NULL REFERENCES public.exam_versions(id) ON DELETE CASCADE,
    adjudication_type adjudication_type NOT NULL,
    valid_option_ids UUID[] NOT NULL DEFAULT '{}',
    scoring_effect_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    reason TEXT NOT NULL,
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- ----------------------------------------------------------------------------
