import crypto from "crypto";
import { GeneratedOption, GeneratedQuestion, OptionKey } from "../types";

const OPTION_KEYS: OptionKey[] = ["A", "B", "C", "D", "E"];

/**
 * Cryptographically secure Fisher-Yates shuffle.
 */
function secureShuffle<T>(array: T[]): T[] {
  const result = [...array];
  for (let i = result.length - 1; i > 0; i--) {
    const j = crypto.randomInt(0, i + 1);
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
}

/**
 * Shuffles question options and re-keys them sequentially (A, B, C, D... or A, B, C, D, E...).
 * Updates correctOptionKey to point to the newly assigned key of the correct option.
 *
 * Guarantees zero position bias (Option A bias mitigation requirement).
 */
export function shuffleQuestionOptions(question: GeneratedQuestion): GeneratedQuestion {
  const shuffledRaw = secureShuffle(question.options);
  const rekeyedOptions: GeneratedOption[] = shuffledRaw.map((opt, index) => {
    const newKey = OPTION_KEYS[index];
    if (!newKey) {
      throw new Error(`Exceeded maximum supported option keys: index ${index}`);
    }
    return {
      optionKey: newKey,
      optionText: opt.optionText,
      isCorrect: opt.isCorrect,
    };
  });

  const correctOption = rekeyedOptions.find((opt) => opt.isCorrect);
  if (!correctOption) {
    throw new Error("Shuffling failed: no correct option found in question");
  }

  return {
    ...question,
    options: rekeyedOptions,
    correctOptionKey: correctOption.optionKey,
  };
}
