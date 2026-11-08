import { describe, it, expect } from "vitest";
import { buildNeetUGPrompt } from "../prompts/neet-ug.prompt";
import { QuestionDraftRequest } from "../types";

describe("NEET-UG Prompt Builder", () => {
  const sampleRequest: QuestionDraftRequest = {
    examCode: "NEET_UG",
    examVersionId: "ver-neet-2026",
    sectionId: "sec-biology",
    syllabusNodeId: "node-human-physiology",
    subject: "Biology",
    topic: "Endocrine System",
    subtopic: "Thyroid hormone regulation",
    difficulty: "HARD",
    count: 2,
    languageCode: "en",
    examYear: 2026,
  };

  it("generates system prompt enforcing 4-option constraint and NCERT syllabus", () => {
    const { systemPrompt } = buildNeetUGPrompt(sampleRequest);

    expect(systemPrompt).toContain("EXACTLY 4 OPTIONS");
    expect(systemPrompt).toContain('labeled "A", "B", "C", and "D"');
    expect(systemPrompt).toContain("NCERT Class 11 and 12 curriculum");
    expect(systemPrompt).toContain("NEET-UG");
    expect(systemPrompt).toContain("2026");
  });

  it("explicitly instructs the AI to prevent Option A bias", () => {
    const { systemPrompt, userPrompt } = buildNeetUGPrompt(sampleRequest);

    expect(systemPrompt).toContain("NEVER make Option A the default correct answer");
    expect(systemPrompt).toContain(
      'Randomly distribute the correct answer across "A", "B", "C", and "D"',
    );
    expect(userPrompt).toContain("Do NOT make Option A the correct answer for every question");
  });

  it("incorporates grounding reference material when provided", () => {
    const requestWithGrounding: QuestionDraftRequest = {
      ...sampleRequest,
      referenceMaterial: "NCERT Chapter 22: Thyroid gland produces T3 and T4 stimulated by TSH.",
    };

    const { userPrompt } = buildNeetUGPrompt(requestWithGrounding);
    expect(userPrompt).toContain("REFERENCE GROUNDING MATERIAL:");
    expect(userPrompt).toContain("Thyroid gland produces T3 and T4");
  });

  it("specifies the requested count, subject, topic, and difficulty level", () => {
    const { userPrompt } = buildNeetUGPrompt(sampleRequest);

    expect(userPrompt).toContain("Generate 2 original, high-quality NEET-UG practice question(s)");
    expect(userPrompt).toContain("Subject: Biology");
    expect(userPrompt).toContain("Topic: Endocrine System");
    expect(userPrompt).toContain("Subtopic: Thyroid hormone regulation");
    expect(userPrompt).toContain("Difficulty Level: HARD");
  });
});
