-- ============================================================================
-- MedPrepOS — PRODUCTION DATABASE DDL & SCHEMA SPECIFICATION
-- ============================================================================
-- Architecture: PostgreSQL 15+ (Supabase)
-- Specification: MedPrepOS Finalized Product Overview & Engineering Spec v3.0
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

-- Exam tracks supported by MedPrepOS (NEET-UG and IMAT only)
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
