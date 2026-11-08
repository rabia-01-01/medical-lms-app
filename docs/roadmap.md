# MedPrep — Engineering & Product Roadmap (Phase by Phase)

## Scalable, Dual-Track NEET-UG & IMAT Learning, Practice & Assessment Platform

| Document Attribute         | Details                                                                                           |
| -------------------------- | ------------------------------------------------------------------------------------------------- |
| **Document Version**       | 1.0 (Master Delivery Plan)                                                                        |
| **Aligned Specifications** | `PRD.md` (v1.0), `project_overview.md` (v3.0), `db.sql`, `api_design.md`                          |
| **Current Test Baseline**  | 11 Test Suites, 55 Tests Passing (Scoring Conformance, AI Infrastructure, Security Guards)        |
| **Architecture**           | TypeScript Monorepo, React + Vite, Node.js/Express Modular Monolith, PostgreSQL/Supabase with RLS |
| **Status**                 | Active Execution Blueprint                                                                        |

---

# 1. Executive Project Health & Implementation Audit

Before detailing future phases, the following audit establishes the exact current implementation state across all layers of the monorepo:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             MedPrep Monorepo State                             │
└──────────────────────────────────────────────────────────────────────────────────┘
  ├── packages/
  │    ├── @MedPrep/exam-engine      ✅ COMPLETE (NEET-UG & IMAT 2026 Scoring Strategies)
  │    ├── @MedPrep/api-contracts    ⚠️ PARTIAL (Auth, Assessments, Curriculum DTOs done)
  │    ├── @MedPrep/database         ✅ COMPLETE (Client factories, Database types)
  │    └── @MedPrep/config           ✅ COMPLETE (TypeScript presets)
  │
  ├── database/ & supabase/
  │    ├── db.sql (51 tables, 27 enums) ✅ COMPLETE (Full DDL, RLS, Procedures, Views)
  │    ├── supabase/migrations         ✅ COMPLETE (14 ordered migration files)
  │    └── seed/exam-versions          ✅ COMPLETE (NEET-UG 2026 & IMAT 2026/27 baseline seeds)
  │
  ├── apps/api/ (Node.js / Express Modular Monolith)
  │    ├── infrastructure/ai/          ✅ COMPLETE (Groq SDK, Llama 3.3/3.1, Prompts, Anti-Bias)
  │    ├── domains/content-bank/       ✅ COMPLETE (AI Drafts routes, service, repo, reviews)
  │    ├── middleware/                 ✅ COMPLETE (authenticate, require-permission, rate-limit)
  │    ├── domains/identity/           ⏳ PENDING (Profile & track selection routes)
  │    ├── domains/academics/          ⏳ PENDING (Syllabus tree & curriculum routes)
  │    ├── domains/assessments/        ⏳ PENDING (Test runner, autosave & submit routes)
  │    └── domains/learning/           ⏳ PENDING (Progress tracking & revision routes)
  │
  ├── apps/web/ (React + Vite Client)
  │    ├── app/ (Shell, routing, guards) ⏳ PENDING (Layouts, routers & state providers)
  │    ├── features/ (Domain slices)    ⏳ PENDING (Assessment runner, curriculum tree, radars)
  │    └── pages/ (Role portals)        ⏳ PENDING (Student, Faculty, Admin views)
  │
  └── tests/
       ├── exam-conformance/           ✅ COMPLETE (NEET-UG & IMAT scoring vectors passing)
       └── apps/api/ unit & integration ✅ COMPLETE (50 tests passing in API & AI infrastructure)
```

---

# 2. Phase-by-Phase Implementation Roadmap

```
Phase 0: Specifications & Blueprints (Completed)
   │
   ▼
Phase 1: Foundation, Identity & Dual-Track Selection (Sprints 1–2)
   │
   ▼
Phase 2: Curriculum Taxonomy & Learning Resources (Sprints 3–4)
   │
   ▼
Phase 3: Question Bank Governance & AI Question Drafting (Sprints 5–6)
   │
   ▼
Phase 4: Unified Assessment Engine, Autosave & Scoring (Sprints 7–9)
   │
   ▼
Phase 5: Performance Radar Analytics & Revision Guidance (Sprints 10–11)
   │
   ▼
Phase 6: Pilot Hardening, Load Concurrency & Launch (Sprints 12–14)
   │
   ▼
Phase 7: Subscriptions, Scale & Post-MVP Expansion (Post-Launch)
```

---

## Phase 0: Research, Baselines & Formal Specifications

**Status: COMPLETED**

- **Objective:** Establish authoritative regulatory baselines for NEET-UG and IMAT, define physical database schemas, design modular monolith APIs, and formalize product requirements.
- **Key Milestones Achieved:**
  - Verified NTA NEET-UG 2026 Information Bulletin (180 questions, 4 options, `+4/-1`, dropped-question adjudication).
  - Verified Italian MUR Ministerial Decree No. 1005 (IMAT 2026/27 baseline: 60 questions, 5 options, `+1.5/-0.4`, 5 discrete sections).
  - Authored physical database schema [`database/db.sql`](file:///c:/Users/ASUS/Downloads/Medical_LMS/database/db.sql) with 51 tables, stored procedures, RLS policies, and analytical views.
  - Implemented `@MedPrep/exam-engine` package with 100% test pass on official scoring vectors.
  - Formulated master [`PRD.md`](file:///c:/Users/ASUS/Downloads/Medical_LMS/PRD.md) addressing cross-document discrepancies.

---

## Phase 1: Core Foundation, Identity & Dual-Track Selection

**Target Duration:** Sprint 1 – Sprint 2 (Weeks 1–4)  
**Primary Goal:** Deliver end-to-end user onboarding, Supabase Auth integration, trusted role resolution, and independent dual-track selection (`NEET_UG` vs `IMAT` vs `BOTH`).

### 1. Work Packages & Technical Deliverables

#### Track A: Shared Packages & Contracts

- **Task 1.1:** Expand `@MedPrep/api-contracts` (`auth`, `identity`, `tenancy` DTOs).
  - `SelectExamTrackSchema`, `SwitchExamYearSchema`, `InstitutionMembershipDto`.
- **Task 1.2:** Implement Supabase client session helpers in `@MedPrep/database`.

#### Track B: Backend API (`apps/api`)

- **Task 1.3:** Build `domains/identity/`:
  - `identity.service.ts`: Handle user profile sync on first login, resolve active institution memberships.
  - `identity.controller.ts` & `identity.routes.ts`: Implement `GET /api/v1/me`, `GET /api/v1/me/exam-access`, `POST /api/v1/me/exam-access`, `PATCH /api/v1/me/exam-access/:accessId`.
- **Task 1.4:** Build `domains/tenancy/`:
  - `tenancy.service.ts`: Manage institutions, academic years, invitations, and role assignments.
  - `tenancy.routes.ts`: Implement `GET /api/v1/institutions/my`, `POST /api/v1/institutions/invitations/accept`.
- **Task 1.5:** Wire authentication middleware:
  - Connect `authenticate.ts` with Supabase JWT validation.
  - Connect `resolve-membership.ts` to inject active `institution_id` and role context.

#### Track C: Frontend Application (`apps/web`)

- **Task 1.6:** Implement Application Shell & Providers:
  - `AuthProvider.tsx`: Supabase session management, token refresh, and user context.
  - `QueryProvider.tsx`: TanStack React Query configuration with safe retry policies.
  - `router/`: Define route hierarchy, `AuthGuard.tsx`, `ExamAccessGuard.tsx`, and `RoleGuard.tsx`.
- **Task 1.7:** Build Layouts:
  - `PublicLayout.tsx`, `LearnerLayout.tsx`, `FacultyLayout.tsx`, `InstituteAdminLayout.tsx`.
- **Task 1.8:** Build Core UI Screens:
  - `SCR-PUB-01` (Landing page), `SCR-AUTH-01` (Sign-in/Sign-up), `SCR-TRACK-01` (Exam track onboarding & switcher).
  - `SCR-STU-01` (Unified Student Dashboard shell with dual-track cards).

### 2. Testing & Verification Gates

- **Unit Tests:** `identity.service.test.ts`, JWT decoding tests, membership resolution tests.
- **Integration Tests:** `identity.routes.test.ts` (Track activation, independent vs institute user profile).
- **Security Tests:** Verify that user-editable metadata in Supabase Auth cannot alter roles in `institution_memberships`.
- **Exit Gate:** A student can register, log in, select NEET-UG, IMAT, or both, switch active tracks, and see isolated track dashboards.

---

## Phase 2: Curriculum Taxonomy & Learning Resources

**Target Duration:** Sprint 3 – Sprint 4 (Weeks 5–8)  
**Primary Goal:** Deliver the 5-level hierarchical syllabus trees (NCERT for NEET, MUR for IMAT) and private object storage delivery for educational resources with dynamic signed URLs.

### 1. Work Packages & Technical Deliverables

#### Track A: Database & Shared Contracts

- **Task 2.1:** Seed authoritative syllabus taxonomies:
  - NEET-UG: Physics, Chemistry, Biology (Botany & Zoology chapters/topics from NMC 2026).
  - IMAT: Reading Skills & Knowledge, Logical Reasoning, Biology, Chemistry, Physics & Mathematics.
- **Task 2.2:** Verify closure table trigger `trg_maintain_syllabus_closures` across all seeded nodes.
- **Task 2.3:** Contract definitions in `@MedPrep/api-contracts`:
  - `SyllabusTreeDto`, `TopicProgressDto`, `ResourceMetadataDto`, `SignedUrlResponseDto`.

#### Track B: Backend API (`apps/api`)

- **Task 2.4:** Build `domains/academics/`:
  - `academics.service.ts`: Query hierarchical syllabus tree using `syllabus_node_closures`.
  - `academics.routes.ts`: Implement `GET /api/v1/exam-tracks`, `GET /api/v1/exam-tracks/:examCode/versions`, `GET /api/v1/exam-versions/:versionId/curriculum`, `GET /api/v1/syllabus-nodes/:nodeId`.
- **Task 2.5:** Build `domains/learning/`:
  - `student-progress.service.ts`: Manage `student_topic_progress` (`NOT_STARTED`, `IN_PROGRESS`, `COMPLETED`).
  - Implement `GET /api/v1/learning/progress` and `PUT /api/v1/learning/progress/:syllabusNodeId`.
- **Task 2.6:** Build `domains/resources/` & `infrastructure/storage/`:
  - `storage-client.ts`: Supabase Storage wrapper generating S3 short-lived signed URLs (<= 60s).
  - `resources.service.ts`: Resource upload, batch access verification, and publication lifecycle.
  - `resources.routes.ts`: Implement `GET /api/v1/resources`, `GET /api/v1/resources/:resourceId`, `POST /api/v1/resources`, `POST /api/v1/resources/:resourceId/publish`.

#### Track C: Frontend Application (`apps/web`)

- **Task 2.7:** Build `features/curriculum/`:
  - Expandable, virtualized syllabus tree navigator with search and subject/section filters.
  - Topic completion toggle and study status badge.
- **Task 2.8:** Build `features/resources/`:
  - Resource library with filters (Notes, DPPs, Videos, Past Papers).
  - Secure PDF viewer component with client-side dynamic watermark (Student ID + Timestamp).
  - Embedded video player with authorized signed URL streaming.

### 2. Testing & Verification Gates

- **Unit Tests:** Recursive tree query performance tests, closure table integrity tests.
- **Integration Tests:** Resource batch-access entitlement tests (ensure students in Batch A cannot access Batch B resources).
- **Security Tests:** Verify that expired signed URLs (after 60s) return HTTP 403.
- **Exit Gate:** An aspirant can navigate the complete NCERT/MUR syllabus tree, track topic progress, and view batch-assigned notes/videos securely.

---

## Phase 3: Question Bank Governance & AI Question Drafting

**Target Duration:** Sprint 5 – Sprint 6 (Weeks 9–12)  
**Primary Goal:** Provide faculty question authoring, immutable versioning, confidential answer keys, and complete AI question drafting via Groq API with human-in-the-loop approval.

### 1. Work Packages & Technical Deliverables

#### Track A: Shared Contracts & AI Infrastructure

- **Task 3.1:** Contracts in `@MedPrep/api-contracts`:
  - `QuestionAuthoringInputSchema`, `QuestionVersionDto`, `AIDraftGenerateInputSchema`, `ReviewDecisionSchema`.
- **Task 3.2:** Verify existing `infrastructure/ai/` modules:
  - Groq client (`llama-3.3-70b-versatile` / `llama-3.1-8b-instant`), `neet-ug.prompt.ts`, `imat.prompt.ts`, `shuffle-options.ts`, and Zod validation schemas.

#### Track B: Backend API (`apps/api`)

- **Task 3.3:** Build `domains/content-bank/` (Manual Question Authoring):
  - `question-authoring.service.ts`: Create logical question containers, create immutable revisions (`question_versions`), store options in `question_options`, and store confidential keys in `question_answer_keys`.
  - Routes: `GET /api/v1/questions`, `POST /api/v1/questions`, `POST /api/v1/questions/:questionId/versions`, `POST /api/v1/question-versions/:versionId/review`.
- **Task 3.4:** Connect AI Question Generation Pipeline:
  - Integrate existing `createAIDraftsRouter()` into API composition.
  - Connect `ai_generation_jobs` and `ai_generation_reviews` to persist drafts strictly in `DRAFT` status.
  - Implement review decision endpoints: `POST /api/v1/content-bank/ai-drafts/reviews/:reviewId/decide`.

#### Track C: Frontend Application (`apps/web`)

- **Task 3.5:** Build `pages/faculty/`:
  - `QuestionAuthoringPage.tsx`: Rich LaTeX question editor, diagram asset uploader, 4-option / 5-option selector, confidential correct-option selector, and detailed rationale input.
  - `AIQuestionGeneratorModal.tsx`: Track/Subject/Topic/Difficulty picker with question count slider (1–10).
  - `AIFacultyReviewQueue.tsx`: Side-by-side review workspace with Approve, Edit, and Reject actions.

### 2. Testing & Verification Gates

- **Unit Tests:** Question option count validation (4 for NEET, 5 for IMAT), Fisher-Yates uniform distribution verification.
- **Integration Tests:** AI draft review state machine (`DRAFT` -> `APPROVED` / `EDITED` / `REJECTED`).
- **Security Tests:** Verify that students calling `POST /api/v1/content-bank/ai-drafts/generate` receive HTTP 403 Forbidden. Verify that `question_answer_keys` is never queried by student roles.
- **Exit Gate:** Faculty can manually author questions, generate drafts via Groq, review them in a dedicated queue, and publish approved questions to the question bank.

---

## Phase 4: Unified Assessment Engine, Autosave & Scoring

**Target Duration:** Sprint 7 – Sprint 9 (Weeks 13–18)  
**Primary Goal:** Deliver the server-authoritative assessment lifecycle: test scheduling, secure attempt initiation, idempotent autosave synchronization, deadline enforcement, and exact decimal dual-track scoring.

### 1. Work Packages & Technical Deliverables

#### Track A: Database & Engine Package

- **Task 4.1:** Verify database stored procedures in `db.sql`:
  - `start_assessment_attempt()`, `autosave_attempt_answer()`, `calculate_and_finalize_score()`.
- **Task 4.2:** Integrate `@MedPrep/exam-engine` into backend attempts domain service.

#### Track B: Backend API (`apps/api`)

- **Task 4.3:** Build `domains/assessments/`:
  - `assessments.service.ts`: Assessment authoring, batch assignment, and blueprint snapshots (`assessment_versions`).
  - Routes: `GET /api/v1/assessments`, `POST /api/v1/assessments`, `POST /api/v1/assessment-versions/:versionId/publish`.
- **Task 4.4:** Build `domains/assessments/attempts.service.ts`:
  - `startAttempt()`: Invoke `start_assessment_attempt()`; return questions **strictly without answer keys**.
  - `autosaveAnswer()`: Invoke `autosave_attempt_answer()`; enforce `deadline_at + 30s` server boundary.
  - `submitAttempt()`: Invoke `calculate_and_finalize_score()`; execute transactional scoring.
  - `getScoreResult()`: Enforce score release schedule (`release_at`).
  - Routes: `POST /api/v1/assessment-versions/:versionId/attempts`, `GET /api/v1/attempts/:attemptId`, `PUT /api/v1/attempts/:attemptId/answers/:questionVersionId`, `POST /api/v1/attempts/:attemptId/submit`, `GET /api/v1/attempts/:attemptId/result`.

#### Track C: Frontend Application (`apps/web`)

- **Task 4.5:** Build `features/assessments/`:
  - `AssessmentLobby.tsx`: Instructions, duration, section distribution, marking rules, and accommodation check.
  - `UnifiedAssessmentRunner.tsx`:
    - Dynamic blueprint driver (adapts to 180Q/4-opt for NEET; 60Q/5-opt for IMAT).
    - Question palette (Answered, Unanswered, Marked for Review).
    - Autosave hook (`useAutosave`) with debouncing and status indicator (`Saving...`, `Saved`, `Offline`).
    - Visual countdown timer synced with server `deadline_at`.
    - Unanswered questions modal on submit.
  - `ResultsAndSolutionsView.tsx`: Released score summary, section-wise breakdown, correct answer highlights, detailed explanations, and question dispute request.

### 2. Testing & Verification Gates

- **Scoring Vectors Test:** NEET ordinary scoring (26.0/40.0), NEET dropped-question (+4.0 to all), IMAT ordinary scoring (7.8/15.0).
- **Fault Injection Tests:** Browser refresh recovery, network loss simulation, submit at exact deadline, submit post-deadline (rejected with 400/403).
- **Concurrency Test:** Idempotent submission: 5 simultaneous submit calls produce exactly 1 `score_results` record.
- **Exit Gate:** An aspirant can take a full-length NEET-UG or IMAT mock test, experience seamless autosave recovery across tab refresh, and receive an authoritative, server-calculated score breakdown upon release.

---

## Phase 5: Performance Radar Analytics & Revision Guidance

**Target Duration:** Sprint 10 – Sprint 11 (Weeks 19–22)  
**Primary Goal:** Implement exam-specific radar mastery analytics, historical score progression, and evidence-based topic revision recommendations without cross-track contamination.

### 1. Work Packages & Technical Deliverables

#### Track A: Database Views & Contracts

- **Task 5.1:** Validate production analytical views in `db.sql`:
  - `view_student_performance_analytics`, `view_student_radar_mastery`, `view_revision_recommendations`.
- **Task 5.2:** Contracts in `@MedPrep/api-contracts`:
  - `PerformanceRadarDto`, `ScoreProgressionDto`, `RevisionRecommendationDto`.

#### Track B: Backend API (`apps/api`)

- **Task 5.3:** Build `domains/analytics/`:
  - `analytics.service.ts`: Query performance views filtered by active `exam_track_code` and learner profile.
  - Enforce track isolation: strictly prevent mixing NEET marks (720 scale) with IMAT marks (90 scale).
  - Routes: `GET /api/v1/analytics/overview`, `GET /api/v1/analytics/radar`, `GET /api/v1/analytics/revisions`.
- **Task 5.4:** Build `domains/communication/`:
  - Implement announcements and academic calendar events (`announcements`, `calendar_events`).
  - Routes: `GET /api/v1/announcements`, `GET /api/v1/calendar`.

#### Track C: Frontend Application (`apps/web`)

- **Task 5.5:** Build `features/analytics/`:
  - NEET Performance Radar: Physics, Chemistry, Botany, Zoology accuracy radars (using Recharts).
  - IMAT Performance Radar: Reading Skills, Logical Reasoning, Biology, Chemistry, Physics & Mathematics radars.
  - Historical score trend chart (filtered by comparable exam versions).
  - Revision Recommendation Cards: displays transparent rationale (e.g. _"Revise Human Physiology: 40% accuracy across 15 questions"_).
- **Task 5.6:** Build `features/communication/`:
  - Academic calendar view (tests, assignment deadlines, revision lectures).
  - Announcement banner and notification drawer.

### 2. Testing & Verification Gates

- **Analytics Tests:** Verify that a student enrolled in both tracks sees two completely isolated radar views and independent revision lists.
- **Recommendation Threshold Tests:** Verify that topics with `< 5` attempted questions are never marked as weak topics.
- **Exit Gate:** Aspirants receive clear, track-isolated performance radar breakdowns and evidence-based revision guidance.

---

## Phase 6: Operational Hardening, Concurrency Testing & Pilot Launch

**Target Duration:** Sprint 12 – Sprint 14 (Weeks 23–28)  
**Primary Goal:** Execute end-to-end security audits, load testing (1,000 concurrent test takers), accessibility conformance, and launch the pilot with independent aspirants and a partner coaching institute.

### 1. Work Packages & Technical Deliverables

- **Task 6.1: Load & Concurrency Testing:**
  - Execute Artillery / k6 load scripts: simulate 1,000 concurrent students taking tests with autosave calls every 15 seconds.
  - Validate p95 latency stays `< 500 ms` on PostgreSQL write paths.
- **Task 6.2: Security & RLS Audit:**
  - Execute automated privilege escalation tests (attempting to alter memberships, forge scores, or query other institutions' data).
  - Verify that `GROQ_API_KEY` and Supabase service-role keys are absent from client bundle source maps.
- **Task 6.3: Accessibility (WCAG 2.1 AA) Audit:**
  - Keyboard navigation review, screen-reader testing on assessment runner, contrast audits, and PwD extended time validation.
- **Task 6.4: Backup & Disaster Recovery Drill:**
  - Execute point-in-time database restoration in staging; measure RTO (`< 1 hour`) and RPO (`< 5 minutes`).
- **Task 6.5: Pilot Onboarding:**
  - Seed pilot institution, faculty accounts, batches, and vetted NEET-UG and IMAT question banks.
  - Activate Pilot Launch Gate.

---

## Phase 7: Post-MVP Expansion & Platform Monetization

**Target Duration:** Post-Pilot Roadmap  
**Scope:** Commercial scaling and advanced features (only after pilot validation):

- **Phase 7.1:** Student subscription plans & coaching institute licensing via Stripe / Razorpay.
- **Phase 7.2:** Student-facing AI Study Assistant grounded in approved curriculum resources with citation links.
- **Phase 7.3:** Printable NEET-UG question papers with scannable OMR answer-sheet capture.
- **Phase 7.4:** Multilingual NEET-UG content delivery across the 12 regional languages once officially reviewed.
- **Phase 7.5:** Moderated question discussion threads with faculty answer pinning.

---

# 3. Sprint Timeline & Milestone Schedule

|      Sprint       | Phase Focus | Key Deliverable                                                            | Milestone Target                                      |
| :---------------: | :---------: | -------------------------------------------------------------------------- | ----------------------------------------------------- |
|  **Sprints 1–2**  |   Phase 1   | Supabase Auth, Profiles, Dual-Track Selection (`NEET_UG`/`IMAT`), Shell UI | **Milestone 1:** Onboarding & Dashboards Ready        |
|  **Sprints 3–4**  |   Phase 2   | 5-Level Syllabus Trees, Closures, Private Resources & Signed URLs          | **Milestone 2:** Curriculum & Resource Library Active |
|  **Sprints 5–6**  |   Phase 3   | Question Bank Revisions, Groq AI Question Drafting, Faculty Review Queue   | **Milestone 3:** Question Authoring & AI Drafter Live |
|  **Sprints 7–9**  |   Phase 4   | Unified Assessment Runner, Autosave Sync, Decimal Dual-Track Scoring       | **Milestone 4:** Authoritative Test Engine Functional |
| **Sprints 10–11** |   Phase 5   | Track-Isolated Radars, Transparent Revisions, Calendar & Notices           | **Milestone 5:** Analytics & Revision Ready           |
| **Sprints 12–14** |   Phase 6   | 1k Concurrency Load Testing, Security Audit, WCAG Audit, Pilot Launch      | **Milestone 6:** Production Pilot Go-Live             |

---

# 4. Delivery Governance & Release Verification Checklist

Every pull request and phase transition must satisfy the following release criteria:

```markdown
- [ ] TypeScript Typecheck: `tsc --noEmit` passes with 0 errors across all apps and packages.
- [ ] Unit & Integration Tests: 100% pass on all 55+ test suites (vitest run).
- [ ] Scoring Conformance: NEET (+4/-1, dropped Q) and IMAT (+1.5/-0.4) test vectors match exact decimal values.
- [ ] RLS & Tenancy Isolation: Verified via multi-tenant integration tests; no cross-tenant leakage.
- [ ] Answer Key Isolation: Confirmed that student endpoints strip correctOptionKey and accepted_option_ids.
- [ ] AI Governance: Confirmed that AI question outputs are saved strictly with review_status = 'DRAFT'.
- [ ] Performance Standards: p95 latency verified < 500ms on autosave and read endpoints.
- [ ] Secrets Cleanliness: No API keys (GROQ_API_KEY, Supabase service-role) exposed in frontend code or Git history.
```
