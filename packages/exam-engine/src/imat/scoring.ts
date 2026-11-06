import { ExamScoreResult, ExamScoringStrategy, QuestionAttempt, SectionScore } from '../types';

export class Imat2026ScoringStrategy implements ExamScoringStrategy {
  public readonly policyCode = 'IMAT_STANDARD_2026_27';
  public readonly correctMarks = 1.5;
  public readonly incorrectMarks = -0.4;
  public readonly unansweredMarks = 0.0;
  public readonly maxScore = 90.0;

  scoreAttempt(attempts: QuestionAttempt[]): ExamScoreResult {
    let rawScore = 0;
    let correctCount = 0;
    let incorrectCount = 0;
    let unansweredCount = 0;

    const sectionBreakdown: Record<string, SectionScore> = {};

    for (const item of attempts) {
      if (!sectionBreakdown[item.sectionCode]) {
        sectionBreakdown[item.sectionCode] = {
          sectionCode: item.sectionCode,
          correctCount: 0,
          incorrectCount: 0,
          unansweredCount: 0,
          score: 0,
          maxScore: 0,
        };
      }
      const sec = sectionBreakdown[item.sectionCode];
      sec.maxScore += this.correctMarks;

      const isAttempted = item.selectedOptionIds && item.selectedOptionIds.length > 0;

      let marks = 0;
      if (!isAttempted) {
        marks = this.unansweredMarks;
        unansweredCount++;
        sec.unansweredCount++;
      } else {
        const isCorrect =
          item.selectedOptionIds.length === 1 &&
          item.correctOptionIds.includes(item.selectedOptionIds[0]);

        if (isCorrect) {
          marks = this.correctMarks;
          correctCount++;
          sec.correctCount++;
        } else {
          marks = this.incorrectMarks;
          incorrectCount++;
          sec.incorrectCount++;
        }
      }

      rawScore += marks;
      sec.score += marks;
    }

    const totalQuestions = attempts.length;
    const attemptedCount = correctCount + incorrectCount;
    const accuracyPercentage = attemptedCount > 0 ? (correctCount / attemptedCount) * 100 : 0;
    const percentage = this.maxScore > 0 ? (rawScore / this.maxScore) * 100 : 0;

    return {
      examCode: 'IMAT',
      examYear: 2026,
      rawScore: Number(rawScore.toFixed(2)),
      maxScore: this.maxScore,
      percentage: Number(percentage.toFixed(2)),
      accuracyPercentage: Number(accuracyPercentage.toFixed(2)),
      totalQuestions,
      correctCount,
      incorrectCount,
      unansweredCount,
      sectionBreakdown,
      scoringPolicyCode: this.policyCode,
    };
  }
}

