# NEET Prep LMS — Production-Ready Folder Structure

## 1. Architecture Decisions

| Layer | Technology | Responsibility |
|---|---|---|
| Frontend | React, TypeScript, Vite | Student, Faculty and Admin interfaces |
| Styling | Tailwind CSS | Responsive UI |
| Backend | Node.js, Express, TypeScript | Business logic and REST APIs |
| Database | Supabase PostgreSQL | Persistent relational data |
| Authentication | Supabase Auth | Identity and session management |
| Authorization | RBAC + PostgreSQL RLS | Role and data access control |
| File storage | Supabase Storage | Private learning resources and documents |
| AI integration | Groq API | AI question generation and academic assistant |
| Validation | Zod | Request and response validation |
| Frontend testing | Vitest, React Testing Library, Playwright | UI and end-to-end testing |
| Backend testing | Vitest | Unit and integration testing |
| API documentation | OpenAPI | API contracts |
| Monitoring | Structured logging and error monitoring | Production observability |
| CI/CD | GitHub Actions | Automated testing and deployment |

### Architectural approach

Use a **modular monolith**, not microservices, for the initial release.

The backend will have independently organized business modules for authentication, students, curriculum, assessments, analytics, resources and AI.

Each module owns its business logic and exposes controlled interfaces to other modules.

Background tasks such as AI generation, email notifications and report generation can run in a separate worker process.

The architecture should support future examination types through configurable examination blueprints rather than hardcoded NEET-specific logic.

---

## 2. Complete Project Directory Structure

```text
neet-prep-lms/
│
├── apps/
│   │
│   ├── web/
│   │   ├── public/
│   │   │   ├── favicon.ico
│   │   │   ├── logo.svg
│   │   │   └── images/
│   │   │
│   │   ├── src/
│   │   │   │
│   │   │   ├── app/
│   │   │   │   ├── App.tsx
│   │   │   │   ├── main.tsx
│   │   │   │   ├── router.tsx
│   │   │   │   ├── providers/
│   │   │   │   │   ├── AuthProvider.tsx
│   │   │   │   │   ├── QueryProvider.tsx
│   │   │   │   │   ├── ThemeProvider.tsx
│   │   │   │   │   └── AppProviders.tsx
│   │   │   │   ├── layouts/
│   │   │   │   │   ├── PublicLayout.tsx
│   │   │   │   │   ├── StudentLayout.tsx
│   │   │   │   │   ├── FacultyLayout.tsx
│   │   │   │   │   └── AdminLayout.tsx
│   │   │   │   └── guards/
│   │   │   │       ├── AuthGuard.tsx
│   │   │   │       └── PermissionGuard.tsx
│   │   │   │
│   │   │   ├── features/
│   │   │   │   │
│   │   │   │   ├── auth/
│   │   │   │   │   ├── api/
│   │   │   │   │   ├── components/
│   │   │   │   │   ├── hooks/
│   │   │   │   │   ├── pages/
│   │   │   │   │   ├── schemas/
│   │   │   │   │   └── index.ts
│   │   │   │   │
│   │   │   │   ├── student-dashboard/
│   │   │   │   ├── faculty-dashboard/
│   │   │   │   ├── admin-dashboard/
│   │   │   │   │
│   │   │   │   ├── exam-catalog/
│   │   │   │   │   ├── api/
│   │   │   │   │   ├── components/
│   │   │   │   │   ├── hooks/
│   │   │   │   │   ├── pages/
│   │   │   │   │   └── index.ts
│   │   │   │   │
│   │   │   │   ├── curriculum/
│   │   │   │   │   ├── api/
│   │   │   │   │   ├── components/
│   │   │   │   │   ├── hooks/
│   │   │   │   │   ├── pages/
│   │   │   │   │   └── index.ts
│   │   │   │   │
│   │   │   │   ├── batches/
│   │   │   │   │   ├── api/
│   │   │   │   │   ├── components/
│   │   │   │   │   ├── hooks/
│   │   │   │   │   ├── pages/
│   │   │   │   │   └── index.ts
│   │   │   │   │
│   │   │   │   ├── enrollments/
│   │   │   │   ├── resources/
│   │   │   │   ├── question-bank/
│   │   │   │   ├── assessments/
│   │   │   │   ├── attempts/
│   │   │   │   ├── analytics/
│   │   │   │   ├── ai-assistant/
│   │   │   ├── ai-question-generator/
│   │   │   ├── announcements/
│   │   │   ├── academic-calendar/
│   │   │   ├── student-documents/
│   │   │   ├── community/
│   │   │   └── administration/
│   │   │
│   │   ├── shared/
│   │   │   ├── components/
│   │   │   │   ├── ui/
│   │   │   │   ├── forms/
│   │   │   │   ├── charts/
│   │   │   │   ├── tables/
│   │   │   │   ├── dialogs/
│   │   │   │   └── feedback/
│   │   │   │
│   │   │   ├── hooks/
│   │   │   ├── lib/
│   │   │   │   ├── api-client.ts
│   │   │   │   ├── supabase-auth.ts
│   │   │   │   ├── query-client.ts
│   │   │   │   └── date-utils.ts
│   │   │   │
│   │   │   ├── constants/
│   │   │   ├── types/
│   │   │   └── utils/
│   │   │
│   │   ├── styles/
│   │   │   ├── globals.css
│   │   │   └── theme.css
│   │   │
│   │   ├── tests/
│   │   │   ├── setup.ts
│   │   │   └── accessibility/
│   │   │
│   │   ├── .env.example
│   │   ├── index.html
│   │   ├── vite.config.ts
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   ├── api/
│   │   ├── src/
│   │   │   │
│   │   │   ├── app.ts
│   │   │   ├── server.ts
│   │   │   │
│   │   │   ├── config/
│   │   │   │   ├── env.ts
│   │   │   │   ├── cors.ts
│   │   │   │   ├── security.ts
│   │   │   │   ├── database.ts
│   │   │   │   └── ai-config.ts
│   │   │   │
│   │   │   ├── common/
│   │   │   │   ├── errors/
│   │   │   │   │   ├── AppError.ts
│   │   │   │   │   ├── ErrorCodes.ts
│   │   │   │   │   └── error-handler.ts
│   │   │   │   │
│   │   │   │   ├── middleware/
│   │   │   │   │   ├── authenticate.ts
│   │   │   │   │   ├── authorize.ts
│   │   │   │   │   ├── validate-request.ts
│   │   │   │   │   ├── rate-limit.ts
│   │   │   │   │   ├── request-id.ts
│   │   │   │   │   ├── security-headers.ts
│   │   │   │   │   └── error-middleware.ts
│   │   │   │   │
│   │   │   │   ├── policies/
│   │   │   │   │   ├── permissions.ts
│   │   │   │   │   └── role-policy.ts
│   │   │   │   │
│   │   │   │   ├── constants/
│   │   │   │   ├── utils/
│   │   │   │   └── types/
│   │   │   │
│   │   │   ├── infrastructure/
│   │   │   │   │
│   │   │   │   ├── supabase/
│   │   │   │   │   ├── client.ts
│   │   │   │   │   ├── user-client.ts
│   │   │   │   │   ├── admin-client.ts
│   │   │   │   │   └── token-verifier.ts
│   │   │   │   │
│   │   │   │   ├── storage/
│   │   │   │   │   ├── storage.service.ts
│   │   │   │   │   └── signed-url.service.ts
│   │   │   │   │
│   │   │   │   ├── ai/
│   │   │   │   │   ├── providers/
│   │   │   │   │   │   └── groq/
│   │   │   │   │   │       ├── groq.client.ts
│   │   │   │   │   │       └── groq.provider.ts
│   │   │   │   │   ├── model-router.ts
│   │   │   │   │   └── ai.interface.ts
│   │   │   │   │
│   │   │   │   ├── queue/
│   │   │   │   │   ├── queue.interface.ts
│   │   │   │   │   ├── queue.config.ts
│   │   │   │   │   └── jobs/
│   │   │   │   │
│   │   │   │   ├── email/
│   │   │   │   └── observability/
│   │   │   │       ├── logger.ts
│   │   │   │       └── metrics.ts
│   │   │   │
│   │   │   ├── modules/
│   │   │   │   │
│   │   │   │   ├── auth/
│   │   │   │   ├── users/
│   │   │   │   ├── students/
│   │   │   │   ├── faculty/
│   │   │   │   ├── exam-catalog/
│   │   │   │   ├── curriculum/
│   │   │   │   ├── batches/
│   │   │   │   ├── enrollments/
│   │   │   │   ├── resources/
│   │   │   │   ├── question-bank/
│   │   │   │   ├── assessments/
│   │   │   │   ├── attempts/
│   │   │   │   ├── analytics/
│   │   │   │   ├── ai-question-generator/
│   │   │   │   ├── ai-assistant/
│   │   │   │   ├── student-documents/
│   │   │   │   ├── announcements/
│   │   │   │   ├── academic-calendar/
│   │   │   │   ├── community/
│   │   │   │   ├── audit/
│   │   │   │   ├── administration/
│   │   │   │   └── health/
│   │   │   │
│   │   │   ├── routes/
│   │   │   │   └── v1/
│   │   │   │       └── index.ts
│   │   │   │
│   │   │   └── docs/
│   │   │       └── openapi.yaml
│   │   │
│   │   ├── tests/
│   │   │   ├── unit/
│   │   │   ├── integration/
│   │   │   ├── security/
│   │   │   └── fixtures/
│   │   │
│   │   ├── .env.example
│   │   ├── tsconfig.json
│   │   ├── package.json
│   │   └── Dockerfile
│   │
│   └── worker/
│       ├── src/
│       │   ├── index.ts
│       │   ├── config/
│       │   ├── infrastructure/
│       │   │   ├── queue/
│       │   │   └── logger/
│       │   ├── jobs/
│       │   │   ├── ai-question-generation/
│       │   │   ├── report-generation/
│       │   │   ├── email-notifications/
│       │   │   ├── document-processing/
│       │   │   └── analytics-aggregation/
│       │   └── tests/
│       ├── .env.example
│       ├── package.json
│       └── Dockerfile
│
├── packages/
│   ├── contracts/
│   │   ├── src/
│   │   │   ├── auth/
│   │   │   ├── users/
│   │   │   ├── exams/
│   │   │   ├── curriculum/
│   │   │   ├── assessments/
│   │   │   ├── questions/
│   │   │   ├── attempts/
│   │   │   ├── analytics/
│   │   │   ├── ai/
│   │   │   ├── common/
│   │   │   └── index.ts
│   │   └── package.json
│   │
│   ├── config-eslint/
│   │   ├── index.js
│   │   └── package.json
│   │
│   └── config-typescript/
│       ├── base.json
│       ├── react.json
│       ├── node.json
│       └── package.json
│
├── supabase/
│   ├── config.toml
│   │
│   ├── migrations/
│   │   ├── 0001_create_enums.sql
│   │   ├── 0002_create_profiles_and_roles.sql
│   │   ├── 0003_create_exam_catalog.sql
│   │   ├── 0004_create_curriculum.sql
│   │   ├── 0005_create_batches_and_enrollments.sql
│   │   ├── 0006_create_resources.sql
│   │   ├── 0007_create_question_bank.sql
│   │   ├── 0008_create_question_versions.sql
│   │   ├── 0009_create_assessments.sql
│   │   ├── 0010_create_attempts.sql
│   │   ├── 0011_create_analytics.sql
│   │   ├── 0012_create_documents.sql
│   │   ├── 0013_create_announcements.sql
│   │   ├── 0014_create_calendar.sql
│   │   ├── 0015_create_community.sql
│   │   ├── 0016_create_audit_logs.sql
│   │   ├── 0017_create_functions_and_triggers.sql
│   │   ├── 0018_create_rls_policies.sql
│   │   ├── 0019_create_storage_policies.sql
│   │   └── 0020_create_indexes.sql
│   │
│   ├── seed/
│   │   ├── development.sql
│   │   ├── neet-ug-blueprint.sql
│   │   └── sample-curriculum.sql
│   │
│   └── tests/
│       ├── rls/
│       ├── constraints/
│       └── functions/
│
├── tests/
│   ├── e2e/
│   │   ├── authentication/
│   │   ├── student/
│   │   ├── faculty/
│   │   ├── admin/
│   │   └── assessment/
│   │
│   ├── security/
│   │   ├── authorization/
│   │   ├── batch-isolation/
│   │   ├── answer-key-protection/
│   │   ├── file-access/
│   │   └── api-abuse/
│   │
│   ├── load/
│   │   ├── concurrent-login/
│   │   ├── assessment-submission/
│   │   └── analytics-queries/
│   │
│   └── ai-evaluation/
│       ├── answer-accuracy/
│       ├── schema-validation/
│       └── academic-safety/
│
├── docs/
│   ├── project-overview.md
│   ├── architecture/
│   │   ├── high-level-architecture.md
│   │   ├── backend-architecture.md
│   │   ├── frontend-architecture.md
│   │   ├── database-architecture.md
│   │   └── security-architecture.md
│   │
│   ├── database/
│   │   ├── er-diagram.md
│   │   ├── data-dictionary.md
│   │   └── migration-guide.md
│   │
│   ├── api/
│   │   └── api-guidelines.md
│   │
│   ├── security/
│   │   ├── threat-model.md
│   │   ├── access-control.md
│   │   └── incident-response.md
│   │
│   ├── development/
│   │   ├── setup-guide.md
│   │   ├── coding-standards.md
│   │   └── contribution-guide.md
│   │
│   ├── deployment/
│   │   ├── deployment-guide.md
│   │   ├── environment-configuration.md
│   │   └── backup-recovery.md
│   │
│   ├── runbooks/
│   │   ├── database-outage.md
│   │   ├── ai-provider-outage.md
│   │   └── assessment-incident.md
│   │
│   └── adr/
│       └── 0001-modular-monolith.md
│
├── infra/
│   ├── docker/
│   │   ├── web.Dockerfile
│   │   ├── api.Dockerfile
│   │   └── worker.Dockerfile
│   │
│   ├── monitoring/
│   │   └── dashboards/
│   │
│   └── deployment/
│       ├── staging/
│       └── production/
│
├── scripts/
│   ├── setup.sh
│   ├── check-env.sh
│   ├── validate-migrations.sh
│   ├── run-tests.sh
│   └── generate-types.sh
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── security-checks.yml
│       └── deploy.yml
│
├── .editorconfig
├── .gitignore
├── .npmrc
├── .nvmrc
├── .prettierrc
├── eslint.config.js
├── package.json
├── pnpm-workspace.yaml
├── pnpm-lock.yaml
├── tsconfig.json
├── turbo.json
├── .env.example
├── README.md
└── LICENSE
```

---

## 3. Backend Module Structure

Every major backend feature should follow the same internal organization.

For example, the assessment module:

```text
modules/
└── assessments/
    ├── assessment.routes.ts
    ├── assessment.controller.ts
    ├── assessment.service.ts
    ├── assessment.repository.ts
    ├── assessment.schemas.ts
    ├── assessment.policies.ts
    ├── assessment.types.ts
    │
    ├── domain/
    │   ├── assessment.entity.ts
    │   ├── assessment-status.ts
    │   └── assessment-rules.ts
    │
    └── tests/
        ├── assessment.service.test.ts
        ├── assessment.repository.test.ts
        └── assessment.policies.test.ts
```

### Responsibility of each file

| File | Responsibility |
|---|---|
| Routes | Define HTTP endpoints |
| Controller | Handle HTTP requests and responses |
| Service | Execute business operations |
| Repository | Handle database operations |
| Schemas | Validate incoming data |
| Policies | Check resource-level permissions |
| Types | Define internal TypeScript types |
| Domain | Maintain important business rules |
| Tests | Verify module behaviour |

### Example assessment endpoints

```text
/api/v1/assessments
/api/v1/assessments/:assessmentId
/api/v1/assessments/:assessmentId/start
/api/v1/assessments/:assessmentId/questions
/api/v1/attempts/:attemptId/answers
/api/v1/attempts/:attemptId/submit
/api/v1/attempts/:attemptId/result
```

The routes should delegate their business operations to services. Controllers should not contain scoring logic or direct database manipulation.

---

## 4. Frontend Feature Structure

Use feature-based organization rather than placing every page, hook and component in one global folder.

For example:

```text
features/
└── assessments/
    ├── api/
    │   ├── assessment.api.ts
    │   └── assessment.queries.ts
    │
    ├── components/
    │   ├── AssessmentCard.tsx
    │   ├── AssessmentHeader.tsx
    │   ├── QuestionPalette.tsx
    │   ├── QuestionNavigator.tsx
    │   ├── QuestionRenderer.tsx
    │   └── ExamTimer.tsx
    │
    ├── hooks/
    │   ├── useAssessment.ts
    │   └── useAssessmentQuestions.ts
    │
    ├── pages/
    │   ├── AssessmentListPage.tsx
    │   ├── AssessmentDetailsPage.tsx
    │   └── AssessmentInstructionsPage.tsx
    │
    ├── schemas/
    │   └── assessment-form.schema.ts
    │
    ├── state/
    │   └── assessment-session.store.ts
    │
    └── index.ts
```

Keep assessment attempt functionality separate from assessment creation and management.

The student-facing question renderer must never receive answer-key data.

---

## 5. Database and Supabase Organization

All database changes must be managed through version-controlled SQL migrations.

### Important database domains

| Domain | Core entities |
|---|---|
| Identity | profiles, roles |
| Academic | exams, exam_blueprints, exam_sections |
| Curriculum | subjects, chapters, topics, exam_subjects |
| Enrollment | students, batches, enrollments |
| Resources | resources, resource_files |
| Question bank | questions, question_versions, question_options |
| Assessments | assessments, assessment_questions |
| Examination attempts | attempts, attempt_answers |
| AI | ai_generation_jobs, ai_generation_reviews |
| Analytics | student_performance, topic_performance |
| Documents | student_documents, document_reviews |
| Communication | announcements, calendar_events |
| Governance | audit_logs |

### Essential database rules

1. Give every entity a primary key.
2. Use foreign keys for relational integrity.
3. Create appropriate indexes for high-frequency queries.
4. Enforce uniqueness for student answers within an attempt.
5. Validate that selected options belong to the referenced question.
6. Preserve immutable versions of published questions.
7. Enable and test RLS on exposed tables.
8. Restrict correct-answer information from student-facing queries.
9. Keep audit logs protected against ordinary user modification.
10. Apply all schema updates through migrations.

### Storage organization

Use private Supabase Storage buckets:

```text
resources/
    notes/
    books/
    dpp/
    pyq/
    videos/
    diagrams/

student-documents/
    admission/
    identity/
    academic/
    other/

question-media/
    diagrams/
    images/
```

Store file paths and metadata in PostgreSQL, not the actual file contents.

Private documents should only be accessed through properly authorized, short-lived signed URLs.

---

## 6. Background Worker Organization

Do not perform slow AI generation, document processing or bulk report creation inside regular HTTP request handlers.

Use a background worker for long-running work.

```text
apps/worker/src/jobs/

├── ai-question-generation/
│   ├── generate-questions.job.ts
│   └── validate-generated-questions.ts
│
├── report-generation/
│   └── generate-student-report.job.ts
│
├── email-notifications/
│   └── send-announcement-email.job.ts
│
├── document-processing/
│   └── process-document.job.ts
│
└── analytics-aggregation/
    └── aggregate-performance.job.ts
```

### Worker requirements

- Retry temporary failures with bounded exponential backoff.
- Prevent duplicate job execution through idempotency.
- Track job status and failure reason.
- Support safe retries.
- Avoid logging sensitive student document contents.
- Alert administrators when important jobs repeatedly fail.

Use a properly implemented queue adapter. Choose the underlying queue technology after validating the expected workload and deployment environment.

---

## 7. Shared Packages

### `packages/contracts`

This package is important because both the frontend and backend need to agree on request and response formats.

Example:

```text
packages/contracts/src/

├── auth/
│   ├── login.schema.ts
│   └── user.schema.ts
│
├── assessments/
│   ├── assessment.schema.ts
│   └── assessment-response.schema.ts
│
├── questions/
│   └── question.schema.ts
│
├── attempts/
│   ├── attempt.schema.ts
│   └── submit-attempt.schema.ts
│
└── index.ts
```

Use Zod schemas to validate API contracts and infer TypeScript types.

Do not share database service-role credentials, repositories, backend entities or privileged types with the frontend.

---

## 8. Testing Organization

A production system needs more than basic component tests.

| Testing type | Tool or method | Main objective |
|---|---|---|
| Unit testing | Vitest | Validate individual functions |
| Component testing | React Testing Library | Validate interface behaviour |
| API integration | Vitest | Validate API and database integration |
| E2E testing | Playwright | Test complete user workflows |
| Database testing | SQL and Supabase local environment | Validate constraints and RLS |
| Security testing | Automated and manual security tests | Find unauthorized access |
| Load testing | k6 | Measure concurrent workload |
| AI evaluation | Curated evaluation dataset | Verify academic output quality |

### Most important test scenarios

```text
Authentication
    - Student login
    - Faculty login
    - Admin login
    - Invalid session
    - Suspended account

Authorization
    - Student cannot access Admin APIs
    - Student cannot access Faculty endpoints
    - Student cannot access another student's records
    - Batch-specific content isolation

Assessment
    - Start assessment
    - Save answers
    - Resume after refresh
    - Submit assessment
    - Automatic timeout
    - Duplicate submission prevention
    - Server-side scoring
    - Answer-key protection

AI
    - Invalid AI response
    - Missing answer options
    - Incorrect schema
    - Duplicate questions
    - Faculty approval requirement

Storage
    - Unauthorized document access
    - Expired signed URL
    - Wrong batch resource access
    - File upload validation
```

---

## 9. Environment Configuration

Use separate environment files for each application.

```text
neet-prep-lms/
│
├── .env.example
│
├── apps/
│   ├── web/.env.example
│   ├── api/.env.example
│   └── worker/.env.example
```

### Web environment

```env
VITE_API_BASE_URL=
VITE_SUPABASE_URL=
VITE_SUPABASE_PUBLISHABLE_KEY=
```

### API environment

```env
NODE_ENV=development
PORT=5000

SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

GROQ_API_KEY=

CORS_ORIGIN=
LOG_LEVEL=
```

### Worker environment

```env
NODE_ENV=development

SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=

GROQ_API_KEY=

QUEUE_CONNECTION=
LOG_LEVEL=
```

These are templates, not actual credentials.

Never put service-role keys or AI provider secrets in the React frontend.

Use a secrets manager or protected deployment environment for real production credentials. Keep `.env` files out of Git.

---

## 10. Root Project Configuration

Use pnpm workspaces to manage the monorepo.

### `pnpm-workspace.yaml`

```yaml
packages:
  - "apps/*"
  - "packages/*"
```

### Root `package.json`

```json
{
  "name": "neet-prep-lms",
  "private": true,
  "packageManager": "pnpm@10",
  "scripts": {
    "dev": "turbo run dev --parallel",
    "build": "turbo run build",
    "test": "turbo run test",
    "lint": "turbo run lint",
    "typecheck": "turbo run typecheck",
    "format": "prettier --write .",
    "check": "pnpm lint && pnpm typecheck && pnpm test && pnpm build"
  },
  "devDependencies": {
    "prettier": "^3",
    "turbo": "^2",
    "typescript": "^5"
  }
}
```

Pin exact dependency versions through the package manager and lockfile in the actual repository. The version ranges above are illustrative starting points, not a verified compatibility matrix.

### `turbo.json`

```json
{
  "$schema": "https://turborepo.dev/schema.json",
  "tasks": {
    "dev": {
      "cache": false,
      "persistent": true
    },
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    },
    "test": {
      "dependsOn": ["^build"],
      "outputs": ["coverage/**"]
    },
    "lint": {
      "outputs": []
    },
    "typecheck": {
      "dependsOn": ["^build"],
      "outputs": []
    }
  }
}
```

Each application should define its own scripts and dependencies.

---

## 11. Coding and Architecture Rules

Follow these rules consistently.

### Frontend

- Organize application code by business feature.
- Keep reusable design-system components in `shared/components`.
- Keep API communication inside feature API modules.
- Never place Supabase service-role credentials in the frontend.
- Never implement authoritative examination scoring in the browser.
- Use server responses as the source of truth for important application state.
- Use accessible components and responsive layouts.

### Backend

- Keep business logic inside services and domain rules.
- Keep database operations inside repositories.
- Validate all external input.
- Authenticate and authorize every protected API request.
- Apply resource-level permission checks, not just role checks.
- Use database transactions for critical multi-step operations.
- Use idempotency for payment, submission and retry-sensitive operations.
- Add request IDs and structured logging.
- Never expose database errors or secrets directly to clients.

### Database

- Never manually modify the production database schema.
- Use migrations for every schema modification.
- Review every RLS policy.
- Test policies using realistic student and faculty identities.
- Avoid unnecessary service-role access.
- Keep published assessment and question revisions stable.

### AI

- Treat AI output as untrusted input.
- Validate every generated question.
- Require authorized faculty approval before publishing.
- Store generation and review metadata.
- Apply usage limits and rate limits.
- Never expose the AI API key to the browser.

### Security

- Do not claim complete screenshot prevention in a web browser.
- Use watermarking as a piracy deterrent.
- Store files privately.
- Apply least-privilege access.
- Maintain audit trails for administrative actions.
- Protect administrative impersonation features with explicit, audited support-session controls rather than changing the underlying authenticated identity.

---

## 12. Recommended Implementation Order

Do not build all directories and modules at once.

### Phase 1 — Foundation

1. Create the monorepo.
2. Configure pnpm workspaces and TypeScript.
3. Set up React and Vite.
4. Set up the Express API.
5. Connect Supabase.
6. Establish authentication and trusted role assignment.
7. Create initial database migrations.
8. Implement RLS and authorization tests.
9. Establish CI/CD and logging.

### Phase 2 — Core NEET LMS

1. Exam blueprint and curriculum.
2. Students and faculty management.
3. Batch and enrollment management.
4. Learning resources.
5. Question bank and question revisions.
6. Assessment creation.
7. Server-side scoring and submission.
8. Student results and analytics.
9. Admin audit functionality.

### Phase 3 — Advanced Features

1. AI question generation.
2. Faculty question review and approval.
3. Student academic assistant.
4. Academic calendar.
5. Announcements.
6. Document verification.
7. Community discussions.
8. Background report generation.
9. Advanced analytics.

### Phase 4 — Production Hardening

1. Security testing.
2. Load and concurrency testing.
3. Backup restoration verification.
4. Monitoring and alerting.
5. Network and outage recovery tests.
6. Accessibility checks.
7. Production deployment.
8. Controlled coaching institute pilot.

---

## 13. Features to Keep Outside the Initial MVP

The following should not delay the initial release:

- IMAT, UCAT and MCAT blueprints.
- Multi-institute SaaS tenancy.
- Advanced community features.
- Sophisticated offline examination delivery.
- AI-generated diagram automation.
- Advanced proctoring integrations.
- Complex payment and billing workflows.

Build them when the initial NEET platform is reliable and users demonstrate the need.

---

## 14. Final Architecture Recommendation

The intended architecture is:

```text
                   STUDENT / FACULTY / ADMIN
                              |
                              v
                     REACT FRONTEND
                              |
                              v
                        EXPRESS API
                              |
               +--------------+--------------+
               |              |              |
               v              v              v
           AUTH/RBAC     BUSINESS MODULES   AI SERVICES
                              |
          +-------------------+-------------------+
          |                   |                   |
          v                   v                   v
      CURRICULUM          ASSESSMENTS          RESOURCES
          |                   |                   |
          v                   v                   v
      ENROLLMENTS       SCORING ENGINE       PRIVATE STORAGE
          |                   |                   |
          +-------------------+-------------------+
                              |
                              v
                     SUPABASE POSTGRESQL
                              |
                              v
                       BACKGROUND QUEUE
                              |
                              v
                       WORKER PROCESS
                  /          |          \
                 v           v           v
               AI JOBS     REPORTS    NOTIFICATIONS
```

### Final engineering decision

Build this project as a **modular monolith in a TypeScript monorepo**, with:

- One React application.
- One Express API.
- One separately deployable background worker.
- One Supabase PostgreSQL database.
- One private cloud storage environment.
- Shared validated API contracts.
- Version-controlled database migrations.
- Automated security, integration and end-to-end tests.

This structure is scalable enough for the initial institute deployment and allows you to introduce additional examination configurations, more workers and eventually multiple institutional tenants without rewriting the entire application.

**Most importantly: this is the proposed target structure. Production readiness will depend on implementing, securing, load-testing and operating each component correctly.***564tr```````````````