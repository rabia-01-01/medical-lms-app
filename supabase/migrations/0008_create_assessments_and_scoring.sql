-- 8. ASSESSMENTS, ATTEMPTS & AUTHORITATIVE SCORING (Section 10.2, 10.4)
-- ----------------------------------------------------------------------------

-- 8.1 Assessment Definitions
CREATE TABLE IF NOT EXISTS public.assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_scope content_scope NOT NULL DEFAULT 'INSTITUTION',
    institution_id UUID REFERENCES public.institutions(id) ON DELETE CASCADE,
    exam_version_id UUID REFERENCES public.exam_versions(id) ON DELETE RESTRICT,
    title TEXT NOT NULL,
    description TEXT NULL,
    assessment_type assessment_type NOT NULL,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    status account_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 8.2 Assessment Versions (Immutable Published Testing Specifications)
CREATE TABLE IF NOT EXISTS public.assessment_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES public.assessments(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL DEFAULT 1,
    scoring_policy_id UUID REFERENCES public.exam_scoring_policies(id) ON DELETE RESTRICT,
    duration_seconds INTEGER NOT NULL, -- e.g. 10800s (180 mins) for NEET; 6000s (100 mins) for IMAT
    available_from TIMESTAMPTZ NULL,
    available_until TIMESTAMPTZ NULL,
    attempt_limit INTEGER NOT NULL DEFAULT 1,
    navigation_policy JSONB NOT NULL DEFAULT '{"allow_backtracking": true, "show_palette": true}'::jsonb,
    result_release_policy JSONB NOT NULL DEFAULT '{"release_mode": "IMMEDIATE"}'::jsonb,
    explanation_release_policy JSONB NOT NULL DEFAULT '{"release_mode": "UPON_RESULT"}'::jsonb,
    status assessment_version_status NOT NULL DEFAULT 'DRAFT',
    published_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    published_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_assessment_version_num UNIQUE (assessment_id, version_number)
);

-- 8.3 Assessment Sections
CREATE TABLE IF NOT EXISTS public.assessment_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_version_id UUID NOT NULL REFERENCES public.assessment_versions(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 1,
    duration_seconds INTEGER NULL,
    question_count INTEGER NOT NULL,
    max_marks NUMERIC(6,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 8.4 Assessment Questions (Frozen Revision Mapping)
CREATE TABLE IF NOT EXISTS public.assessment_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_version_id UUID NOT NULL REFERENCES public.assessment_versions(id) ON DELETE CASCADE,
    section_id UUID REFERENCES public.assessment_sections(id) ON DELETE SET NULL,
    question_version_id UUID NOT NULL REFERENCES public.question_versions(id) ON DELETE RESTRICT,
    question_order INTEGER NOT NULL DEFAULT 1,
    marks_override NUMERIC(5,2) NULL,
    negative_marks_override NUMERIC(5,2) NULL,
    CONSTRAINT unique_version_question_order UNIQUE (assessment_version_id, question_order),
    CONSTRAINT unique_version_question_item UNIQUE (assessment_version_id, question_version_id)
);

-- 8.5 Assessment Eligibility (Batch-Level Testing Gating)
CREATE TABLE IF NOT EXISTS public.assessment_eligibility (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_version_id UUID NOT NULL REFERENCES public.assessment_versions(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES public.batches(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_assessment_batch UNIQUE (assessment_version_id, batch_id)
);

-- 8.6 Assessment Attempts (Learner Testing Sessions)
CREATE TABLE IF NOT EXISTS public.assessment_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_version_id UUID NOT NULL REFERENCES public.assessment_versions(id) ON DELETE RESTRICT,
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    institution_id UUID REFERENCES public.institutions(id) ON DELETE SET NULL,
    batch_id UUID REFERENCES public.batches(id) ON DELETE SET NULL,
    attempt_number INTEGER NOT NULL DEFAULT 1,
    status attempt_status NOT NULL DEFAULT 'IN_PROGRESS',
    started_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    deadline_at TIMESTAMPTZ NOT NULL,
    submitted_at TIMESTAMPTZ NULL,
    finalized_at TIMESTAMPTZ NULL,
    idempotency_key TEXT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT check_attempt_deadline CHECK (deadline_at > started_at),
    CONSTRAINT unique_profile_assessment_attempt UNIQUE (assessment_version_id, profile_id, attempt_number)
);

-- Index single in-progress attempt per student
CREATE UNIQUE INDEX IF NOT EXISTS idx_single_in_progress_attempt
    ON public.assessment_attempts(profile_id, assessment_version_id)
    WHERE status = 'IN_PROGRESS';

-- 8.7 Attempt Answers (Server-Authoritative Evaluation & Autosave Sync)
CREATE TABLE IF NOT EXISTS public.attempt_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES public.assessment_attempts(id) ON DELETE CASCADE,
    assessment_question_id UUID NOT NULL REFERENCES public.assessment_questions(id) ON DELETE RESTRICT,
    question_version_id UUID NOT NULL REFERENCES public.question_versions(id) ON DELETE RESTRICT,
    selected_option_id UUID REFERENCES public.question_options(id) ON DELETE SET NULL,
    selected_response_json JSONB NULL,
    answer_status answer_status NOT NULL DEFAULT 'UNANSWERED',
    saved_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    evaluated_is_correct BOOLEAN NULL, -- Written ONLY by trusted backend scoring service
    marks_awarded NUMERIC(5,2) NULL,    -- Written ONLY by trusted backend scoring service
    CONSTRAINT unique_attempt_question_response UNIQUE (attempt_id, assessment_question_id)
);

-- 8.8 Attempt Events (Audit Trail for Autosave, Timeouts, Tab Visibility)
CREATE TABLE IF NOT EXISTS public.attempt_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES public.assessment_attempts(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL, -- 'STARTED', 'ANSWER_SAVED', 'AUTO_TIMEOUT', 'SUBMITTED'
    server_recorded_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    request_id TEXT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

-- 8.9 Score Results (Reproducible Scoring Breakdown)
CREATE TABLE IF NOT EXISTS public.score_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL UNIQUE REFERENCES public.assessment_attempts(id) ON DELETE CASCADE,
    scoring_policy_id UUID REFERENCES public.exam_scoring_policies(id) ON DELETE RESTRICT,
    raw_score NUMERIC(6,2) NOT NULL,
    maximum_raw_score NUMERIC(6,2) NOT NULL,
    percentage_of_maximum NUMERIC(5,2) NOT NULL,
    correct_count INTEGER NOT NULL,
    incorrect_count INTEGER NOT NULL,
    unanswered_count INTEGER NOT NULL,
    section_breakdown_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    finalized_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 8.10 Regrade Events (Tamper-evident record of post-exam regrades & adjudication adjustments)
CREATE TABLE IF NOT EXISTS public.regrade_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES public.assessment_attempts(id) ON DELETE CASCADE,
    score_result_id UUID NOT NULL REFERENCES public.score_results(id) ON DELETE CASCADE,
    old_score NUMERIC(6,2) NOT NULL,
    new_score NUMERIC(6,2) NOT NULL,
    reason TEXT NOT NULL,
    adjudication_id UUID REFERENCES public.question_adjudications(id) ON DELETE SET NULL,
    regraded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- ----------------------------------------------------------------------------
