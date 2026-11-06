import { Request, Response, NextFunction } from 'express';
import { AIDraftsService, AuthContext } from './ai-drafts.service';

export class AIDraftsController {
  constructor(private readonly draftsService: AIDraftsService) {}

  generate = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const auth = this.extractAuth(req);
      const result = await this.draftsService.generateQuestions(req.body, auth);
      res.status(202).json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  getJobStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const auth = this.extractAuth(req);
      const { jobId } = req.params;
      const job = await this.draftsService.getJobStatus(jobId, auth);
      res.json({
        success: true,
        data: job,
      });
    } catch (err) {
      next(err);
    }
  };

  getPendingReviews = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const auth = this.extractAuth(req);
      const reviews = await this.draftsService.getPendingReviews(auth);
      res.json({
        success: true,
        data: reviews,
      });
    } catch (err) {
      next(err);
    }
  };

  decideReview = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const auth = this.extractAuth(req);
      const { reviewId } = req.params;
      const result = await this.draftsService.reviewDraft(
        {
          reviewId,
          decision: req.body.decision,
          comments: req.body.comments,
          edits: req.body.edits,
        },
        auth
      );
      res.json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  /**
   * Helper extracting auth identity and role from headers/request context
   */
  private extractAuth(req: Request): AuthContext {
    // In production, populated by Supabase JWT auth middleware
    // We provide a fallback for testing or read from headers
    const userId = (req.headers['x-user-id'] as string) || (req as any).user?.id || 'demo-faculty-id';
    const role = (req.headers['x-user-role'] as any) || (req as any).user?.role || 'FACULTY';
    const institutionId = (req.headers['x-institution-id'] as string) || (req as any).user?.institutionId || null;

    return {
      userId,
      role,
      institutionId,
    };
  }
}

