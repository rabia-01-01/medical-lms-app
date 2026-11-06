import { describe, it, expect } from 'vitest';
import { NeetUg2026ScoringStrategy } from '../../../packages/exam-engine/src/neet-ug/scoring';
import { QuestionAttempt } from '../../../packages/exam-engine/src/types';

describe('NEET-UG 2026 Scoring & Adjudication Conformance', () => {
  const strategy = new NeetUg2026ScoringStrategy();

  it('correctly calculates maximum raw score (180 questions = 720 marks)', () => {
    const attempts: QuestionAttempt[] = Array.from({ length: 180 }, (_, i) => ({
      questionId: `neet-q-${i + 1}`,
      sectionCode: i < 45 ? 'NEET_PHYSICS' : i < 90 ? 'NEET_CHEMISTRY' : 'NEET_BIOLOGY',
      selectedOptionIds: ['opt-correct'],
      correctOptionIds: ['opt-correct'],
    }));

    const result = strategy.scoreAttempt(attempts);
    expect(result.rawScore).toBe(720);
    expect(result.correctCount).toBe(180);
    expect(result.incorrectCount).toBe(0);
  });

  it('awards +4 to all candidates for INVALID_OR_DROPPED questions regardless of attempt', () => {
    const attempts: QuestionAttempt[] = [
      {
        questionId: 'dropped-q1',
        sectionCode: 'NEET_PHYSICS',
        selectedOptionIds: [], // Unanswered
        correctOptionIds: ['opt-1'],
        adjudicationStatus: 'INVALID_OR_DROPPED',
      },
      {
        questionId: 'dropped-q2',
        sectionCode: 'NEET_CHEMISTRY',
        selectedOptionIds: ['opt-wrong'], // Marked wrong
        correctOptionIds: ['opt-1'],
        adjudicationStatus: 'INVALID_OR_DROPPED',
      },
    ];

    const result = strategy.scoreAttempt(attempts);
    expect(result.rawScore).toBe(8); // +4 + +4 = 8
  });

  it('awards +4 for MULTIPLE_CORRECT only if candidate selected any correct option', () => {
    const attempts: QuestionAttempt[] = [
      {
        questionId: 'mult-q1',
        sectionCode: 'NEET_BIOLOGY',
        selectedOptionIds: ['opt-2'],
        correctOptionIds: ['opt-1', 'opt-2'], // Both 1 & 2 are correct
        adjudicationStatus: 'MULTIPLE_CORRECT',
      },
      {
        questionId: 'mult-q2',
        sectionCode: 'NEET_BIOLOGY',
        selectedOptionIds: ['opt-4'], // Marked option 4 (wrong)
        correctOptionIds: ['opt-1', 'opt-2'],
        adjudicationStatus: 'MULTIPLE_CORRECT',
      },
    ];

    const result = strategy.scoreAttempt(attempts);
    // q1: +4, q2: -1 => 3
    expect(result.rawScore).toBe(3);
  });
});

