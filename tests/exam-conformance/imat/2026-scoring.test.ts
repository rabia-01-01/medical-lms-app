import { describe, it, expect } from 'vitest';
import { Imat2026ScoringStrategy } from '../../../packages/exam-engine/src/imat/scoring';
import { QuestionAttempt } from '../../../packages/exam-engine/src/types';

describe('IMAT 2026/27 Scoring Conformance', () => {
  const strategy = new Imat2026ScoringStrategy();

  it('correctly calculates maximum possible raw score (60 correct questions = 90.0 marks)', () => {
    const attempts: QuestionAttempt[] = Array.from({ length: 60 }, (_, i) => ({
      questionId: `q-${i + 1}`,
      sectionCode: i < 4 ? 'IMAT_READING' : i < 9 ? 'IMAT_LOGIC' : i < 32 ? 'IMAT_BIO' : i < 47 ? 'IMAT_CHEM' : 'IMAT_MATH_PHYS',
      selectedOptionIds: ['opt-1'],
      correctOptionIds: ['opt-1'],
    }));

    const result = strategy.scoreAttempt(attempts);
    expect(result.rawScore).toBe(90.0);
    expect(result.correctCount).toBe(60);
    expect(result.incorrectCount).toBe(0);
    expect(result.unansweredCount).toBe(0);
    expect(result.accuracyPercentage).toBe(100);
  });

  it('deducts 0.4 for incorrect answers and 0 for unanswered', () => {
    const attempts: QuestionAttempt[] = [
      // 10 correct (+1.5 * 10 = +15.0)
      ...Array.from({ length: 10 }, (_, i) => ({
        questionId: `q-corr-${i}`,
        sectionCode: 'IMAT_BIO',
        selectedOptionIds: ['opt-correct'],
        correctOptionIds: ['opt-correct'],
      })),
      // 5 incorrect (-0.4 * 5 = -2.0)
      ...Array.from({ length: 5 }, (_, i) => ({
        questionId: `q-inc-${i}`,
        sectionCode: 'IMAT_BIO',
        selectedOptionIds: ['opt-wrong'],
        correctOptionIds: ['opt-correct'],
      })),
      // 45 unanswered (0 * 45 = 0)
      ...Array.from({ length: 45 }, (_, i) => ({
        questionId: `q-unans-${i}`,
        sectionCode: 'IMAT_CHEM',
        selectedOptionIds: [],
        correctOptionIds: ['opt-correct'],
      })),
    ];

    const result = strategy.scoreAttempt(attempts);
    expect(result.rawScore).toBe(13.0); // 15.0 - 2.0 = 13.0
    expect(result.correctCount).toBe(10);
    expect(result.incorrectCount).toBe(5);
    expect(result.unansweredCount).toBe(45);
  });
});

