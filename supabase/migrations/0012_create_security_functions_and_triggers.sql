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
