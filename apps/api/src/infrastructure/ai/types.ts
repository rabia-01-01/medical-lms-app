/**
 * Core type definitions for AI Question Generation and Provider Abstraction
 * Aligns with MedPrep Section 13 (AI Architecture & Quality Controls)
 */

export type ExamTrackCode = "NEET_UG" | "IMAT";

export type DifficultyLevel = "EASY" | "MEDIUM" | "HARD";

export type QuestionTypeCode = "SINGLE_SELECT_MCQ";

export type OptionKey = "A" | "B" | "C" | "D" | "E";

export interface QuestionDraftRequest {
  examCode: ExamTrackCode;
  examVersionId: string;
  sectionId: string;
  syllabusNodeId: string;
  subject: string;
  topic: string;
  subtopic?: string;
  difficulty: DifficultyLevel;
  questionType?: QuestionTypeCode;
  count: number;
  languageCode?: string; // Default 'en'
  referenceMaterial?: string; // Optional grounding text or syllabus excerpt
  examYear?: number;
}

export interface GeneratedOption {
  optionKey: OptionKey;
  optionText: string;
  isCorrect: boolean;
}

export interface GeneratedQuestion {
  questionText: string;
  difficulty: DifficultyLevel;
  subject: string;
  topic: string;
  subtopic?: string;
  options: GeneratedOption[];
  correctOptionKey: OptionKey;
  explanation: string;
  sourceReference?: string;
}

export interface TokenUsage {
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
}

export interface GeneratedQuestionBatch {
  questions: GeneratedQuestion[];
  provider: string;
  model: string;
  usage: TokenUsage;
  latencyMs: number;
}

export interface AIProviderConfig {
  apiKey: string;
  model: string;
  fallbackModel: string;
  timeoutMs: number;
  maxRetries: number;
}
