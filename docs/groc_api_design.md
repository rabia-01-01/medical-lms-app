# MedPrep — API Architecture & Endpoints Specification

**Scope:** Dual-Track NEET-UG & IMAT Learning Management & Assessment Platform  
**Architecture:** Node.js + Express Modular Monolith (`apps/api`)  
**Shared Contracts:** `@medprepos/api-contracts`

---

## 1. Authentication & Tenant Context Middleware Pipeline

Every request passes through the following standard pipeline:

```text
HTTP Request
     │
     ▼
[cors + helmet + requestId]
     │
     ▼
[authenticate.ts] ──────► Verifies Supabase Bearer JWT & extracts `sub` (profile_id)
     │
     ▼
[resolve-membership.ts] ─► Injects current active institution_id & user role (RBAC)
     │
     ▼
[require-exam-access.ts] ─► Verifies student has active entitlement for NEET_UG / IMAT
     │
     ▼
[validate-request.ts] ──► Validates request body / params / query using Zod DTO schema
     │
     ▼
[Domain Controller]
     │
     ▼
[Domain Service]
```

---

## 2. Core API Endpoints

### 2.1 Identity & Exam Track Selection (`/api/v1/me`)
- `GET /api/v1/me` — Retrieve current authenticated profile, role, and active institution.
- `GET /api/v1/me/exam-access` — List learner's active exam tracks (NEET_UG, IMAT, or both).
- `POST /api/v1/me/exam-access` — Enroll in an exam track and select official cycle/year.
- `PATCH /api/v1/me/exam-access/:accessId` — Switch active target exam year or syllabus version.

### 2.2 Exam Tracks & Curriculums (`/api/v1/exam-tracks`)
- `GET /api/v1/exam-tracks` — List supported tracks (`NEET_UG`, `IMAT`).
- `GET /api/v1/exam-tracks/:examCode/versions` — Get version history (e.g. 2026 baseline).
- `GET /api/v1/exam-versions/:versionId` — Get blueprint details (sections, timing, scoring policy).
- `GET /api/v1/exam-versions/:versionId/curriculum` — Get complete hierarchical syllabus tree.
- `GET /api/v1/syllabus-nodes/:nodeId` — Get single node (Subject, Chapter, Topic) with learning objectives.

### 2.3 Learning Resources (`/api/v1/resources`)
- `GET /api/v1/resources` — List resources filtered by track, node, batch, and status.
- `GET /api/v1/resources/:resourceId` — Fetch resource metadata & short-lived signed URLs for documents/videos.
- `POST /api/v1/resources` — Faculty drafts a learning resource.
- `POST /api/v1/resources/:resourceId/submit-review` — Submit for academic review.
- `POST /api/v1/resources/:resourceId/publish` — Publish resource to assigned batches.

### 2.4 Question Bank & AI Drafting (`/api/v1/questions`, `/api/v1/ai`)
- `GET /api/v1/questions` — Filter questions by syllabus node, difficulty, and review status.
- `POST /api/v1/questions` — Create question draft with options and confidential answer key.
- `POST /api/v1/questions/:questionId/versions` — Create an immutable revision.
- `POST /api/v1/question-versions/:versionId/review` — Review and approve/reject question version.
- `POST /api/v1/ai/question-drafts` — Trigger background AI drafting job (Groq LLM).
- `GET /api/v1/ai/question-drafts/:draftId` — Check generation job status & structured output.

### 2.5 Assessments & Authoritative Scoring (`/api/v1/assessments`, `/api/v1/attempts`)
- `GET /api/v1/assessments` — List scheduled/practice assessments for learner's track & batch.
- `POST /api/v1/assessment-versions/:versionId/attempts` — Start assessment attempt; records server start time and deadline.
- `GET /api/v1/attempts/:attemptId` — Resume attempt; returns questions (strictly without answer keys) and autosaved answers.
- `PUT /api/v1/attempts/:attemptId/answers/:questionVersionId` — Idempotent autosave answer selection.
- `POST /api/v1/attempts/:attemptId/submit` — Finalize attempt and trigger server-side score calculation.
- `GET /api/v1/attempts/:attemptId/result` — Get authoritative score breakdown (subject to release schedule).
- `POST /api/v1/attempts/:attemptId/request-review` — Submit question dispute for academic review.

