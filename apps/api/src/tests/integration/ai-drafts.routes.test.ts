import { describe, it, expect, beforeEach } from 'vitest';
import { createAIDraftsRouter } from '../../domains/content-bank/ai-drafts.routes';
import { AIDraftsService } from '../../domains/content-bank/ai-drafts.service';
import { InMemoryAIDraftsRepository } from '../../domains/content-bank/ai-drafts.repository';
import { MockQuestionProvider } from '../../infrastructure/ai/mock-provider';

function createMockResponse() {
  const headers: Record<string, any> = {};
  const res: any = {
    statusCode: 200,
    body: null,
    setHeader(key: string, value: any) {
      headers[key.toLowerCase()] = value;
      return this;
    },
    getHeader(key: string) {
      return headers[key.toLowerCase()];
    },
    status(code: number) {
      this.statusCode = code;
      return this;
    },
    json(payload: any) {
      this.body = payload;
      return this;
    },
  };
  return res;
}

describe('AI Drafts Routes (Router Integration)', () => {
  let repository: InMemoryAIDraftsRepository;
  let service: AIDraftsService;
  let router: ReturnType<typeof createAIDraftsRouter>;

  beforeEach(() => {
    repository = new InMemoryAIDraftsRepository();
    const provider = new MockQuestionProvider();
    service = new AIDraftsService(repository, provider);
    router = createAIDraftsRouter(service, repository, provider);
  });

  describe('Route: POST /generate', () => {
    it('validates schema and returns 400 when missing required fields', async () => {
      // Find middleware and handler for /generate
      const routeLayer = (router as any).stack.find(
        (layer: any) => layer.route?.path === '/generate' && layer.route?.methods?.post
      );
      expect(routeLayer).toBeDefined();

      const validationMiddleware = routeLayer.route.stack[0].handle;
      const controllerHandler = routeLayer.route.stack[1].handle;

      const req: any = {
        body: { examCode: 'INVALID_CODE' },
        headers: {},
      };
      const res = createMockResponse();
      let nextCalled = false;

      await validationMiddleware(req, res, () => {
        nextCalled = true;
      });

      expect(nextCalled).toBe(false);
      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('processes valid payload and returns 202 Accepted with draft question batch', async () => {
      const routeLayer = (router as any).stack.find(
        (layer: any) => layer.route?.path === '/generate' && layer.route?.methods?.post
      );

      const validationMiddleware = routeLayer.route.stack[0].handle;
      const controllerHandler = routeLayer.route.stack[1].handle;

      const req: any = {
        body: {
          examCode: 'NEET_UG',
          examVersionId: 'ver-neet-2026',
          sectionId: 'sec-biology',
          syllabusNodeId: 'node-botany',
          subject: 'Biology',
          topic: 'Plant Physiology',
          difficulty: 'MEDIUM',
          count: 2,
        },
        headers: {
          'x-user-id': 'fac-101',
          'x-user-role': 'FACULTY',
          'x-institution-id': 'inst-apex',
        },
      };
      const res = createMockResponse();

      let nextCalled = false;
      validationMiddleware(req, res, () => {
        nextCalled = true;
      });
      expect(nextCalled).toBe(true);

      await controllerHandler(req, res, (err: any) => {
        if (err) throw err;
      });

      expect(res.statusCode).toBe(202);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('COMPLETED');
      expect(res.body.data.drafts).toHaveLength(2);
      expect(res.body.data.jobId).toBeDefined();
    });
  });

  describe('Route: GET /jobs/:jobId', () => {
    it('returns 200 with job details', async () => {
      // 1. Generate job
      const generateResult = await service.generateQuestions(
        {
          examCode: 'IMAT',
          examVersionId: 'ver-imat-2026',
          sectionId: 'sec-chem',
          syllabusNodeId: 'node-acids-bases',
          subject: 'Chemistry',
          topic: 'Acids and Bases',
          difficulty: 'HARD',
          count: 1,
        },
        {
          userId: 'fac-101',
          role: 'FACULTY',
          institutionId: 'inst-apex',
        }
      );

      const routeLayer = (router as any).stack.find(
        (layer: any) => layer.route?.path === '/jobs/:jobId' && layer.route?.methods?.get
      );
      const controllerHandler = routeLayer.route.stack[0].handle;

      const req: any = {
        params: { jobId: generateResult.jobId },
        headers: {
          'x-user-id': 'fac-101',
          'x-user-role': 'FACULTY',
          'x-institution-id': 'inst-apex',
        },
      };
      const res = createMockResponse();

      await controllerHandler(req, res, () => {});

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.id).toBe(generateResult.jobId);
      expect(res.body.data.status).toBe('COMPLETED');
    });
  });

  describe('Route: POST /reviews/:reviewId/decide', () => {
    it('approves a pending draft question via review decision route', async () => {
      // 1. Generate job
      const generateResult = await service.generateQuestions(
        {
          examCode: 'NEET_UG',
          examVersionId: 'ver-neet-2026',
          sectionId: 'sec-physics',
          syllabusNodeId: 'node-optics',
          subject: 'Physics',
          topic: 'Ray Optics',
          difficulty: 'HARD',
          count: 1,
        },
        {
          userId: 'fac-101',
          role: 'FACULTY',
          institutionId: 'inst-apex',
        }
      );

      const reviewId = generateResult.drafts[0].reviewId;

      const routeLayer = (router as any).stack.find(
        (layer: any) => layer.route?.path === '/reviews/:reviewId/decide' && layer.route?.methods?.post
      );
      const validationMiddleware = routeLayer.route.stack[0].handle;
      const controllerHandler = routeLayer.route.stack[1].handle;

      const req: any = {
        params: { reviewId },
        body: { decision: 'APPROVE' },
        headers: {
          'x-user-id': 'fac-101',
          'x-user-role': 'FACULTY',
        },
      };
      const res = createMockResponse();

      let nextCalled = false;
      validationMiddleware(req, res, () => {
        nextCalled = true;
      });
      expect(nextCalled).toBe(true);

      await controllerHandler(req, res, (err: any) => {
        if (err) throw err;
      });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('APPROVED');
    });
  });

  describe('Route-Level Rate Limiting on POST /generate', () => {
    it('enforces rate limiting when enabled and blocks with 429 when max requests exceeded', async () => {
      const rateLimitedRouter = createAIDraftsRouter(
        service,
        repository,
        new MockQuestionProvider(),
        {
          enableRateLimit: true,
          rateLimitMaxRequests: 1,
          rateLimitWindowMs: 60000,
        }
      );

      const routeLayer = (rateLimitedRouter as any).stack.find(
        (layer: any) => layer.route?.path === '/generate' && layer.route?.methods?.post
      );

      expect(routeLayer.route.stack.length).toBe(3); // rateLimiter, validator, controller
      const rateLimiterMiddleware = routeLayer.route.stack[0].handle;

      const req: any = {
        headers: { 'x-user-id': 'fac-rate-limited' },
      };

      // 1st request -> allowed
      const res1 = createMockResponse();
      let nextCalled1 = false;
      rateLimiterMiddleware(req, res1, () => {
        nextCalled1 = true;
      });
      expect(nextCalled1).toBe(true);

      // 2nd request -> 429 Too Many Requests
      const res2 = createMockResponse();
      let nextCalled2 = false;
      rateLimiterMiddleware(req, res2, () => {
        nextCalled2 = true;
      });
      expect(nextCalled2).toBe(false);
      expect(res2.statusCode).toBe(429);
      expect(res2.body.error.code).toBe('RATE_LIMIT_EXCEEDED');
    });
  });
});
