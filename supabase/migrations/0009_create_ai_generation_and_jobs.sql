-- 9. AI GENERATION & ACADEMIC SAFEGUARDS (Section 10.2, 13)
-- ----------------------------------------------------------------------------

-- 9.1 AI Generation Jobs (Asynchronous Worker Pipeline)
CREATE TABLE IF NOT EXISTS public.ai_generation_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES public.institutions(id) ON DELETE CASCADE,
    requested_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    exam_version_id UUID REFERENCES public.exam_versions(id) ON DELETE SET NULL,
    syllabus_node_id UUID REFERENCES public.syllabus_nodes(id) ON DELETE SET NULL,
    provider TEXT NOT NULL DEFAULT 'GROQ', -- 'GROQ', 'OPENAI', etc.
    model_id TEXT NOT NULL,
    prompt_template_version TEXT NOT NULL DEFAULT 'v1',
    status ai_job_status NOT NULL DEFAULT 'QUEUED',
    input_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    error_code TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    completed_at TIMESTAMPTZ NULL
);

-- 9.2 AI Generation Reviews (Mandatory Human-in-the-Loop Review Queue)
CREATE TABLE IF NOT EXISTS public.ai_generation_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    generation_job_id UUID NOT NULL REFERENCES public.ai_generation_jobs(id) ON DELETE CASCADE,
    draft_payload JSONB NOT NULL,
    validation_status ai_validation_status NOT NULL DEFAULT 'PENDING',
    review_status ai_review_status NOT NULL DEFAULT 'PENDING',
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ NULL,
    published_question_version_id UUID REFERENCES public.question_versions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 9.3 AI Reference Sources (Grounding Excerpts & Attribution)
CREATE TABLE IF NOT EXISTS public.ai_reference_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    generation_job_id UUID NOT NULL REFERENCES public.ai_generation_jobs(id) ON DELETE CASCADE,
    resource_id UUID REFERENCES public.resources(id) ON DELETE SET NULL,
    source_locator TEXT NULL,
    excerpt_hash TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- ----------------------------------------------------------------------------
