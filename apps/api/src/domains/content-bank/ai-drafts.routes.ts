import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { AIDraftsController } from './ai-drafts.controller';
import { AIDraftsService } from './ai-drafts.service';
import { AIDraftsRepository, InMemoryAIDraftsRepository } from './ai-drafts.repository';
import { AIQuestionProvider, getAIQuestionProvider } from '../../infrastructure/ai';
import { createRateLimiter } from '../../middleware/rate-limit';

const generateDraftsSchema = z.object({
  examCode: z.enum(['NEET_UG', 'IMAT']),
  examVersionId: z.string().min(1, 'examVersionId is required'),
  sectionId: z.string().min(1, 'sectionId is required'),
  syllabusNodeId: z.string().min(1, 'syllabusNodeId is required'),
  subject: z.string().trim().min(1, 'subject is required'),
  topic: z.string().trim().min(1, 'topic is required'),
  subtopic: z.string().trim().optional(),
  difficulty: z.enum(['EASY', 'MEDIUM', 'HARD']),
  count: z.number().int().min(1).max(10).default(1),
  languageCode: z.string().default('en'),
  referenceMaterial: z.string().optional(),
  examYear: z.number().int().optional(),
});

const reviewDecisionSchema = z.object({
  decision: z.enum(['APPROVE', 'REJECT']),
  comments: z.string().optional(),
  edits: z
    .object({
      questionText: z.string().min(10).optional(),
      explanation: z.string().min(20).optional(),
    })
    .optional(),
});

function validateBody(schema: z.ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    const parseResult = schema.safeParse(req.body);
    if (!parseResult.success) {
      res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid request payload',
          details: parseResult.error.issues,
        },
      });
      return;
    }
    req.body = parseResult.data;
    next();
  };
}

export interface AIDraftsRouterOptions {
  enableRateLimit?: boolean;
  rateLimitWindowMs?: number;
  rateLimitMaxRequests?: number;
}

export function createAIDraftsRouter(
  service?: AIDraftsService,
  repository?: AIDraftsRepository,
  aiProvider?: AIQuestionProvider,
  options?: AIDraftsRouterOptions
): Router {
  const router = Router();
  const repo = repository || new InMemoryAIDraftsRepository();
  const provider = aiProvider || getAIQuestionProvider();
  const draftsService = service || new AIDraftsService(repo, provider);
  const controller = new AIDraftsController(draftsService);

  const rateLimitEnabled = options?.enableRateLimit ?? (process.env.NODE_ENV !== 'test');
  const generationRateLimiter = createRateLimiter({
    windowMs: options?.rateLimitWindowMs || 60 * 1000,
    maxRequests: options?.rateLimitMaxRequests || 10,
    message: 'AI question generation rate limit exceeded. Please wait a minute before generating more questions.',
  });

  // Generation endpoint (Protected, Faculty & Admin only, Rate-limited)
  if (rateLimitEnabled) {
    router.post('/generate', generationRateLimiter, validateBody(generateDraftsSchema), controller.generate);
  } else {
    router.post('/generate', validateBody(generateDraftsSchema), controller.generate);
  }

  // Job status endpoint
  router.get('/jobs/:jobId', controller.getJobStatus);

  // Faculty review queue
  router.get('/reviews/pending', controller.getPendingReviews);

  // Faculty human-in-the-loop decision endpoint
  router.post('/reviews/:reviewId/decide', validateBody(reviewDecisionSchema), controller.decideReview);

  return router;
}

