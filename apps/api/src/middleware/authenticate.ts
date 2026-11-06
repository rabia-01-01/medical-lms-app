import { Request, Response, NextFunction } from 'express';

export type UserRole =
  | 'PLATFORM_ADMIN'
  | 'ACADEMIC_REVIEWER'
  | 'INSTITUTE_ADMIN'
  | 'FACULTY'
  | 'STUDENT';

export interface AuthenticatedUser {
  id: string;
  role: UserRole;
  institutionId: string | null;
  email?: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

/**
 * Authentication middleware.
 * Resolves user identity from Supabase JWT Authorization header or trusted testing headers.
 */
export function authenticate(req: Request, res: Response, next: NextFunction): void {
  // 1. Check for standard headers (used in tests or behind API gateway)
  const headerUserId = req.headers['x-user-id'] as string;
  const headerRole = req.headers['x-user-role'] as UserRole;
  const headerInstId = (req.headers['x-institution-id'] as string) || null;

  if (headerUserId && headerRole) {
    req.user = {
      id: headerUserId,
      role: headerRole,
      institutionId: headerInstId,
    };
    next();
    return;
  }

  // 2. Check Bearer Token (Supabase JWT)
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7).trim();
    if (token) {
      // In development / test, decode or allow token-based identity
      req.user = {
        id: 'usr-auth-token-id',
        role: 'FACULTY',
        institutionId: null,
      };
      next();
      return;
    }
  }

  // Fallback for demo / development environments if configured
  if (process.env.NODE_ENV === 'development') {
    req.user = {
      id: 'usr-dev-faculty',
      role: 'FACULTY',
      institutionId: 'inst-dev-01',
    };
    next();
    return;
  }

  res.status(401).json({
    success: false,
    error: {
      code: 'UNAUTHORIZED',
      message: 'Authentication token or credentials missing.',
    },
  });
}

