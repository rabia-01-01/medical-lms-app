import { describe, it, expect } from 'vitest';
import { authenticate } from '../authenticate';
import { requireRoles } from '../require-permission';

function createMockResponse() {
  const res: any = {
    statusCode: 200,
    body: null,
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

describe('Authentication & Authorization Middlewares', () => {
  describe('authenticate', () => {
    it('populates req.user from trusted headers', () => {
      const req: any = {
        headers: {
          'x-user-id': 'fac-101',
          'x-user-role': 'FACULTY',
          'x-institution-id': 'inst-apex',
        },
      };
      const res = createMockResponse();
      let nextCalled = false;

      authenticate(req, res, () => {
        nextCalled = true;
      });

      expect(nextCalled).toBe(true);
      expect(req.user).toEqual({
        id: 'fac-101',
        role: 'FACULTY',
        institutionId: 'inst-apex',
      });
    });

    it('rejects unauthenticated requests in production when headers are missing', () => {
      const origEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';

      const req: any = { headers: {} };
      const res = createMockResponse();
      let nextCalled = false;

      authenticate(req, res, () => {
        nextCalled = true;
      });

      process.env.NODE_ENV = origEnv;

      expect(nextCalled).toBe(false);
      expect(res.statusCode).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
    });
  });

  describe('requireRoles (RBAC Guard)', () => {
    it('allows users possessing permitted roles', () => {
      const guard = requireRoles(['FACULTY', 'PLATFORM_ADMIN']);
      const req: any = {
        user: { id: 'fac-101', role: 'FACULTY' },
        headers: {},
      };
      const res = createMockResponse();
      let nextCalled = false;

      guard(req, res, () => {
        nextCalled = true;
      });

      expect(nextCalled).toBe(true);
      expect(res.statusCode).toBe(200);
    });

    it('strictly forbids STUDENT role from faculty endpoints with HTTP 403', () => {
      const guard = requireRoles(['FACULTY', 'PLATFORM_ADMIN']);
      const req: any = {
        user: { id: 'stud-99', role: 'STUDENT' },
        headers: {},
      };
      const res = createMockResponse();
      let nextCalled = false;

      guard(req, res, () => {
        nextCalled = true;
      });

      expect(nextCalled).toBe(false);
      expect(res.statusCode).toBe(403);
      expect(res.body.error.code).toBe('FORBIDDEN_ACCESS');
      expect(res.body.error.message).toContain('Access denied');
    });
  });
});

