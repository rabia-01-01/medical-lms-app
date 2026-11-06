/**
 * MedPrepOS Database Schema Definitions
 * Aligned with PostgreSQL 15+ & Supabase Migrations 0001 - 0014
 */

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type ExamTrackCode = 'NEET_UG' | 'IMAT';
export type ExamVersionStatus = 'DRAFT' | 'UNDER_REVIEW' | 'VERIFIED' | 'PUBLISHED' | 'RETIRED';
export type PlatformRoleType = 'PLATFORM_ADMIN' | 'ACADEMIC_REVIEWER' | 'AUDITOR';
export type InstitutionRole = 'INSTITUTE_ADMIN' | 'FACULTY' | 'STUDENT';
export type AccountStatus = 'ACTIVE' | 'SUSPENDED' | 'PENDING' | 'ARCHIVED';
export type AccessSourceType = 'PERSONAL' | 'INSTITUTION' | 'PROMOTIONAL';
export type EnrollmentStatus = 'ACTIVE' | 'TRANSFERRED' | 'WITHDRAWN' | 'COMPLETED';
export type AssignmentStatus = 'ACTIVE' | 'INACTIVE';
export type ContentScope = 'PLATFORM' | 'INSTITUTION';
export type SyllabusNodeType = 'SUBJECT' | 'SECTION' | 'CHAPTER' | 'TOPIC' | 'SKILL';
export type ResourceType = 'NOTE' | 'PDF' | 'BOOK_REFERENCE' | 'DPP' | 'PYQ' | 'VIDEO' | 'IMAGE' | 'LINK';
export type PublicationStatus = 'DRAFT' | 'PENDING_REVIEW' | 'PUBLISHED' | 'ARCHIVED' | 'REJECTED';
export type QuestionType = 'SINGLE_SELECT_MCQ' | 'MULTIPLE_SELECT' | 'NUMERICAL' | 'ASSERTION_REASON';
export type DifficultyLevel = 'EASY' | 'MEDIUM' | 'HARD';
export type ReviewStatus = 'DRAFT' | 'IN_REVIEW' | 'APPROVED' | 'REJECTED' | 'PUBLISHED' | 'ARCHIVED';
export type AdjudicationStatus = 'STANDARD' | 'MULTIPLE_CORRECT' | 'ALL_OPTIONS_CORRECT' | 'INVALID_OR_DROPPED';
export type AttemptStatus = 'IN_PROGRESS' | 'SUBMITTED' | 'TIMED_OUT' | 'ABANDONED' | 'EVALUATED';
export type AIJobStatus = 'QUEUED' | 'PROCESSING' | 'COMPLETED' | 'FAILED';
export type AIValidationStatus = 'PENDING' | 'PASSED' | 'FAILED';
export type AIReviewStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'EDITED';

export interface Database {
  public: {
    Tables: {
      exam_tracks: {
        Row: {
          id: string;
          code: ExamTrackCode;
          display_name: string;
          authority_name: string;
          official_website: string | null;
          status: string;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['exam_tracks']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['exam_tracks']['Insert']>;
      };
      exam_versions: {
        Row: {
          id: string;
          exam_track_id: string;
          exam_year: number;
          academic_cycle: string;
          version_number: string;
          status: ExamVersionStatus;
          official_source_url: string;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['exam_versions']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['exam_versions']['Insert']>;
      };
      exam_scoring_policies: {
        Row: {
          id: string;
          exam_version_id: string;
          policy_code: string;
          correct_marks: number;
          incorrect_marks: number;
          unanswered_marks: number;
          max_raw_score: number;
          configuration: Json;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['exam_scoring_policies']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['exam_scoring_policies']['Insert']>;
      };
      exam_sections: {
        Row: {
          id: string;
          exam_version_id: string;
          scoring_policy_id: string;
          code: string;
          name: string;
          display_order: number;
          question_count: number;
          option_count: number;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['exam_sections']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['exam_sections']['Insert']>;
      };
      profiles: {
        Row: {
          id: string;
          email: string;
          full_name: string | null;
          account_status: AccountStatus;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['profiles']['Row'], 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['profiles']['Insert']>;
      };
      institutions: {
        Row: {
          id: string;
          slug: string;
          name: string;
          is_active: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['institutions']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['institutions']['Insert']>;
      };
      institution_memberships: {
        Row: {
          id: string;
          institution_id: string;
          profile_id: string;
          role: InstitutionRole;
          status: AccountStatus;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['institution_memberships']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['institution_memberships']['Insert']>;
      };
      learner_exam_access: {
        Row: {
          id: string;
          profile_id: string;
          exam_track_id: string;
          exam_version_id: string;
          source_type: AccessSourceType;
          institution_id: string | null;
          is_active: boolean;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['learner_exam_access']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['learner_exam_access']['Insert']>;
      };
      assessment_attempts: {
        Row: {
          id: string;
          assessment_version_id: string;
          profile_id: string;
          status: AttemptStatus;
          started_at: string;
          server_deadline_at: string;
          submitted_at: string | null;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['assessment_attempts']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['assessment_attempts']['Insert']>;
      };
      attempt_answers: {
        Row: {
          id: string;
          attempt_id: string;
          question_version_id: string;
          selected_option_ids: string[];
          is_marked_for_review: boolean;
          is_correct: boolean | null;
          marks_awarded: number | null;
          saved_at: string;
        };
        Insert: Omit<Database['public']['Tables']['attempt_answers']['Row'], 'id' | 'saved_at'>;
        Update: Partial<Database['public']['Tables']['attempt_answers']['Insert']>;
      };
      score_results: {
        Row: {
          id: string;
          attempt_id: string;
          raw_score: number;
          max_possible_score: number;
          percentage: number;
          accuracy_percentage: number;
          correct_count: number;
          incorrect_count: number;
          unanswered_count: number;
          section_breakdown: Json;
          topic_breakdown: Json;
          scoring_policy_version: string;
          calculated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['score_results']['Row'], 'id' | 'calculated_at'>;
        Update: Partial<Database['public']['Tables']['score_results']['Insert']>;
      };
      questions: {
        Row: {
          id: string;
          content_scope: ContentScope;
          institution_id: string | null;
          current_version_id: string | null;
          created_by: string;
          created_at: string;
          archived_at: string | null;
        };
        Insert: Omit<Database['public']['Tables']['questions']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['questions']['Insert']>;
      };
      question_versions: {
        Row: {
          id: string;
          question_id: string;
          version_number: number;
          exam_version_id: string | null;
          section_id: string | null;
          question_type: QuestionType;
          question_text: string;
          language_code: string;
          difficulty: DifficultyLevel;
          explanation: string | null;
          diagram_storage_path: string | null;
          diagram_alt_text: string | null;
          source_reference: string | null;
          review_status: ReviewStatus;
          created_by: string;
          reviewed_by: string | null;
          approved_at: string | null;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['question_versions']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['question_versions']['Insert']>;
      };
      question_options: {
        Row: {
          id: string;
          question_version_id: string;
          option_key: string;
          option_text: string;
          display_order: number;
          is_correct: boolean;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['question_options']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['question_options']['Insert']>;
      };
      question_answer_keys: {
        Row: {
          question_version_id: string;
          accepted_option_ids: string[];
          resolution_type: AdjudicationStatus;
          reviewed_by: string | null;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['question_answer_keys']['Row'], 'updated_at'>;
        Update: Partial<Database['public']['Tables']['question_answer_keys']['Insert']>;
      };
      ai_generation_jobs: {
        Row: {
          id: string;
          institution_id: string | null;
          requested_by: string;
          exam_version_id: string | null;
          syllabus_node_id: string | null;
          provider: string;
          model_id: string;
          prompt_template_version: string;
          status: AIJobStatus;
          input_metadata: Json;
          error_code: string | null;
          created_at: string;
          completed_at: string | null;
        };
        Insert: Omit<Database['public']['Tables']['ai_generation_jobs']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['ai_generation_jobs']['Insert']>;
      };
      ai_generation_reviews: {
        Row: {
          id: string;
          generation_job_id: string;
          draft_payload: Json;
          validation_status: AIValidationStatus;
          review_status: AIReviewStatus;
          reviewed_by: string | null;
          reviewed_at: string | null;
          published_question_version_id: string | null;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['ai_generation_reviews']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['ai_generation_reviews']['Insert']>;
      };
    };
  };
}

