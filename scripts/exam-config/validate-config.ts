import fs from 'fs';
import path from 'path';

function validateJson(filePath: string) {
  try {
    const raw = fs.readFileSync(filePath, 'utf-8');
    const data = JSON.parse(raw);
    if (!data.examCode || !data.examYear || !data.scoringPolicy) {
      throw new Error(`Missing required fields in ${filePath}`);
    }
    console.log(`✓ Validated ${data.examCode} ${data.examYear} configuration.`);
  } catch (err) {
    console.error(`✗ Error in ${filePath}:`, err);
    process.exit(1);
  }
}

const seedDir = path.resolve(__dirname, '../../supabase/seed/exam-versions');
validateJson(path.join(seedDir, 'neet-ug/2026.json'));
validateJson(path.join(seedDir, 'imat/2026-27.json'));
console.log('All official exam blueprints verified successfully.');
