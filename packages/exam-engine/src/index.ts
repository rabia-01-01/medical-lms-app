export * from './types';
export * from './neet-ug';
export * from './imat';

import { ExamCode, ExamScoringStrategy } from './types';
import { NeetUg2026ScoringStrategy } from './neet-ug';
import { Imat2026ScoringStrategy } from './imat';

export function getScoringStrategy(examCode: ExamCode, examYear: number = 2026): ExamScoringStrategy {
  if (examCode === 'NEET_UG') {
    return new NeetUg2026ScoringStrategy();
  }
  if (examCode === 'IMAT') {
    return new Imat2026ScoringStrategy();
  }
  throw new Error(`Unsupported exam track: ${examCode} for year ${examYear}`);
}

