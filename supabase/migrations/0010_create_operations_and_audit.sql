-- 10. OPERATIONS, NOTIFICATIONS, DISCUSSIONS & AUDIT (Section 10.2)
-- ----------------------------------------------------------------------------

-- 10.1 Announcements
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES public.institutions(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    audience_type content_scope NOT NULL DEFAULT 'INSTITUTION',
    priority TEXT NOT NULL DEFAULT 'NORMAL', -- 'LOW', 'NORMAL', 'HIGH', 'URGENT'
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    published_at TIMESTAMPTZ NULL,
    expires_at TIMESTAMPTZ NULL,
    status publication_status NOT NULL DEFAULT 'PUBLISHED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 10.2 Announcement Batches
CREATE TABLE IF NOT EXISTS public.announcement_batches (
    announcement_id UUID NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES public.batches(id) ON DELETE CASCADE,
    PRIMARY KEY (announcement_id, batch_id)
);

-- 10.3 Academic Calendar Events
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES public.institutions(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NULL,
    event_type TEXT NOT NULL, -- 'EXAM', 'LECTURE', 'DEADLINE', 'DOUBT_SESSION'
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    visibility content_scope NOT NULL DEFAULT 'INSTITUTION',
    status TEXT NOT NULL DEFAULT 'SCHEDULED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT check_calendar_dates CHECK (ends_at >= starts_at)
);

-- 10.4 Calendar Event Batches
CREATE TABLE IF NOT EXISTS public.calendar_event_batches (
    event_id UUID NOT NULL REFERENCES public.calendar_events(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES public.batches(id) ON DELETE CASCADE,
    PRIMARY KEY (event_id, batch_id)
);

-- 10.5 Notification Outbox
CREATE TABLE IF NOT EXISTS public.notification_outbox (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    institution_id UUID REFERENCES public.institutions(id) ON DELETE CASCADE,
    channel notification_channel NOT NULL DEFAULT 'IN_APP',
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'SENT', 'FAILED'
    scheduled_for TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    sent_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 10.6 Moderated Discussion Threads
CREATE TABLE IF NOT EXISTS public.discussion_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES public.institutions(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES public.batches(id) ON DELETE SET NULL,
    syllabus_node_id UUID REFERENCES public.syllabus_nodes(id) ON DELETE SET NULL,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    is_pinned BOOLEAN NOT NULL DEFAULT false,
    is_locked BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 10.7 Discussion Replies
CREATE TABLE IF NOT EXISTS public.discussion_replies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES public.discussion_threads(id) ON DELETE CASCADE,
    parent_reply_id UUID REFERENCES public.discussion_replies(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 10.8 Discussion Moderation Actions
CREATE TABLE IF NOT EXISTS public.moderation_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type TEXT NOT NULL, -- 'THREAD', 'REPLY'
    entity_id UUID NOT NULL,
    action TEXT NOT NULL, -- 'PIN', 'UNPIN', 'LOCK', 'DELETE', 'RESTORE'
    reason TEXT NULL,
    moderator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 10.9 Student Admission Documents
CREATE TABLE IF NOT EXISTS public.student_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    institution_id UUID REFERENCES public.institutions(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category document_category NOT NULL,
    file_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    status document_status NOT NULL DEFAULT 'PENDING',
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 10.10 Document Reviews
CREATE TABLE IF NOT EXISTS public.document_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.student_documents(id) ON DELETE CASCADE,
    status document_status NOT NULL,
    remarks TEXT NULL,
    reviewed_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    reviewed_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 10.11 Audit Logs (Append-Only Tamper-Evident Security Log)
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES public.institutions(id) ON DELETE SET NULL,
    actor_profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL, -- 'ROLE_GRANTED', 'EXAM_FINALIZED', 'QUESTION_ADJUDICATED'
    entity_type TEXT NOT NULL,
    entity_id UUID NULL,
    metadata_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    request_id TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- ----------------------------------------------------------------------------
