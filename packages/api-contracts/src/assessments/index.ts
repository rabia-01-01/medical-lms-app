import { z } from 'zod';
import { ExamTrackCodeEnum } from '../auth';

export const AutosaveAnswerSchema = z.object({
  attemptId: z.string().uuid(),
  questionVersionId: z.string().uuid(),
  selectedOptionIds: z.array(z.string().uuid()),
  isMarkedForReview: z.boolean().default(false),
  timeSpentSeconds: z.number().nonnegative().optional(),
});
export type AutosaveAnswerInput = z.infer<typeof AutosaveAnswerSchema>;

export const SubmitAssessmentSchema = z.object({
  attemptId: z.string().uuid(),
  clientFinishedAt: z.string().datetime(),
});
export type SubmitAssessmentInput = z.infer<typeof SubmitAssessmentSchema>;

export interface StudentQuestionViewDto {
  id: string;
  questionVersionId: string;
  sectionCode: string;
  questionNumber: number;
  stem: string;
  options: {
    id: string;
    optionKey: string;
    text: string;
  }[];
  // Correct answers and explanations are STRICTLY excluded during active testing!
}

export interface AssessmentAttemptDto {
  attemptId: string;
  assessmentId: string;
  title: string;
  examTrack: z.infer<typeof ExamTrackCodeEnum>;
  totalQuestions: number;
  durationMinutes: number;
  startedAt: string;
  serverDeadlineAt: string;
  questions: StudentQuestionViewDto[];
}
