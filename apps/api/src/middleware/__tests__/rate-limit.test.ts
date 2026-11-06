import { describe, it, expect } from 'vitest';
import { createRateLimiter } from '../rate-limit';

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
  return { res, headers };
}

describe('Rate Limiter Middleware', () => {
  it('allows requests within limit and attaches rate limit headers', () => {
    const limiter = createRateLimiter({
      windowMs: 60000,
      maxRequests: 3,
      keyGenerator: () => 'test-user-1',
    });

    const req: any = {};
    const { res, headers } = createMockResponse();
    let nextCalled = false;

    limiter(req, res, () => {
      nextCalled = true;
    });

    expect(nextCalled).toBe(true);
    expect(res.statusCode).toBe(200);
    expect(headers['x-ratelimit-limit']).toBe(3);
    expect(headers['x-ratelimit-remaining']).toBe(2);
  });

  it('blocks requests exceeding the configured threshold with HTTP 429', () => {
    const limiter = createRateLimiter({
      windowMs: 60000,
      maxRequests: 2,
      keyGenerator: () => 'test-user-exceeded',
    });

    const req: any = {};

    // 1st request -> Allowed
    const first = createMockResponse();
    limiter(req, first.res, () => {});
    expect(first.res.statusCode).toBe(200);

    // 2nd request -> Allowed
    const second = createMockResponse();
    limiter(req, second.res, () => {});
    expect(second.res.statusCode).toBe(200);

    // 3rd request -> Blocked with 429
    let thirdNextCalled = false;
    const third = createMockResponse();
    limiter(req, third.res, () => {
      thirdNextCalled = true;
    });

    expect(thirdNextCalled).toBe(false);
    expect(third.res.statusCode).toBe(429);
    expect(third.res.body.success).toBe(false);
    expect(third.res.body.error.code).toBe('RATE_LIMIT_EXCEEDED');
    expect(third.headers['retry-after']).toBeDefined();
    expect(third.headers['x-ratelimit-remaining']).toBe(0);
  });
});

