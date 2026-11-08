import { AIQuestionProvider } from "./ai-provider.interface";
import { GroqQuestionProvider } from "./groq-provider";
import { MockQuestionProvider } from "./mock-provider";
import { AIProviderConfig } from "./types";

let cachedGroqProvider: GroqQuestionProvider | null = null;
let cachedMockProvider: MockQuestionProvider | null = null;

export function getAIQuestionProvider(
  providerName: string = "GROQ",
  config?: Partial<AIProviderConfig>,
): AIQuestionProvider {
  const normalized = providerName.toUpperCase();

  if (normalized === "MOCK" || (process.env.NODE_ENV === "test" && !process.env.FORCE_REAL_GROQ)) {
    if (!cachedMockProvider) {
      cachedMockProvider = new MockQuestionProvider();
    }
    return cachedMockProvider;
  }

  if (normalized === "GROQ") {
    if (!cachedGroqProvider || config) {
      cachedGroqProvider = new GroqQuestionProvider(config);
    }
    return cachedGroqProvider;
  }

  throw new Error(
    `Unsupported AI Question Provider: ${providerName}. Supported providers: GROQ, MOCK`,
  );
}

/**
 * Resets cached provider instances (useful for test isolation)
 */
export function resetCachedProviders(): void {
  cachedGroqProvider = null;
  cachedMockProvider = null;
}
