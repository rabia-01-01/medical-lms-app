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
