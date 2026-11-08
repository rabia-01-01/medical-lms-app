import { z } from 'zod';

export const ExamTrackCodeEnum = z.enum(['NEET_UG', 'IMAT']);
export type ExamTrackCode = z.infer<typeof ExamTrackCodeEnum>;

export const SelectExamTrackSchema = z.object({
  trackCode: ExamTrackCodeEnum,
  examYear: z.number().int().min(2024).max(2030),
});
export type SelectExamTrackInput = z.infer<typeof SelectExamTrackSchema>;

export interface UserProfileDto {
  id: string;
  email: string;
  fullName: string | null;
  activeTracks: ExamTrackCode[];
  activeInstitutionId: string | null;
  role: 'STUDENT' | 'FACULTY' | 'INSTITUTE_ADMIN' | 'PLATFORM_ADMIN';
}
