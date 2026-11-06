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
