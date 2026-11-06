import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(8000),
  WEB_ORIGIN: z.string().default('http://localhost:5173'),
  SUPABASE_URL: z.string().url().default('http://localhost:54321'),
  SUPABASE_ANON_KEY: z.string().min(1).default('dummy-anon-key'),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1).default('dummy-service-role-key'),
  LOG_LEVEL: z.string().default('info'),
  GROQ_API_KEY: z.string().min(1).default('gsk_development_placeholder_key'),
  GROQ_MODEL: z.string().default('llama-3.3-70b-versatile'),
  GROQ_FALLBACK_MODEL: z.string().default('llama-3.1-8b-instant'),
  GROQ_TIMEOUT_MS: z.coerce.number().default(30000),
  GROQ_MAX_RETRIES: z.coerce.number().default(3),
});

export const env = envSchema.parse(process.env);

