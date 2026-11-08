import Groq from "groq-sdk";
import { env } from "../../config/env";
import { logger } from "../logging/logger";
import { AIQuestionProvider } from "./ai-provider.interface";
import { buildNeetUGPrompt } from "./prompts/neet-ug.prompt";
import { buildImatPrompt } from "./prompts/imat.prompt";
import { validateGeneratedQuestions } from "./schemas/question-generation.schema";
import { shuffleQuestionOptions } from "./utils/shuffle-options";
import {
  AIProviderConfig,
  GeneratedQuestionBatch,
  QuestionDraftRequest,
  TokenUsage,
} from "./types";

export class GroqQuestionProvider implements AIQuestionProvider {
  public readonly providerName = "GROQ";
  private readonly client: Groq;
  private readonly config: AIProviderConfig;

  constructor(config?: Partial<AIProviderConfig>, customClient?: Groq) {
    this.config = {
      apiKey: config?.apiKey || env.GROQ_API_KEY,
      model: config?.model || env.GROQ_MODEL,
      fallbackModel: config?.fallbackModel || env.GROQ_FALLBACK_MODEL,
      timeoutMs: config?.timeoutMs || env.GROQ_TIMEOUT_MS,
      maxRetries: config?.maxRetries || env.GROQ_MAX_RETRIES,
    };

    this.client =
      customClient ||
      new Groq({
        apiKey: this.config.apiKey,
        timeout: this.config.timeoutMs,
      });
  }

  /**
   * Generates draft questions for NEET-UG or IMAT with resilience, fallback, and validation
   */
  async generateDraftQuestions(request: QuestionDraftRequest): Promise<GeneratedQuestionBatch> {
    const startTime = Date.now();
    const prompt =
      request.examCode === "NEET_UG" ? buildNeetUGPrompt(request) : buildImatPrompt(request);

    logger.info(
      {
        provider: this.providerName,
        examCode: request.examCode,
        subject: request.subject,
        topic: request.topic,
        difficulty: request.difficulty,
        count: request.count,
        primaryModel: this.config.model,
      },
      "Initiating AI draft question generation",
    );

    let rawJsonText: string;
    let usedModel = this.config.model;
    let usage: TokenUsage = { promptTokens: 0, completionTokens: 0, totalTokens: 0 };

    try {
      // Primary model attempt with retry
      const result = await this.callWithRetry(
        prompt.systemPrompt,
        prompt.userPrompt,
        this.config.model,
      );
      rawJsonText = result.text;
      usage = result.usage;
    } catch (primaryError) {
      logger.warn(
        {
          err: primaryError instanceof Error ? primaryError.message : String(primaryError),
          primaryModel: this.config.model,
          fallbackModel: this.config.fallbackModel,
        },
        "Primary Groq model failed. Attempting fallback model.",
      );

      // Fallback model attempt with retry
      usedModel = this.config.fallbackModel;
      const result = await this.callWithRetry(
        prompt.systemPrompt,
        prompt.userPrompt,
        this.config.fallbackModel,
      );
      rawJsonText = result.text;
      usage = result.usage;
    }

    // Parse and validate JSON structure
    let parsedJson: unknown;
    try {
      parsedJson = JSON.parse(rawJsonText);
    } catch (parseError) {
      logger.error(
        { err: parseError, rawJsonSnippet: rawJsonText.substring(0, 300) },
        "Groq returned invalid JSON",
      );
      throw new Error("AI provider returned malformed JSON output that could not be parsed.");
    }

    // Enforce track-specific schemas (NEET: 4 options, IMAT: 5 options)
    const validatedQuestions = validateGeneratedQuestions(parsedJson, request.examCode);

    // Enforce zero position bias (Fisher-Yates option shuffle and rekeying)
    const unbiasedQuestions = validatedQuestions.map((q) => shuffleQuestionOptions(q));

    const latencyMs = Date.now() - startTime;

    logger.info(
      {
        provider: this.providerName,
        model: usedModel,
        questionCount: unbiasedQuestions.length,
        latencyMs,
        usage,
      },
      "AI draft questions successfully generated and validated",
    );

    return {
      questions: unbiasedQuestions,
      provider: this.providerName,
      model: usedModel,
      usage,
      latencyMs,
    };
  }

  /**
   * Calls Groq Chat Completions API with exponential backoff on 429/503 errors and timeout
   */
  private async callWithRetry(
    systemPrompt: string,
    userPrompt: string,
    model: string,
  ): Promise<{ text: string; usage: TokenUsage }> {
    let lastError: Error | unknown;

    for (let attempt = 1; attempt <= this.config.maxRetries; attempt++) {
      const abortController = new AbortController();
      const timeoutHandle = setTimeout(() => {
        abortController.abort();
      }, this.config.timeoutMs);

      try {
        const response = await this.client.chat.completions.create(
          {
            model,
            messages: [
              { role: "system", content: systemPrompt },
              { role: "user", content: userPrompt },
            ],
            response_format: { type: "json_object" },
            temperature: 0.4,
            max_completion_tokens: 4096,
          },
          { signal: abortController.signal },
        );

        clearTimeout(timeoutHandle);

        const choice = response.choices?.[0];
        const content = choice?.message?.content;

        if (!content) {
          throw new Error("Groq API returned an empty completion content.");
        }

        const usage: TokenUsage = {
          promptTokens: response.usage?.prompt_tokens ?? 0,
          completionTokens: response.usage?.completion_tokens ?? 0,
          totalTokens: response.usage?.total_tokens ?? 0,
        };

        return { text: content, usage };
      } catch (err: any) {
        clearTimeout(timeoutHandle);
        lastError = err;

        const isRateLimit = err?.status === 429 || err?.message?.includes("429");
        const isServerUnavailable = err?.status === 503 || err?.message?.includes("503");
        const isTimeout =
          err?.name === "AbortError" ||
          err?.message?.includes("timeout") ||
          abortController.signal.aborted;

        const isTransient = isRateLimit || isServerUnavailable || isTimeout;

        if (isTransient && attempt < this.config.maxRetries) {
          const backoffDelay = Math.min(
            1000 * Math.pow(2, attempt - 1) + Math.random() * 500,
            10000,
          );
          logger.warn(
            {
              attempt,
              maxRetries: this.config.maxRetries,
              model,
              errorStatus: err?.status,
              errorMessage: err?.message,
              backoffDelayMs: Math.round(backoffDelay),
            },
            "Transient Groq API error encountered; retrying after backoff",
          );
          await new Promise((resolve) => setTimeout(resolve, backoffDelay));
        } else {
          // Fatal error or exhausted retries
          break;
        }
      }
    }

    throw lastError instanceof Error
      ? lastError
      : new Error(`Groq API invocation failed: ${String(lastError)}`);
  }
}
