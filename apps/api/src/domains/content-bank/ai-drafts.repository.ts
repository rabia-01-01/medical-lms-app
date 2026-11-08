import crypto from 'crypto';
import { Database, AIJobStatus, AIReviewStatus, SupabaseClient } from '@MedPrep/database';

export interface DraftQuestionSaveParams {
  jobId: string;
  institutionId: string | null;
  createdBy: string;
  examVersionId: string | null;
  sectionId: string | null;
  questionType: Database['public']['Tables']['question_versions']['Row']['question_type'];
  questionText: string;
  languageCode: string;
  difficulty: Database['public']['Tables']['question_versions']['Row']['difficulty'];
  explanation: string;
  sourceReference?: string;
  options: Array<{
    optionKey: string;
    optionText: string;
    displayOrder: number;
    isCorrect: boolean;
  }>;
  correctOptionKey: string;
  rawPayload: any;
}

export interface SavedDraftResult {
  questionId: string;
  versionId: string;
  reviewId: string;
}

export interface AIDraftsRepository {
  createJob(
    job: Database['public']['Tables']['ai_generation_jobs']['Insert']
  ): Promise<Database['public']['Tables']['ai_generation_jobs']['Row']>;

  updateJob(
    jobId: string,
    updates: Database['public']['Tables']['ai_generation_jobs']['Update']
  ): Promise<void>;

  getJobById(jobId: string): Promise<Database['public']['Tables']['ai_generation_jobs']['Row'] | null>;

  saveDraftQuestion(params: DraftQuestionSaveParams): Promise<SavedDraftResult>;

  getReviewById(
    reviewId: string
  ): Promise<Database['public']['Tables']['ai_generation_reviews']['Row'] | null>;

  getPendingReviews(
    institutionId?: string | null
  ): Promise<Database['public']['Tables']['ai_generation_reviews']['Row'][]>;

  updateReview(
    reviewId: string,
    updates: Database['public']['Tables']['ai_generation_reviews']['Update']
  ): Promise<void>;

  updateQuestionVersion(
    versionId: string,
    updates: Database['public']['Tables']['question_versions']['Update']
  ): Promise<void>;
}

/**
 * In-memory repository implementation for unit tests and local mock execution
 */
export class InMemoryAIDraftsRepository implements AIDraftsRepository {
  public jobs = new Map<string, Database['public']['Tables']['ai_generation_jobs']['Row']>();
  public questions = new Map<string, Database['public']['Tables']['questions']['Row']>();
  public versions = new Map<string, Database['public']['Tables']['question_versions']['Row']>();
  public options = new Map<string, Database['public']['Tables']['question_options']['Row']>();
  public answerKeys = new Map<string, Database['public']['Tables']['question_answer_keys']['Row']>();
  public reviews = new Map<string, Database['public']['Tables']['ai_generation_reviews']['Row']>();

  async createJob(
    job: Database['public']['Tables']['ai_generation_jobs']['Insert']
  ): Promise<Database['public']['Tables']['ai_generation_jobs']['Row']> {
    const id = crypto.randomUUID();
    const created: Database['public']['Tables']['ai_generation_jobs']['Row'] = {
      id,
      institution_id: job.institution_id ?? null,
      requested_by: job.requested_by,
      exam_version_id: job.exam_version_id ?? null,
      syllabus_node_id: job.syllabus_node_id ?? null,
      provider: job.provider ?? 'GROQ',
      model_id: job.model_id,
      prompt_template_version: job.prompt_template_version ?? 'v1',
      status: job.status ?? 'QUEUED',
      input_metadata: job.input_metadata ?? {},
      error_code: job.error_code ?? null,
      created_at: new Date().toISOString(),
      completed_at: null,
    };
    this.jobs.set(id, created);
    return created;
  }

  async updateJob(
    jobId: string,
    updates: Database['public']['Tables']['ai_generation_jobs']['Update']
  ): Promise<void> {
    const existing = this.jobs.get(jobId);
    if (!existing) throw new Error(`Job not found: ${jobId}`);
    this.jobs.set(jobId, { ...existing, ...updates });
  }

  async getJobById(
    jobId: string
  ): Promise<Database['public']['Tables']['ai_generation_jobs']['Row'] | null> {
    return this.jobs.get(jobId) || null;
  }

  async saveDraftQuestion(params: DraftQuestionSaveParams): Promise<SavedDraftResult> {
    const questionId = crypto.randomUUID();
    const versionId = crypto.randomUUID();
    const reviewId = crypto.randomUUID();

    const now = new Date().toISOString();

    // 1. Create Question container
    this.questions.set(questionId, {
      id: questionId,
      content_scope: params.institutionId ? 'INSTITUTION' : 'PLATFORM',
      institution_id: params.institutionId,
      current_version_id: versionId,
      created_by: params.createdBy,
      created_at: now,
      archived_at: null,
    });

    // 2. Create Question Version (strictly review_status = 'DRAFT')
    this.versions.set(versionId, {
      id: versionId,
      question_id: questionId,
      version_number: 1,
      exam_version_id: params.examVersionId,
      section_id: params.sectionId,
      question_type: params.questionType,
      question_text: params.questionText,
      languageCode: params.languageCode,
      difficulty: params.difficulty,
      explanation: params.explanation,
      diagram_storage_path: null,
      diagram_alt_text: null,
      source_reference: params.sourceReference || null,
      review_status: 'DRAFT',
      created_by: params.createdBy,
      reviewed_by: null,
      approved_at: null,
      created_at: now,
    } as any);

    // 3. Create Question Options
    const acceptedOptionIds: string[] = [];
    for (const opt of params.options) {
      const optionId = crypto.randomUUID();
      this.options.set(optionId, {
        id: optionId,
        question_version_id: versionId,
        option_key: opt.optionKey,
        option_text: opt.optionText,
        display_order: opt.displayOrder,
        is_correct: opt.isCorrect,
        created_at: now,
      });
      if (opt.isCorrect) {
        acceptedOptionIds.push(optionId);
      }
    }

    // 4. Create Answer Key (server-side only)
    this.answerKeys.set(versionId, {
      question_version_id: versionId,
      accepted_option_ids: acceptedOptionIds,
      resolution_type: 'STANDARD',
      reviewed_by: null,
      updated_at: now,
    });

    // 5. Create AI Generation Review record (Human-in-the-Loop review queue)
    this.reviews.set(reviewId, {
      id: reviewId,
      generation_job_id: params.jobId,
      draft_payload: params.rawPayload,
      validation_status: 'PASSED',
      review_status: 'PENDING',
      reviewed_by: null,
      reviewed_at: null,
      published_question_version_id: versionId,
      created_at: now,
    });

    return { questionId, versionId, reviewId };
  }

  async getReviewById(
    reviewId: string
  ): Promise<Database['public']['Tables']['ai_generation_reviews']['Row'] | null> {
    return this.reviews.get(reviewId) || null;
  }

  async getPendingReviews(
    institutionId?: string | null
  ): Promise<Database['public']['Tables']['ai_generation_reviews']['Row'][]> {
    const result: Database['public']['Tables']['ai_generation_reviews']['Row'][] = [];
    for (const review of this.reviews.values()) {
      if (review.review_status === 'PENDING') {
        const job = this.jobs.get(review.generation_job_id);
        if (!institutionId || job?.institution_id === institutionId) {
          result.push(review);
        }
      }
    }
    return result;
  }

  async updateReview(
    reviewId: string,
    updates: Database['public']['Tables']['ai_generation_reviews']['Update']
  ): Promise<void> {
    const existing = this.reviews.get(reviewId);
    if (!existing) throw new Error(`Review not found: ${reviewId}`);
    this.reviews.set(reviewId, { ...existing, ...updates });
  }

  async updateQuestionVersion(
    versionId: string,
    updates: Database['public']['Tables']['question_versions']['Update']
  ): Promise<void> {
    const existing = this.versions.get(versionId);
    if (!existing) throw new Error(`Question version not found: ${versionId}`);
    this.versions.set(versionId, { ...existing, ...updates });
  }
}

/**
 * Supabase-backed repository implementation for production
 */
export class SupabaseAIDraftsRepository implements AIDraftsRepository {
  constructor(private readonly supabase: SupabaseClient<any>) { }

  async createJob(
    job: Database['public']['Tables']['ai_generation_jobs']['Insert']
  ): Promise<Database['public']['Tables']['ai_generation_jobs']['Row']> {
    const { data, error } = await this.supabase
      .from('ai_generation_jobs')
      .insert(job)
      .select()
      .single();
    if (error || !data) {
      throw new Error(`Failed to create AI generation job: ${error?.message}`);
    }
    return data;
  }

  async updateJob(
    jobId: string,
    updates: Database['public']['Tables']['ai_generation_jobs']['Update']
  ): Promise<void> {
    const { error } = await this.supabase
      .from('ai_generation_jobs')
      .update(updates)
      .eq('id', jobId);
    if (error) {
      throw new Error(`Failed to update AI generation job ${jobId}: ${error.message}`);
    }
  }

  async getJobById(
    jobId: string
  ): Promise<Database['public']['Tables']['ai_generation_jobs']['Row'] | null> {
    const { data, error } = await this.supabase
      .from('ai_generation_jobs')
      .select('*')
      .eq('id', jobId)
      .maybeSingle();
    if (error) {
      throw new Error(`Failed to fetch AI generation job ${jobId}: ${error.message}`);
    }
    return data;
  }

  async saveDraftQuestion(params: DraftQuestionSaveParams): Promise<SavedDraftResult> {
    // 1. Create Question
    const { data: qData, error: qErr } = await this.supabase
      .from('questions')
      .insert({
        content_scope: params.institutionId ? 'INSTITUTION' : 'PLATFORM',
        institution_id: params.institutionId,
        created_by: params.createdBy,
        current_version_id: null,
      })
      .select('id')
      .single();
    if (qErr || !qData) {
      throw new Error(`Failed to insert draft question: ${qErr?.message}`);
    }
    const questionId = qData.id;

    // 2. Create Question Version (strictly review_status = 'DRAFT')
    const { data: vData, error: vErr } = await this.supabase
      .from('question_versions')
      .insert({
        question_id: questionId,
        version_number: 1,
        exam_version_id: params.examVersionId,
        section_id: params.sectionId,
        question_type: params.questionType,
        question_text: params.questionText,
        language_code: params.languageCode,
        difficulty: params.difficulty,
        explanation: params.explanation,
        source_reference: params.sourceReference || null,
        review_status: 'DRAFT',
        created_by: params.createdBy,
      })
      .select('id')
      .single();
    if (vErr || !vData) {
      throw new Error(`Failed to insert question version: ${vErr?.message}`);
    }
    const versionId = vData.id;

    // Link current version to question
    await this.supabase
      .from('questions')
      .update({ current_version_id: versionId })
      .eq('id', questionId);

    // 3. Create Question Options
    const optionInserts = params.options.map((opt) => ({
      question_version_id: versionId,
      option_key: opt.optionKey,
      option_text: opt.optionText,
      display_order: opt.displayOrder,
      is_correct: opt.isCorrect,
    }));

    const { data: optData, error: optErr } = await this.supabase
      .from('question_options')
      .insert(optionInserts)
      .select('id, is_correct');
    if (optErr || !optData) {
      throw new Error(`Failed to insert question options: ${optErr?.message}`);
    }

    const correctOptionIds = (optData as Array<{ id: string; is_correct: boolean }>)
      .filter((o) => o.is_correct)
      .map((o) => o.id);

    // 4. Create Answer Key
    const { error: keyErr } = await this.supabase
      .from('question_answer_keys')
      .insert({
        question_version_id: versionId,
        accepted_option_ids: correctOptionIds,
        resolution_type: 'STANDARD',
      });
    if (keyErr) {
      throw new Error(`Failed to insert question answer key: ${keyErr.message}`);
    }

    // 5. Create AI Generation Review
    const { data: revData, error: revErr } = await this.supabase
      .from('ai_generation_reviews')
      .insert({
        generation_job_id: params.jobId,
        draft_payload: params.rawPayload,
        validation_status: 'PASSED',
        review_status: 'PENDING',
        published_question_version_id: versionId,
      })
      .select('id')
      .single();
    if (revErr || !revData) {
      throw new Error(`Failed to insert AI review record: ${revErr?.message}`);
    }

    return { questionId, versionId, reviewId: revData.id };
  }

  async getReviewById(
    reviewId: string
  ): Promise<Database['public']['Tables']['ai_generation_reviews']['Row'] | null> {
    const { data, error } = await this.supabase
      .from('ai_generation_reviews')
      .select('*')
      .eq('id', reviewId)
      .maybeSingle();
    if (error) {
      throw new Error(`Failed to fetch AI review ${reviewId}: ${error.message}`);
    }
    return data;
  }

  async getPendingReviews(
    institutionId?: string | null
  ): Promise<Database['public']['Tables']['ai_generation_reviews']['Row'][]> {
    if (institutionId) {
      // Secure tenant isolation: Only fetch jobs belonging to this institution
      const { data: jobs, error: jobsErr } = await this.supabase
        .from('ai_generation_jobs')
        .select('id')
        .eq('institution_id', institutionId);

      if (jobsErr) {
        throw new Error(`Failed to fetch AI generation jobs for institution: ${jobsErr.message}`);
      }

      const jobIds = (jobs || []).map((j: { id: string }) => j.id);
      if (jobIds.length === 0) {
        return [];
      }

      const { data, error } = await this.supabase
        .from('ai_generation_reviews')
        .select('*')
        .eq('review_status', 'PENDING')
        .in('generation_job_id', jobIds);

      if (error) {
        throw new Error(`Failed to fetch pending AI reviews: ${error.message}`);
      }
      return data || [];
    }

    const { data, error } = await this.supabase
      .from('ai_generation_reviews')
      .select('*')
      .eq('review_status', 'PENDING');
    if (error) {
      throw new Error(`Failed to fetch pending AI reviews: ${error.message}`);
    }
    return data || [];
  }

  async updateReview(
    reviewId: string,
    updates: Database['public']['Tables']['ai_generation_reviews']['Update']
  ): Promise<void> {
    const { error } = await this.supabase
      .from('ai_generation_reviews')
      .update(updates)
      .eq('id', reviewId);
    if (error) {
      throw new Error(`Failed to update AI review ${reviewId}: ${error.message}`);
    }
  }

  async updateQuestionVersion(
    versionId: string,
    updates: Database['public']['Tables']['question_versions']['Update']
  ): Promise<void> {
    const { error } = await this.supabase
      .from('question_versions')
      .update(updates)
      .eq('id', versionId);
    if (error) {
      throw new Error(`Failed to update question version ${versionId}: ${error.message}`);
    }
  }
}
