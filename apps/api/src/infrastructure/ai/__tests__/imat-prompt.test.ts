import { describe, it, expect } from "vitest";
import { buildImatPrompt } from "../prompts/imat.prompt";
import { QuestionDraftRequest } from "../types";

describe("IMAT Prompt Builder", () => {
  const sampleRequest: QuestionDraftRequest = {
    examCode: "IMAT",
    examVersionId: "ver-imat-2026",
    sectionId: "sec-reading-knowledge",
    syllabusNodeId: "node-argument-structure",
    subject: "Reading Skills and Knowledge Acquired in Studies",
    topic: "Philosophical Text Comprehension",
    subtopic: "Identifying unstated assumptions",
    difficulty: "MEDIUM",
    count: 3,
    languageCode: "en",
    examYear: 2026,
  };

  it("generates system prompt enforcing 5-option constraint (A to E)", () => {
    const { systemPrompt } = buildImatPrompt(sampleRequest);

    expect(systemPrompt).toContain("EXACTLY 5 OPTIONS");
    expect(systemPrompt).toContain('labeled "A", "B", "C", "D", and "E"');
    expect(systemPrompt).toContain("Italian Ministry of University and Research (MUR)");
    expect(systemPrompt).toContain("IMAT");
  });

  it("strictly instructs against English grammar substitutions for Reading Skills", () => {
    const { systemPrompt } = buildImatPrompt(sampleRequest);

    expect(systemPrompt).toContain("NEVER English grammar drills");
    expect(systemPrompt).toContain("complex text analysis");
    expect(systemPrompt).toContain("historical/philosophical literacy");
  });

  it("explicitly instructs the AI to prevent Option A bias across all 5 choices", () => {
    const { systemPrompt, userPrompt } = buildImatPrompt(sampleRequest);

    expect(systemPrompt).toContain("NEVER make Option A the default correct answer");
    expect(systemPrompt).toContain('Distribute correct answers across "A", "B", "C", "D", and "E"');
    expect(userPrompt).toContain("Do NOT make Option A the correct answer for every question");
  });

  it("specifies the requested count, section, and difficulty level", () => {
    const { userPrompt } = buildImatPrompt(sampleRequest);

    expect(userPrompt).toContain("Generate 3 original, high-quality IMAT practice question(s)");
    expect(userPrompt).toContain(
      "Section / Subject: Reading Skills and Knowledge Acquired in Studies",
    );
    expect(userPrompt).toContain("Topic: Philosophical Text Comprehension");
    expect(userPrompt).toContain("Difficulty Level: MEDIUM");
  });
});
