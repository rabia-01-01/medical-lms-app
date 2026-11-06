import { describe, it, expect, vi, beforeEach } from 'vitest';
import { GroqQuestionProvider } from '../groq-provider';
import { QuestionDraftRequest } from '../types';

describe('GroqQuestionProvider', () => {
  const sampleNeetRequest: QuestionDraftRequest = {
    examCode: 'NEET_UG',
    examVersionId: 'ver-neet-2026',
    sectionId: 'sec-biology',
    syllabusNodeId: 'node-genetics',
    subject: 'Biology',
    topic: 'Principles of Inheritance',
    difficulty: 'MEDIUM',
    count: 1,
    languageCode: 'en',
  };

  const sampleImatRequest: QuestionDraftRequest = {
    examCode: 'IMAT',
    examVersionId: 'ver-imat-2026',
    sectionId: 'sec-chemistry',
    syllabusNodeId: 'node-bonding',
    subject: 'Chemistry',
    topic: 'Covalent Bonding and Molecular Shapes',
    difficulty: 'HARD',
    count: 1,
    languageCode: 'en',
  };

  const validNeetMockContent = JSON.stringify({
    questions: [
      {
        questionText: 'What phenotypic ratio is expected in the F2 generation of a classic Mendelian monohybrid cross?',
        difficulty: 'MEDIUM',
        subject: 'Biology',
        topic: 'Principles of Inheritance',
        options: [
          { optionKey: 'A', optionText: '3:1 (dominant to recessive)', isCorrect: true },
          { optionKey: 'B', optionText: '9:3:3:1', isCorrect: false },
          { optionKey: 'C', optionText: '1:2:1', isCorrect: false },
          { optionKey: 'D', optionText: '1:1', isCorrect: false },
        ],
        correctOptionKey: 'A',
        explanation: 'In a monohybrid cross between heterozygotes (Aa x Aa), the phenotypic ratio is 3 dominant to 1 recessive, while genotypic is 1:2:1.',
        sourceReference: 'NCERT Biology Class 12',
      },
    ],
  });

  const validImatMockContent = JSON.stringify({
    questions: [
      {
        questionText: 'According to VSEPR theory, what is the geometric shape of the sulfur tetrafluoride (SF4) molecule?',
        difficulty: 'HARD',
        subject: 'Chemistry',
        topic: 'Covalent Bonding and Molecular Shapes',
        options: [
          { optionKey: 'A', optionText: 'See-saw geometry based on trigonal bipyramidal electron geometry', isCorrect: true },
          { optionKey: 'B', optionText: 'Regular tetrahedral geometry', isCorrect: false },
          { optionKey: 'C', optionText: 'Square planar geometry with two axial lone pairs', isCorrect: false },
          { optionKey: 'D', optionText: 'Trigonal pyramidal geometry', isCorrect: false },
          { optionKey: 'E', optionText: 'T-shaped molecular geometry', isCorrect: false },
        ],
        correctOptionKey: 'A',
        explanation: 'SF4 has 5 electron domains (4 bonding pairs, 1 equatorial lone pair), resulting in a see-saw molecular shape.',
        sourceReference: 'IMAT Chemistry Specification: Chemical Bonding',
      },
    ],
  });

  let mockCreate: ReturnType<typeof vi.fn>;
  let mockGroqClient: any;

  beforeEach(() => {
    mockCreate = vi.fn();
    mockGroqClient = {
      chat: {
        completions: {
          create: mockCreate,
        },
      },
    };
  });

  it('successfully generates and validates NEET-UG questions with primary model', async () => {
    mockCreate.mockResolvedValueOnce({
      choices: [{ message: { content: validNeetMockContent } }],
      usage: { prompt_tokens: 350, completion_tokens: 200, total_tokens: 550 },
    });

    const provider = new GroqQuestionProvider(
      {
        apiKey: 'gsk_test_key',
        model: 'llama-3.3-70b-versatile',
        maxRetries: 2,
        timeoutMs: 5000,
      },
      mockGroqClient
    );

    const result = await provider.generateDraftQuestions(sampleNeetRequest);

    expect(result.provider).toBe('GROQ');
    expect(result.model).toBe('llama-3.3-70b-versatile');
    expect(result.questions).toHaveLength(1);
    expect(result.questions[0].options).toHaveLength(4);
    expect(result.usage.totalTokens).toBe(550);
    expect(mockCreate).toHaveBeenCalledTimes(1);
  });

  it('successfully generates and validates IMAT questions with 5 options', async () => {
    mockCreate.mockResolvedValueOnce({
      choices: [{ message: { content: validImatMockContent } }],
      usage: { prompt_tokens: 420, completion_tokens: 280, total_tokens: 700 },
    });

    const provider = new GroqQuestionProvider(
      {
        apiKey: 'gsk_test_key',
        model: 'llama-3.3-70b-versatile',
        maxRetries: 2,
        timeoutMs: 5000,
      },
      mockGroqClient
    );

    const result = await provider.generateDraftQuestions(sampleImatRequest);

    expect(result.questions).toHaveLength(1);
    expect(result.questions[0].options).toHaveLength(5);
    expect(result.questions[0].options.map((o) => o.optionKey)).toEqual(['A', 'B', 'C', 'D', 'E']);
  });

  it('retries on HTTP 429 rate limit error and recovers', async () => {
    // 1st attempt: 429 Rate limit
    mockCreate.mockRejectedValueOnce({ status: 429, message: 'Rate limit exceeded' });
    // 2nd attempt: Success
    mockCreate.mockResolvedValueOnce({
      choices: [{ message: { content: validNeetMockContent } }],
      usage: { prompt_tokens: 300, completion_tokens: 150, total_tokens: 450 },
    });

    const provider = new GroqQuestionProvider(
      {
        apiKey: 'gsk_test_key',
        model: 'llama-3.3-70b-versatile',
        maxRetries: 3,
        timeoutMs: 5000,
      },
      mockGroqClient
    );

    const result = await provider.generateDraftQuestions(sampleNeetRequest);

    expect(result.questions).toHaveLength(1);
    expect(mockCreate).toHaveBeenCalledTimes(2);
  });

  it('falls back to secondary model when primary model fails', async () => {
    // Primary model attempts fail with fatal 400 error
    mockCreate.mockRejectedValueOnce(new Error('Model unavailable'));
    // Fallback model attempt succeeds
    mockCreate.mockResolvedValueOnce({
      choices: [{ message: { content: validNeetMockContent } }],
      usage: { prompt_tokens: 250, completion_tokens: 120, total_tokens: 370 },
    });

    const provider = new GroqQuestionProvider(
      {
        apiKey: 'gsk_test_key',
        model: 'llama-3.3-70b-versatile',
        fallbackModel: 'llama-3.1-8b-instant',
        maxRetries: 1,
        timeoutMs: 5000,
      },
      mockGroqClient
    );

    const result = await provider.generateDraftQuestions(sampleNeetRequest);

    expect(result.model).toBe('llama-3.1-8b-instant');
    expect(result.questions).toHaveLength(1);
    expect(mockCreate).toHaveBeenCalledTimes(2);
  });

  it('throws descriptive error when Groq returns malformed unparseable JSON', async () => {
    mockCreate.mockResolvedValueOnce({
      choices: [{ message: { content: 'This is not JSON at all!' } }],
    });
    // Fallback also returns malformed
    mockCreate.mockResolvedValueOnce({
      choices: [{ message: { content: 'Still not JSON!' } }],
    });

    const provider = new GroqQuestionProvider(
      {
        apiKey: 'gsk_test_key',
        maxRetries: 1,
      },
      mockGroqClient
    );

    await expect(provider.generateDraftQuestions(sampleNeetRequest)).rejects.toThrow(
      /malformed JSON output/
    );
  });
});

