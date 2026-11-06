-- 5. CURRICULUM, SYLLABUS TAXONOMY & STUDY PLANS (Section 10.2, 10.4)
-- ----------------------------------------------------------------------------

-- 5.1 Syllabus Versions (Official annual syllabus tree snapshots)
CREATE TABLE IF NOT EXISTS public.syllabus_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_version_id UUID NOT NULL REFERENCES public.exam_versions(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL DEFAULT 1,
    status exam_version_status NOT NULL DEFAULT 'PUBLISHED',
    source_url TEXT NULL,
    published_at DATE NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_exam_version_syllabus UNIQUE (exam_version_id, version_number)
);

-- 5.2 Syllabus Nodes (Dual-track hierarchical tree: SUBJECT, SECTION, CHAPTER, TOPIC, SKILL)
CREATE TABLE IF NOT EXISTS public.syllabus_nodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    syllabus_version_id UUID NOT NULL REFERENCES public.syllabus_versions(id) ON DELETE CASCADE,
    parent_node_id UUID REFERENCES public.syllabus_nodes(id) ON DELETE CASCADE,
    node_type syllabus_node_type NOT NULL,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT NULL,
    display_order INTEGER NOT NULL DEFAULT 1,
    source_reference TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 5.3 Syllabus Node Relationships (Closure table for fast subtree queries)
CREATE TABLE IF NOT EXISTS public.syllabus_node_relationships (
    ancestor_id UUID NOT NULL REFERENCES public.syllabus_nodes(id) ON DELETE CASCADE,
    descendant_id UUID NOT NULL REFERENCES public.syllabus_nodes(id) ON DELETE CASCADE,
    depth INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ancestor_id, descendant_id)
);

-- 5.4 Student Topic Progress
CREATE TABLE IF NOT EXISTS public.student_topic_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    syllabus_node_id UUID NOT NULL REFERENCES public.syllabus_nodes(id) ON DELETE CASCADE,
    status progress_status NOT NULL DEFAULT 'NOT_STARTED',
    mastery_score NUMERIC(5,2) NULL, -- Percentage or calculated mastery
    completed_at TIMESTAMPTZ NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_profile_syllabus_progress UNIQUE (profile_id, syllabus_node_id)
);

-- 5.5 Study Plans
CREATE TABLE IF NOT EXISTS public.study_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    exam_track_id UUID NOT NULL REFERENCES public.exam_tracks(id) ON DELETE RESTRICT,
    exam_version_id UUID REFERENCES public.exam_versions(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    target_date DATE NULL,
    status account_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 5.6 Study Plan Items
CREATE TABLE IF NOT EXISTS public.study_plan_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    study_plan_id UUID NOT NULL REFERENCES public.study_plans(id) ON DELETE CASCADE,
    syllabus_node_id UUID NOT NULL REFERENCES public.syllabus_nodes(id) ON DELETE CASCADE,
    target_date DATE NULL,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    completed_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- ----------------------------------------------------------------------------
