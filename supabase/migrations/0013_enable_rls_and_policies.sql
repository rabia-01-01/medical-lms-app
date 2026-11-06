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
