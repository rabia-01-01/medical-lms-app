export type ExamCode = 'NEET_UG' | 'IMAT';

export interface QuestionAttempt {
  questionId: string;
  sectionCode: string;
  selectedOptionIds: string[];
  correctOptionIds: string[];
  adjudicationStatus?:
    'STANDARD' | 'MULTIPLE_CORRECT' | 'ALL_OPTIONS_CORRECT' | 'INVALID_OR_DROPPED';
}

export interface SectionScore {
  sectionCode: string;
  correctCount: number;
  incorrectCount: number;
  unansweredCount: number;
  score: number;
  maxScore: number;
}

export interface ExamScoreResult {
  examCode: ExamCode;
  examYear: number;
  rawScore: number;
  maxScore: number;
  percentage: number;
  accuracyPercentage: number;
  totalQuestions: number;
  correctCount: number;
  incorrectCount: number;
  unansweredCount: number;
  sectionBreakdown: Record<string, SectionScore>;
  scoringPolicyCode: string;
}

export interface ExamScoringStrategy {
  scoreAttempt(attempts: QuestionAttempt[]): ExamScoreResult;
}
