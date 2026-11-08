import { z } from "zod";
import { ExamTrackCode, GeneratedOption, GeneratedQuestion, OptionKey } from "../types";

/**
 * Disallows executable HTML/JS or malicious markup in AI outputs.
 */
const FORBIDDEN_MARKUP_REGEX =
  /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>|javascript:|onerror\s*=|onload\s*=/i;

function sanitizeText(val: string): boolean {
  return !FORBIDDEN_MARKUP_REGEX.test(val);
}

const optionKeySchema = z.enum(["A", "B", "C", "D", "E"]);

export const rawAIOptionSchema = z.object({
  optionKey: optionKeySchema,
  optionText: z
    .string()
    .trim()
    .min(1, "Option text cannot be empty")
    .refine(sanitizeText, { message: "Option text contains forbidden executable markup" }),
  isCorrect: z.boolean(),
});

export const baseQuestionSchema = z.object({
  questionText: z
    .string()
    .trim()
    .min(10, "Question text must be at least 10 characters long")
    .refine(sanitizeText, { message: "Question text contains forbidden executable markup" }),
  difficulty: z.enum(["EASY", "MEDIUM", "HARD"]),
  subject: z.string().trim().min(1, "Subject is required"),
  topic: z.string().trim().min(1, "Topic is required"),
  subtopic: z.string().trim().optional(),
  options: z.array(rawAIOptionSchema),
  correctOptionKey: optionKeySchema,
  explanation: z
    .string()
    .trim()
    .min(20, "Explanation must be at least 20 characters and scientifically detailed")
    .refine(sanitizeText, { message: "Explanation contains forbidden executable markup" }),
  sourceReference: z.string().trim().optional(),
});

/**
 * Common validation rules applied to all question types regardless of track:
 * 1. Exactly one option marked isCorrect: true
 * 2. correctOptionKey matches the option marked isCorrect: true
 * 3. Unique option texts (no identical duplicate distractors)
 */
function applyCommonRefinements<T extends z.ZodTypeAny>(schema: T) {
  return schema
    .refine(
      (data: z.infer<typeof baseQuestionSchema>) => {
        const correctCount = data.options.filter((o) => o.isCorrect).length;
        return correctCount === 1;
      },
      { message: "Exactly one option must be marked as correct (isCorrect: true)" },
    )
    .refine(
      (data: z.infer<typeof baseQuestionSchema>) => {
        const correctOption = data.options.find((o) => o.isCorrect);
        return correctOption?.optionKey === data.correctOptionKey;
      },
      { message: "correctOptionKey must match the option with isCorrect: true" },
    )
    .refine(
      (data: z.infer<typeof baseQuestionSchema>) => {
        const normalized = data.options.map((o) => o.optionText.trim().toLowerCase());
        const unique = new Set(normalized);
        return unique.size === data.options.length;
      },
      { message: "All question options must have unique text (no duplicate distractors)" },
    );
}

/**
 * NEET-UG Question Schema:
 * Strictly 4 options: ['A', 'B', 'C', 'D']
 */
export const neetUGQuestionSchema = applyCommonRefinements(
  baseQuestionSchema.refine(
    (data) => {
      if (data.options.length !== 4) return false;
      const expectedKeys = ["A", "B", "C", "D"];
      const actualKeys = data.options.map((o) => o.optionKey);
      return expectedKeys.every((key, idx) => actualKeys[idx] === key);
    },
    { message: "NEET-UG questions must have exactly 4 options with keys A, B, C, D" },
  ),
);

/**
 * IMAT Question Schema:
 * Strictly 5 options: ['A', 'B', 'C', 'D', 'E']
 */
export const imatQuestionSchema = applyCommonRefinements(
  baseQuestionSchema.refine(
    (data) => {
      if (data.options.length !== 5) return false;
      const expectedKeys = ["A", "B", "C", "D", "E"];
      const actualKeys = data.options.map((o) => o.optionKey);
      return expectedKeys.every((key, idx) => actualKeys[idx] === key);
    },
    { message: "IMAT questions must have exactly 5 options with keys A, B, C, D, E" },
  ),
);

export const rawBatchResponseSchema = z.object({
  questions: z.array(z.record(z.any())).min(1, "At least one question must be generated"),
});

/**
 * Validates a raw AI batch against the specific exam track rules.
 */
export function validateGeneratedQuestions(
  rawJson: unknown,
  examCode: ExamTrackCode,
): GeneratedQuestion[] {
  const batchResult = rawBatchResponseSchema.safeParse(rawJson);
  if (!batchResult.success) {
    throw new Error(`AI output batch validation failed: ${batchResult.error.message}`);
  }

  const targetSchema = examCode === "NEET_UG" ? neetUGQuestionSchema : imatQuestionSchema;

  return batchResult.data.questions.map((q, idx) => {
    const parseResult = targetSchema.safeParse(q);
    if (!parseResult.success) {
      const issueDetails = parseResult.error.issues
        .map((issue) => `[${issue.path.join(".")}] ${issue.message}`)
        .join("; ");
      throw new Error(`Validation failed for question #${idx + 1} (${examCode}): ${issueDetails}`);
    }
    const validated = parseResult.data as z.infer<typeof baseQuestionSchema>;
    return {
      questionText: validated.questionText,
      difficulty: validated.difficulty,
      subject: validated.subject,
      topic: validated.topic,
      subtopic: validated.subtopic,
      options: validated.options.map((o) => ({
        optionKey: o.optionKey as OptionKey,
        optionText: o.optionText,
        isCorrect: o.isCorrect,
      })),
      correctOptionKey: validated.correctOptionKey as OptionKey,
      explanation: validated.explanation,
      sourceReference: validated.sourceReference,
    };
  });
}
