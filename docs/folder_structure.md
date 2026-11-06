# MedPrep — Scalable, Production-Oriented Repository Structure

**Based on:** `project_overview.md`, Version 3.0  
**Product scope:** NEET-UG and IMAT only  
**Primary user:** Aspirant  
**Supporting users:** Faculty, tutors, coaching-institute administrators, platform administrators  
**Architecture:** TypeScript monorepo with a modular-monolith backend  
**Frontend:** React + TypeScript + Vite  
**Backend:** Node.js + Express + TypeScript  
**Platform services:** Supabase Auth, PostgreSQL, Row Level Security (RLS), private Supabase Storage  
**Purpose:** Repository blueprint and implementation guidance

> This is a recommended production-oriented structure, not proof that the application is production-ready. Production readiness must be demonstrated through implementation, security testing, exam-conformance testing, operational controls, and deployment validation.

---

## 1. Architecture decisions derived from the project overview

1. **Two exam tracks only:** `NEET_UG` and `IMAT`. Do not create generic UCAT, MCAT, or unrelated exam modules.
2. **Aspirant-first experience:** independent aspirants are first-class users. Institute workspaces, faculty, batches, and administration are supporting workflows.
3. **One platform, two exam experiences:** share the application shell and reusable learning/assessment components, but keep NEET-UG and IMAT syllabi, exam configurations, scoring, result labels, and analytics distinct.
4. **Version exam rules by cycle:** question distribution, option count, time, scoring, language, syllabus mapping, and applicable accommodations must be versioned and reviewed before publication.
5. **Modular monolith first:** keep domain modules separated in one backend codebase. Do not split into microservices before actual scale, team ownership, or reliability requirements justify it.
6. **Trusted backend decisions:** authorization, exam access, assessment deadlines, answer-key access, attempt finalization, and scoring are server-authoritative.
7. **AI output is a draft:** generated questions require structural validation and human academic approval before publication.
8. **Immutable history:** preserve the published syllabus, question, assessment, and scoring versions used by completed attempts.
9. **RLS and tenant isolation are foundational:** institute-owned records and private resources must be isolated at database and server layers.
10. **Testing follows the domain:** keep separate NEET scoring/adjudication tests, IMAT scoring/section tests, security tests, reliability tests, and end-to-end learner flows.
11. **Avoid premature complexity:** establish the main boundaries early, but add implementation files when the related product phase begins.

---

## 2. Recommended monorepo structure

```text
medprep/
│
├── apps/
│   ├── web/                                      # React application
│   │   ├── public/
│   │   │   ├── favicon.svg
│   │   │   ├── logo.svg
│   │   │   └── images/
│   │   │
│   │   ├── src/
│   │   │   ├── app/
│   │   │   │   ├── App.tsx
│   │   │   │   ├── main.tsx
│   │   │   │   ├── router/
│   │   │   │   │   ├── index.tsx
│   │   │   │   │   ├── paths.ts
│   │   │   │   │   └── guards/
│   │   │   │   │       ├── AuthGuard.tsx
│   │   │   │   │       ├── ExamAccessGuard.tsx
│   │   │   │   │       └── MembershipGuard.tsx
│   │   │   │   ├── providers/
│   │   │   │   │   ├── AppProviders.tsx
│   │   │   │   │   ├── AuthProvider.tsx
│   │   │   │   │   ├── QueryProvider.tsx
│   │   │   │   │   └── ThemeProvider.tsx
│   │   │   │   └── layouts/
│   │   │   │       ├── PublicLayout.tsx
│   │   │   │       ├── LearnerLayout.tsx
│   │   │   │       ├── FacultyLayout.tsx
│   │   │   │       ├── InstituteAdminLayout.tsx
│   │   │   │       └── PlatformAdminLayout.tsx
│   │   │   │
│   │   │   ├── features/                     # Domain capability slices (Self-contained)
│   │   │   │   ├── exam-selection/           # Dual-track switcher (NEET-UG vs IMAT vs both)
│   │   │   │   │   ├── api/
│   │   │   │   │   └── components/
│   │   │   │   │
│   │   │   │   ├── curriculum/               # Unified syllabus navigator & topic tree
│   │   │   │   │   ├── api/
│   │   │   │   │   ├── components/
│   │   │   │   │   └── hooks/
│   │   │   │   │
│   │   │   │   ├── resources/                # PDF document viewer, video player, DPPs
│   │   │   │   │   ├── api/
│   │   │   │   │   └── components/
│   │   │   │   │
│   │   │   │   ├── practice/                 # Topic-wise drill runner & scratchpad
│   │   │   │   │   ├── api/
│   │   │   │   │   └── components/
│   │   │   │   │
│   │   │   │   ├── assessments/              # Unified exam runner, question palette, autosave sync
│   │   │   │   │   ├── api/
│   │   │   │   │   ├── components/
│   │   │   │   │   │   ├── runner/
│   │   │   │   │   │   ├── palette/
│   │   │   │   │   │   └── timer/
│   │   │   │   │   └── hooks/
│   │   │   │   │
│   │   │   │   ├── analytics/                # Performance radars, subject breakdown, error analysis
│   │   │   │   │   ├── api/
│   │   │   │   │   └── components/
│   │   │   │   │
│   │   │   │   └── ai-assistant/             # Academic grounding chat assistant
│   │   │   │       ├── api/
│   │   │   │       └── components/
│   │   │   │
│   │   │   ├── pages/                        # Composed views per Role Portal (Route targets)
│   │   │   │   ├── student/                  # Student Dashboard, SyllabusView, DrillPage, ExamLobby, Results
│   │   │   │   ├── faculty/                  # Faculty Dashboard, QuestionAuthoring, Reviews, AssessmentSetup
│   │   │   │   ├── institute-admin/          # Batches, CohortEnrollments, FacultyAssignments, Reports
│   │   │   │   └── platform-admin/           # Institutions, BlueprintVerification, AuditLogs
│   │   │   │
│   │   │   ├── shared/                       # Genuinely reusable cross-cutting components & hooks
│   │   │   │   ├── components/
│   │   │   │   │   ├── ui/
│   │   │   │   │   ├── forms/
│   │   │   │   │   ├── navigation/
│   │   │   │   │   ├── charts/
│   │   │   │   │   └── feedback/
│   │   │   │   ├── hooks/
│   │   │   │   ├── styles/
│   │   │   │   └── utils/
│   │   │   │
│   │   │   ├── tests/
│   │   │   │   ├── component/
│   │   │   │   └── e2e/
│   │   │   │
│   │   │       ├── auth/
│   │   │       ├── exam-selection/
│   │   │       ├── neet-ug/
│   │   │       ├── imat/
│   │   │       ├── dual-track-account/
│   │   │       ├── assessment-recovery/
│   │   │       └── role-access/
│   │   │
│   │   ├── index.html
│   │   ├── vite.config.ts
│   │   ├── tsconfig.json
│   │   ├── package.json
│   │   └── .env.example
│   │
│   └── api/                                    # Node.js / Express modular monolith
│       ├── src/
│       │   ├── app.ts                          # Express composition; no listen()
│       │   ├── server.ts                       # HTTP process entry point
│       │   ├── worker.ts                       # Optional job-worker process entry
│       │   │
│       │   ├── config/
│       │   │   ├── env.ts                      # Runtime environment validation
│       │   │   ├── app-config.ts
│       │   │   ├── cors.ts
│       │   │   ├── security.ts
│       │   │   └── constants.ts
│       │   │
│       │   ├── bootstrap/
│       │   │   ├── register-modules.ts
│       │   │   ├── register-routes.ts
│       │   │   └── register-jobs.ts
│       │   │
│       │   ├── middleware/
│       │   │   ├── authenticate.ts
│       │   │   ├── resolve-membership.ts
│       │   │   ├── require-permission.ts
│       │   │   ├── require-exam-access.ts
│       │   │   ├── validate-request.ts
│       │   │   ├── rate-limit.ts
│       │   │   ├── request-id.ts
│       │   │   ├── security-headers.ts
│       │   │   ├── not-found.ts
│       │   │   └── error-handler.ts
│       │   │
│       │   ├── domains/                        # Domain-Driven Bounded Contexts (Vertical Slices)
│       │   │   ├── identity/                   # Auth, profiles, memberships, permissions
│       │   │   │   ├── identity.routes.ts
│       │   │   │   ├── identity.controller.ts
│       │   │   │   ├── identity.service.ts
│       │   │   │   ├── identity.repository.ts
│       │   │   │   └── identity.schemas.ts
│       │   │   │
│       │   │   ├── tenancy/                    # Multi-tenant institutions, batches, enrollments
│       │   │   │   ├── tenancy.routes.ts
│       │   │   │   ├── tenancy.controller.ts
│       │   │   │   ├── tenancy.service.ts
│       │   │   │   └── tenancy.repository.ts
│       │   │   │
│       │   │   ├── academics/                  # Curriculum taxonomy, subjects, chapters, topics
│       │   │   │   ├── academics.routes.ts
│       │   │   │   ├── academics.controller.ts
│       │   │   │   └── academics.service.ts
│       │   │   │
│       │   │   ├── examination/                # Exam tracks (NEET/IMAT), blueprints, adapters
│       │   │   │   ├── examination.routes.ts
│       │   │   │   ├── examination.controller.ts
│       │   │   │   ├── examination.service.ts
│       │   │   │   └── adapters/
│       │   │   │       ├── neet-ug.adapter.ts
│       │   │   │       └── imat.adapter.ts
│       │   │   │
│       │   │   ├── content-bank/               # Question items, revisions, confidential keys, reviews
│       │   │   │   ├── content-bank.routes.ts
│       │   │   │   ├── content-bank.controller.ts
│       │   │   │   ├── content-bank.service.ts
│       │   │   │   ├── question-reviews.service.ts
│       │   │   │   ├── ai-drafts.service.ts
│       │   │   │   └── content-bank.repository.ts
│       │   │   │
│       │   │   ├── assessments/                # Test definitions, versions, attempts, scoring sync
│       │   │   │   ├── assessments.routes.ts
│       │   │   │   ├── assessments.controller.ts
│       │   │   │   ├── attempts.service.ts
│       │   │   │   └── assessments.repository.ts
│       │   │   │
│       │   │   ├── learning/                   # Study plans, progress tracking, AI tutor
│       │   │   │   ├── learning.routes.ts
│       │   │   │   ├── learning.controller.ts
│       │   │   │   ├── study-plans.service.ts
│       │   │   │   └── ai-tutor.service.ts
│       │   │   │
│       │   │   ├── communication/              # Announcements, calendar, notifications
│       │   │   │   ├── communication.routes.ts
│       │   │   │   ├── announcements.service.ts
│       │   │   │   └── notifications.service.ts
│       │   │   │
│       │   │   └── platform/                   # Audit logs, health checks, telemetry
│       │   │       ├── audit.service.ts
│       │   │       └── health.controller.ts
│       │   │
│       │   ├── infrastructure/                 # External integration adapters
│       │   │   ├── database/                   # Supabase client instances (user-scoped / service-role)
│       │   │   │   ├── user-client.ts
│       │   │   │   └── service-role-client.ts
│       │   │   ├── storage/                    # Supabase Storage S3 client & signed URLs
│       │   │   ├── ai/                         # LLM provider adapters (Groq / OpenAI)
│       │   │   └── queue/                      # Redis / BullMQ / in-memory queues
│       │   │
│       │   ├── jobs/                           # Asynchronous job handlers
│       │   │   ├── ai-question-gen.job.ts
│       │   │   ├── attempt-timeout.job.ts
│       │   │   └── notification-dispatch.job.ts
│       │   │
│       │   ├── shared/                         # Domain-agnostic utilities (errors, result, pagination)
│       │   │   ├── errors/
│       │   │   ├── result/
│       │   │   ├── pagination/
│       │   │   └── logging/
│       │   │
│       │   └── tests/
│       │       ├── unit/
│       │       └── integration/
│       │
│       ├── tsconfig.json
│       ├── package.json
│       └── .env.example
│
├── packages/
│   ├── api-contracts/                          # Safe shared DTOs & Zod schemas (Frontend + Backend)
│   │   ├── src/
│   │   │   ├── auth/
│   │   │   ├── curriculum/
│   │   │   ├── assessments/
│   │   │   ├── common/
│   │   │   └── index.ts
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   ├── database/                               # Database schema types & Supabase client factories
│   │   ├── src/
│   │   │   ├── types.ts                        # Generated PostgreSQL & Supabase schema types
│   │   │   ├── client.ts                       # User-scoped & admin service-role clients
│   │   │   └── index.ts
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   ├── exam-engine/                            # Official NEET-UG & IMAT rules & scoring strategies
│   │   ├── src/
│   │   │   ├── types.ts                        # Scoring interfaces & specification types
│   │   │   ├── neet-ug/                        # 180Q, 4-opt, +4/-1/0, dropped-Q adjudication
│   │   │   ├── imat/                           # 60Q, 5-opt, +1.5/-0.4/0, 5 sections, 90 marks
│   │   │   └── index.ts
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   └── config/                                 # Shared lint / TypeScript presets
│       └── package.json
│
├── supabase/
│   ├── config.toml                             # Supabase CLI local orchestration configuration
│   ├── migrations/                             # Ordered, immutable SQL migrations
│   │   ├── 0001_create_extensions_and_types.sql
│   │   ├── 0002_create_identity_and_roles.sql
│   │   ├── 0003_create_exam_tracks_and_blueprints.sql
│   │   ├── 0004_create_academic_structure_and_tenancy.sql
│   │   ├── 0005_create_curriculum_and_study_plans.sql
│   │   ├── 0006_create_learning_resources.sql
│   │   ├── 0007_create_question_bank.sql
│   │   ├── 0008_create_assessments_and_scoring.sql
│   │   ├── 0009_create_ai_generation_and_jobs.sql
│   │   ├── 0010_create_operations_and_audit.sql
│   │   ├── 0011_create_indexes.sql
│   │   ├── 0012_create_security_functions_and_triggers.sql
│   │   ├── 0013_enable_rls_and_policies.sql
│   │   └── 0014_create_storage_buckets_and_policies.sql
│   ├── seed/
│   │   ├── 00_reference_data.sql
│   │   ├── exam-configurations/
│   │   │   ├── neet-ug/
│   │   │   │   └── 2026.json
│   │   │   └── imat/
│   │   │       └── 2026-27.json
│   │   └── demo/
│   │       ├── demo-institution.sql
│   │       ├── demo-users.sql
│   │       └── demo-content.sql
│   │
│   ├── tests/
│   │   ├── rls/
│   │   │   ├── independent-learner.test.sql
│   │   │   ├── student-access.test.sql
│   │   │   ├── faculty-access.test.sql
│   │   │   ├── institute-isolation.test.sql
│   │   │   └── platform-admin-access.test.sql
│   │   └── constraints/
│   │
│   └── README.md
│
├── tests/
│   ├── exam-conformance/
│   │   ├── neet-ug/
│   │   │   ├── 2026-configuration.test.ts
│   │   │   ├── 2026-scoring.test.ts
│   │   │   ├── 2026-adjudication.test.ts
│   │   │   └── 2026-language-mapping.test.ts
│   │   └── imat/
│   │       ├── 2026-27-configuration.test.ts
│   │       ├── 2026-27-scoring.test.ts
│   │       └── 2026-27-section-distribution.test.ts
│   │
│   ├── security/
│   │   ├── role-escalation.test.ts
│   │   ├── cross-user-access.test.ts
│   │   ├── cross-institution-access.test.ts
│   │   ├── exam-entitlement.test.ts
│   │   ├── answer-key-exposure.test.ts
│   │   ├── forged-score.test.ts
│   │   └── signed-url-expiry.test.ts
│   │
│   ├── reliability/
│   │   ├── answer-autosave.test.ts
│   │   ├── duplicate-submit.test.ts
│   │   ├── timeout-finalization.test.ts
│   │   ├── attempt-recovery.test.ts
│   │   └── regrading-history.test.ts
│   │
│   ├── load/
│   │   ├── assessment-start.js
│   │   ├── answer-save.js
│   │   └── simultaneous-submit.js
│   │
│   └── fixtures/
│       ├── neet-ug/
│       ├── imat/
│       ├── learners/
│       └── institutions/
│
├── docs/
│   ├── product/
│   │   ├── project-overview.md
│   │   ├── mvp-scope.md
│   │   ├── user-journeys.md
│   │   └── product-decisions.md
│   │
│   ├── architecture/
│   │   ├── system-architecture.md
│   │   ├── repository-structure.md
│   │   ├── frontend-architecture.md
│   │   ├── backend-architecture.md
│   │   ├── database-design.md
│   │   ├── assessment-lifecycle.md
│   │   ├── scoring-design.md
│   │   └── ai-workflows.md
│   │
│   ├── exam-specifications/
│   │   ├── neet-ug/
│   │   │   ├── annual-verification-checklist.md
│   │   │   └── 2026/
│   │   │       ├── official-sources.md
│   │   │       ├── exam-configuration.md
│   │   │       ├── syllabus-mapping.md
│   │   │       ├── scoring-and-adjudication.md
│   │   │       └── language-review.md
│   │   └── imat/
│   │       ├── annual-verification-checklist.md
│   │       └── 2026-27/
│   │           ├── official-sources.md
│   │           ├── exam-configuration.md
│   │           ├── syllabus-mapping.md
│   │           ├── section-distribution.md
│   │           └── scoring.md
│   │
│   ├── api/
│   │   ├── api-conventions.md
│   │   ├── authentication-and-authorization.md
│   │   ├── error-catalog.md
│   │   └── openapi.yaml
│   │
│   ├── database/
│   │   ├── schema-overview.md
│   │   ├── data-dictionary.md
│   │   ├── rls-policy-matrix.md
│   │   └── migration-policy.md
│   │
│   ├── security/
│   │   ├── threat-model.md
│   │   ├── secrets-management.md
│   │   ├── content-protection.md
│   │   ├── privacy-and-retention.md
│   │   └── incident-response.md
│   │
│   ├── operations/
│   │   ├── local-development.md
│   │   ├── environments.md
│   │   ├── deployment.md
│   │   ├── backup-and-restore.md
│   │   ├── monitoring-and-alerting.md
│   │   └── troubleshooting.md
│   │
│   ├── decisions/                              # Architecture Decision Records
│   │   ├── 0001-modular-monolith.md
│   │   ├── 0002-neet-imat-exam-adapters.md
│   │   ├── 0003-server-authoritative-scoring.md
│   │   ├── 0004-supabase-rls.md
│   │   └── 0005-versioned-assessments.md
│   │
│   └── runbooks/
│       ├── assessment-incident.md
│       ├── database-recovery.md
│       ├── ai-provider-outage.md
│       ├── storage-access-incident.md
│       └── exam-configuration-rollover.md
│
├── infra/
│   ├── docker/
│   │   ├── web.Dockerfile
│   │   └── api.Dockerfile
│   ├── local/
│   │   └── docker-compose.yml
│   ├── deployment/
│   │   ├── web/
│   │   ├── api/
│   │   └── worker/
│   └── monitoring/
│       ├── dashboards/
│       └── alerts/
│
├── scripts/
│   ├── database/
│   │   ├── reset-local.sh
│   │   ├── migration-check.sh
│   │   └── generate-types.sh
│   ├── exam-config/
│   │   ├── validate-config.ts
│   │   ├── compare-versions.ts
│   │   └── verify-publication-checklist.ts
│   ├── quality/
│   │   ├── check-env.ts
│   │   └── check-secrets.sh
│   └── release/
│       ├── pre-release-check.sh
│       └── create-release-notes.ts
│
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── database-migration-check.yml
│   │   ├── security-scan.yml
│   │   ├── deploy-staging.yml
│   │   └── deploy-production.yml
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE.md
│
├── .husky/
│   ├── pre-commit
│   └── commit-msg
│
├── .editorconfig
├── .gitignore
├── .npmrc
├── .nvmrc
├── .prettierignore
├── .prettierrc.json
├── eslint.config.js
├── package.json
├── pnpm-lock.yaml
├── pnpm-workspace.yaml
├── turbo.json
├── tsconfig.base.json
├── docker-compose.yml
├── .env.example
└── README.md
```

---

## 3. Responsibilities of the major directories

### 3.1 `apps/web`

Contains the React application only.

Responsibilities:

- Aspirant onboarding and exam selection.
- NEET-UG and IMAT learner experiences.
- Curriculum, study plans, resources, practice, assessments, and results.
- Faculty question authoring and review interfaces.
- Institute administration workflows.
- Platform administration screens where required.
- Accessible and responsive user interfaces.

Rules:

- The backend produces the authoritative result. Do not calculate final scores in the browser.
- Do not store answer keys for active or unreleased assessments in client state or frontend bundles.
- Do not expose Supabase service-role keys or AI provider credentials.
- Route guards are a user-experience feature, not a security boundary.
- Put feature-specific components, hooks, API calls, and schemas inside their feature folder.
- Put components in `components/` only when they are genuinely shared.

### 3.2 `apps/api`

Contains the trusted backend and modular-monolith domain services.

Responsibilities:

- Authentication/session verification.
- Exam-track entitlement.
- Institution membership and permissions.
- Annual exam configuration publication.
- Syllabus and curriculum access.
- Resource authorization.
- Question and answer-key governance.
- AI generation and faculty review.
- Assessment configuration and versioning.
- Attempt creation and answer saving.
- Server-authoritative deadlines and scoring.
- Result release and regrading.
- Analytics and revision recommendations.
- Notifications and audit events.

The API may be deployed as an HTTP process and, when required, a separate worker process using the same codebase. This is still a modular monolith; it does not require separate microservices.

### 3.3 `packages/api-contracts`

Contains safe request/response contracts shared by web and API.

Examples:

- Exam-track selection request.
- Public exam configuration response.
- Syllabus tree response.
- Resource summary DTO.
- Assessment instructions DTO.
- Student-safe question DTO.
- Attempt status DTO.
- Released result DTO.

**Never export private answer keys, service-role types, internal scoring state, or privileged database entities into a package imported by the browser.** Student-facing DTOs must be separate from backend persistence models.

### 3.4 `packages/exam-config-schema`

Defines the structural schema for exam configuration documents.

Allowed exam codes:

- `NEET_UG`
- `IMAT`

Validate exam version metadata, section order and counts, option count, language configuration, duration, scoring-policy shape, and source/review metadata. This validates configuration structure; it does not establish that an official source was interpreted correctly. Academic verification and publication approval remain separate steps.

### 3.5 `supabase/migrations`

The ordered SQL migrations are the database schema source of truth.

Rules:

- Every schema or RLS change gets a new migration.
- Never rewrite a migration already applied to a shared environment.
- Include indexes, constraints, grants, triggers, and RLS policies in reviewed migrations.
- Test migrations against a clean local database.
- Keep schema migrations separate from demo seed data.
- Generate TypeScript database types from the schema; do not manually edit generated output.

### 3.6 `supabase/seed/exam-configurations`

Contains versioned configuration data for the two supported exams.

Examples:

- `neet-ug/2026.json`
- `imat/2026-27.json`

Each file should include exam code and cycle, configuration version, official source URL(s), source publication date where available, reviewer/verification status, sections and question counts, option count, duration, scoring configuration, language configuration, and syllabus mapping version.

A seed file is not automatically authoritative. It must pass schema validation and academic verification before being published to learners.

### 3.7 `tests`

Contains cross-module behavior and product-conformance tests. Keep separate suites for NEET scoring/adjudication, IMAT scoring/section distribution, dual-track separation, cross-user and cross-institute access, answer-key exposure, forged-score attempts, answer-save recovery, duplicate finalization, and concurrent assessment activity.

### 3.8 `docs`

Contains maintained product, architecture, exam verification, security, API, and operational documents. Keep official exam evidence separated by exam and cycle. Do not combine NEET and IMAT source verification into one generic document.

### 3.9 `infra`

Contains deployment and runtime configuration. Keep it simple until the hosting provider and operational requirements are finalized. Do not add Kubernetes or a large Terraform layout simply to make the repository look enterprise-grade.

---

## 4. Standard backend module pattern

Use a vertical-slice structure for complex modules. Small modules may start with fewer files and grow as needed.

```text
question-bank/
├── question-bank.routes.ts
├── question-bank.controller.ts
├── question-bank.service.ts
├── question-bank.repository.ts
├── question-bank.schemas.ts
├── question-bank.dto.ts
├── question-bank.permissions.ts
├── question-bank.errors.ts
├── question-bank.types.ts
└── __tests__/
    ├── question-bank.service.test.ts
    └── question-bank.repository.test.ts
```

Request flow:

```text
HTTP Request
    |
    v
Authentication middleware
    |
    v
Resolve learner / institution membership
    |
    v
Check permission and exam entitlement
    |
    v
Validate request schema
    |
    v
Controller
    |
    v
Domain service
    |
    v
Repository / trusted infrastructure
    |
    v
PostgreSQL / private storage / external AI provider
    |
    v
Safe response DTO
```

Rules:

- Controllers handle HTTP concerns; they should not implement business rules.
- Services coordinate use cases and domain rules.
- Repositories encapsulate persistence access.
- Validation occurs at external boundaries.
- Authorization is checked server-side and reinforced with RLS.
- Do not trust `profile_id`, `institution_id`, role, score, correct answer, or permission values supplied by the browser.
- Use database transactions for attempt finalization and score persistence.
- Use idempotency for retryable answer saves, submissions, and job processing.

---

## 5. NEET-UG and IMAT separation

Do not create two duplicate frontends or two entire backends. Use shared workflows with separate exam adapters and versioned configuration.

```text
                  Shared Learner Application
                            |
                            v
                      Selected Track
                       /         \
                      /           \
                  NEET-UG         IMAT
                    |              |
                    v              v
              NEET syllabus   IMAT syllabus
              NEET sections   IMAT sections
              4-option MCQ    5-option MCQ
              NEET scoring    IMAT scoring
              NEET analytics  IMAT analytics
                      \          /
                       \        /
                   Shared Platform Services
                   - Authentication
                   - Learner entitlements
                   - Resources
                   - Question bank
                   - Assessment lifecycle
                   - Attempts
                   - Results
                   - Study plans
                   - Notifications
```

Implementation rules:

- Use shared curriculum components configured with the selected syllabus version.
- Use one assessment runner driven by a published exam configuration.
- Use separate scoring strategies for NEET-UG and IMAT.
- Keep NEET-specific multiple-correct, all-options-correct, and dropped/invalid question handling in its scoring policy.
- Keep IMAT's five-option format and section distribution in the IMAT configuration.
- Keep separate analytics aggregations and labels.
- Never compare NEET raw marks directly with IMAT raw marks.
- Do not hardcode annual values in React components.
- Retain old exam configuration versions for historical attempts.

---

## 6. AI module boundaries

### 6.1 AI question drafting

```text
ai-question-drafts/
├── ai-drafts.routes.ts
├── ai-drafts.controller.ts
├── ai-drafts.service.ts
├── ai-drafts.repository.ts
├── ai-drafts.schemas.ts
├── validators/
│   ├── option-count.validator.ts
│   ├── answer-key.validator.ts
│   ├── syllabus-mapping.validator.ts
│   └── markup-safety.validator.ts
├── prompts/
│   ├── neet-ug/
│   │   ├── question-generation.prompt.ts
│   │   └── explanation-generation.prompt.ts
│   └── imat/
│       ├── question-generation.prompt.ts
│       └── explanation-generation.prompt.ts
└── __tests__/
    ├── output-validation.test.ts
    └── approval-workflow.test.ts
```

Rules:

- AI output is always a draft.
- The selected exam track and exam version must be passed to the generator.
- NEET prompts must follow the applicable NEET syllabus and question format.
- IMAT prompts must follow the applicable IMAT section, syllabus, and five-option format.
- Do not default Option A or any other option as correct.
- Validate output structure before storing it.
- Require qualified human academic review before publication.
- Record provider/model and prompt version where useful.
- Rate-limit requests and apply cost limits.
- Do not send unnecessary learner personal data to the provider.

### 6.2 AI study assistant

Keep this separate from question generation because its data permissions and workflow are different.

- Retrieve only approved resources the current learner may access.
- Keep active assessment answer keys out of the retrieval index.
- Link explanations to source materials where possible.
- Apply institution and exam-track access filters.
- Maintain a retention policy for prompts and responses.

---

## 7. Assessment and scoring module boundaries

### Assessments

Own assessment creation, assessment versions, section/question selection, eligibility, scheduling, attempt limits, result-release policy, explanation-release policy, and published assessment snapshots.

### Attempts

Own attempt creation, server start time and deadline, answer persistence, attempt state transitions, retry/idempotency behavior, submission, timeout handling, and recovery after refresh or network interruption.

### Scoring

Own loading the scoring policy snapshot, correct/incorrect/unanswered calculation, NEET question adjudication, IMAT ordinary scoring, section breakdown, result finalization, and regrading integration.

Suggested policy organization:

```text
scoring/
├── scoring.service.ts
├── scoring.registry.ts
├── scoring.types.ts
├── score-calculator.ts
├── policies/
│   ├── neet-ug/
│   │   ├── neet-ug-2026.policy.ts
│   │   ├── neet-ug-adjudication.ts
│   │   └── neet-ug-2026.test-vectors.ts
│   └── imat/
│       ├── imat-2026-27.policy.ts
│       └── imat-2026-27.test-vectors.ts
└── __tests__/
    ├── neet-ug-scoring.test.ts
    ├── neet-ug-adjudication.test.ts
    └── imat-scoring.test.ts
```

Do not use a policy file as the only source of annual rules. Persisted exam-version configuration and assessment snapshots must identify which policy version was applied.

---

## 8. Database and Supabase organization

### Migration principles

- Use ordered, append-only migrations.
- Keep schema, constraints, indexes, triggers, grants, and RLS policies reviewed.
- Do not make production schema changes manually without a corresponding migration.
- Do not put real student records in seed data.
- Use fake demo accounts and content only in local/test environments.
- Keep generated database types under a clearly marked generated directory.

### Storage organization

Suggested private bucket separation:

```text
Supabase Storage
├── platform-resources/
├── institution-resources/
├── question-assets/
├── video-assets/
└── private-exports/
```

Use metadata and database policies to control access. Bucket names alone are not security boundaries. Do not create a public bucket for protected paid or institute-owned content by default.

### Service-role client

Keep `service-role-client.ts` isolated in backend infrastructure. The Supabase service role can bypass RLS. Use it only in narrowly scoped trusted operations after explicit server-side authorization. Prefer a user-scoped client for operations that should remain constrained by that user's RLS permissions.

---

## 9. Test organization and mandatory regression suites

| Test category | Location | Required coverage |
|---|---|---|
| UI component tests | `apps/web/tests/component` | Form behavior, accessible interactions, display logic |
| Browser E2E | `apps/web/tests/e2e` | Complete learner, faculty, and admin workflows |
| Backend unit tests | `apps/api/src/**/__tests__` | Domain services and policy logic |
| API integration tests | `apps/api/src/tests/integration` | Routes, permissions, database behavior |
| RLS tests | `supabase/tests/rls` | Direct database authorization boundaries |
| Exam conformance | `tests/exam-conformance` | Official-format configuration and scoring |
| Security | `tests/security` | Role escalation, IDOR, tenant leakage, answer-key exposure |
| Reliability | `tests/reliability` | Autosave, retry, timeout, finalization, regrading |
| Load | `tests/load` | Concurrent assessment start, answer save, submission |
| Accessibility | `tests/accessibility` | Keyboard, screen reader, contrast, timer communication |

### 9.1 NEET-UG 2026 reference regression cases

- 180 questions.
- Physics: 45.
- Chemistry: 45.
- Biology: 90.
- Four options per standard question.
- 180-minute full-length timer.
- Ordinary scoring: +4 / -1 / 0.
- Multiple-correct adjudication.
- All-options-correct adjudication.
- Invalid/dropped question adjudication.
- Language version and option mapping.
- Clear indication that an online assessment is a practice simulation of the official pen-and-paper examination.

### 9.2 IMAT 2026/27 reference regression cases

- 60 questions.
- Five options per standard question.
- 100-minute full-length timer.
- Section distribution: 4 / 5 / 23 / 15 / 13.
- Ordinary scoring: +1.5 / -0.4 / 0.
- Reading/knowledge separated from logical reasoning.
- Combined Physics/Mathematics exam allocation preserved.
- English question content.
- Historical assessment version remains reproducible.

### 9.3 Security and reliability regression cases

- User cannot assign themselves an administrator or faculty role through editable metadata.
- A learner cannot retrieve another learner's attempts by changing an identifier.
- A learner cannot retrieve an active answer key.
- A learner cannot forge an authoritative score.
- An expired signed URL cannot access protected content beyond its expiry.
- A suspended user loses protected access.
- Repeated submission does not create duplicate results.
- Refresh/network recovery restores server-saved answers and server deadline.
- Regrading creates an audit record and preserves previous results.

Update these tests whenever a new official NEET-UG or IMAT configuration is reviewed and published.

---

## 10. Environment and secret handling

Use separate environment examples for the frontend and backend:

```text
.env.example
apps/web/.env.example
apps/api/.env.example
```

### Frontend variables

```text
VITE_API_BASE_URL=
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
```

Only browser-safe values belong in the frontend.

### Backend variables

```text
NODE_ENV=
PORT=
WEB_ORIGIN=
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
DATABASE_URL=
GROQ_API_KEY=
LOG_LEVEL=
```

Rules:

- `.env.example` contains placeholders, not real credentials.
- Real `.env` files are excluded from Git.
- `SUPABASE_SERVICE_ROLE_KEY` and `GROQ_API_KEY` stay server-side.
- Never embed secrets in frontend Vite variables, Docker build arguments, logs, screenshots, test fixtures, or documentation.
- Use different credentials for local, test, staging, and production.
- Rotate credentials after suspected exposure.

---

## 11. Root workspace configuration

| File | Responsibility |
|---|---|
| `package.json` | Root scripts and workspace commands |
| `pnpm-workspace.yaml` | Workspace package declarations |
| `pnpm-lock.yaml` | Reproducible dependency resolution |
| `turbo.json` | Optional build/test task orchestration |
| `tsconfig.base.json` | Shared TypeScript compiler settings |
| `eslint.config.js` | Lint rules |
| `.prettierrc.json` | Formatting rules |
| `.nvmrc` | Pinned Node.js version |
| `.npmrc` | Package-manager behavior |
| `.editorconfig` | Consistent editor settings |
| `.env.example` | Documented safe variable names |
| `docker-compose.yml` | Optional local service orchestration |
| `README.md` | Setup, commands, architecture links, contribution rules |

Recommended package manager: **pnpm workspaces**. Turborepo is optional; use it if task orchestration and caching are useful. It is not required by the product architecture.

---

## 12. Recommended root commands

```bash
pnpm install

# Development
pnpm dev
pnpm dev:web
pnpm dev:api

# Quality
pnpm lint
pnpm typecheck
pnpm format:check

# Tests
pnpm test
pnpm test:unit
pnpm test:integration
pnpm test:e2e
pnpm test:security
pnpm test:exam-conformance
pnpm test:load

# Database
pnpm db:start
pnpm db:reset
pnpm db:migrate
pnpm db:types

# Exam configuration
pnpm exam-config:validate
pnpm exam-config:compare
```

Exact scripts depend on selected package versions and test tools. Do not run destructive reset or demo-seed commands in production.

---

## 13. Naming and implementation conventions

- Folder and non-component filenames: `kebab-case`.
- React components: `PascalCase`.
- Functions and variables: `camelCase`.
- Database tables and columns: consistent `snake_case`.
- Internal exam codes: `NEET_UG` and `IMAT`.
- Use domain-specific identifiers such as `examVersionId` and `questionVersionId`.
- Keep exam-year values in data/configuration, not UI constants.
- Store timestamps in UTC and display them in the relevant learner/institute timezone.
- Avoid `any` in exam configuration, scoring, and API contracts.
- Keep controllers thin.
- Keep scoring logic in tested domain services.
- Keep database access in repositories or dedicated data-access functions.
- Validate all external input.
- Use safe DTOs at API boundaries.
- Do not expose answer-key fields in student-facing queries before release.
- Keep historical versions immutable; corrections create new versions or audited adjudications.

---

## 14. CI/CD and release workflow

### Pull-request workflow

1. Install locked dependencies.
2. Run formatting check.
3. Run lint and TypeScript checks.
4. Run unit tests.
5. Start a disposable database and apply migrations.
6. Run RLS and integration tests.
7. Run NEET-UG and IMAT exam-conformance tests.
8. Build frontend and API.
9. Run security/dependency scanning.
10. Run selected end-to-end tests.

### Deployment workflow

```text
Developer Branch
      |
      v
Pull Request Checks
      |
      v
Code Review + Required CI
      |
      v
Merge to Main
      |
      v
Staging Deployment
      |
      v
Staging Smoke + Security + Exam Regression
      |
      v
Production Approval
      |
      v
Production Deployment
      |
      v
Monitoring + Rollback Readiness
```

Production release must be blocked if critical/high security issues remain, scoring tests fail, exam configuration lacks academic verification, or backup/restore procedures have not been tested.

---

## 15. What this structure does not guarantee

Creating these folders does not make the platform production-ready. Before real students depend on it, the implementation must demonstrate:

- Correct RLS on all protected database tables and storage access paths.
- Trusted role, membership, and exam entitlement checks.
- No service-role or AI provider secret in frontend bundles.
- Server-authoritative attempt deadlines, answer-key access, and scoring.
- Idempotent answer saves and submission finalization.
- Versioned exam configurations, questions, and assessment snapshots.
- Human approval before AI-generated questions are published.
- NEET-specific adjudication and IMAT-specific scoring conformance.
- Cross-user and cross-institution security tests.
- Assessment recovery and concurrent-submission tests.
- Backup restoration, monitoring, and incident runbooks.
- Accessibility testing for the exam runner.
- Privacy, retention, and content-license review.
- Representative load testing.

The folder structure makes these concerns visible and gives them a home. It does not replace the engineering work needed to satisfy them.

---

## 16. Recommended implementation order

1. Create the monorepo, pnpm workspaces, TypeScript, linting, formatting, and CI.
2. Configure local Supabase and create the first database migrations.
3. Implement profiles, independent learner access, institutions, memberships, and invitations.
4. Implement the two exam tracks and versioned exam configurations.
5. Import and verify separate NEET-UG and IMAT syllabus structures.
6. Implement courses, batches, enrollments, and faculty assignments.
7. Implement private resources and content eligibility.
8. Implement question versions, sources, review, and approval.
9. Implement NEET-UG and IMAT scoring strategies with conformance tests.
10. Implement assessment versions, attempts, answer saving, deadlines, and results.
11. Implement exam-specific analytics and revision plans.
12. Add AI question drafts with structural validation and faculty approval.
13. Add the grounded AI study assistant, announcements, calendar, and notifications.
14. Complete security, accessibility, load, backup/restore, and production release checks.

**Final recommendation:** Use this repository structure as the blueprint, but implement it incrementally in the order above. Keep the product focused on NEET-UG and IMAT, share common platform services, preserve separate exam rules, and avoid adding empty modules or infrastructure that the current product phase does not need.
