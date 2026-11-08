import { ExamScoreResult, ExamScoringStrategy, QuestionAttempt, SectionScore } from '../types';

export class NeetUg2026ScoringStrategy implements ExamScoringStrategy {
  public readonly policyCode = 'NEET_UG_STANDARD_2026';
  public readonly correctMarks = 4.0;
  public readonly incorrectMarks = -1.0;
  public readonly unansweredMarks = 0.0;
  public readonly maxScore = 720.0;

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
      const status = item.adjudicationStatus || 'STANDARD';

      let marks = 0;

      if (status === 'INVALID_OR_DROPPED') {
        // Full +4 awarded to ALL candidates whether attempted or not
        marks = this.correctMarks;
        correctCount++;
        sec.correctCount++;
      } else if (status === 'ALL_OPTIONS_CORRECT') {
        // +4 awarded to anyone who attempted
        if (isAttempted) {
          marks = this.correctMarks;
          correctCount++;
          sec.correctCount++;
        } else {
          marks = this.unansweredMarks;
          unansweredCount++;
          sec.unansweredCount++;
        }
      } else if (status === 'MULTIPLE_CORRECT') {
        // +4 awarded if candidate marked any of the correct options
        if (!isAttempted) {
          marks = this.unansweredMarks;
          unansweredCount++;
          sec.unansweredCount++;
        } else {
          const matched = item.selectedOptionIds.some((id) => item.correctOptionIds.includes(id));
          if (matched) {
            marks = this.correctMarks;
            correctCount++;
            sec.correctCount++;
          } else {
            marks = this.incorrectMarks;
            incorrectCount++;
            sec.incorrectCount++;
          }
        }
      } else {
        // STANDARD single correct
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
      }

      rawScore += marks;
      sec.score += marks;
    }

    const totalQuestions = attempts.length;
    const attemptedCount = correctCount + incorrectCount;
    const accuracyPercentage = attemptedCount > 0 ? (correctCount / attemptedCount) * 100 : 0;
    const percentage = this.maxScore > 0 ? (rawScore / this.maxScore) * 100 : 0;

    return {
      examCode: 'NEET_UG',
      examYear: 2026,
      rawScore,
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
