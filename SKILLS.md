# SKILLS.md — MedPrep

## 1. Purpose

This document defines the technical skills, development capabilities, implementation workflows, and domain-specific knowledge required to develop **MedPrep**, a web-based medical entrance examination preparation platform.

The AI coding agent must use these skills when implementing, debugging, testing, and maintaining the project.

The skills must remain aligned with:

- `project_overview.md`
- `folder_structure.md`
- `AGENTS.md`
- `groq_api_design.md` (when available)

**Important:** The project name is MedPrep. Do not use MedPrep as the application name.

---

# 2. Core Technical Skills

## 2.1 Frontend Development

**Required technologies:**
- React
- TypeScript
- Vite
- React Router
- Tailwind CSS or the existing styling solution
- Modern JavaScript (ES6+)

### Required capabilities

The agent must be able to:

1. Build reusable React components.
2. Develop responsive web application layouts.
3. Implement authentication interfaces.
4. Create student dashboards.
5. Build exam selection interfaces.
6. Develop syllabus navigation components.
7. Create learning resource interfaces.
8. Build question practice interfaces.
9. Develop interactive mock test interfaces.
10. Implement performance analytics dashboards.
11. Handle API integration using appropriate asynchronous patterns.
12. Manage loading, error, empty, and success states.
13. Implement form validation.
14. Maintain accessible and keyboard-friendly interfaces.

### Frontend development rules

- Use functional React components.
- Prefer reusable components over duplicated UI.
- Use TypeScript for component props and application data.
- Keep API logic separate from presentation components.
- Avoid unnecessary global state.
- Use the existing routing and state-management conventions.
- Do not place confidential business logic in the frontend.
- Do not calculate authoritative examination scores in the browser.
- Ensure responsive behavior across desktop, tablet, and mobile.

### Important UI modules

- Authentication pages.
- Student dashboard.
- Examination selection.
- NEET-UG dashboard.
- IMAT dashboard.
- Syllabus explorer.
- Learning resources.
- Question practice.
- Assessment runner.
- Results and solutions.
- Performance analytics.
- Faculty dashboard.
- Institute administration.

---

## 2.2 Backend Development

**Required technologies:**
- Node.js
- Express.js
- TypeScript
- REST-style APIs
- Zod validation

### Required capabilities

The agent must be able to:

1. Design REST API endpoints.
2. Implement Express routes.
3. Develop controllers and services.
4. Implement repository-based database access.
5. Build authentication middleware.
6. Implement role-based authorization.
7. Validate request bodies and parameters.
8. Handle application errors centrally.
9. Implement pagination and filtering.
10. Handle asynchronous operations.
11. Implement secure file access.
12. Build reliable assessment submission workflows.

### Backend architecture

Follow this structure:

```text
apps/api/src/
│
├── config/
├── bootstrap/
├── middleware/
├── domains/
│   ├── identity/
│   ├── tenancy/
│   ├── academics/
│   ├── examination/
│   ├── content-bank/
│   ├── assessments/
│   ├── learning/
│   ├── communication/
│   └── platform/
│
├── infrastructure/
│   ├── database/
│   ├── storage/
│   ├── ai/
│   └── queue/
│
├── jobs/
├── shared/
└── tests/
```

### Backend implementation rules

- Keep controllers thin.
- Place business logic in services.
- Place database operations in repositories.
- Validate external inputs.
- Use consistent API responses.
- Implement appropriate HTTP status codes.
- Never trust client-submitted roles or scores.
- Use database transactions for critical operations.
- Implement idempotency for retryable assessment operations.

---

## 2.3 Database Development

**Required technologies:**
- PostgreSQL
- Supabase
- Supabase Auth
- Row Level Security (RLS)
- Supabase Storage

### Required capabilities

The agent must understand:

- Relational database design.
- Primary and foreign keys.
- Database normalization.
- One-to-many and many-to-many relationships.
- SQL queries.
- Joins and aggregations.
- Indexing.
- Constraints.
- Transactions.
- Database migrations.
- RLS policies.
- Database triggers and functions.
- Supabase client integration.

### MedPrep database responsibilities

Support data management for:

1. User profiles.
2. User roles and permissions.
3. Institutions and memberships.
4. Courses and batches.
5. Examination tracks.
6. Examination-year configurations.
7. Subjects and chapters.
8. Syllabus topics.
9. Learning resources.
10. Question bank.
11. Question versions and reviews.
12. Assessments.
13. Assessment attempts.
14. Student answers.
15. Results and scoring.
16. Performance analytics.
17. Study plans.
18. AI-generated drafts.
19. Audit records.

### Database rules

- Use migrations for schema changes.
- Maintain foreign-key relationships.
- Add indexes where appropriate.
- Enable RLS on protected tables.
- Keep student records isolated.
- Enforce institution-level access boundaries.
- Preserve historical question and assessment versions.
- Never expose privileged database credentials.
- Generate TypeScript database types from the actual schema.

---

# 3. Examination Domain Skills

## 3.1 NEET-UG Examination Knowledge

The agent must understand the NEET-UG examination structure and its configured yearly rules.

### Reference configuration: NEET-UG 2026

| Attribute | Configuration |
|---|---|
| Total questions | 180 |
| Physics | 45 |
| Chemistry | 45 |
| Biology | 90 |
| Options | 4 |
| Duration | 180 minutes |
| Correct answer | +4 |
| Incorrect answer | -1 |
| Unanswered | 0 |
| Maximum marks | 720 |

### Required capabilities

- NEET syllabus organization.
- Physics, Chemistry, and Biology categorization.
- Subject-wise question management.
- Four-option MCQ generation and validation.
- Topic-wise practice.
- Full-length mock test configuration.
- NEET-specific scoring.
- Multiple-correct question adjudication.
- All-options-correct adjudication.
- Dropped or invalid question adjudication.
- Subject-wise analytics.

The agent must verify applicable official examination rules before creating a new examination-year configuration.

## 3.2 IMAT Examination Knowledge

The agent must understand the IMAT examination structure independently of NEET-UG.

### Reference configuration: IMAT 2026/27

| Attribute | Configuration |
|---|---|
| Total questions | 60 |
| Reading and knowledge | 4 |
| Logical reasoning | 5 |
| Biology | 23 |
| Chemistry | 15 |
| Physics and Mathematics | 13 |
| Options | 5 |
| Duration | 100 minutes |
| Correct answer | +1.5 |
| Incorrect answer | -0.4 |
| Unanswered | 0 |

### Required capabilities

- IMAT syllabus organization.
- Section-based question management.
- Five-option MCQ validation.
- Section-wise assessment configuration.
- Timed mock examinations.
- IMAT-specific scoring.
- Section-level analytics.
- English question content and explanations.
- Historical examination configuration management.

### Examination separation rules

- Never use NEET scoring for IMAT.
- Never use IMAT scoring for NEET.
- Maintain independent question banks and syllabus trees.
- Maintain separate examination configurations.
- Maintain independent student progress.
- Maintain separate result calculations.
- Preserve historical examination versions.

The configurations above are reference baselines, not permanent rules.

---

# 4. Authentication and Authorization Skills

The agent must be able to implement secure authentication using Supabase Auth.

### Required capabilities

- Registration.
- Login.
- Logout.
- Session management.
- User profile management.
- Authentication middleware.
- Role-based access control.
- Institution membership verification.
- Protected routes.
- Secure API authorization.

### Application roles

Support the following roles:

1. Student / Aspirant.
2. Faculty / Tutor.
3. Institute Administrator.
4. Platform Administrator.

### Authorization rules

- Students can access their own protected records.
- Faculty can manage only authorized academic content.
- Institute administrators can manage their own institution.
- Platform administrators can perform authorized platform operations.
- Independent students must not require institute membership.
- Users must not be able to modify their own privileged roles.

Always enforce permissions on the backend and through database policies where applicable.

---

# 5. AI and Groq API Integration Skills

**Designated AI provider: Groq**

The agent must understand how to integrate Groq into the MedPrep backend.

### Required technologies

- Groq API.
- Node.js.
- Express.js.
- TypeScript.
- Environment variables.
- Structured JSON output validation.
- Zod schemas.

### Required AI capabilities

#### A. AI Question Generation

Generate draft questions based on:

- Selected examination.
- Examination year.
- Subject.
- Chapter.
- Topic.
- Difficulty.
- Question format.

NEET-UG must use four options.

IMAT must use five options.

Generated questions must include:

- Question statement.
- Answer options.
- Correct answer.
- Explanation.
- Subject.
- Topic.
- Difficulty.
- Examination track.

Validate all generated data before storing it.

#### B. AI Explanation Generation

Generate educational explanations for approved questions.

Explanations should:

- Be academically clear.
- Explain the reasoning.
- Address relevant concepts.
- Avoid unsupported claims.
- Match the selected examination.

#### C. AI Study Assistant

Build a student-facing academic assistant that can:

- Explain difficult topics.
- Answer syllabus-related questions.
- Clarify concepts.
- Help with revision.
- Explain approved practice questions.
- Recommend relevant learning resources.

Use approved learning materials as grounding sources where possible.

Do not expose active assessment answer keys.

### Groq integration rules

- Store credentials in `GROQ_API_KEY`.
- Make all Groq requests from the backend.
- Never expose API keys in frontend code.
- Implement rate limiting.
- Handle provider failures gracefully.
- Validate AI responses.
- Track usage and costs where supported.
- Keep AI provider details inside the infrastructure layer.
- Make provider/model selection configurable.
- Never automatically publish generated academic content.

Suggested location:

```text
apps/api/src/infrastructure/ai/
├── groq.client.ts
├── groq.config.ts
├── groq.types.ts
└── index.ts
```

Domain-specific prompts and validation should remain in their respective academic modules.

---

# 6. Question Bank and Content Management Skills

The agent must be capable of developing an academic question management system.

### Required capabilities

- Question creation.
- Question editing.
- Question versioning.
- Subject mapping.
- Chapter mapping.
- Topic mapping.
- Difficulty classification.
- Option management.
- Answer-key management.
- Explanation management.
- Faculty review.
- Question approval.
- Question publication.
- Question withdrawal.

### Question lifecycle

```text
Question Creation
       |
       v
Validation
       |
       v
Academic Review
       |
       v
Approval / Rejection
       |
       v
Publication
       |
       v
Student Practice
```

AI-generated questions must follow the same validation and review process.

Never treat AI-generated answers as automatically correct.

Respect content ownership, copyright, and licensing requirements for previous examination papers and other learning materials.

---

# 7. Assessment Engine Development Skills

The assessment engine is one of the most important technical components of MedPrep.

### Required capabilities

- Assessment creation.
- Assessment configuration.
- Question selection.
- Question navigation.
- Question palette.
- Countdown timer.
- Answer selection.
- Answer autosave.
- Attempt tracking.
- Submission.
- Server-side deadline enforcement.
- Scoring.
- Result generation.
- Solution review.
- Attempt recovery.

### Assessment lifecycle

```text
Assessment Created
       |
       v
Student Starts Test
       |
       v
Server Creates Attempt
       |
       v
Questions Loaded
       |
       v
Student Answers Questions
       |
       v
Answers Saved to Server
       |
       v
Student Submits Test
       |
       v
Server Validates Submission
       |
       v
Server Calculates Score
       |
       v
Result Published
```

### Reliability requirements

- Store authoritative start time on the server.
- Enforce deadlines on the server.
- Save answers reliably.
- Recover attempts after browser refresh.
- Handle temporary network interruptions.
- Prevent duplicate finalization.
- Use transactions for result finalization.
- Preserve historical attempts.

The frontend timer is a display mechanism, not the authority for assessment deadlines.

---

# 8. Analytics and Performance Tracking Skills

The agent must understand data analysis and visualization for educational performance.

### Required capabilities

- SQL aggregations.
- Statistical summaries.
- Subject-wise analysis.
- Topic-wise analysis.
- Section-wise analysis.
- Historical comparisons.
- Accuracy calculations.
- Attempt analysis.
- Weakness identification.
- Revision recommendations.
- Dashboard chart integration.

### Student analytics

Display:

- Total marks.
- Maximum marks.
- Correct answers.
- Incorrect answers.
- Unanswered questions.
- Accuracy percentage.
- Subject performance.
- Topic performance.
- Section performance.
- Previous test comparisons.
- Improvement trends.

### Recommendation principles

- Use actual student performance data.
- Explain why a topic is recommended for revision.
- Avoid unsupported predictions.
- Keep NEET and IMAT analytics separate.
- Do not guarantee ranks, admissions, or examination outcomes.

---

# 9. Learning Resource Management Skills

The agent must understand resource organization and secure delivery.

### Required capabilities

- PDF resource management.
- Video resource management.
- Learning material categorization.
- Subject and topic mapping.
- Resource metadata.
- File upload.
- Protected file access.
- Signed URL generation.
- Resource authorization.

### Resource categories

- Notes.
- Study materials.
- Videos.
- Practice documents.
- Previous examination papers where permitted.
- Daily Practice Problems.

Use Supabase Storage for protected resources.

Do not expose private storage resources through unrestricted public URLs.

---

# 10. API Design and Integration Skills

The agent must understand REST-style API design.

### Required capabilities

- HTTP methods.
- URL design.
- Request validation.
- Response formatting.
- Authentication headers.
- Status codes.
- Error handling.
- Pagination.
- Filtering.
- API versioning.
- Frontend/backend integration.

### Example API endpoints

```text
/api/v1/auth
/api/v1/users
/api/v1/exams
/api/v1/curriculum
/api/v1/resources
/api/v1/questions
/api/v1/assessments
/api/v1/attempts
/api/v1/results
/api/v1/analytics
/api/v1/ai
```

These are endpoint group examples. Final endpoints must follow the approved API design.

Do not generate OpenAPI specifications unless explicitly requested.

---

# 11. Security Engineering Skills

Security must be applied throughout the application.

### Required knowledge

- Authentication security.
- Authorization.
- Role-based access control.
- PostgreSQL RLS.
- SQL injection prevention.
- Input validation.
- Secure session management.
- Environment variable protection.
- Rate limiting.
- CORS configuration.
- HTTP security headers.
- Secure file access.
- Audit logging.
- Tenant isolation.

### Mandatory security checks

- A student cannot access another student's private data.
- A student cannot modify another student's assessment attempt.
- A student cannot access an active answer key.
- A student cannot submit a forged score.
- Faculty cannot access unauthorized institute records.
- Institute administrators cannot access other institutions.
- Frontend code cannot access service-role credentials.
- Frontend code cannot access Groq credentials.
- Expired signed URLs must not provide continuing access.

Never bypass security checks to make a feature work.

---

# 12. Testing and Debugging Skills

The agent must be capable of writing and executing tests.

### Testing areas

#### Frontend

- Component testing.
- Form validation.
- Authentication flows.
- Routing.
- Responsive behavior.
- Assessment interactions.

#### Backend

- API testing.
- Controller testing.
- Service testing.
- Repository testing.
- Validation testing.
- Error-handling testing.

#### Database

- Migration testing.
- Constraint testing.
- RLS testing.
- Tenant-isolation testing.
- Database transaction testing.

#### Examination

- NEET scoring tests.
- IMAT scoring tests.
- Option-count validation.
- Section distribution.
- Time-limit enforcement.
- Historical configuration tests.

#### Reliability

- Autosave.
- Refresh recovery.
- Network interruption.
- Duplicate submissions.
- Deadline enforcement.
- Attempt finalization.

### Debugging workflow

1. Reproduce the problem.
2. Identify the affected component or module.
3. Inspect logs and error messages.
4. Identify the root cause.
5. Apply a focused fix.
6. Run relevant tests.
7. Verify that existing functionality remains intact.

Never claim a bug is fixed without verifying the result.

---

# 13. DevOps and Development Workflow Skills

The agent should understand:

- Git.
- GitHub.
- pnpm workspaces.
- Node.js package management.
- Environment configuration.
- Docker.
- Build processes.
- CI/CD fundamentals.
- Deployment configuration.
- Logging and monitoring.
- Backup and recovery.

### Required practices

- Maintain a clean Git history.
- Use `.gitignore` correctly.
- Keep secrets out of repositories.
- Maintain `.env.example`.
- Use reproducible dependency installation.
- Run linting and TypeScript checks.
- Test database migrations.
- Keep development and production configurations separate.

Do not introduce Kubernetes or unnecessary infrastructure without an approved requirement.

---

# 14. Documentation Skills

The agent must maintain technical documentation.

### Required documentation capabilities

- Project README.
- Architecture documentation.
- API documentation.
- Database documentation.
- Environment setup instructions.
- Feature documentation.
- Testing documentation.
- Troubleshooting guides.
- Deployment instructions.

### Documentation rules

- Document actual implementation.
- Do not describe planned features as completed.
- Keep examples consistent with current source code.
- Update documentation after significant architecture changes.
- Preserve the distinction between NEET and IMAT.

---

# 15. Accessibility and Responsive Design Skills

MedPrep must provide an accessible learning experience.

### Required capabilities

- Semantic HTML.
- Keyboard navigation.
- Screen-reader labels.
- Accessible form validation.
- Appropriate color contrast.
- Responsive layouts.
- Text resizing.
- Focus management.
- Reduced-motion support.
- Accessible timer notifications.

The examination runner must remain usable through keyboard navigation and different screen sizes.

---

# 16. Skill Activation and Task Mapping

Use the following mapping when deciding which skills to apply.

| Development task | Required skills |
|---|---|
| Build student dashboard | React, TypeScript, UI/UX, API integration |
| Implement login | React, Express, Supabase Auth, security |
| Create syllabus module | Frontend, backend, PostgreSQL |
| Build question bank | Backend, PostgreSQL, academic domain |
| Generate AI questions | Groq, prompt engineering, Zod, academic validation |
| Build mock test | React, Express, assessment engine |
| Calculate examination results | Scoring logic, PostgreSQL, testing |
| Create analytics dashboard | SQL, data analysis, visualization |
| Upload study materials | Supabase Storage, backend security |
| Manage institutes | RBAC, tenancy, PostgreSQL RLS |
| Debug API errors | Node.js, Express, TypeScript, testing |
| Deploy application | Git, Docker, CI/CD, environment management |

Apply only the skills relevant to the task. Do not introduce every module or technology into a small feature.

---

# 17. Implementation Workflow

For every assigned development task, use the following workflow.

## Step 1: Analyze

- Understand the requested functionality.
- Read the relevant documentation.
- Inspect the existing source code.
- Identify dependencies.
- Identify affected modules.

## Step 2: Design

- Define the implementation approach.
- Identify frontend changes.
- Identify backend changes.
- Identify database changes.
- Consider security and validation.

## Step 3: Implement

- Follow the established architecture.
- Reuse existing utilities.
- Write clean TypeScript.
- Avoid duplicated logic.
- Keep modules independent.
- Follow examination-specific rules.

## Step 4: Test

- Run relevant tests.
- Run TypeScript checks.
- Run linting.
- Test API integration.
- Validate database behavior.
- Check security boundaries.

## Step 5: Document

- Update relevant documentation.
- Record important implementation decisions.
- Document environment variables.
- Update tests where required.

## Step 6: Report

Provide a concise summary containing:

1. Implemented functionality.
2. Files created.
3. Files modified.
4. Dependencies added.
5. Database changes.
6. Tests executed.
7. Remaining issues.

---

# 18. Development Priorities

Follow this implementation order.

### Priority 1: Foundation

- Monorepo configuration.
- Frontend setup.
- Backend setup.
- Supabase connection.
- Database migrations.
- Authentication.
- User roles.

### Priority 2: Academic Foundation

- Examination selection.
- Exam-year configurations.
- NEET syllabus.
- IMAT syllabus.
- Student dashboards.
- Resource management.

### Priority 3: Assessment System

- Question bank.
- Question review.
- Assessment builder.
- Mock test runner.
- Answer autosave.
- Scoring engine.
- Results.

### Priority 4: Intelligence

- Performance analytics.
- Weak-topic detection.
- Revision recommendations.
- Groq API integration.
- AI question drafting.
- Faculty approval.
- AI study assistant.

### Priority 5: Production Readiness

- Security testing.
- Accessibility.
- Performance optimization.
- Backup and recovery.
- Monitoring.
- Deployment.

Do not skip foundational security or examination-conformance requirements to accelerate feature development.

---

# 19. Definition of a Successful Implementation

A feature is considered successfully implemented when:

- It satisfies the requested requirement.
- It follows the existing architecture.
- It uses appropriate TypeScript types.
- Inputs are validated.
- Permissions are enforced.
- Errors are handled.
- Relevant tests pass.
- Existing functionality remains intact.
- Documentation is updated where necessary.

A feature that only works visually but lacks its required backend, database, or security implementation must not be described as fully implemented.

---

# 20. Final Instruction

Act as a skilled full-stack development agent with expertise in React, TypeScript, Node.js, Express, PostgreSQL, Supabase, Groq AI, examination systems, and educational technology.

Use the skills in this document to build MedPrep as a reliable, secure, maintainable, and scalable web application.

Always remember:

- MedPrep is a web application.
- NEET-UG and IMAT are its only supported examination tracks.
- Aspirants are the primary users.
- Faculty and institutes are supporting users.
- Examination rules must be accurate and versioned.
- Backend services are authoritative for security and scoring.
- AI-generated academic content requires human review.
- Student data must remain protected.
- Development must follow the approved project roadmap.

**The ultimate goal is to build one cohesive MedPrep platform with two independent and accurate medical entrance examination preparation experiences.**