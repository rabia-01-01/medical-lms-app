-- ============================================================================
-- MedPrep — PRODUCTION DATABASE DDL & SCHEMA SPECIFICATION
-- ============================================================================
-- Architecture: PostgreSQL 15+ (Supabase)
-- Specification: MedPrep Finalized Product Overview & Engineering Spec v3.0
-- Scope: Dual-Track NEET-UG & IMAT Learning Management & Assessment Platform
-- Multi-Tenancy: Platform + Coaching Institutions + Independent Aspirants
-- Security: Server-Authoritative Scoring, Role-Based Access Control, Supabase RLS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. EXTENSIONS & PREREQUISITES
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. CUSTOM ENUMS & DATA DICTIONARY DOMAIN CONSTRAINTS
-- ----------------------------------------------------------------------------

-- Exam tracks supported by MedPrep (NEET-UG and IMAT only)
DO $$ BEGIN
    CREATE TYPE exam_track_code AS ENUM ('NEET_UG', 'IMAT');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Exam version status lifecycle
DO $$ BEGIN
    CREATE TYPE exam_version_status AS ENUM ('DRAFT', 'UNDER_REVIEW', 'VERIFIED', 'PUBLISHED', 'RETIRED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Platform-level governance roles
DO $$ BEGIN
    CREATE TYPE platform_role_type AS ENUM ('PLATFORM_ADMIN', 'ACADEMIC_REVIEWER', 'AUDITOR');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Institution membership roles (RBAC)
DO $$ BEGIN
    CREATE TYPE institution_role AS ENUM ('INSTITUTE_ADMIN', 'FACULTY', 'STUDENT');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Membership & account status
DO $$ BEGIN
    CREATE TYPE account_status AS ENUM ('ACTIVE', 'SUSPENDED', 'PENDING', 'ARCHIVED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Learner exam access source
DO $$ BEGIN
    CREATE TYPE access_source_type AS ENUM ('PERSONAL', 'INSTITUTION', 'PROMOTIONAL');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Student enrollment status in batches
DO $$ BEGIN
    CREATE TYPE enrollment_status AS ENUM ('ACTIVE', 'TRANSFERRED', 'WITHDRAWN', 'COMPLETED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Faculty assignment status
DO $$ BEGIN
    CREATE TYPE assignment_status AS ENUM ('ACTIVE', 'INACTIVE');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Content ownership scope (Platform-wide shared vs. Institution-private)
DO $$ BEGIN
    CREATE TYPE content_scope AS ENUM ('PLATFORM', 'INSTITUTION');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Syllabus node taxonomy types (dual-track support)
DO $$ BEGIN
    CREATE TYPE syllabus_node_type AS ENUM ('SUBJECT', 'SECTION', 'CHAPTER', 'TOPIC', 'SKILL');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Learning resource types
DO $$ BEGIN
    CREATE TYPE resource_type AS ENUM ('NOTE', 'PDF', 'BOOK_REFERENCE', 'DPP', 'PYQ', 'VIDEO', 'IMAGE', 'LINK');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Resource publication status
DO $$ BEGIN
    CREATE TYPE publication_status AS ENUM ('DRAFT', 'PENDING_REVIEW', 'PUBLISHED', 'ARCHIVED', 'REJECTED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Antivirus file scan status
DO $$ BEGIN
    CREATE TYPE file_scan_status AS ENUM ('PENDING', 'CLEAN', 'INFECTED', 'ERROR');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Question item types
DO $$ BEGIN
    CREATE TYPE question_type AS ENUM ('SINGLE_SELECT_MCQ', 'MULTIPLE_SELECT', 'NUMERICAL', 'ASSERTION_REASON');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Question difficulty calibration
DO $$ BEGIN
    CREATE TYPE difficulty_level AS ENUM ('EASY', 'MEDIUM', 'HARD');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Question review lifecycle status
DO $$ BEGIN
    CREATE TYPE review_status AS ENUM ('DRAFT', 'IN_REVIEW', 'APPROVED', 'REJECTED', 'PUBLISHED', 'ARCHIVED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Official question adjudication outcome (NEET/IMAT challenge resolution)
DO $$ BEGIN
    CREATE TYPE adjudication_type AS ENUM ('STANDARD', 'MULTIPLE_CORRECT', 'ALL_OPTIONS_CORRECT', 'DROPPED_FULL_CREDIT', 'AMBIGUOUS_STEM');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Assessment test category
DO $$ BEGIN
    CREATE TYPE assessment_type AS ENUM ('DPP', 'CHAPTER_TEST', 'SUBJECT_TEST', 'MOCK_TEST', 'REVISION_TEST', 'PYQ_PRACTICE');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Assessment version status
DO $$ BEGIN
    CREATE TYPE assessment_version_status AS ENUM ('DRAFT', 'PUBLISHED', 'CLOSED', 'ARCHIVED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Assessment attempt lifecycle
DO $$ BEGIN
    CREATE TYPE attempt_status AS ENUM ('IN_PROGRESS', 'SUBMITTED', 'TIMED_OUT', 'ABANDONED', 'SCORED', 'RESULT_RELEASED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Individual question response status in assessment
DO $$ BEGIN
    CREATE TYPE answer_status AS ENUM ('ANSWERED', 'UNANSWERED', 'MARKED_FOR_REVIEW');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Topic mastery progress status
DO $$ BEGIN
    CREATE TYPE progress_status AS ENUM ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Notification channel
DO $$ BEGIN
    CREATE TYPE notification_channel AS ENUM ('IN_APP', 'EMAIL', 'SMS');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- AI generation job status
DO $$ BEGIN
    CREATE TYPE ai_job_status AS ENUM ('QUEUED', 'PROCESSING', 'COMPLETED', 'FAILED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- AI draft validation status
DO $$ BEGIN
    CREATE TYPE ai_validation_status AS ENUM ('PENDING', 'PASSED', 'FAILED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- AI draft faculty review status
DO $$ BEGIN
    CREATE TYPE ai_review_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'EDITED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Verification document categories
DO $$ BEGIN
    CREATE TYPE document_category AS ENUM ('IDENTITY', 'ACADEMIC', 'MEDICAL', 'FINANCIAL');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Document verification status
DO $$ BEGIN
    CREATE TYPE document_status AS ENUM ('PENDING', 'VERIFIED', 'REJECTED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ----------------------------------------------------------------------------

-- 2. IDENTITY, PROFILES & MULTI-TENANT INSTITUTION ACCESS (Section 10.2)
-- ----------------------------------------------------------------------------

-- 2.1 Profiles (1:1 with Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT NULL,
    avatar_path TEXT NULL,
    preferred_interface_language TEXT NOT NULL DEFAULT 'en',
    status account_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 2.2 Institutions (Multi-tenant Coaching Institutes & Academies)
CREATE TABLE IF NOT EXISTS public.institutions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    status account_status NOT NULL DEFAULT 'ACTIVE',
    timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata',
    settings_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 2.3 Institution Memberships (Trusted Server-Side RBAC; Never User Metadata)
CREATE TABLE IF NOT EXISTS public.institution_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role institution_role NOT NULL DEFAULT 'STUDENT',
    status account_status NOT NULL DEFAULT 'ACTIVE',
    invited_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_profile_institution_role UNIQUE (institution_id, profile_id, role)
);

-- 2.4 Invitations (Tenant Onboarding Queue)
CREATE TABLE IF NOT EXISTS public.invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role institution_role NOT NULL DEFAULT 'STUDENT',
    token TEXT NOT NULL UNIQUE,
    invited_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'PENDING', -- PENDING, ACCEPTED, EXPIRED, REVOKED
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 2.5 Platform Roles (High-Security Global Governance)
CREATE TABLE IF NOT EXISTS public.platform_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role platform_role_type NOT NULL,
    granted_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_profile_platform_role UNIQUE (profile_id, role)
);

-- ----------------------------------------------------------------------------

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

-- 4. LEARNER EXAM ACCESS & ACADEMIC STRUCTURE (Section 10.2, 10.4)
-- ----------------------------------------------------------------------------

-- 4.1 Learner Exam Access (Personal & Institutional Track Entitlements)
CREATE TABLE IF NOT EXISTS public.learner_exam_access (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    exam_track_id UUID NOT NULL REFERENCES public.exam_tracks(id) ON DELETE RESTRICT,
    exam_version_id UUID REFERENCES public.exam_versions(id) ON DELETE SET NULL,
    access_source access_source_type NOT NULL DEFAULT 'PERSONAL',
    institution_id UUID REFERENCES public.institutions(id) ON DELETE CASCADE,
    status account_status NOT NULL DEFAULT 'ACTIVE',
    valid_from TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    valid_until TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_learner_track_institution UNIQUE (profile_id, exam_track_id, institution_id)
);

-- 4.2 Academic Years
CREATE TABLE IF NOT EXISTS public.academic_years (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
    name TEXT NOT NULL, -- e.g. '2026-2027'
    starts_on DATE NOT NULL,
    ends_on DATE NOT NULL,
    status account_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT check_academic_year_range CHECK (ends_on > starts_on)
);

-- 4.3 Courses (Programs linked to specific Exam Track & Version)
CREATE TABLE IF NOT EXISTS public.courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
    exam_track_id UUID NOT NULL REFERENCES public.exam_tracks(id) ON DELETE RESTRICT,
    exam_version_id UUID REFERENCES public.exam_versions(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    description TEXT NULL,
    status account_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_course_code_per_institution UNIQUE (institution_id, code)
);

-- 4.4 Batches (Cohorts under Courses)
CREATE TABLE IF NOT EXISTS public.batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    institution_id UUID NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    starts_on DATE NOT NULL,
    ends_on DATE NOT NULL,
    capacity INTEGER NULL CHECK (capacity IS NULL OR capacity > 0),
    status account_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT check_batch_dates CHECK (ends_on >= starts_on)
);

-- 4.5 Student Enrollments (Tracks batch enrollment with transfer/withdrawal audit)
CREATE TABLE IF NOT EXISTS public.student_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES public.batches(id) ON DELETE CASCADE,
    status enrollment_status NOT NULL DEFAULT 'ACTIVE',
    starts_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    ends_at TIMESTAMPTZ NULL,
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- Index active batch enrollment per student
CREATE UNIQUE INDEX IF NOT EXISTS idx_student_single_active_batch
    ON public.student_enrollments(profile_id, batch_id)
    WHERE status = 'ACTIVE';

-- 4.6 Faculty Assignments
CREATE TABLE IF NOT EXISTS public.faculty_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES public.batches(id) ON DELETE CASCADE,
    subject_code TEXT NOT NULL,
    status assignment_status NOT NULL DEFAULT 'ACTIVE',
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    revoked_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- ----------------------------------------------------------------------------

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

-- 11. INDEXING STRATEGY FOR HIGH-TRAFFIC QUERY PATHS (Section 10.5)
-- ----------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_learner_exam_access_profile
    ON public.learner_exam_access(profile_id, status, exam_track_id);

CREATE INDEX IF NOT EXISTS idx_exam_versions_track_year
    ON public.exam_versions(exam_track_id, exam_year, status);

CREATE INDEX IF NOT EXISTS idx_syllabus_nodes_parent
    ON public.syllabus_nodes(syllabus_version_id, parent_node_id, display_order);

CREATE INDEX IF NOT EXISTS idx_resources_exam_status
    ON public.resources(exam_version_id, status);

CREATE INDEX IF NOT EXISTS idx_questions_exam_status
    ON public.question_versions(exam_version_id, review_status);

CREATE INDEX IF NOT EXISTS idx_attempts_profile_started
    ON public.assessment_attempts(profile_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_attempt_answers_attempt
    ON public.attempt_answers(attempt_id);

CREATE INDEX IF NOT EXISTS idx_audit_institution_created
    ON public.audit_logs(institution_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_enrollments_profile_batch
    ON public.student_enrollments(profile_id, batch_id, status);

CREATE INDEX IF NOT EXISTS idx_memberships_profile_inst
    ON public.institution_memberships(profile_id, institution_id, status);

-- ----------------------------------------------------------------------------

-- 12. SECURITY HELPER FUNCTIONS & TRIGGERS (Section 7.4)
-- ----------------------------------------------------------------------------

-- Helper: Check if caller possesses Platform Admin privileges
CREATE OR REPLACE FUNCTION public.is_platform_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.platform_roles
        WHERE profile_id = auth.uid()
          AND role = 'PLATFORM_ADMIN'
    );
$$;

-- Helper: Check if caller is Institute Admin in a specific institution
CREATE OR REPLACE FUNCTION public.is_institute_admin(inst_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT public.is_platform_admin() OR EXISTS (
        SELECT 1 FROM public.institution_memberships
        WHERE profile_id = auth.uid()
          AND institution_id = inst_id
          AND role = 'INSTITUTE_ADMIN'
          AND status = 'ACTIVE'
    );
$$;

-- Helper: Check if caller is Faculty in a specific institution
CREATE OR REPLACE FUNCTION public.is_faculty(inst_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT public.is_institute_admin(inst_id) OR EXISTS (
        SELECT 1 FROM public.institution_memberships
        WHERE profile_id = auth.uid()
          AND institution_id = inst_id
          AND role = 'FACULTY'
          AND status = 'ACTIVE'
    );
$$;

-- Helper: Check student active enrollment in a specific batch
CREATE OR REPLACE FUNCTION public.is_student_in_batch(b_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.student_enrollments
        WHERE profile_id = auth.uid()
          AND batch_id = b_id
          AND status = 'ACTIVE'
    );
$$;

-- Helper: Check active track access entitlement
CREATE OR REPLACE FUNCTION public.has_exam_track_access(track_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.learner_exam_access
        WHERE profile_id = auth.uid()
          AND exam_track_id = track_id
          AND status = 'ACTIVE'
    );
$$;

-- Trigger: Automatically update 'updated_at' column
CREATE OR REPLACE FUNCTION public.set_current_timestamp_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = timezone('utc', now());
    RETURN NEW;
END;
$$;

-- Trigger: Automated User Provisioning from Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user_provisioning()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, avatar_path, status)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'MedPrep Candidate'),
        NEW.raw_user_meta_data->>'avatar_url',
        'ACTIVE'
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        updated_at = timezone('utc', now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_provisioning();

-- ----------------------------------------------------------------------------

-- 13. ROW LEVEL SECURITY (RLS) POLICIES (Section 7.4)
-- ----------------------------------------------------------------------------

-- Enable RLS across all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.institutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.institution_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_scoring_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_language_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_source_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_configuration_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learner_exam_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faculty_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.syllabus_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.syllabus_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.syllabus_node_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_topic_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_plan_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resource_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resource_eligibility ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resource_revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_answer_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_syllabus_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_adjudications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_eligibility ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempt_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempt_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.score_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regrade_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_generation_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_generation_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_reference_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_event_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discussion_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discussion_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderation_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- 13.1 Profiles RLS
CREATE POLICY "Profiles: Users read own profile or staff view"
    ON public.profiles FOR SELECT
    USING (id = auth.uid() OR public.is_platform_admin());

CREATE POLICY "Profiles: Users update own profile"
    ON public.profiles FOR UPDATE
    USING (id = auth.uid());

-- 13.2 Institution Memberships RLS
CREATE POLICY "Memberships: Read own or institute admins view"
    ON public.institution_memberships FOR SELECT
    USING (
        profile_id = auth.uid()
        OR public.is_institute_admin(institution_id)
    );

CREATE POLICY "Memberships: Institute Admins manage memberships"
    ON public.institution_memberships FOR ALL
    USING (public.is_institute_admin(institution_id));

-- 13.3 Public Exam Tracks & Curriculums
CREATE POLICY "ExamTracks: Authenticated read active tracks"
    ON public.exam_tracks FOR SELECT
    USING (status = 'ACTIVE' OR public.is_platform_admin());

CREATE POLICY "ExamVersions: Read published versions"
    ON public.exam_versions FOR SELECT
    USING (status = 'PUBLISHED' OR public.is_platform_admin());

CREATE POLICY "SyllabusNodes: Read published syllabus nodes"
    ON public.syllabus_nodes FOR SELECT
    USING (is_active = true OR public.is_platform_admin());

-- 13.4 Question Answer Keys Isolation (STRICT NON-STUDENT ACCESS)
CREATE POLICY "AnswerKeys: Non-students and service role only"
    ON public.question_answer_keys FOR SELECT
    USING (public.is_platform_admin());

-- 13.5 Assessment Attempts & Answers Isolation
CREATE POLICY "Attempts: Students manage own attempts"
    ON public.assessment_attempts FOR SELECT
    USING (
        profile_id = auth.uid()
        OR (institution_id IS NOT NULL AND public.is_faculty(institution_id))
    );

CREATE POLICY "Attempts: Students start attempts"
    ON public.assessment_attempts FOR INSERT
    WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Answers: Students read and update own answers while in progress"
    ON public.attempt_answers FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.assessment_attempts a
            WHERE a.id = attempt_id
              AND a.profile_id = auth.uid()
              AND (a.status = 'IN_PROGRESS' OR a.status = 'RESULT_RELEASED')
        )
    );

-- 13.6 Score Results
CREATE POLICY "ScoreResults: Read released results"
    ON public.score_results FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.assessment_attempts a
            WHERE a.id = attempt_id
              AND (
                  (a.profile_id = auth.uid() AND a.status = 'RESULT_RELEASED')
                  OR (a.institution_id IS NOT NULL AND public.is_faculty(a.institution_id))
              )
        )
    );

-- 13.7 Student Progress
CREATE POLICY "Progress: Read and write own progress"
    ON public.student_topic_progress FOR ALL
    USING (profile_id = auth.uid());

-- ----------------------------------------------------------------------------

-- 14. PRIVATE STORAGE BUCKETS & STORAGE RLS POLICIES (Section 8.2)
-- ----------------------------------------------------------------------------

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('resources', 'resources', false, 104857600, ARRAY['application/pdf', 'video/mp4', 'image/jpeg', 'image/png', 'image/webp', 'text/plain']),
    ('documents', 'documents', false, 20971520, ARRAY['application/pdf', 'image/jpeg', 'image/png']),
    ('questions', 'questions', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml'])
ON CONFLICT (id) DO UPDATE SET
    public = false;

CREATE POLICY "Storage: Authenticated read authorized resources"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'resources'
        AND auth.role() = 'authenticated'
    );

CREATE POLICY "Storage: Authenticated upload verification documents"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'documents'
        AND auth.role() = 'authenticated'
    );

-- ----------------------------------------------------------------------------

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


-- ============================================================================
-- 16. CORE APPLICATION PROCEDURAL RPC FUNCTIONS & STORED PROCEDURES
-- ============================================================================

-- 16.1 Closure Table Maintenance Trigger for Syllabus Nodes
CREATE OR REPLACE FUNCTION public.fn_trg_syllabus_node_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Self-referential path at depth 0
    INSERT INTO public.syllabus_node_relationships (ancestor_id, descendant_id, depth)
    VALUES (NEW.id, NEW.id, 0);

    -- Copy all ancestor paths and increment depth
    IF NEW.parent_node_id IS NOT NULL THEN
        INSERT INTO public.syllabus_node_relationships (ancestor_id, descendant_id, depth)
        SELECT r.ancestor_id, NEW.id, r.depth + 1
        FROM public.syllabus_node_relationships r
        WHERE r.descendant_id = NEW.parent_node_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_syllabus_nodes_closure ON public.syllabus_nodes;
CREATE TRIGGER trg_syllabus_nodes_closure
AFTER INSERT ON public.syllabus_nodes
FOR EACH ROW
EXECUTE FUNCTION public.fn_trg_syllabus_node_insert();

-- 16.2 Procedure: Start Assessment Attempt (Authoritative Deadline & Gating)
CREATE OR REPLACE FUNCTION public.fn_start_assessment_attempt(
    p_assessment_version_id UUID,
    p_profile_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_attempt_id UUID;
    v_duration_seconds INT;
    v_exam_track_id UUID;
    v_has_access BOOLEAN;
    v_existing_id UUID;
    v_attempt_count INT;
    v_attempt_limit INT;
BEGIN
    -- Check if learner already has an active in-progress attempt
    SELECT id INTO v_existing_id
    FROM public.assessment_attempts
    WHERE assessment_version_id = p_assessment_version_id
      AND profile_id = p_profile_id
      AND status = 'IN_PROGRESS'
      AND deadline_at > timezone('utc', now());

    IF v_existing_id IS NOT NULL THEN
        RETURN v_existing_id;
    END IF;

    -- Lookup duration, exam track, and attempt limits
    SELECT av.duration_seconds, av.attempt_limit, a.exam_track_id
    INTO v_duration_seconds, v_attempt_limit, v_exam_track_id
    FROM public.assessment_versions av
    JOIN public.assessments a ON av.assessment_id = a.id
    WHERE av.id = p_assessment_version_id
      AND av.status = 'PUBLISHED';

    IF v_duration_seconds IS NULL THEN
        RAISE EXCEPTION 'Assessment version not found or not published.';
    END IF;

    -- Verify attempt count against attempt limit
    SELECT COUNT(*) INTO v_attempt_count
    FROM public.assessment_attempts
    WHERE assessment_version_id = p_assessment_version_id
      AND profile_id = p_profile_id;

    IF v_attempt_count >= v_attempt_limit THEN
        RAISE EXCEPTION 'Maximum attempt limit (%) reached for this assessment.', v_attempt_limit;
    END IF;

    -- Verify learner exam track entitlement
    SELECT EXISTS (
        SELECT 1 FROM public.learner_exam_access
        WHERE profile_id = p_profile_id
          AND exam_track_id = v_exam_track_id
          AND is_active = TRUE
    ) INTO v_has_access;

    IF NOT v_has_access THEN
        RAISE EXCEPTION 'Learner is not enrolled in the required exam track for this assessment.';
    END IF;

    -- Create new authoritative attempt
    INSERT INTO public.assessment_attempts (
        assessment_version_id,
        profile_id,
        attempt_number,
        status,
        started_at,
        deadline_at
    )
    VALUES (
        p_assessment_version_id,
        p_profile_id,
        v_attempt_count + 1,
        'IN_PROGRESS',
        timezone('utc', now()),
        timezone('utc', now()) + (v_duration_seconds * INTERVAL '1 second')
    )
    RETURNING id INTO v_attempt_id;

    -- Audit attempt start event
    INSERT INTO public.attempt_events (attempt_id, event_type, metadata)
    VALUES (v_attempt_id, 'STARTED', jsonb_build_object('duration_seconds', v_duration_seconds, 'attempt_number', v_attempt_count + 1));

    RETURN v_attempt_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 16.3 Procedure: Autosave Attempt Answer (Idempotent & Deadline-Enforced)
CREATE OR REPLACE FUNCTION public.fn_autosave_attempt_answer(
    p_attempt_id UUID,
    p_assessment_question_id UUID,
    p_selected_option_id UUID,
    p_answer_status answer_status DEFAULT 'ANSWERED'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_status attempt_status;
    v_deadline TIMESTAMPTZ;
    v_question_version_id UUID;
BEGIN
    SELECT status, deadline_at
    INTO v_status, v_deadline
    FROM public.assessment_attempts
    WHERE id = p_attempt_id;

    IF v_status IS NULL THEN
        RAISE EXCEPTION 'Attempt not found.';
    END IF;

    IF v_status != 'IN_PROGRESS' THEN
        RAISE EXCEPTION 'Cannot save answer: attempt is in % state.', v_status;
    END IF;

    -- Enforce server deadline (with 30-second network latency grace buffer)
    IF timezone('utc', now()) > (v_deadline + INTERVAL '30 seconds') THEN
        UPDATE public.assessment_attempts
        SET status = 'TIMED_OUT', finalized_at = timezone('utc', now())
        WHERE id = p_attempt_id;
        RAISE EXCEPTION 'Assessment time has expired. Submission rejected.';
    END IF;

    -- Resolve question_version_id from assessment_question
    SELECT question_version_id INTO v_question_version_id
    FROM public.assessment_questions
    WHERE id = p_assessment_question_id;

    IF v_question_version_id IS NULL THEN
        RAISE EXCEPTION 'Assessment question not found.';
    END IF;

    -- Upsert response
    INSERT INTO public.attempt_answers (
        attempt_id,
        assessment_question_id,
        question_version_id,
        selected_option_id,
        answer_status,
        saved_at
    )
    VALUES (
        p_attempt_id,
        p_assessment_question_id,
        v_question_version_id,
        p_selected_option_id,
        p_answer_status,
        timezone('utc', now())
    )
    ON CONFLICT (attempt_id, assessment_question_id) DO UPDATE SET
        selected_option_id = EXCLUDED.selected_option_id,
        answer_status = EXCLUDED.answer_status,
        saved_at = timezone('utc', now());

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 16.4 Authoritative Scoring Engine Procedure (Dual-Track NEET-UG & IMAT)
CREATE OR REPLACE FUNCTION public.fn_finalize_and_score_attempt(
    p_attempt_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_attempt RECORD;
    v_policy RECORD;
    v_track_code exam_track_code;
    v_ans RECORD;
    v_adj RECORD;
    v_correct_marks NUMERIC(5,2);
    v_incorrect_marks NUMERIC(5,2);
    v_unanswered_marks NUMERIC(5,2);
    v_marks NUMERIC(5,2);
    v_is_correct BOOLEAN;
    v_total_raw_score NUMERIC(6,2) := 0.00;
    v_correct_count INT := 0;
    v_incorrect_count INT := 0;
    v_unanswered_count INT := 0;
    v_section_breakdown JSONB := '{}'::jsonb;
    v_sec_record RECORD;
    v_score_result_id UUID;
BEGIN
    -- 1. Fetch attempt and lock row
    SELECT a.*, av.scoring_policy_id, t.code as track_code
    INTO v_attempt
    FROM public.assessment_attempts a
    JOIN public.assessment_versions av ON a.assessment_version_id = av.id
    JOIN public.assessments asm ON av.assessment_id = asm.id
    JOIN public.exam_tracks t ON asm.exam_track_id = t.id
    WHERE a.id = p_attempt_id
    FOR UPDATE;

    IF v_attempt.id IS NULL THEN
        RAISE EXCEPTION 'Attempt not found.';
    END IF;

    IF v_attempt.status IN ('SUBMITTED', 'EVALUATED') THEN
        SELECT id INTO v_score_result_id FROM public.score_results WHERE attempt_id = p_attempt_id;
        RETURN v_score_result_id;
    END IF;

    -- 2. Lookup Scoring Policy
    SELECT * INTO v_policy
    FROM public.exam_scoring_policies
    WHERE id = v_attempt.scoring_policy_id;

    IF v_policy.id IS NULL THEN
        RAISE EXCEPTION 'Scoring policy not found for assessment.';
    END IF;

    v_correct_marks := v_policy.correct_marks;
    v_incorrect_marks := v_policy.incorrect_marks;
    v_unanswered_marks := v_policy.unanswered_marks;

    -- 3. Evaluate each answer
    FOR v_ans IN
        SELECT 
            aq.id as assessment_question_id,
            aq.section_id,
            sec.name as section_name,
            sec.code as section_code,
            aq.question_version_id,
            aa.selected_option_id,
            aa.answer_status,
            k.accepted_option_ids,
            k.resolution_type
        FROM public.assessment_questions aq
        JOIN public.assessment_sections sec ON aq.section_id = sec.id
        LEFT JOIN public.attempt_answers aa ON aa.attempt_id = p_attempt_id AND aa.assessment_question_id = aq.id
        LEFT JOIN public.question_answer_keys k ON aq.question_version_id = k.question_version_id
        WHERE aq.assessment_version_id = v_attempt.assessment_version_id
    LOOP
        -- Check question adjudication overrides (Official NTA / MUR corrections)
        SELECT * INTO v_adj
        FROM public.question_adjudications
        WHERE question_version_id = v_ans.question_version_id;

        v_marks := 0.00;
        v_is_correct := FALSE;

        -- CASE A: Question Dropped / Invalid (NEET-UG NTA Rule: Full marks to all candidates)
        IF (v_adj.id IS NOT NULL AND v_adj.adjudication_type = 'INVALID_OR_DROPPED') OR v_ans.resolution_type = 'INVALID_OR_DROPPED' THEN
            v_marks := v_correct_marks;
            v_is_correct := TRUE;
            v_correct_count := v_correct_count + 1;

        -- CASE B: All Options Correct (NTA Rule: Full marks to anyone who attempted)
        ELSIF (v_adj.id IS NOT NULL AND v_adj.adjudication_type = 'ALL_OPTIONS_CORRECT') OR v_ans.resolution_type = 'ALL_OPTIONS_CORRECT' THEN
            IF v_ans.selected_option_id IS NOT NULL THEN
                v_marks := v_correct_marks;
                v_is_correct := TRUE;
                v_correct_count := v_correct_count + 1;
            ELSE
                v_marks := v_unanswered_marks;
                v_unanswered_count := v_unanswered_count + 1;
            END IF;

        -- CASE C: Multiple Options Correct
        ELSIF (v_adj.id IS NOT NULL AND v_adj.adjudication_type = 'MULTIPLE_CORRECT') OR v_ans.resolution_type = 'MULTIPLE_CORRECT' THEN
            IF v_ans.selected_option_id IS NULL THEN
                v_marks := v_unanswered_marks;
                v_unanswered_count := v_unanswered_count + 1;
            ELSIF v_ans.selected_option_id = ANY(COALESCE(v_adj.valid_option_ids, v_ans.accepted_option_ids)) THEN
                v_marks := v_correct_marks;
                v_is_correct := TRUE;
                v_correct_count := v_correct_count + 1;
            ELSE
                v_marks := v_incorrect_marks;
                v_incorrect_count := v_incorrect_count + 1;
            END IF;

        -- CASE D: Standard Single Correct
        ELSE
            IF v_ans.selected_option_id IS NULL THEN
                v_marks := v_unanswered_marks;
                v_unanswered_count := v_unanswered_count + 1;
            ELSIF v_ans.selected_option_id = ANY(v_ans.accepted_option_ids) THEN
                v_marks := v_correct_marks;
                v_is_correct := TRUE;
                v_correct_count := v_correct_count + 1;
            ELSE
                v_marks := v_incorrect_marks;
                v_incorrect_count := v_incorrect_count + 1;
            END IF;
        END IF;

        v_total_raw_score := v_total_raw_score + v_marks;

        -- Update or insert answer evaluation
        IF v_ans.selected_option_id IS NOT NULL THEN
            UPDATE public.attempt_answers
            SET evaluated_is_correct = v_is_correct,
                marks_awarded = v_marks
            WHERE attempt_id = p_attempt_id AND assessment_question_id = v_ans.assessment_question_id;
        END IF;
    END LOOP;

    -- 4. Aggregate Section Breakdown
    FOR v_sec_record IN
        SELECT 
            sec.code as section_code,
            sec.name as section_name,
            COUNT(aq.id) as total_questions,
            COUNT(aa.id) FILTER (WHERE aa.evaluated_is_correct = TRUE) as correct_count,
            COUNT(aa.id) FILTER (WHERE aa.evaluated_is_correct = FALSE AND aa.selected_option_id IS NOT NULL) as incorrect_count,
            COUNT(aq.id) - COUNT(aa.selected_option_id) as unanswered_count,
            COALESCE(SUM(aa.marks_awarded), 0.00) as section_score
        FROM public.assessment_sections sec
        JOIN public.assessment_questions aq ON aq.section_id = sec.id
        LEFT JOIN public.attempt_answers aa ON aa.attempt_id = p_attempt_id AND aa.assessment_question_id = aq.id
        WHERE sec.assessment_version_id = v_attempt.assessment_version_id
        GROUP BY sec.code, sec.name
    LOOP
        v_section_breakdown := v_section_breakdown || jsonb_build_object(
            v_sec_record.section_code,
            jsonb_build_object(
                'name', v_sec_record.section_name,
                'total_questions', v_sec_record.total_questions,
                'correct_count', v_sec_record.correct_count,
                'incorrect_count', v_sec_record.incorrect_count,
                'unanswered_count', v_sec_record.unanswered_count,
                'score', v_sec_record.section_score
            )
        );
    END LOOP;

    -- 5. Insert Score Results
    INSERT INTO public.score_results (
        attempt_id,
        scoring_policy_id,
        raw_score,
        maximum_raw_score,
        percentage_of_maximum,
        correct_count,
        incorrect_count,
        unanswered_count,
        section_breakdown_json,
        finalized_at
    )
    VALUES (
        p_attempt_id,
        v_policy.id,
        v_total_raw_score,
        v_policy.maximum_raw_score,
        CASE WHEN v_policy.maximum_raw_score > 0 THEN ROUND((v_total_raw_score / v_policy.maximum_raw_score) * 100, 2) ELSE 0 END,
        v_correct_count,
        v_incorrect_count,
        v_unanswered_count,
        v_section_breakdown,
        timezone('utc', now())
    )
    RETURNING id INTO v_score_result_id;

    -- 6. Finalize Attempt Status
    UPDATE public.assessment_attempts
    SET status = 'EVALUATED',
        submitted_at = COALESCE(submitted_at, timezone('utc', now())),
        finalized_at = timezone('utc', now())
    WHERE id = p_attempt_id;

    -- 7. Audit Event
    INSERT INTO public.attempt_events (attempt_id, event_type, metadata)
    VALUES (p_attempt_id, 'SUBMITTED_AND_SCORED', jsonb_build_object('raw_score', v_total_raw_score, 'result_id', v_score_result_id));

    RETURN v_score_result_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- 17. PRODUCTION ANALYTICAL & BUSINESS REPORTING VIEWS
-- ============================================================================

-- 17.1 View: Student Performance & Progression Analytics
CREATE OR REPLACE VIEW public.view_student_exam_analytics AS
SELECT 
    p.id as profile_id,
    p.full_name,
    t.code as exam_track_code,
    t.display_name as exam_track_name,
    COUNT(a.id) as total_tests_attempted,
    ROUND(AVG(sr.raw_score), 2) as average_raw_score,
    MAX(sr.raw_score) as highest_raw_score,
    ROUND(AVG(sr.percentage_of_maximum), 2) as average_percentage,
    SUM(sr.correct_count) as total_correct_answers,
    SUM(sr.incorrect_count) as total_incorrect_answers,
    SUM(sr.unanswered_count) as total_unanswered_questions,
    CASE 
        WHEN (SUM(sr.correct_count) + SUM(sr.incorrect_count)) > 0 
        THEN ROUND((SUM(sr.correct_count)::numeric / (SUM(sr.correct_count) + SUM(sr.incorrect_count))) * 100, 2)
        ELSE 0.00 
    END as overall_accuracy_percentage
FROM public.profiles p
JOIN public.assessment_attempts a ON a.profile_id = p.id
JOIN public.score_results sr ON sr.attempt_id = a.id
JOIN public.assessment_versions av ON a.assessment_version_id = av.id
JOIN public.assessments asm ON av.assessment_id = asm.id
JOIN public.exam_tracks t ON asm.exam_track_id = t.id
WHERE a.status = 'EVALUATED'
GROUP BY p.id, p.full_name, t.code, t.display_name;

-- 17.2 View: Student Subject & Section Mastery Radar
CREATE OR REPLACE VIEW public.view_student_subject_accuracy AS
SELECT 
    a.profile_id,
    t.code as exam_track_code,
    sec.code as section_code,
    sec.name as section_name,
    COUNT(aq.id) as questions_attempted,
    COUNT(aa.id) FILTER (WHERE aa.evaluated_is_correct = TRUE) as correct_count,
    COUNT(aa.id) FILTER (WHERE aa.evaluated_is_correct = FALSE AND aa.selected_option_id IS NOT NULL) as incorrect_count,
    CASE 
        WHEN COUNT(aa.selected_option_id) > 0 
        THEN ROUND((COUNT(aa.id) FILTER (WHERE aa.evaluated_is_correct = TRUE)::numeric / COUNT(aa.selected_option_id)) * 100, 2)
        ELSE 0.00
    END as accuracy_percentage,
    CASE 
        WHEN COUNT(aa.selected_option_id) >= 15 THEN 'CONFIDENT'
        WHEN COUNT(aa.selected_option_id) >= 5 THEN 'EMERGING'
        ELSE 'LOW_SAMPLE'
    END as confidence_calibration
FROM public.assessment_attempts a
JOIN public.assessment_versions av ON a.assessment_version_id = av.id
JOIN public.assessments asm ON av.assessment_id = asm.id
JOIN public.exam_tracks t ON asm.exam_track_id = t.id
JOIN public.assessment_questions aq ON aq.assessment_version_id = av.id
JOIN public.assessment_sections sec ON aq.section_id = sec.id
LEFT JOIN public.attempt_answers aa ON aa.attempt_id = a.id AND aa.assessment_question_id = aq.id
WHERE a.status = 'EVALUATED'
GROUP BY a.profile_id, t.code, sec.code, sec.name;

-- 17.3 View: Topic-Level Revision Recommendations (Section 4.15 Safeguards)
CREATE OR REPLACE VIEW public.view_topic_revision_recommendations AS
SELECT 
    a.profile_id,
    t.code as exam_track_code,
    sn.id as syllabus_node_id,
    sn.name as topic_name,
    COUNT(aa.id) as questions_attempted,
    COUNT(aa.id) FILTER (WHERE aa.evaluated_is_correct = TRUE) as correct_count,
    ROUND((COUNT(aa.id) FILTER (WHERE aa.evaluated_is_correct = TRUE)::numeric / COUNT(aa.id)) * 100, 2) as accuracy_percentage,
    CASE 
        WHEN COUNT(aa.id) >= 5 AND (COUNT(aa.id) FILTER (WHERE aa.evaluated_is_correct = TRUE)::numeric / COUNT(aa.id)) < 0.60
        THEN 'URGENT_REVISION'
        WHEN COUNT(aa.id) >= 5 AND (COUNT(aa.id) FILTER (WHERE aa.evaluated_is_correct = TRUE)::numeric / COUNT(aa.id)) < 0.75
        THEN 'RECOMMENDED_PRACTICE'
        ELSE 'MASTERY_RETAINED'
    END as recommendation_status,
    'Accuracy is ' || ROUND((COUNT(aa.id) FILTER (WHERE aa.evaluated_is_correct = TRUE)::numeric / COUNT(aa.id)) * 100, 1) || '% across ' || COUNT(aa.id) || ' questions.' as diagnostic_rationale
FROM public.assessment_attempts a
JOIN public.assessment_versions av ON a.assessment_version_id = av.id
JOIN public.assessments asm ON av.assessment_id = asm.id
JOIN public.exam_tracks t ON asm.exam_track_id = t.id
JOIN public.attempt_answers aa ON aa.attempt_id = a.id
JOIN public.question_syllabus_mappings qsm ON aa.question_version_id = qsm.question_version_id
JOIN public.syllabus_nodes sn ON qsm.syllabus_node_id = sn.id
WHERE a.status = 'EVALUATED' AND aa.selected_option_id IS NOT NULL
GROUP BY a.profile_id, t.code, sn.id, sn.name
HAVING COUNT(aa.id) >= 5;

-- 17.4 View: Full Recursive Syllabus Hierarchy Explorer
CREATE OR REPLACE VIEW public.view_syllabus_hierarchy AS
WITH RECURSIVE node_tree AS (
    SELECT 
        sn.id,
        sn.syllabus_version_id,
        sn.parent_node_id,
        sn.node_type,
        sn.code,
        sn.name,
        sn.display_order,
        1 as depth,
        sn.name::text as hierarchy_path
    FROM public.syllabus_nodes sn
    WHERE sn.parent_node_id IS NULL
    UNION ALL
    SELECT 
        child.id,
        child.syllabus_version_id,
        child.parent_node_id,
        child.node_type,
        child.code,
        child.name,
        child.display_order,
        parent.depth + 1,
        parent.hierarchy_path || ' > ' || child.name
    FROM public.syllabus_nodes child
    JOIN node_tree parent ON child.parent_node_id = parent.id
)
SELECT * FROM node_tree
ORDER BY syllabus_version_id, depth, display_order;

-- 17.5 View: Faculty Question Review Queue
CREATE OR REPLACE VIEW public.view_faculty_question_review_queue AS
SELECT 
    qv.id as question_version_id,
    q.id as question_id,
    q.code as question_code,
    t.code as exam_track_code,
    sec.name as section_name,
    qv.version_number,
    qv.question_type,
    qv.difficulty,
    qv.stem,
    qv.review_status,
    creator.full_name as created_by_name,
    qv.created_at,
    (SELECT COUNT(*) FROM public.question_options qo WHERE qo.question_version_id = qv.id) as option_count
FROM public.question_versions qv
JOIN public.questions q ON qv.question_id = q.id
JOIN public.exam_versions ev ON qv.exam_version_id = ev.id
JOIN public.exam_tracks t ON ev.exam_track_id = t.id
JOIN public.exam_sections sec ON qv.section_id = sec.id
LEFT JOIN public.profiles creator ON qv.created_by = creator.id
WHERE qv.review_status = 'IN_REVIEW'
ORDER BY qv.created_at ASC;


-- ============================================================================
-- 18. CORE API PARAMETERIZED SQL QUERIES (REPOSITORY CATALOG)
-- ============================================================================

-- Query 18.1: Fetch Learner Profile & Dual-Track Entitlements (GET /api/v1/me)
-- Param: $1 = profile_id (from verified Supabase JWT)
-- SELECT 
--     p.id, p.email, p.full_name, p.account_status,
--     COALESCE(
--         jsonb_agg(
--             jsonb_build_object(
--                 'track_code', t.code,
--                 'display_name', t.display_name,
--                 'version_id', ev.id,
--                 'academic_cycle', ev.academic_cycle,
--                 'source_type', lea.source_type
--             )
--         ) FILTER (WHERE lea.id IS NOT NULL), '[]'::jsonb
--     ) as active_tracks
-- FROM public.profiles p
-- LEFT JOIN public.learner_exam_access lea ON lea.profile_id = p.id AND lea.is_active = TRUE
-- LEFT JOIN public.exam_tracks t ON lea.exam_track_id = t.id
-- LEFT JOIN public.exam_versions ev ON lea.exam_version_id = ev.id
-- WHERE p.id = $1
-- GROUP BY p.id;

-- Query 18.2: Fetch Exam Blueprint & Sections (GET /api/v1/exam-versions/:versionId)
-- Param: $1 = exam_version_id
-- SELECT 
--     ev.id, ev.exam_year, ev.academic_cycle, ev.version_number, ev.status,
--     t.code as track_code, t.display_name as track_name,
--     sp.correct_marks, sp.incorrect_marks, sp.unanswered_marks, sp.maximum_raw_score,
--     jsonb_agg(
--         jsonb_build_object(
--             'section_code', es.code,
--             'name', es.name,
--             'question_count', es.question_count,
--             'option_count', es.option_count,
--             'display_order', es.display_order
--         ) ORDER BY es.display_order
--     ) as sections
-- FROM public.exam_versions ev
-- JOIN public.exam_tracks t ON ev.exam_track_id = t.id
-- JOIN public.exam_scoring_policies sp ON sp.exam_version_id = ev.id
-- JOIN public.exam_sections es ON es.exam_version_id = ev.id
-- WHERE ev.id = $1
-- GROUP BY ev.id, t.code, t.display_name, sp.correct_marks, sp.incorrect_marks, sp.unanswered_marks, sp.maximum_raw_score;

-- Query 18.3: Safe Question Delivery for Active Attempt (STRICT ZERO ANSWER KEYS)
-- Param: $1 = attempt_id, $2 = profile_id
-- SELECT 
--     aq.id as assessment_question_id,
--     aq.question_order,
--     sec.code as section_code,
--     sec.name as section_name,
--     qv.id as question_version_id,
--     qv.question_type,
--     qv.stem,
--     (
--         SELECT jsonb_agg(
--             jsonb_build_object(
--                 'id', qo.id,
--                 'option_key', qo.option_key,
--                 'option_text', qo.option_text,
--                 'display_order', qo.display_order
--             ) ORDER BY qo.display_order
--         )
--         FROM public.question_options qo
--         WHERE qo.question_version_id = qv.id
--     ) as options,
--     aa.selected_option_id,
--     aa.answer_status
-- FROM public.assessment_attempts a
-- JOIN public.assessment_questions aq ON aq.assessment_version_id = a.assessment_version_id
-- JOIN public.assessment_sections sec ON aq.section_id = sec.id
-- JOIN public.question_versions qv ON aq.question_version_id = qv.id
-- LEFT JOIN public.attempt_answers aa ON aa.attempt_id = a.id AND aa.assessment_question_id = aq.id
-- WHERE a.id = $1 AND a.profile_id = $2 AND a.status = 'IN_PROGRESS'
-- ORDER BY aq.question_order;

-- Query 18.4: Released Score Report with Question Rationales (GET /api/v1/attempts/:attemptId/result)
-- Param: $1 = attempt_id, $2 = profile_id
-- SELECT 
--     sr.id, sr.raw_score, sr.maximum_raw_score, sr.percentage_of_maximum,
--     sr.correct_count, sr.incorrect_count, sr.unanswered_count,
--     sr.section_breakdown_json, sr.finalized_at,
--     jsonb_agg(
--         jsonb_build_object(
--             'question_order', aq.question_order,
--             'stem', qv.stem,
--             'selected_option_id', aa.selected_option_id,
--             'accepted_option_ids', k.accepted_option_ids,
--             'is_correct', aa.evaluated_is_correct,
--             'marks_awarded', aa.marks_awarded,
--             'explanation', qv.explanation
--         ) ORDER BY aq.question_order
--     ) as questions_breakdown
-- FROM public.score_results sr
-- JOIN public.assessment_attempts a ON sr.attempt_id = a.id
-- JOIN public.assessment_questions aq ON aq.assessment_version_id = a.assessment_version_id
-- JOIN public.question_versions qv ON aq.question_version_id = qv.id
-- LEFT JOIN public.attempt_answers aa ON aa.attempt_id = a.id AND aa.assessment_question_id = aq.id
-- LEFT JOIN public.question_answer_keys k ON qv.id = k.question_version_id
-- WHERE sr.attempt_id = $1 AND a.profile_id = $2
-- GROUP BY sr.id, sr.raw_score, sr.maximum_raw_score, sr.percentage_of_maximum, sr.correct_count, sr.incorrect_count, sr.unanswered_count, sr.section_breakdown_json, sr.finalized_at;

-- Query 18.5: Gated Learning Resources for Assigned Batch (GET /api/v1/resources)
-- Param: $1 = exam_version_id, $2 = syllabus_node_id, $3 = profile_id
-- SELECT 
--     r.id, r.title, r.description, r.resource_type, r.published_at,
--     rf.storage_path, rf.file_size_bytes, rf.mime_type
-- FROM public.resources r
-- LEFT JOIN public.resource_files rf ON rf.resource_id = r.id AND rf.is_primary = TRUE
-- WHERE r.exam_version_id = $1 
--   AND r.status = 'PUBLISHED'
--   AND (r.syllabus_node_id = $2 OR $2 IS NULL)
--   AND (
--       r.content_scope = 'PLATFORM'
--       OR EXISTS (
--           SELECT 1 FROM public.student_enrollments se
--           JOIN public.resource_eligibility re ON re.batch_id = se.batch_id
--           WHERE se.profile_id = $3 AND re.resource_id = r.id AND se.status = 'ACTIVE'
--       )
--   )
-- ORDER BY r.display_order ASC;