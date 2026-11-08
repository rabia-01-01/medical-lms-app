import { Request, Response, NextFunction } from "express";
import { UserRole } from "./authenticate";

/**
 * Role-Based Access Control (RBAC) middleware.
 * Ensures the authenticated user possesses one of the permitted roles.
 * Strictly prevents students from generating questions or accessing faculty draft queues.
 */
export function requireRoles(allowedRoles: UserRole[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const userRole = req.user?.role || (req.headers["x-user-role"] as UserRole);

    if (!userRole) {
      res.status(401).json({
        success: false,
        error: {
          code: "UNAUTHENTICATED",
          message: "User authentication required.",
        },
      });
      return;
    }

    if (!allowedRoles.includes(userRole)) {
      res.status(403).json({
        success: false,
        error: {
          code: "FORBIDDEN_ACCESS",
          message: `Access denied. Role '${userRole}' is not authorized to access this resource. Required roles: [${allowedRoles.join(", ")}]`,
        },
      });
      return;
    }

    next();
  };
}
