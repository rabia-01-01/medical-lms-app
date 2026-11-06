-- 6. LEARNING RESOURCES & OBJECT STORAGE METADATA (Section 10.2, 10.4)
-- ----------------------------------------------------------------------------

-- 6.1 Learning Resources
CREATE TABLE IF NOT EXISTS public.resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_scope content_scope NOT NULL DEFAULT 'INSTITUTION',
    institution_id UUID REFERENCES public.institutions(id) ON DELETE CASCADE,
    exam_version_id UUID REFERENCES public.exam_versions(id) ON DELETE SET NULL,
    course_id UUID REFERENCES public.courses(id) ON DELETE SET NULL,
    syllabus_node_id UUID REFERENCES public.syllabus_nodes(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NULL,
    resource_type resource_type NOT NULL,
    reading_content TEXT NULL, -- Rich contextual outline
    language_code TEXT NOT NULL DEFAULT 'en',
    license_status TEXT NULL,
    status publication_status NOT NULL DEFAULT 'DRAFT',
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    published_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT check_institution_ownership CHECK (
        (content_scope = 'PLATFORM' AND institution_id IS NULL) OR
        (content_scope = 'INSTITUTION' AND institution_id IS NOT NULL)
    )
);

-- 6.2 Resource Files (Cloud Storage Object Metadata)
CREATE TABLE IF NOT EXISTS public.resource_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES public.resources(id) ON DELETE CASCADE,
    bucket_id TEXT NOT NULL DEFAULT 'resources',
    storage_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    checksum_sha256 TEXT NULL,
    scan_status file_scan_status NOT NULL DEFAULT 'CLEAN',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 6.3 Resource Batch Eligibility (Cohort Gating)
CREATE TABLE IF NOT EXISTS public.resource_eligibility (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES public.resources(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES public.batches(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_resource_batch UNIQUE (resource_id, batch_id)
);

-- 6.4 Resource Revisions
CREATE TABLE IF NOT EXISTS public.resource_revisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES public.resources(id) ON DELETE CASCADE,
    revision_number INTEGER NOT NULL DEFAULT 1,
    reading_content TEXT NULL,
    storage_path TEXT NULL,
    change_summary TEXT NULL,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_resource_revision UNIQUE (resource_id, revision_number)
);

-- ----------------------------------------------------------------------------
