import pino from "pino";
import { env } from "../../config/env";

/**
 * Centrally configured Pino logger with strict PII & credential redaction
 */
export const logger = pino({
  level: env.LOG_LEVEL || "info",
  redact: {
    paths: [
      "apiKey",
      "*.apiKey",
      "GROQ_API_KEY",
      "authorization",
      "headers.authorization",
      "req.headers.authorization",
      'headers["x-api-key"]',
      "password",
      "token",
      "refreshToken",
      "accessToken",
      "secret",
    ],
    censor: "[REDACTED]",
  },
  timestamp: pino.stdTimeFunctions.isoTime,
});
