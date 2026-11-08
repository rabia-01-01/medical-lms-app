import express, { Express, Request, Response, NextFunction } from "express";
import cors from "cors";
import helmet from "helmet";
import { env } from "./config/env";
import { createAIDraftsRouter } from "./domains/content-bank";

export function createApp(): Express {
  const app = express();

  app.use(helmet());
  app.use(cors({ origin: env.WEB_ORIGIN, credentials: true }));
  app.use(express.json());

  // System Health
  app.get("/health", (_req: Request, res: Response) => {
    res.json({
      status: "ok",
      service: "MedPrep-api",
      environment: env.NODE_ENV,
      timestamp: new Date().toISOString(),
    });
  });

  // AI Content Bank Routes
  app.use("/api/v1/content-bank/ai-drafts", createAIDraftsRouter());

  // Centralized Error Handler
  app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
    console.error("Unhandled API Error:", err);
    res.status(500).json({
      success: false,
      error: {
        code: "INTERNAL_SERVER_ERROR",
        message: env.NODE_ENV === "production" ? "An unexpected error occurred." : err.message,
      },
      timestamp: new Date().toISOString(),
    });
  });

  return app;
}
