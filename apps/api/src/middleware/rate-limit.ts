import { Request, Response, NextFunction } from "express";

export interface RateLimitOptions {
  windowMs: number;
  maxRequests: number;
  message?: string;
  keyGenerator?: (req: Request) => string;
}

/**
 * Sliding window in-memory rate limiter middleware.
 * Protects expensive LLM inference endpoints (Groq API) from quota exhaustion and denial-of-service.
 */
export function createRateLimiter(options: RateLimitOptions) {
  const {
    windowMs,
    maxRequests,
    message = "Too many requests. Please try again later.",
    keyGenerator = (req: Request) => {
      const authUser = (req as any).user?.id || (req.headers["x-user-id"] as string);
      return authUser
        ? `user:${authUser}`
        : `ip:${req.ip || req.socket.remoteAddress || "unknown"}`;
    },
  } = options;

  const hits = new Map<string, { count: number; resetTime: number }>();

  // Periodic cleanup of expired rate limit entries
  const cleanupTimer = setInterval(
    () => {
      const now = Date.now();
      for (const [key, record] of hits.entries()) {
        if (now > record.resetTime) {
          hits.delete(key);
        }
      }
    },
    Math.max(windowMs, 30000),
  );

  if (cleanupTimer.unref) {
    cleanupTimer.unref();
  }

  return (req: Request, res: Response, next: NextFunction): void => {
    const key = keyGenerator(req);
    const now = Date.now();
    const record = hits.get(key);

    const setHeaderSafe = (name: string, value: any) => {
      if (typeof res.setHeader === "function") {
        res.setHeader(name, value);
      }
    };

    if (!record || now > record.resetTime) {
      hits.set(key, { count: 1, resetTime: now + windowMs });
      setHeaderSafe("X-RateLimit-Limit", maxRequests);
      setHeaderSafe("X-RateLimit-Remaining", maxRequests - 1);
      setHeaderSafe("X-RateLimit-Reset", Math.ceil((now + windowMs) / 1000));
      next();
      return;
    }

    if (record.count >= maxRequests) {
      const retryAfterSeconds = Math.max(1, Math.ceil((record.resetTime - now) / 1000));
      setHeaderSafe("Retry-After", retryAfterSeconds);
      setHeaderSafe("X-RateLimit-Limit", maxRequests);
      setHeaderSafe("X-RateLimit-Remaining", 0);
      setHeaderSafe("X-RateLimit-Reset", Math.ceil(record.resetTime / 1000));
      res.status(429).json({
        success: false,
        error: {
          code: "RATE_LIMIT_EXCEEDED",
          message,
          retryAfterSeconds,
        },
      });
      return;
    }

    record.count++;
    setHeaderSafe("X-RateLimit-Limit", maxRequests);
    setHeaderSafe("X-RateLimit-Remaining", maxRequests - record.count);
    setHeaderSafe("X-RateLimit-Reset", Math.ceil(record.resetTime / 1000));
    next();
  };
}
