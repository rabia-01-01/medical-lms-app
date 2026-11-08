import { ExamTrackCode } from '../auth';

export interface SyllabusNodeDto {
  id: string;
  parentId: string | null;
  examTrack: ExamTrackCode;
  nodeType: 'SUBJECT' | 'SECTION' | 'CHAPTER' | 'TOPIC' | 'SKILL';
  code: string;
  title: string;
  displayOrder: number;
  learningObjectives?: string[];
  isCompleted?: boolean;
}
