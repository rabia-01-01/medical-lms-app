import { describe, it, expect } from "vitest";
import { shuffleQuestionOptions } from "../utils/shuffle-options";
import { GeneratedQuestion } from "../types";

describe("Option Shuffling & Position Bias Mitigation", () => {
  const baseQuestion: GeneratedQuestion = {
    questionText: "Which organelle is responsible for cellular respiration?",
    difficulty: "EASY",
    subject: "Biology",
    topic: "Cell Biology",
    options: [
      { optionKey: "A", optionText: "Mitochondria (Correct)", isCorrect: true },
      { optionKey: "B", optionText: "Ribosome", isCorrect: false },
      { optionKey: "C", optionText: "Chloroplast", isCorrect: false },
      { optionKey: "D", optionText: "Endoplasmic reticulum", isCorrect: false },
    ],
    correctOptionKey: "A",
    explanation: "Mitochondria generate ATP through oxidative phosphorylation.",
  };

  it("preserves the relationship between isCorrect and correctOptionKey", () => {
    for (let i = 0; i < 50; i++) {
      const shuffled = shuffleQuestionOptions(baseQuestion);

      const correctOption = shuffled.options.find((opt) => opt.isCorrect);
      expect(correctOption).toBeDefined();
      expect(shuffled.correctOptionKey).toBe(correctOption!.optionKey);
      expect(correctOption!.optionText).toBe("Mitochondria (Correct)");
    }
  });

  it("strictly renumbers option keys sequentially as A, B, C, D", () => {
    const shuffled = shuffleQuestionOptions(baseQuestion);

    expect(shuffled.options.map((o) => o.optionKey)).toEqual(["A", "B", "C", "D"]);
  });

  it("demonstrates uniform distribution across positions A, B, C, D over multiple runs", () => {
    const keyCounts: Record<string, number> = { A: 0, B: 0, C: 0, D: 0 };
    const iterations = 200;

    for (let i = 0; i < iterations; i++) {
      const shuffled = shuffleQuestionOptions(baseQuestion);
      keyCounts[shuffled.correctOptionKey]++;
    }

    // Each position should be hit roughly ~25% of the time (min 15 hits out of 200)
    expect(keyCounts["A"]).toBeGreaterThan(15);
    expect(keyCounts["B"]).toBeGreaterThan(15);
    expect(keyCounts["C"]).toBeGreaterThan(15);
    expect(keyCounts["D"]).toBeGreaterThan(15);
    // Verifies Option A is NOT the default 100% of the time
    expect(keyCounts["A"]).toBeLessThan(iterations * 0.5);
  });

  it("supports 5 options for IMAT and renumbers A through E", () => {
    const imatQuestion: GeneratedQuestion = {
      ...baseQuestion,
      options: [
        ...baseQuestion.options,
        { optionKey: "E", optionText: "Peroxisome", isCorrect: false },
      ],
    };

    const shuffled = shuffleQuestionOptions(imatQuestion);
    expect(shuffled.options.map((o) => o.optionKey)).toEqual(["A", "B", "C", "D", "E"]);
    const correctOpt = shuffled.options.find((o) => o.isCorrect);
    expect(shuffled.correctOptionKey).toBe(correctOpt?.optionKey);
  });
});
