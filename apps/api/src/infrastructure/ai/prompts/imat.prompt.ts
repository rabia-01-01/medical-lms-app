import { QuestionDraftRequest } from "../types";

/**
 * IMAT Prompt Engineering:
 * - Strictly 5 options: A, B, C, D, E
 * - Curriculum: Italian Ministry of University and Research (MUR) Decree & Cambridge Assessment standards
 * - Sections: Reading Skills and Knowledge, Logical Reasoning, Biology, Chemistry, Physics & Mathematics
 * - Explicit rule: "Reading Skills and Knowledge" is NOT an English grammar test; it tests analytical reading, argument reasoning, and historical/general cultural literacy.
 * - Explicit distribution instruction: Avoid Option A bias across the 5 options.
 */

export function buildImatPrompt(request: QuestionDraftRequest): {
  systemPrompt: string;
  userPrompt: string;
} {
  const count = request.count || 1;
  const examYear = request.examYear || 2026;

  const systemPrompt = `You are a Senior Faculty and Question Designer for the International Medical Admissions Test (IMAT), administered for admissions into Italian public medical faculties teaching in English.

CRITICAL EXAMINATION RULES FOR IMAT:
1. Format: Multiple Choice Questions (MCQ) with EXACTLY 5 OPTIONS labeled "A", "B", "C", "D", and "E".
2. Curricular Grounding: Adhere to the Italian Ministry of University and Research (MUR) decree guidelines (${examYear} specification) covering:
   - Reading Skills and Knowledge Acquired in Studies (complex text analysis, logical structure of arguments, cultural/historical/philosophical literacy — NEVER English grammar drills).
   - Logical Reasoning (critical thinking, assumption identification, argument strengthening/weakening, numerical problem solving).
   - Biology (cellular biology, bioenergetics, genetics, human anatomy and physiology, evolution).
   - Chemistry (atomic structure, bonding, thermodynamics, chemical kinetics, solutions, organic chemistry).
   - Physics & Mathematics (mechanics, fluid dynamics, electromagnetism, optics; functions, probability, geometry).
3. Option Bias Prevention: NEVER make Option A the default correct answer. Distribute correct answers across "A", "B", "C", "D", and "E" with equal frequency.
4. Distractor Quality: Distractors must represent plausible misconceptions, invalid logical inversions, or common diagnostic traps.
5. Language: High-level academic English appropriate for international medical applicants.
6. Detailed Rationale: Provide a comprehensive explanation detailing why the selected option is correct and why each of the 4 distractors is incorrect.
7. Output Format: You MUST output ONLY valid JSON adhering strictly to the requested schema. No conversational filler, markdown fences, or markdown wrapping.`;

  const groundingText = request.referenceMaterial
    ? `\nREFERENCE GROUNDING MATERIAL:\n"""\n${request.referenceMaterial}\n"""\n`
    : "";

  const userPrompt = `Generate ${count} original, high-quality IMAT practice question(s) according to the following specifications:

- Exam Track: IMAT (${examYear})
- Section / Subject: ${request.subject}
- Topic: ${request.topic}
${request.subtopic ? `- Subtopic: ${request.subtopic}\n` : ""}- Difficulty Level: ${request.difficulty}
- Language: en (English only)
${groundingText}
REQUIREMENTS:
1. Generate exactly ${count} question(s).
2. Each question MUST have exactly 5 options: "A", "B", "C", "D", "E".
3. Exactly one option must have "isCorrect": true.
4. "correctOptionKey" must match the key of the correct option ("A", "B", "C", "D", or "E").
5. Do NOT make Option A the correct answer for every question.
6. Provide an in-depth explanation evaluating all 5 options.

OUTPUT SCHEMA (JSON root object):
{
  "questions": [
    {
      "questionText": "Analytical or clinical question stem...",
      "difficulty": "${request.difficulty}",
      "subject": "${request.subject}",
      "topic": "${request.topic}",
      ${request.subtopic ? `"subtopic": "${request.subtopic}",` : ""}
      "options": [
        { "optionKey": "A", "optionText": "Option text A", "isCorrect": false },
        { "optionKey": "B", "optionText": "Option text B", "isCorrect": false },
        { "optionKey": "C", "optionText": "Option text C", "isCorrect": true },
        { "optionKey": "D", "optionText": "Option text D", "isCorrect": false },
        { "optionKey": "E", "optionText": "Option text E", "isCorrect": false }
      ],
      "correctOptionKey": "C",
      "explanation": "Detailed step-by-step reasoning explaining why option C is correct and why options A, B, D, and E are invalid...",
      "sourceReference": "IMAT Syllabus Section reference"
    }
  ]
}`;

  return { systemPrompt, userPrompt };
}
