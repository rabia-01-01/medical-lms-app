import { logger } from '../../infrastructure/logging/logger';
import {
  AIQuestionProvider,
  QuestionDraftRequest,
  GeneratedQuestionBatch,
  getAIQuestionProvider,
} from '../../infrastructure/ai';
import { AIDraftsRepository, InMemoryAIDraftsRepository } from './ai-drafts.repository';

export interface AuthContext {
  userId: string;
  role: 'PLATFORM_ADMIN' | 'ACADEMIC_REVIEWER' | 'INSTITUTE_ADMIN' | 'FACULTY' | 'STUDENT';
  institutionId?: string | null;
}

export interface GenerateDraftsInput {
  examCode: 'NEET_UG' | 'IMAT';
  examVersionId: string;
  sectionId: string;
  syllabusNodeId: string;
  subject: string;
  topic: string;
  subtopic?: string;
  difficulty: 'EASY' | 'MEDIUM' | 'HARD';
  count: number;
  languageCode?: string;
  referenceMaterial?: string;
  examYear?: number;
}

export interface ReviewDraftInput {
  reviewId: string;
  decision: 'APPROVE' | 'REJECT';
  comments?: string;
  edits?: {
    questionText?: string;
    explanation?: string;
  };
}

export class AIDraftsService {
  constructor(
    private readonly repository: AIDraftsRepository = new InMemoryAIDraftsRepository(),
    private readonly aiProvider: AIQuestionProvider = getAIQuestionProvider()
  ) {}

  /**
   * Generates draft questions and registers them for faculty human-in-the-loop review.
   * STRICT SECURITY:
   * 1. Requires FACULTY or ADMIN role (Students blocked)
   * 2. Zero access to student data or active assessment keys
   * 3. AI outputs are saved strictly as review_status = 'DRAFT'
   */
  async generateQuestions(input: GenerateDraftsInput, auth: AuthContext) {
    this.assertAuthorizedCreator(auth);

    // Enforce batch size limits (1 to 10 questions per batch)
    if (input.count < 1 || input.count > 10) {
      throw new Error('Question generation count must be between 1 and 10 questions per request.');
    }

    // Tenant boundary: If institute faculty, scope to their institution
    const institutionId = auth.role === 'PLATFORM_ADMIN' ? null : auth.institutionId ?? null;

    logger.info(
      {
        userId: auth.userId,
        role: auth.role,
        institutionId,
        examCode: input.examCode,
        subject: input.subject,
        topic: input.topic,
        count: input.count,
      },
      'Starting AI Question Generation Job'
    );

    // 1. Create AI Generation Job Record
    const job = await this.repository.createJob({
      institution_id: institutionId,
      requested_by: auth.userId,
      exam_version_id: input.examVersionId,
      syllabus_node_id: input.syllabusNodeId,
      provider: this.aiProvider.providerName,
      model_id: 'llama-3.3-70b-versatile',
      prompt_template_version: 'v1',
      status: 'PROCESSING',
      input_metadata: {
        examCode: input.examCode,
        subject: input.subject,
        topic: input.topic,
        subtopic: input.subtopic,
        difficulty: input.difficulty,
        count: input.count,
        languageCode: input.languageCode || 'en',
      },
      error_code: null,
      completed_at: null,
    });

    let batchResult: GeneratedQuestionBatch;

    try {
      const draftRequest: QuestionDraftRequest = {
        examCode: input.examCode,
        examVersionId: input.examVersionId,
        sectionId: input.sectionId,
        syllabusNodeId: input.syllabusNodeId,
        subject: input.subject,
        topic: input.topic,
        subtopic: input.subtopic,
        difficulty: input.difficulty,
        count: input.count,
        languageCode: input.languageCode || 'en',
        referenceMaterial: input.referenceMaterial,
        examYear: input.examYear,
      };

      // 2. Invoke Swappable AI Provider (Groq / Mock)
      batchResult = await this.aiProvider.generateDraftQuestions(draftRequest);

      // 3. Persist each generated question as DRAFT with Human-in-the-Loop review entry
      const savedDrafts = [];
      for (const question of batchResult.questions) {
        const saved = await this.repository.saveDraftQuestion({
          jobId: job.id,
          institutionId,
          createdBy: auth.userId,
          examVersionId: input.examVersionId,
          sectionId: input.sectionId,
          questionType: 'SINGLE_SELECT_MCQ',
          questionText: question.questionText,
          languageCode: input.languageCode || 'en',
          difficulty: question.difficulty,
          explanation: question.explanation,
          sourceReference: question.sourceReference,
          options: question.options.map((opt, idx) => ({
            optionKey: opt.optionKey,
            optionText: opt.optionText,
            displayOrder: idx + 1,
            isCorrect: opt.isCorrect,
          })),
          correctOptionKey: question.correctOptionKey,
          rawPayload: question,
        });
        savedDrafts.push(saved);
      }

      // 4. Mark Job as COMPLETED
      await this.repository.updateJob(job.id, {
        status: 'COMPLETED',
        completed_at: new Date().toISOString(),
      });

      return {
        jobId: job.id,
        status: 'COMPLETED',
        count: savedDrafts.length,
        provider: batchResult.provider,
        model: batchResult.model,
        latencyMs: batchResult.latencyMs,
        drafts: savedDrafts,
      };
    } catch (err: any) {
      logger.error(
        { jobId: job.id, err: err instanceof Error ? err.message : String(err) },
        'AI Question Generation Job failed'
      );

      // Update job to FAILED
      await this.repository.updateJob(job.id, {
        status: 'FAILED',
        error_code: err?.message || 'UNKNOWN_AI_GENERATION_ERROR',
        completed_at: new Date().toISOString(),
      });

      throw err;
    }
  }

  /**
   * Faculty review action: Approve or Reject a draft question
   */
  async reviewDraft(input: ReviewDraftInput, auth: AuthContext) {
    this.assertAuthorizedCreator(auth);

    const review = await this.repository.getReviewById(input.reviewId);
    if (!review) {
      throw new Error(`AI Generation Review record not found: ${input.reviewId}`);
    }

    if (review.review_status !== 'PENDING') {
      throw new Error(`Review #${input.reviewId} has already been resolved as ${review.review_status}.`);
    }

    const now = new Date().toISOString();

    if (input.decision === 'APPROVE') {
      const reviewStatus = input.edits ? 'EDITED' : 'APPROVED';

      await this.repository.updateReview(input.reviewId, {
        review_status: reviewStatus,
        reviewed_by: auth.userId,
        reviewed_at: now,
      });

      if (review.published_question_version_id) {
        const versionUpdates: any = {
          review_status: 'APPROVED',
          reviewed_by: auth.userId,
          approved_at: now,
        };
        if (input.edits?.questionText) {
          versionUpdates.question_text = input.edits.questionText;
        }
        if (input.edits?.explanation) {
          versionUpdates.explanation = input.edits.explanation;
        }
        await this.repository.updateQuestionVersion(review.published_question_version_id, versionUpdates);
      }

      logger.info({ reviewId: input.reviewId, reviewer: auth.userId, decision: reviewStatus }, 'Draft question approved');
      return { success: true, reviewId: input.reviewId, status: reviewStatus };
    } else {
      // REJECT
      await this.repository.updateReview(input.reviewId, {
        review_status: 'REJECTED',
        reviewed_by: auth.userId,
        reviewed_at: now,
      });

      if (review.published_question_version_id) {
        await this.repository.updateQuestionVersion(review.published_question_version_id, {
          review_status: 'REJECTED',
          reviewed_by: auth.userId,
        });
      }

      logger.info({ reviewId: input.reviewId, reviewer: auth.userId, decision: 'REJECTED', reason: input.comments }, 'Draft question rejected');
      return { success: true, reviewId: input.reviewId, status: 'REJECTED' };
    }
  }

  /**
   * Fetches job status and details
   */
  async getJobStatus(jobId: string, auth: AuthContext) {
    this.assertAuthorizedCreator(auth);

    const job = await this.repository.getJobById(jobId);
    if (!job) {
      throw new Error(`Job not found: ${jobId}`);
    }

    // Tenancy isolation check
    if (auth.role !== 'PLATFORM_ADMIN' && job.institution_id && job.institution_id !== auth.institutionId) {
      throw new Error('Access denied: You cannot view jobs belonging to another institution.');
    }

    return job;
  }

  /**
   * Fetches pending reviews for faculty review queue
   */
  async getPendingReviews(auth: AuthContext) {
    this.assertAuthorizedCreator(auth);
    const institutionId = auth.role === 'PLATFORM_ADMIN' ? null : auth.institutionId;
    return this.repository.getPendingReviews(institutionId);
  }

  /**
   * Security guard: Block student access to question drafting tools
   */
  private assertAuthorizedCreator(auth: AuthContext): void {
    const allowedRoles = ['PLATFORM_ADMIN', 'ACADEMIC_REVIEWER', 'INSTITUTE_ADMIN', 'FACULTY'];
    if (!allowedRoles.includes(auth.role)) {
      throw new Error('Access Denied: Only faculty and academic administrators can access AI question drafting.');
    }
  }
}

