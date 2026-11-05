-- ============================================================================
-- NEET PREP LMS - PRODUCTION DATABASE DDL & SCHEMA SPECIFICATION
-- ============================================================================
-- Architecture: PostgreSQL 15+ (Supabase)
-- Specification Version: 2.0 (Finalized Product Overview & Engineering Spec)
-- Scope: High-Security Learning Management & Assessment System
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. EXTENSIONS & PREREQUISITES
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. CUSTOM TYPES & ENUMS (Data Dictionary Domain Constraints)
-- ----------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('STUDENT', 'FACULTY', 'ADMIN');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE role_assignment_status AS ENUM ('ACTIVE', 'REVOKED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE user_status AS ENUM ('ACTIVE', 'SUSPENDED', 'INACTIVE');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE admission_status AS ENUM ('ENROLLED', 'PENDING', 'WITHDRAWN', 'ALUMNI');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE employment_status AS ENUM ('ACTIVE', 'ON_LEAVE', 'TERMINATED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE academic_year_status AS ENUM ('UPCOMING', 'ACTIVE', 'COMPLETED', 'ARCHIVED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE program_status AS ENUM ('ACTIVE', 'INACTIVE', 'ARCHIVED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE cohort_status AS ENUM ('ACTIVE', 'UPCOMING', 'COMPLETED', 'ARCHIVED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE enrollment_status AS ENUM ('PENDING', 'ACTIVE', 'COMPLETED', 'TRANSFERRED', 'WITHDRAWN');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE faculty_assignment_status AS ENUM ('ACTIVE', 'INACTIVE', 'COMPLETED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE exam_status AS ENUM ('ACTIVE', 'DRAFT', 'ARCHIVED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE blueprint_status AS ENUM ('DRAFT', 'VERIFIED', 'ACTIVE', 'ARCHIVED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE topic_inclusion_status AS ENUM ('INCLUDED', 'EXCLUDED', 'REVIEW_REQUIRED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE resource_type AS ENUM ('NOTE', 'PDF', 'BOOK_REFERENCE', 'DPP', 'PYQ', 'VIDEO', 'IMAGE', 'LINK');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE resource_status AS ENUM ('DRAFT', 'PENDING_REVIEW', 'PUBLISHED', 'ARCHIVED', 'REJECTED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE file_scan_status AS ENUM ('PENDING', 'CLEAN', 'INFECTED', 'ERROR');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE question_type AS ENUM ('SINGLE_SELECT_MCQ', 'MULTIPLE_SELECT', 'NUMERICAL', 'ASSERTION_REASON');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE question_approval_status AS ENUM ('DRAFT', 'IN_REVIEW', 'APPROVED', 'REJECTED', 'PUBLISHED', 'ARCHIVED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE assessment_type AS ENUM ('DPP', 'CHAPTER_TEST', 'SUBJECT_TEST', 'MOCK_TEST', 'REVISION_TEST', 'PYQ_PRACTICE');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE assessment_version_status AS ENUM ('DRAFT', 'PUBLISHED', 'CLOSED', 'ARCHIVED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE attempt_status AS ENUM ('IN_PROGRESS', 'SUBMITTED', 'TIMED_OUT', 'ABANDONED', 'SCORED', 'RESULT_RELEASED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE answer_status AS ENUM ('ANSWERED', 'UNANSWERED', 'MARKED_FOR_REVIEW');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE progress_status AS ENUM ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE announcement_status AS ENUM ('DRAFT', 'PUBLISHED', 'ARCHIVED', 'EXPIRED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE announcement_priority AS ENUM ('LOW', 'NORMAL', 'HIGH', 'URGENT');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE calendar_event_type AS ENUM ('EXAM', 'LECTURE', 'DEADLINE', 'ANNOUNCEMENT', 'DOUBT_SESSION');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE calendar_event_status AS ENUM ('SCHEDULED', 'CANCELLED', 'COMPLETED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE ai_job_status AS ENUM ('QUEUED', 'PROCESSING', 'COMPLETED', 'FAILED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE ai_draft_validation_status AS ENUM ('PENDING', 'PASSED', 'FAILED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE ai_draft_review_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'EDITED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE document_category AS ENUM ('IDENTITY', 'ACADEMIC', 'MEDICAL', 'FINANCIAL');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE document_verification_status AS ENUM ('PENDING', 'VERIFIED', 'REJECTED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ----------------------------------------------------------------------------
-- 2. CORE IDENTITY, ROLES & INSTITUTE STRUCTURE (Section 15.2)
-- ----------------------------------------------------------------------------

-- 2.1 Profiles (1:1 with Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT NULL,
    avatar_path TEXT NULL,
    locale TEXT NOT NULL DEFAULT 'en',
    status user_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 2.2 Role Assignments (Trusted server/admin grants; never user metadata)
CREATE TABLE IF NOT EXISTS public.role_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role user_role NOT NULL,
    status role_assignment_status NOT NULL DEFAULT 'ACTIVE',
    assigned_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    revoked_at TIMESTAMPTZ NULL,
    reason TEXT NULL
);

-- Enforce at most one active role assignment per profile & role
CREATE UNIQUE INDEX IF NOT EXISTS idx_role_assignments_unique_active
    ON public.role_assignments(profile_id, role)
    WHERE status = 'ACTIVE';

-- 2.3 Students Domain Extension
CREATE TABLE IF NOT EXISTS public.students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    student_code TEXT UNIQUE NULL,
    admission_status admission_status NOT NULL DEFAULT 'ENROLLED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 2.4 Faculty Domain Extension
CREATE TABLE IF NOT EXISTS public.faculty (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    designation TEXT NULL,
    employment_status employment_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 2.5 Academic Years
CREATE TABLE IF NOT EXISTS public.academic_years (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL, -- e.g. '2026-2027'
    starts_on DATE NOT NULL,
    ends_on DATE NOT NULL,
    status academic_year_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT check_academic_year_dates CHECK (ends_on > starts_on)
);

-- ----------------------------------------------------------------------------
-- 3. EXAM DEFINITIONS, BLUEPRINTS & CURRICULUM (Section 15.3)
-- ----------------------------------------------------------------------------

-- 3.1 Exam Definitions (e.g. NEET_UG)
CREATE TABLE IF NOT EXISTS public.exam_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE, -- e.g. 'NEET_UG'
    name TEXT NOT NULL,
    authority_name TEXT NULL, -- e.g. 'National Testing Agency'
    official_website TEXT NULL,
    status exam_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 3.2 Programs (e.g. NEET-UG Long-Term or Repeater)
CREATE TABLE IF NOT EXISTS public.programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    exam_id UUID NOT NULL REFERENCES public.exam_definitions(id) ON DELETE RESTRICT,
    description TEXT NULL,
    status program_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 3.3 Cohorts (e.g. Batch 1 Dec, Batch 2 May/June)
CREATE TABLE IF NOT EXISTS public.cohorts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID NOT NULL REFERENCES public.programs(id) ON DELETE RESTRICT,
    academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
    name TEXT NOT NULL, -- e.g. 'Batch 1 (Dec)'
    starts_on DATE NOT NULL,
    ends_on DATE NOT NULL,
    capacity INTEGER NULL CHECK (capacity IS NULL OR capacity > 0),
    status cohort_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT check_cohort_dates CHECK (ends_on >= starts_on)
);

-- 3.4 Student Enrollments (Supports transfer history and cohort auditing)
CREATE TABLE IF NOT EXISTS public.student_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES public.cohorts(id) ON DELETE RESTRICT,
    status enrollment_status NOT NULL DEFAULT 'ACTIVE',
    starts_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    ends_at TIMESTAMPTZ NULL,
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- Enforce at most one active enrollment per student at any time
CREATE UNIQUE INDEX IF NOT EXISTS idx_student_single_active_enrollment
    ON public.student_enrollments(student_id)
    WHERE status = 'ACTIVE';

-- 3.5 Subjects (Physics, Chemistry, Biology, etc.)
CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE, -- e.g. 'PHY', 'CHEM', 'BIO'
    name TEXT NOT NULL,
    description TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 3.6 Faculty Cohort & Subject Assignments
CREATE TABLE IF NOT EXISTS public.faculty_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id UUID NOT NULL REFERENCES public.faculty(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES public.cohorts(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE RESTRICT,
    starts_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    ends_at TIMESTAMPTZ NULL,
    status faculty_assignment_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 3.7 Exam Blueprints (Immutable/versioned configuration for specific exam cycles)
CREATE TABLE IF NOT EXISTS public.exam_blueprints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id UUID NOT NULL REFERENCES public.exam_definitions(id) ON DELETE RESTRICT,
    exam_year INTEGER NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    source_url TEXT NULL,
    source_published_at DATE NULL,
    verified_at TIMESTAMPTZ NULL,
    verified_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status blueprint_status NOT NULL DEFAULT 'DRAFT',
    notes TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_exam_blueprint_version UNIQUE (exam_id, exam_year, version)
);

-- 3.8 Exam Sections (e.g. Physics Section A/B, Botany, Zoology)
CREATE TABLE IF NOT EXISTS public.exam_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blueprint_id UUID NOT NULL REFERENCES public.exam_blueprints(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 1,
    question_count INTEGER NULL,
    duration_seconds INTEGER NULL,
    max_marks NUMERIC(6,2) NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 3.9 Scoring Profiles (Validatable scoring matrix, correct, incorrect, unanswered)
CREATE TABLE IF NOT EXISTS public.scoring_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blueprint_id UUID NOT NULL REFERENCES public.exam_blueprints(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    correct_marks NUMERIC(5,2) NOT NULL DEFAULT 4.00,
    incorrect_marks NUMERIC(5,2) NOT NULL DEFAULT -1.00,
    unanswered_marks NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    partial_marking_config JSONB NULL,
    invalid_item_policy JSONB NOT NULL DEFAULT '{"dropped_item_full_credit": true}'::jsonb,
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 3.10 Blueprint Subjects Mapping
CREATE TABLE IF NOT EXISTS public.blueprint_subjects (
    blueprint_id UUID NOT NULL REFERENCES public.exam_blueprints(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE RESTRICT,
    section_id UUID REFERENCES public.exam_sections(id) ON DELETE SET NULL,
    display_order INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (blueprint_id, subject_id)
);

-- 3.11 Chapters
CREATE TABLE IF NOT EXISTS public.chapters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 3.12 Topics
CREATE TABLE IF NOT EXISTS public.topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chapter_id UUID NOT NULL REFERENCES public.chapters(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 3.13 Blueprint Topics (Maps approved topics to specific exam cycles)
CREATE TABLE IF NOT EXISTS public.blueprint_topics (
    blueprint_id UUID NOT NULL REFERENCES public.exam_blueprints(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES public.topics(id) ON DELETE CASCADE,
    inclusion_status topic_inclusion_status NOT NULL DEFAULT 'INCLUDED',
    source_reference TEXT NULL,
    PRIMARY KEY (blueprint_id, topic_id)
);

-- ----------------------------------------------------------------------------
-- 4. LEARNING RESOURCES & CLOUD STORAGE METADATA (Section 15.4)
-- ----------------------------------------------------------------------------

-- 4.1 Resources Table
CREATE TABLE IF NOT EXISTS public.resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NULL,
    resource_type resource_type NOT NULL,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    chapter_id UUID REFERENCES public.chapters(id) ON DELETE SET NULL,
    topic_id UUID REFERENCES public.topics(id) ON DELETE SET NULL,
    blueprint_id UUID REFERENCES public.exam_blueprints(id) ON DELETE SET NULL,
    reading_content TEXT NULL, -- Rich contextual outline for Document Reading Section
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    status resource_status NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    published_at TIMESTAMPTZ NULL
);

-- 4.2 Resource Files (Object Storage References)
CREATE TABLE IF NOT EXISTS public.resource_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES public.resources(id) ON DELETE CASCADE,
    bucket_id TEXT NOT NULL DEFAULT 'resources',
    storage_path TEXT NOT NULL, -- e.g. 'physics/mechanics/kinematics.pdf'
    file_name TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    checksum_sha256 TEXT NULL,
    scan_status file_scan_status NOT NULL DEFAULT 'CLEAN',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 4.3 Resource Cohort Access (Strict Batch-Wise Content Gating)
CREATE TABLE IF NOT EXISTS public.resource_cohort_access (
    resource_id UUID NOT NULL REFERENCES public.resources(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES public.cohorts(id) ON DELETE CASCADE,
    PRIMARY KEY (resource_id, cohort_id)
);

-- ----------------------------------------------------------------------------
-- 5. QUESTION BANK & IMMUTABLE REVISIONS (Section 15.5)
-- ----------------------------------------------------------------------------

-- 5.1 Question Bank Items (Logical Identity)
CREATE TABLE IF NOT EXISTS public.question_bank_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    chapter_id UUID REFERENCES public.chapters(id) ON DELETE SET NULL,
    topic_id UUID REFERENCES public.topics(id) ON DELETE SET NULL,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    current_revision_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    archived_at TIMESTAMPTZ NULL
);

-- 5.2 Question Revisions (Immutable Question Content)
CREATE TABLE IF NOT EXISTS public.question_revisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_item_id UUID NOT NULL REFERENCES public.question_bank_items(id) ON DELETE CASCADE,
    revision_number INTEGER NOT NULL DEFAULT 1,
    question_text TEXT NOT NULL,
    question_type question_type NOT NULL DEFAULT 'SINGLE_SELECT_MCQ',
    explanation TEXT NULL,
    difficulty_label TEXT NULL, -- 'EASY', 'MEDIUM', 'HARD'
    diagram_storage_path TEXT NULL, -- Cloud storage path for clinical stem diagrams
    diagram_alt_text TEXT NULL,
    source_reference TEXT NULL,
    rights_status TEXT NULL,
    approval_status question_approval_status NOT NULL DEFAULT 'DRAFT',
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_question_revision UNIQUE (question_item_id, revision_number)
);

-- Link current revision back to item
ALTER TABLE public.question_bank_items
    ADD CONSTRAINT fk_question_current_revision
    FOREIGN KEY (current_revision_id) REFERENCES public.question_revisions(id) ON DELETE SET NULL;

-- 5.3 Question Revision Options (Exactly 4 or 5 Options per Revision)
CREATE TABLE IF NOT EXISTS public.question_revision_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_revision_id UUID NOT NULL REFERENCES public.question_revisions(id) ON DELETE CASCADE,
    option_label TEXT NOT NULL, -- 'A', 'B', 'C', 'D', 'E'
    option_text TEXT NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT unique_revision_option_label UNIQUE (question_revision_id, option_label),
    CONSTRAINT unique_revision_option_order UNIQUE (question_revision_id, display_order)
);

-- 5.4 Question Answer Keys (HIGH-SECURITY: Non-student access; server-side scoring only)
CREATE TABLE IF NOT EXISTS public.question_answer_keys (
    question_revision_id UUID PRIMARY KEY REFERENCES public.question_revisions(id) ON DELETE CASCADE,
    accepted_option_ids UUID[] NOT NULL,
    resolution_type TEXT NOT NULL DEFAULT 'STANDARD', -- 'STANDARD', 'MULTIPLE_KEYS', 'ALL_ACCEPTED', 'DROPPED'
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- ----------------------------------------------------------------------------
-- 6. ASSESSMENTS, VERSIONS & SCHEDULED RUNS (Section 15.5)
-- ----------------------------------------------------------------------------

-- 6.1 Assessment Definitions
CREATE TABLE IF NOT EXISTS public.assessment_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NULL,
    assessment_type assessment_type NOT NULL,
    blueprint_id UUID REFERENCES public.exam_blueprints(id) ON DELETE RESTRICT,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    status TEXT NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 6.2 Assessment Versions (Immutable Published Testing Specifications)
CREATE TABLE IF NOT EXISTS public.assessment_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES public.assessment_definitions(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL DEFAULT 1,
    duration_seconds INTEGER NOT NULL DEFAULT 3600, -- e.g. 200 minutes (12000s) for NEET
    scoring_profile_id UUID NOT NULL REFERENCES public.scoring_profiles(id) ON DELETE RESTRICT,
    available_from TIMESTAMPTZ NULL,
    available_until TIMESTAMPTZ NULL,
    attempt_limit INTEGER NULL DEFAULT 1,
    navigation_policy JSONB NOT NULL DEFAULT '{"allow_backtracking": true, "show_palette": true}'::jsonb,
    result_release_policy JSONB NOT NULL DEFAULT '{"release_mode": "IMMEDIATE"}'::jsonb,
    status assessment_version_status NOT NULL DEFAULT 'DRAFT',
    published_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    published_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_assessment_version UNIQUE (assessment_id, version_number)
);

-- 6.3 Assessment Cohort Access
CREATE TABLE IF NOT EXISTS public.assessment_cohort_access (
    assessment_version_id UUID NOT NULL REFERENCES public.assessment_versions(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES public.cohorts(id) ON DELETE CASCADE,
    PRIMARY KEY (assessment_version_id, cohort_id)
);

-- 6.4 Assessment Questions (Ordered Mapping of Frozen Revisions to Test Version)
CREATE TABLE IF NOT EXISTS public.assessment_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_version_id UUID NOT NULL REFERENCES public.assessment_versions(id) ON DELETE CASCADE,
    question_revision_id UUID NOT NULL REFERENCES public.question_revisions(id) ON DELETE RESTRICT,
    question_order INTEGER NOT NULL DEFAULT 1,
    marks_override NUMERIC(5,2) NULL,
    negative_marks_override NUMERIC(5,2) NULL,
    CONSTRAINT unique_assessment_version_order UNIQUE (assessment_version_id, question_order),
    CONSTRAINT unique_assessment_version_question UNIQUE (assessment_version_id, question_revision_id)
);

-- ----------------------------------------------------------------------------
-- 7. ATTEMPTS, ANSWERS & VERIFIED SCORING (Section 15.6)
-- ----------------------------------------------------------------------------

-- 7.1 Student Assessment Attempts
CREATE TABLE IF NOT EXISTS public.attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_version_id UUID NOT NULL REFERENCES public.assessment_versions(id) ON DELETE RESTRICT,
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    enrollment_id UUID NOT NULL REFERENCES public.student_enrollments(id) ON DELETE RESTRICT,
    attempt_number INTEGER NOT NULL DEFAULT 1,
    status attempt_status NOT NULL DEFAULT 'IN_PROGRESS',
    started_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    deadline_at TIMESTAMPTZ NOT NULL,
    submitted_at TIMESTAMPTZ NULL,
    scored_at TIMESTAMPTZ NULL,
    raw_score NUMERIC(6,2) NULL,
    maximum_score NUMERIC(6,2) NULL,
    correct_count INTEGER NULL,
    incorrect_count INTEGER NULL,
    unanswered_count INTEGER NULL,
    scoring_snapshot JSONB NULL,
    idempotency_key TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT check_deadline_after_start CHECK (deadline_at > started_at),
    CONSTRAINT unique_assessment_student_attempt UNIQUE (assessment_version_id, student_id, attempt_number)
);

-- Enforce single active attempt per student and assessment
CREATE UNIQUE INDEX IF NOT EXISTS idx_single_active_attempt_per_student
    ON public.attempts(student_id, assessment_version_id)
    WHERE status = 'IN_PROGRESS';

-- 7.2 Attempt Answers (Per-question response & server-scored evaluation)
CREATE TABLE IF NOT EXISTS public.attempt_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES public.attempts(id) ON DELETE CASCADE,
    assessment_question_id UUID NOT NULL REFERENCES public.assessment_questions(id) ON DELETE RESTRICT,
    question_revision_id UUID NOT NULL REFERENCES public.question_revisions(id) ON DELETE RESTRICT,
    selected_option_id UUID REFERENCES public.question_revision_options(id) ON DELETE SET NULL,
    answer_status answer_status NOT NULL DEFAULT 'UNANSWERED',
    saved_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    evaluated_is_correct BOOLEAN NULL, -- Written by authoritative backend scoring service only
    marks_awarded NUMERIC(5,2) NULL,    -- Written by authoritative backend scoring service only
    CONSTRAINT unique_attempt_question UNIQUE (attempt_id, assessment_question_id)
);

-- 7.3 Attempt Events (Append-only operational timeline)
CREATE TABLE IF NOT EXISTS public.attempt_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES public.attempts(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL, -- e.g. 'STARTED', 'ANSWER_SAVED', 'AUTO_TIMEOUT', 'SUBMITTED'
    server_recorded_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    request_id TEXT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

-- 7.4 Score Adjustments (Tamper-evident adjudication & regrading audit)
CREATE TABLE IF NOT EXISTS public.score_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES public.attempts(id) ON DELETE CASCADE,
    old_score NUMERIC(6,2) NOT NULL,
    new_score NUMERIC(6,2) NOT NULL,
    reason TEXT NOT NULL,
    adjusted_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    adjudication_reference TEXT NULL
);

-- ----------------------------------------------------------------------------
-- 8. PROGRESS, CALENDAR, ANNOUNCEMENTS & AI (Section 15.7)
-- ----------------------------------------------------------------------------

-- 8.1 Student Topic Progress
CREATE TABLE IF NOT EXISTS public.student_topic_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES public.topics(id) ON DELETE CASCADE,
    status progress_status NOT NULL DEFAULT 'NOT_STARTED',
    completed_at TIMESTAMPTZ NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_student_topic_progress UNIQUE (student_id, topic_id)
);

-- 8.2 Announcements
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    audience_type TEXT NOT NULL DEFAULT 'COHORT', -- 'INSTITUTE', 'COHORT', 'ROLE'
    priority announcement_priority NOT NULL DEFAULT 'NORMAL',
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    published_at TIMESTAMPTZ NULL,
    expires_at TIMESTAMPTZ NULL,
    status announcement_status NOT NULL DEFAULT 'PUBLISHED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 8.3 Announcement Cohorts Mapping
CREATE TABLE IF NOT EXISTS public.announcement_cohorts (
    announcement_id UUID NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES public.cohorts(id) ON DELETE CASCADE,
    PRIMARY KEY (announcement_id, cohort_id)
);

-- 8.4 Academic Calendar Events
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NULL,
    event_type calendar_event_type NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    visibility TEXT NOT NULL DEFAULT 'COHORT',
    status calendar_event_status NOT NULL DEFAULT 'SCHEDULED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT check_calendar_event_dates CHECK (ends_at >= starts_at)
);

-- 8.5 Calendar Event Cohorts Mapping
CREATE TABLE IF NOT EXISTS public.calendar_event_cohorts (
    event_id UUID NOT NULL REFERENCES public.calendar_events(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES public.cohorts(id) ON DELETE CASCADE,
    PRIMARY KEY (event_id, cohort_id)
);

-- 8.6 AI Generation Jobs (Faculty/Admin AI question creation)
CREATE TABLE IF NOT EXISTS public.ai_generation_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requested_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    exam_blueprint_id UUID REFERENCES public.exam_blueprints(id) ON DELETE SET NULL,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    chapter_id UUID REFERENCES public.chapters(id) ON DELETE SET NULL,
    topic_id UUID REFERENCES public.topics(id) ON DELETE SET NULL,
    provider TEXT NOT NULL DEFAULT 'GROQ',
    model_id TEXT NOT NULL, -- e.g. 'openai/gpt-oss-120b', 'qwen/qwen3.8-27b'
    prompt_template_version TEXT NOT NULL DEFAULT 'v1',
    status ai_job_status NOT NULL DEFAULT 'QUEUED',
    input_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    error_code TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    completed_at TIMESTAMPTZ NULL
);

-- 8.7 AI Question Drafts (Staging before faculty review & publishing)
CREATE TABLE IF NOT EXISTS public.ai_question_drafts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    generation_job_id UUID NOT NULL REFERENCES public.ai_generation_jobs(id) ON DELETE CASCADE,
    draft_payload JSONB NOT NULL,
    validation_status ai_draft_validation_status NOT NULL DEFAULT 'PENDING',
    review_status ai_draft_review_status NOT NULL DEFAULT 'PENDING',
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ NULL,
    published_question_revision_id UUID REFERENCES public.question_revisions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 8.8 AI Reference Sources
CREATE TABLE IF NOT EXISTS public.ai_reference_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    generation_job_id UUID NOT NULL REFERENCES public.ai_generation_jobs(id) ON DELETE CASCADE,
    resource_id UUID REFERENCES public.resources(id) ON DELETE SET NULL,
    source_locator TEXT NULL,
    excerpt_hash TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- ----------------------------------------------------------------------------
-- 9. OPTIONAL & GOVERNANCE MODULES (Section 15.8)
-- ----------------------------------------------------------------------------

-- 9.1 Student Admission Documents (Admin/Agent Verified)
CREATE TABLE IF NOT EXISTS public.student_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category document_category NOT NULL,
    file_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    status document_verification_status NOT NULL DEFAULT 'PENDING',
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 9.2 Document Reviews
CREATE TABLE IF NOT EXISTS public.document_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.student_documents(id) ON DELETE CASCADE,
    status document_verification_status NOT NULL,
    remarks TEXT NULL,
    reviewed_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    reviewed_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 9.3 Discussion Threads (Moderated Community)
CREATE TABLE IF NOT EXISTS public.discussion_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    cohort_id UUID REFERENCES public.cohorts(id) ON DELETE SET NULL,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    is_pinned BOOLEAN NOT NULL DEFAULT false,
    is_locked BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 9.4 Discussion Replies (Nested Comment Trees)
CREATE TABLE IF NOT EXISTS public.discussion_replies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES public.discussion_threads(id) ON DELETE CASCADE,
    parent_reply_id UUID REFERENCES public.discussion_replies(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 9.5 Discussion Moderation Actions
CREATE TABLE IF NOT EXISTS public.moderation_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type TEXT NOT NULL, -- 'THREAD', 'REPLY'
    entity_id UUID NOT NULL,
    action TEXT NOT NULL, -- 'PIN', 'UNPIN', 'LOCK', 'DELETE', 'RESTORE'
    reason TEXT NULL,
    moderator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 9.6 Security Audit Logs (Immutable Security & Administrative Event Log)
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL, -- e.g. 'ROLE_GRANTED', 'COHORT_TRANSFERRED', 'RESOURCE_PUBLISHED'
    entity_type TEXT NOT NULL,
    entity_id UUID NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- ----------------------------------------------------------------------------
-- 10. INDEXING STRATEGY FOR HIGH-TRAFFIC READ PATHS (Section 15.9)
-- ----------------------------------------------------------------------------

-- Curriculum Lookups
CREATE INDEX IF NOT EXISTS idx_chapters_subject_order
    ON public.chapters(subject_id, display_order);

CREATE INDEX IF NOT EXISTS idx_topics_chapter_order
    ON public.topics(chapter_id, display_order);

CREATE INDEX IF NOT EXISTS idx_blueprint_topics_composite
    ON public.blueprint_topics(blueprint_id, topic_id);

-- Cohort and Student Enrollment Lookups
CREATE INDEX IF NOT EXISTS idx_enrollments_student_status
    ON public.student_enrollments(student_id, status);

CREATE INDEX IF NOT EXISTS idx_enrollments_cohort_status
    ON public.student_enrollments(cohort_id, status);

CREATE INDEX IF NOT EXISTS idx_faculty_assignments_lookup
    ON public.faculty_assignments(faculty_id, cohort_id, subject_id);

-- Resources and Cohort Access
CREATE INDEX IF NOT EXISTS idx_resources_status_type
    ON public.resources(status, resource_type);

CREATE INDEX IF NOT EXISTS idx_resources_subject_chapter
    ON public.resources(subject_id, chapter_id);

CREATE INDEX IF NOT EXISTS idx_resource_cohort_access_cohort
    ON public.resource_cohort_access(cohort_id, resource_id);

-- Question Bank Lookups
CREATE INDEX IF NOT EXISTS idx_question_revisions_lookup
    ON public.question_revisions(question_item_id, revision_number);

CREATE INDEX IF NOT EXISTS idx_question_revision_options_rev
    ON public.question_revision_options(question_revision_id, display_order);

-- Assessment and Version Lookups
CREATE INDEX IF NOT EXISTS idx_assessment_versions_status_window
    ON public.assessment_versions(status, available_from, available_until);

CREATE INDEX IF NOT EXISTS idx_assessment_cohort_access_lookup
    ON public.assessment_cohort_access(cohort_id, assessment_version_id);

CREATE INDEX IF NOT EXISTS idx_assessment_questions_order
    ON public.assessment_questions(assessment_version_id, question_order);

-- Attempts, Answers and Analytics Lookups
CREATE INDEX IF NOT EXISTS idx_attempts_student_started
    ON public.attempts(student_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_attempts_assessment_status
    ON public.attempts(assessment_version_id, status);

CREATE INDEX IF NOT EXISTS idx_attempt_answers_attempt
    ON public.attempt_answers(attempt_id);

CREATE INDEX IF NOT EXISTS idx_attempt_events_attempt_time
    ON public.attempt_events(attempt_id, server_recorded_at);

-- Progress and Community Lookups
CREATE INDEX IF NOT EXISTS idx_student_topic_progress_student
    ON public.student_topic_progress(student_id, status);

CREATE INDEX IF NOT EXISTS idx_discussion_replies_thread
    ON public.discussion_replies(thread_id, created_at);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_action
    ON public.audit_logs(actor_id, action, created_at DESC);

-- ----------------------------------------------------------------------------
-- 11. SECURITY FUNCTIONS & AUTOMATIC TRIGGERS (Section 17.4)
-- ----------------------------------------------------------------------------

-- 11.1 Helper: Get Authenticated User Active Role from Trusted Tables
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS user_role AS $$
DECLARE
    v_role user_role;
BEGIN
    SELECT role INTO v_role
    FROM public.role_assignments
    WHERE profile_id = auth.uid()
      AND status = 'ACTIVE'
    ORDER BY CASE
        WHEN role = 'ADMIN' THEN 1
        WHEN role = 'FACULTY' THEN 2
        ELSE 3
    END
    LIMIT 1;

    IF v_role IS NULL THEN
        -- Fallback to default
        v_role := 'STUDENT';
    END IF;

    RETURN v_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public, pg_temp;

-- 11.2 Helper: Check If Caller Possesses Admin Privileges
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.get_user_role() = 'ADMIN';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public, pg_temp;

-- 11.3 Helper: Check If Caller Possesses Faculty Privileges
CREATE OR REPLACE FUNCTION public.is_faculty()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.get_user_role() IN ('FACULTY', 'ADMIN');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public, pg_temp;

-- 11.4 Helper: Check Student Active Cohort Enrollment
CREATE OR REPLACE FUNCTION public.is_enrolled_in_cohort(p_cohort_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.student_enrollments se
        JOIN public.students s ON se.student_id = s.id
        WHERE s.profile_id = auth.uid()
          AND se.cohort_id = p_cohort_id
          AND se.status = 'ACTIVE'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public, pg_temp;

-- 11.5 Automatic Updated At Trigger Function
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc', now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach updated_at triggers
DO $$
DECLARE
    tbl text;
    tables text[] := ARRAY[
        'profiles', 'students', 'faculty', 'academic_years', 'programs',
        'cohorts', 'student_enrollments', 'faculty_assignments',
        'exam_definitions', 'exam_blueprints', 'scoring_profiles',
        'subjects', 'chapters', 'topics', 'resources', 'assessment_definitions',
        'assessment_versions', 'attempts', 'student_topic_progress',
        'announcements', 'calendar_events', 'discussion_threads', 'discussion_replies'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS trigger_set_updated_at ON public.%I;
            CREATE TRIGGER trigger_set_updated_at
                BEFORE UPDATE ON public.%I
                FOR EACH ROW
                EXECUTE FUNCTION public.set_updated_at();
        ', tbl, tbl);
    END LOOP;
END $$;

-- 11.6 Automated User Provisioning Trigger (Section 17.4 Compliance)
-- NEVER trust user-supplied raw_user_meta_data for administrative escalation.
-- Defaults new accounts securely to 'STUDENT' unless created through an audited admin procedure.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_full_name TEXT;
    v_phone TEXT;
    v_avatar TEXT;
    v_assigned_role user_role := 'STUDENT';
    v_student_id UUID;
BEGIN
    -- Extract profile fields
    v_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1));
    v_phone := NEW.raw_user_meta_data->>'phone';
    v_avatar := NEW.raw_user_meta_data->>'avatar_url';

    -- 1. Insert or update public.profiles
    INSERT INTO public.profiles (id, full_name, phone, avatar_path, status)
    VALUES (NEW.id, v_full_name, v_phone, v_avatar, 'ACTIVE')
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        phone = EXCLUDED.phone,
        avatar_path = EXCLUDED.avatar_path,
        updated_at = timezone('utc', now());

    -- 2. Insert role assignment (defaulting safely to STUDENT)
    INSERT INTO public.role_assignments (profile_id, role, status, reason)
    VALUES (NEW.id, v_assigned_role, 'ACTIVE', 'Automated initial account provisioning')
    ON CONFLICT DO NOTHING;

    -- 3. Create role-specific extension record
    INSERT INTO public.students (profile_id, admission_status)
    VALUES (NEW.id, 'ENROLLED')
    ON CONFLICT (profile_id) DO NOTHING;

    -- 4. Record audit event
    INSERT INTO public.audit_logs (actor_id, action, entity_type, entity_id, metadata)
    VALUES (NEW.id, 'USER_SIGNUP_PROVISIONED', 'PROFILE', NEW.id, jsonb_build_object('email', NEW.email));

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 12. ROW LEVEL SECURITY (RLS) POLICIES (Section 17)
-- ----------------------------------------------------------------------------

-- Enable RLS across every table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faculty ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cohorts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faculty_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_blueprints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scoring_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blueprint_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blueprint_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resource_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resource_cohort_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_bank_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_revision_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_answer_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_cohort_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempt_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempt_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.score_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_topic_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_cohorts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_event_cohorts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_generation_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_question_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_reference_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discussion_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discussion_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderation_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- 12.1 Profiles Policies
CREATE POLICY "Profiles: Users read own, staff read institute"
    ON public.profiles FOR SELECT
    USING (id = auth.uid() OR public.is_faculty());

CREATE POLICY "Profiles: Users update own allowed fields"
    ON public.profiles FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "Profiles: Admins manage all profiles"
    ON public.profiles FOR ALL
    USING (public.is_admin());

-- 12.2 Role Assignments Policies (Admin only management)
CREATE POLICY "RoleAssignments: Read own active role or admin"
    ON public.role_assignments FOR SELECT
    USING (profile_id = auth.uid() OR public.is_admin());

CREATE POLICY "RoleAssignments: Admins manage roles"
    ON public.role_assignments FOR ALL
    USING (public.is_admin());

-- 12.3 Students & Faculty Policies
CREATE POLICY "Students: Read own student record or staff"
    ON public.students FOR SELECT
    USING (profile_id = auth.uid() OR public.is_faculty());

CREATE POLICY "Students: Admins manage students"
    ON public.students FOR ALL
    USING (public.is_admin());

CREATE POLICY "Faculty: Read faculty list"
    ON public.faculty FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Faculty: Admins manage faculty"
    ON public.faculty FOR ALL
    USING (public.is_admin());

-- 12.4 Academic Structure (Academic Years, Programs, Cohorts)
CREATE POLICY "Structure: Read academic structure"
    ON public.academic_years FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Structure: Admins manage academic years"
    ON public.academic_years FOR ALL
    USING (public.is_admin());

CREATE POLICY "Structure: Read programs"
    ON public.programs FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Structure: Admins manage programs"
    ON public.programs FOR ALL
    USING (public.is_admin());

CREATE POLICY "Structure: Read cohorts"
    ON public.cohorts FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Structure: Admins manage cohorts"
    ON public.cohorts FOR ALL
    USING (public.is_admin());

-- 12.5 Enrollments & Assignments
CREATE POLICY "Enrollments: Read own enrollment or staff"
    ON public.student_enrollments FOR SELECT
    USING (
        student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
        OR public.is_faculty()
    );

CREATE POLICY "Enrollments: Admins manage enrollments"
    ON public.student_enrollments FOR ALL
    USING (public.is_admin());

CREATE POLICY "FacultyAssignments: Staff read assignments"
    ON public.faculty_assignments FOR SELECT
    USING (public.is_faculty());

CREATE POLICY "FacultyAssignments: Admins manage assignments"
    ON public.faculty_assignments FOR ALL
    USING (public.is_admin());

-- 12.6 Exam Definitions, Blueprints & Curriculum
CREATE POLICY "Curriculum: Read exam definitions"
    ON public.exam_definitions FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Curriculum: Admins manage exam definitions"
    ON public.exam_definitions FOR ALL
    USING (public.is_admin());

CREATE POLICY "Curriculum: Read active blueprints"
    ON public.exam_blueprints FOR SELECT
    USING (status = 'ACTIVE' OR public.is_faculty());

CREATE POLICY "Curriculum: Staff manage blueprints"
    ON public.exam_blueprints FOR ALL
    USING (public.is_admin());

CREATE POLICY "Curriculum: Read sections and scoring"
    ON public.exam_sections FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Curriculum: Staff manage sections"
    ON public.exam_sections FOR ALL
    USING (public.is_admin());

CREATE POLICY "Curriculum: Read scoring profiles"
    ON public.scoring_profiles FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Curriculum: Staff manage scoring profiles"
    ON public.scoring_profiles FOR ALL
    USING (public.is_admin());

CREATE POLICY "Curriculum: Authenticated users read subjects, chapters, topics"
    ON public.subjects FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Curriculum: Staff manage subjects"
    ON public.subjects FOR ALL USING (public.is_admin());

CREATE POLICY "Curriculum: Read blueprint subjects"
    ON public.blueprint_subjects FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Curriculum: Staff manage blueprint subjects"
    ON public.blueprint_subjects FOR ALL USING (public.is_admin());

CREATE POLICY "Curriculum: Read chapters"
    ON public.chapters FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Curriculum: Staff manage chapters"
    ON public.chapters FOR ALL USING (public.is_faculty());

CREATE POLICY "Curriculum: Read topics"
    ON public.topics FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Curriculum: Staff manage topics"
    ON public.topics FOR ALL USING (public.is_faculty());

CREATE POLICY "Curriculum: Read blueprint topics"
    ON public.blueprint_topics FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Curriculum: Staff manage blueprint topics"
    ON public.blueprint_topics FOR ALL USING (public.is_admin());

-- 12.7 Learning Resources & Files (Strict Cohort Gating)
CREATE POLICY "Resources: Students read published cohort resources, staff read all"
    ON public.resources FOR SELECT
    USING (
        public.is_faculty()
        OR (
            status = 'PUBLISHED'
            AND EXISTS (
                SELECT 1
                FROM public.resource_cohort_access rca
                WHERE rca.resource_id = public.resources.id
                  AND public.is_enrolled_in_cohort(rca.cohort_id)
            )
        )
    );

CREATE POLICY "Resources: Faculty and Admins create resources"
    ON public.resources FOR INSERT
    WITH CHECK (public.is_faculty() AND created_by = auth.uid());

CREATE POLICY "Resources: Authors and Admins update resources"
    ON public.resources FOR UPDATE
    USING (created_by = auth.uid() OR public.is_admin());

CREATE POLICY "Resources: Admins delete resources"
    ON public.resources FOR DELETE
    USING (public.is_admin());

CREATE POLICY "ResourceFiles: Read accessible resource files"
    ON public.resource_files FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.resources r
            WHERE r.id = public.resource_files.resource_id
              AND (
                  public.is_faculty()
                  OR (
                      r.status = 'PUBLISHED'
                      AND EXISTS (
                          SELECT 1 FROM public.resource_cohort_access rca
                          WHERE rca.resource_id = r.id
                            AND public.is_enrolled_in_cohort(rca.cohort_id)
                      )
                  )
              )
        )
    );

CREATE POLICY "ResourceFiles: Staff manage resource files"
    ON public.resource_files FOR ALL
    USING (public.is_faculty());

CREATE POLICY "ResourceCohortAccess: Read accessible mappings"
    ON public.resource_cohort_access FOR SELECT
    USING (public.is_faculty() OR public.is_enrolled_in_cohort(cohort_id));

CREATE POLICY "ResourceCohortAccess: Staff manage mappings"
    ON public.resource_cohort_access FOR ALL
    USING (public.is_faculty());

-- 12.8 Question Bank & Question Revisions
CREATE POLICY "QuestionBank: Staff manage question items"
    ON public.question_bank_items FOR ALL
    USING (public.is_faculty());

CREATE POLICY "QuestionRevisions: Staff manage revisions"
    ON public.question_revisions FOR ALL
    USING (public.is_faculty());

CREATE POLICY "QuestionOptions: Read options during active attempt or staff"
    ON public.question_revision_options FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "QuestionOptions: Staff manage options"
    ON public.question_revision_options FOR ALL
    USING (public.is_faculty());

-- 12.9 QUESTION ANSWER KEYS: STRICT ISOLATION (Section 15.5)
-- Students must NEVER be able to read answer keys through REST, GraphQL or Supabase Data API!
CREATE POLICY "AnswerKeys: Restricted strictly to Staff review workflows"
    ON public.question_answer_keys FOR SELECT
    USING (public.is_faculty());

CREATE POLICY "AnswerKeys: Staff manage answer keys"
    ON public.question_answer_keys FOR ALL
    USING (public.is_faculty());

-- 12.10 Assessment Definitions & Versions
CREATE POLICY "Assessments: Staff manage definitions"
    ON public.assessment_definitions FOR ALL
    USING (public.is_faculty());

CREATE POLICY "AssessmentVersions: Students read published cohort versions, staff read all"
    ON public.assessment_versions FOR SELECT
    USING (
        public.is_faculty()
        OR (
            status = 'PUBLISHED'
            AND EXISTS (
                SELECT 1
                FROM public.assessment_cohort_access aca
                WHERE aca.assessment_version_id = public.assessment_versions.id
                  AND public.is_enrolled_in_cohort(aca.cohort_id)
            )
        )
    );

CREATE POLICY "AssessmentVersions: Staff manage versions"
    ON public.assessment_versions FOR ALL
    USING (public.is_faculty());

CREATE POLICY "AssessmentCohortAccess: Read mappings"
    ON public.assessment_cohort_access FOR SELECT
    USING (public.is_faculty() OR public.is_enrolled_in_cohort(cohort_id));

CREATE POLICY "AssessmentCohortAccess: Staff manage cohort access"
    ON public.assessment_cohort_access FOR ALL
    USING (public.is_faculty());

CREATE POLICY "AssessmentQuestions: Read questions for enrolled assessment or staff"
    ON public.assessment_questions FOR SELECT
    USING (
        public.is_faculty()
        OR EXISTS (
            SELECT 1
            FROM public.assessment_versions av
            JOIN public.assessment_cohort_access aca ON aca.assessment_version_id = av.id
            WHERE av.id = public.assessment_questions.assessment_version_id
              AND av.status = 'PUBLISHED'
              AND public.is_enrolled_in_cohort(aca.cohort_id)
        )
    );

CREATE POLICY "AssessmentQuestions: Staff manage assessment questions"
    ON public.assessment_questions FOR ALL
    USING (public.is_faculty());

-- 12.11 Attempts & Answers (Strict Student Isolation)
CREATE POLICY "Attempts: Students manage own attempts, staff read all"
    ON public.attempts FOR SELECT
    USING (
        student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
        OR public.is_faculty()
    );

CREATE POLICY "Attempts: Students insert own attempt"
    ON public.attempts FOR INSERT
    WITH CHECK (
        student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
    );

CREATE POLICY "Attempts: Students update own in-progress attempt, staff update any"
    ON public.attempts FOR UPDATE
    USING (
        (student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid()) AND status = 'IN_PROGRESS')
        OR public.is_faculty()
    );

CREATE POLICY "AttemptAnswers: Students manage own answers, staff read all"
    ON public.attempt_answers FOR SELECT
    USING (
        attempt_id IN (
            SELECT a.id FROM public.attempts a
            JOIN public.students s ON a.student_id = s.id
            WHERE s.profile_id = auth.uid()
        )
        OR public.is_faculty()
    );

CREATE POLICY "AttemptAnswers: Students insert or update own answers"
    ON public.attempt_answers FOR INSERT
    WITH CHECK (
        attempt_id IN (
            SELECT a.id FROM public.attempts a
            JOIN public.students s ON a.student_id = s.id
            WHERE s.profile_id = auth.uid() AND a.status = 'IN_PROGRESS'
        )
    );

CREATE POLICY "AttemptAnswers: Students update own answers during attempt"
    ON public.attempt_answers FOR UPDATE
    USING (
        attempt_id IN (
            SELECT a.id FROM public.attempts a
            JOIN public.students s ON a.student_id = s.id
            WHERE s.profile_id = auth.uid() AND a.status = 'IN_PROGRESS'
        )
        OR public.is_faculty()
    );

CREATE POLICY "AttemptEvents: Insert and read own events"
    ON public.attempt_events FOR ALL
    USING (
        attempt_id IN (
            SELECT a.id FROM public.attempts a
            JOIN public.students s ON a.student_id = s.id
            WHERE s.profile_id = auth.uid()
        )
        OR public.is_faculty()
    );

CREATE POLICY "ScoreAdjustments: Read adjustments on own attempt or staff"
    ON public.score_adjustments FOR SELECT
    USING (
        attempt_id IN (
            SELECT a.id FROM public.attempts a
            JOIN public.students s ON a.student_id = s.id
            WHERE s.profile_id = auth.uid()
        )
        OR public.is_faculty()
    );

CREATE POLICY "ScoreAdjustments: Staff manage score adjustments"
    ON public.score_adjustments FOR ALL
    USING (public.is_faculty());

-- 12.12 Student Topic Progress
CREATE POLICY "TopicProgress: Students manage own progress, staff read all"
    ON public.student_topic_progress FOR ALL
    USING (
        student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
        OR public.is_faculty()
    )
    WITH CHECK (
        student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
        OR public.is_faculty()
    );

-- 12.13 Announcements & Calendar Events
CREATE POLICY "Announcements: Read permitted announcements"
    ON public.announcements FOR SELECT
    USING (
        public.is_faculty()
        OR (
            status = 'PUBLISHED'
            AND (
                audience_type = 'INSTITUTE'
                OR EXISTS (
                    SELECT 1 FROM public.announcement_cohorts ac
                    WHERE ac.announcement_id = public.announcements.id
                      AND public.is_enrolled_in_cohort(ac.cohort_id)
                )
            )
        )
    );

CREATE POLICY "Announcements: Staff manage announcements"
    ON public.announcements FOR ALL
    USING (public.is_faculty());

CREATE POLICY "AnnouncementCohorts: Read mappings"
    ON public.announcement_cohorts FOR SELECT
    USING (public.is_faculty() OR public.is_enrolled_in_cohort(cohort_id));

CREATE POLICY "AnnouncementCohorts: Staff manage mappings"
    ON public.announcement_cohorts FOR ALL
    USING (public.is_faculty());

CREATE POLICY "CalendarEvents: Read scheduled events"
    ON public.calendar_events FOR SELECT
    USING (
        public.is_faculty()
        OR (
            status = 'SCHEDULED'
            AND (
                visibility = 'INSTITUTE'
                OR EXISTS (
                    SELECT 1 FROM public.calendar_event_cohorts cec
                    WHERE cec.event_id = public.calendar_events.id
                      AND public.is_enrolled_in_cohort(cec.cohort_id)
                )
            )
        )
    );

CREATE POLICY "CalendarEvents: Staff manage calendar events"
    ON public.calendar_events FOR ALL
    USING (public.is_faculty());

CREATE POLICY "CalendarCohorts: Read mappings"
    ON public.calendar_event_cohorts FOR SELECT
    USING (public.is_faculty() OR public.is_enrolled_in_cohort(cohort_id));

CREATE POLICY "CalendarCohorts: Staff manage mappings"
    ON public.calendar_event_cohorts FOR ALL
    USING (public.is_faculty());

-- 12.14 AI Features (Staff Only Access)
CREATE POLICY "AIJobs: Staff manage AI generation jobs"
    ON public.ai_generation_jobs FOR ALL
    USING (public.is_faculty());

CREATE POLICY "AIDrafts: Staff manage AI drafts"
    ON public.ai_question_drafts FOR ALL
    USING (public.is_faculty());

CREATE POLICY "AIReferences: Staff manage AI sources"
    ON public.ai_reference_sources FOR ALL
    USING (public.is_faculty());

-- 12.15 Student Documents & Verification (Admin/Agent Verified)
CREATE POLICY "Documents: Students read own documents, Admins manage all"
    ON public.student_documents FOR SELECT
    USING (
        student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
        OR public.is_admin()
    );

CREATE POLICY "Documents: Students upload own documents"
    ON public.student_documents FOR INSERT
    WITH CHECK (
        student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
    );

CREATE POLICY "Documents: Admins manage documents"
    ON public.student_documents FOR ALL
    USING (public.is_admin());

CREATE POLICY "DocumentReviews: Read on own document or admin"
    ON public.document_reviews FOR SELECT
    USING (
        document_id IN (
            SELECT d.id FROM public.student_documents d
            JOIN public.students s ON d.student_id = s.id
            WHERE s.profile_id = auth.uid()
        )
        OR public.is_admin()
    );

CREATE POLICY "DocumentReviews: Admins manage reviews"
    ON public.document_reviews FOR ALL
    USING (public.is_admin());

-- 12.16 Community Discussions
CREATE POLICY "Discussions: Read threads"
    ON public.discussion_threads FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Discussions: Create threads"
    ON public.discussion_threads FOR INSERT
    WITH CHECK (author_id = auth.uid());

CREATE POLICY "Discussions: Author or Admin update threads"
    ON public.discussion_threads FOR UPDATE
    USING (author_id = auth.uid() OR public.is_admin());

CREATE POLICY "Discussions: Admins delete threads"
    ON public.discussion_threads FOR DELETE
    USING (public.is_admin());

CREATE POLICY "Replies: Read replies"
    ON public.discussion_replies FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Replies: Create replies"
    ON public.discussion_replies FOR INSERT
    WITH CHECK (author_id = auth.uid());

CREATE POLICY "Replies: Author or Admin update replies"
    ON public.discussion_replies FOR UPDATE
    USING (author_id = auth.uid() OR public.is_admin());

CREATE POLICY "Replies: Admins delete replies"
    ON public.discussion_replies FOR DELETE
    USING (public.is_admin());

CREATE POLICY "Moderation: Staff read and write moderation logs"
    ON public.moderation_actions FOR ALL
    USING (public.is_faculty());

-- 12.17 Audit Logs (Admin Only Read; Authenticated Append)
CREATE POLICY "AuditLogs: Admins read audit logs"
    ON public.audit_logs FOR SELECT
    USING (public.is_admin());

CREATE POLICY "AuditLogs: System records audit events"
    ON public.audit_logs FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- ----------------------------------------------------------------------------
-- 13. CLOUD STORAGE BUCKETS & STORAGE RLS POLICIES (Section 19.5, 20.3)
-- ----------------------------------------------------------------------------

-- Initialize private buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('resources', 'resources', false, 104857600, ARRAY['application/pdf', 'video/mp4', 'image/jpeg', 'image/png', 'image/webp', 'text/plain']),
    ('documents', 'documents', false, 20971520, ARRAY['application/pdf', 'image/jpeg', 'image/png'])
ON CONFLICT (id) DO UPDATE SET
    public = false;

-- Storage Policy: Read Resources
CREATE POLICY "Storage: Authenticated read authorized resources"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'resources'
        AND (
            public.is_faculty()
            OR auth.role() = 'authenticated'
        )
    );

-- Storage Policy: Staff Upload Resources
CREATE POLICY "Storage: Staff upload resources"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'resources'
        AND public.is_faculty()
    );

-- Storage Policy: Staff Delete Resources
CREATE POLICY "Storage: Admins delete resources"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'resources'
        AND public.is_admin()
    );

-- Storage Policy: Student Upload Documents
CREATE POLICY "Storage: Student upload verification documents"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'documents'
        AND auth.role() = 'authenticated'
    );

-- Storage Policy: Student Read Own Documents & Admin Read All
CREATE POLICY "Storage: Read personal documents"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'documents'
        AND (
            (storage.foldername(name))[1] = auth.uid()::text
            OR public.is_admin()
        )
    );

