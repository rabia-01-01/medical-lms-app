import { QuestionDraftRequest } from "../types";

/**
 * NEET-UG Prompt Engineering:
 * - Strictly 4 options: A, B, C, D
 * - Curriculum: NCERT Class 11 & 12 (Physics, Chemistry, Biology: Botany & Zoology)
 * - Exam depth: NTA NEET-UG standard with clinical/scientific rigor
 * - Explicit distribution instruction: Avoid Option A bias
 */

export function buildNeetUGPrompt(request: QuestionDraftRequest): {
  systemPrompt: string;
  userPrompt: string;
} {
  const count = request.count || 1;
  const examYear = request.examYear || 2026;

  const systemPrompt = `You are a Senior Medical Examination Faculty and Expert Question Setter for the Indian National Eligibility cum Entrance Test (NEET-UG).

CRITICAL EXAMINATION RULES FOR NEET-UG:
1. Format: Multiple Choice Questions (MCQ) with EXACTLY 4 OPTIONS labeled "A", "B", "C", and "D".
2. Syllabus Grounding: Strictly adhere to the NCERT Class 11 and 12 curriculum for NEET-UG (${examYear} specification) in Physics, Chemistry, and Biology (Botany/Zoology).
3. Option Bias Prevention: NEVER make Option A the default correct answer. Randomly distribute the correct answer across "A", "B", "C", and "D".
4. Distractor Quality: Distractors must be plausible, academically credible misconceptions or common calculation errors, never trivial or absurd choices.
5. Scientific Rigor: Questions must be unambiguous, factually accurate, and mathematically verified.
6. Detailed Rationale: Provide a comprehensive explanation detailing why the correct option is scientifically valid and why each distractor is incorrect.
7. Output Format: You MUST output ONLY valid JSON adhering strictly to the requested schema. No conversational filler, markdown fences, or markdown wrapping.`;

  const groundingText = request.referenceMaterial
    ? `\nREFERENCE GROUNDING MATERIAL:\n"""\n${request.referenceMaterial}\n"""\n`
    : "";

  const userPrompt = `Generate ${count} original, high-quality NEET-UG practice question(s) according to the following specifications:

- Exam Track: NEET-UG (${examYear})
- Subject: ${request.subject}
- Topic: ${request.topic}
${request.subtopic ? `- Subtopic: ${request.subtopic}\n` : ""}- Difficulty Level: ${request.difficulty}
- Language: ${request.languageCode || "en"}
${groundingText}
REQUIREMENTS:
1. Generate exactly ${count} question(s).
2. Each question MUST have exactly 4 options: "A", "B", "C", "D".
3. Exactly one option must have "isCorrect": true.
4. "correctOptionKey" must match the key of the correct option ("A", "B", "C", or "D").
5. Do NOT make Option A the correct answer for every question.
6. Provide an in-depth explanation covering both the correct solution and why distractors are incorrect.

OUTPUT SCHEMA (JSON root object):
{
  "questions": [
    {
      "questionText": "Clinical or conceptual question stem...",
      "difficulty": "${request.difficulty}",
      "subject": "${request.subject}",
      "topic": "${request.topic}",
      ${request.subtopic ? `"subtopic": "${request.subtopic}",` : ""}
      "options": [
        { "optionKey": "A", "optionText": "Option text A", "isCorrect": false },
        { "optionKey": "B", "optionText": "Option text B", "isCorrect": true },
        { "optionKey": "C", "optionText": "Option text C", "isCorrect": false },
        { "optionKey": "D", "optionText": "Option text D", "isCorrect": false }
      ],
      "correctOptionKey": "B",
      "explanation": "Detailed scientific explanation of the concept, derivation, or biological pathway...",
      "sourceReference": "NCERT Class 11/12 Chapter reference"
    }
  ]
}`;

  return { systemPrompt, userPrompt };
}
