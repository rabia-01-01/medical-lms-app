import { QuestionDraftRequest, GeneratedQuestionBatch } from "./types";

/**
 * Reusable AI Question Provider Interface
 * Supports swappable providers (Groq, mock, future LLM vendors)
 */
export interface AIQuestionProvider {
  readonly providerName: string;

  /**
   * Generates draft questions for the given exam track and specifications.
   *
   * @param request - Validated drafting request parameters
   * @returns Batch of validated, shuffled draft questions with token usage and latency metrics
   */
  generateDraftQuestions(request: QuestionDraftRequest): Promise<GeneratedQuestionBatch>;
}
