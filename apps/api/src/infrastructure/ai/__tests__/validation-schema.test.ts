import { describe, it, expect } from "vitest";
import {
  neetUGQuestionSchema,
  imatQuestionSchema,
  validateGeneratedQuestions,
} from "../schemas/question-generation.schema";

describe("AI Question Validation Schemas", () => {
  const validNeetQuestion = {
    questionText:
      "Which enzyme is primarily responsible for unwinding double-stranded DNA during replication in E. coli?",
    difficulty: "MEDIUM",
    subject: "Biology",
    topic: "Molecular Basis of Inheritance",
    subtopic: "DNA Replication",
    options: [
      { optionKey: "A", optionText: "DNA Helicase (DnaB)", isCorrect: true },
      { optionKey: "B", optionText: "DNA Polymerase I", isCorrect: false },
      { optionKey: "C", optionText: "RNA Primase (DnaG)", isCorrect: false },
      { optionKey: "D", optionText: "DNA Topoisomerase II (Gyrase)", isCorrect: false },
    ],
    correctOptionKey: "A",
    explanation:
      "DNA Helicase (DnaB) unwinds the DNA double helix at the replication fork using ATP hydrolysis.",
    sourceReference: "NCERT Biology Class 12, Chapter 6",
  };

  const validImatQuestion = {
    questionText:
      "An isolated ideal gas undergoes an adiabatic expansion. Which of the following statements is correct regarding this process?",
    difficulty: "HARD",
    subject: "Physics & Mathematics",
    topic: "Thermodynamics",
    options: [
      {
        optionKey: "A",
        optionText: "The internal energy of the gas decreases while temperature drops.",
        isCorrect: true,
      },
      {
        optionKey: "B",
        optionText: "Heat is absorbed from the external surroundings during expansion.",
        isCorrect: false,
      },
      {
        optionKey: "C",
        optionText: "The temperature of the gas increases as volume expands.",
        isCorrect: false,
      },
      {
        optionKey: "D",
        optionText: "The total work done by the gas is strictly zero.",
        isCorrect: false,
      },
      {
        optionKey: "E",
        optionText: "The internal energy of the gas remains completely constant.",
        isCorrect: false,
      },
    ],
    correctOptionKey: "A",
    explanation:
      "In an adiabatic process, Q = 0. According to the First Law of Thermodynamics, Delta U = -W. Expansion means W > 0, so internal energy decreases and temperature drops.",
    sourceReference: "IMAT Physics Syllabus: Thermodynamics",
  };

  describe("NEET-UG Schema", () => {
    it("accepts a valid 4-option NEET question", () => {
      const result = neetUGQuestionSchema.safeParse(validNeetQuestion);
      expect(result.success).toBe(true);
    });

    it("rejects a NEET question with 5 options", () => {
      const invalid = {
        ...validNeetQuestion,
        options: [
          ...validNeetQuestion.options,
          { optionKey: "E", optionText: "Extra option", isCorrect: false },
        ],
      };
      const result = neetUGQuestionSchema.safeParse(invalid);
      expect(result.success).toBe(false);
      expect(result.error?.issues[0].message).toContain(
        "NEET-UG questions must have exactly 4 options",
      );
    });

    it("rejects a NEET question with 3 options", () => {
      const invalid = {
        ...validNeetQuestion,
        options: validNeetQuestion.options.slice(0, 3),
      };
      const result = neetUGQuestionSchema.safeParse(invalid);
      expect(result.success).toBe(false);
    });
  });

  describe("IMAT Schema", () => {
    it("accepts a valid 5-option IMAT question", () => {
      const result = imatQuestionSchema.safeParse(validImatQuestion);
      expect(result.success).toBe(true);
    });

    it("rejects an IMAT question with only 4 options", () => {
      const invalid = {
        ...validImatQuestion,
        options: validImatQuestion.options.slice(0, 4),
      };
      const result = imatQuestionSchema.safeParse(invalid);
      expect(result.success).toBe(false);
      expect(result.error?.issues[0].message).toContain(
        "IMAT questions must have exactly 5 options",
      );
    });
  });

  describe("Common Refinements & Security Controls", () => {
    it("rejects questions with duplicate option texts", () => {
      const duplicateOptionQuestion = {
        ...validNeetQuestion,
        options: [
          { optionKey: "A", optionText: "Same option text", isCorrect: true },
          { optionKey: "B", optionText: "Same option text", isCorrect: false },
          { optionKey: "C", optionText: "Different option C", isCorrect: false },
          { optionKey: "D", optionText: "Different option D", isCorrect: false },
        ],
      };
      const result = neetUGQuestionSchema.safeParse(duplicateOptionQuestion);
      expect(result.success).toBe(false);
      expect(result.error?.issues[0].message).toContain("unique text");
    });

    it("rejects questions with zero correct options", () => {
      const zeroCorrect = {
        ...validNeetQuestion,
        options: validNeetQuestion.options.map((o) => ({ ...o, isCorrect: false })),
      };
      const result = neetUGQuestionSchema.safeParse(zeroCorrect);
      expect(result.success).toBe(false);
      expect(result.error?.issues[0].message).toContain(
        "Exactly one option must be marked as correct",
      );
    });

    it("rejects questions with multiple correct options", () => {
      const multipleCorrect = {
        ...validNeetQuestion,
        options: validNeetQuestion.options.map((o) => ({ ...o, isCorrect: true })),
      };
      const result = neetUGQuestionSchema.safeParse(multipleCorrect);
      expect(result.success).toBe(false);
      expect(result.error?.issues[0].message).toContain(
        "Exactly one option must be marked as correct",
      );
    });

    it("rejects questions where correctOptionKey does not match the isCorrect option", () => {
      const mismatchedKey = {
        ...validNeetQuestion,
        correctOptionKey: "D", // option A is isCorrect: true
      };
      const result = neetUGQuestionSchema.safeParse(mismatchedKey);
      expect(result.success).toBe(false);
      expect(result.error?.issues[0].message).toContain(
        "correctOptionKey must match the option with isCorrect: true",
      );
    });

    it("rejects questions with forbidden executable markup (XSS injection attempt)", () => {
      const malicious = {
        ...validNeetQuestion,
        questionText: 'What is photosynthesis? <script>alert("pwned")</script>',
      };
      const result = neetUGQuestionSchema.safeParse(malicious);
      expect(result.success).toBe(false);
      expect(result.error?.issues[0].message).toContain("forbidden executable markup");
    });

    it("rejects explanations that are too short (< 20 characters)", () => {
      const shortExplanation = {
        ...validNeetQuestion,
        explanation: "Because it is.",
      };
      const result = neetUGQuestionSchema.safeParse(shortExplanation);
      expect(result.success).toBe(false);
      expect(result.error?.issues[0].message).toContain("at least 20 characters");
    });
  });

  describe("validateGeneratedQuestions helper", () => {
    it("validates a batch of NEET questions", () => {
      const rawBatch = {
        questions: [validNeetQuestion],
      };
      const validated = validateGeneratedQuestions(rawBatch, "NEET_UG");
      expect(validated).toHaveLength(1);
      expect(validated[0].options).toHaveLength(4);
    });

    it("throws when raw batch does not match requested exam track", () => {
      const rawBatch = {
        questions: [validNeetQuestion], // 4 options
      };
      expect(() => validateGeneratedQuestions(rawBatch, "IMAT")).toThrow(
        /IMAT questions must have exactly 5 options/,
      );
    });
  });
});
