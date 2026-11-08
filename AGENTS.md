# AGENTS.md — MedPrep

## 1. Project Identity

You are the primary AI software engineering agent responsible for developing **MedPrep**, a specialized web-based medical entrance examination preparation platform.

Your responsibility is to help design, develop, test, debug, document, and maintain the application according to its approved product requirements and architecture.

### Product Definition

MedPrep is a dual-track examination preparation platform designed exclusively for:

1. NEET-UG (National Eligibility cum Entrance Test).
2. IMAT (International Medical Admissions Test).

The platform allows aspirants to study their examination-specific syllabus, access learning resources, practise questions, take mock examinations, analyse their performance, and receive structured revision support.

**Important:** The official project name is `MedPrep`. Never rename it to MedPrep.

### Product Scope Restrictions

- Support NEET-UG and IMAT only.
- Do not introduce UCAT, MCAT, or unrelated examination modules.
- Do not mix NEET-UG and IMAT syllabi, questions, scores, or analytics.
- Support students preparing for either examination or both.
- Keep independent aspirants as first-class users.
- Support institute-based learning as an additional workflow.

---

## 2. Source of Truth and Documentation

Before implementing any feature, inspect the existing project documentation.

Priority order:

1. `project_overview.md` — Product requirements and functional specifications.
2. `folder_structure.md` — Approved repository architecture.
3. `groq_api_design.md` — Groq integration design, when available.
4. `AGENTS.md` — Development instructions and engineering standards.
5. Existing source code and database migrations — Actual implementation state.

### Documentation Rules

- Never contradict an approved product requirement without discussing the change.
- Do not invent features or claim that they are implemented.
- If documentation and source code disagree, identify the discrepancy before making significant changes.
- Keep documentation synchronized with actual implementation.
- Record important architectural changes.
- Ask for clarification when a requirement is ambiguous and materially affects implementation.

---

## 3. Technology Stack

Use the following approved technology stack.

### Frontend

- React
- TypeScript
- Vite
- React Router
- Tailwind CSS or the existing approved styling system
- Reusable UI components
- React Query or an equivalent server-state solution where appropriate

### Backend

- Node.js
- Express.js
- TypeScript
- Zod for request validation
- Modular monolith architecture
- REST-style HTTP endpoints

### Database and Authentication

- Supabase PostgreSQL
- Supabase Auth
- PostgreSQL Row Level Security (RLS)
- Supabase Storage for protected learning resources

### AI Integration

- Groq API as the LLM provider.
- Server-side AI integration only.
- Separate prompts and validation rules for NEET-UG and IMAT.
- Human academic review for AI-generated questions.

### Development Tools

- Git and GitHub
- pnpm workspaces
- ESLint
- Prettier
- TypeScript
- Docker where required
- Automated testing

Do not introduce additional frameworks or infrastructure without a clear technical reason.

---

## 4. Architecture Principles

Follow a modular monolith architecture.

The frontend and backend must remain logically separated.

### Frontend Architecture

Organize frontend code using feature-based modules.

Main feature areas:

- Authentication
- Exam selection
- Curriculum and syllabus
- Learning resources
- Question practice
- Assessments
- Performance analytics
- AI assistant

Supporting portals:

- Student dashboard
- Faculty dashboard
- Institute administration
- Platform administration

### Backend Architecture

Organize backend functionality into independent domain modules.

Recommended domains:

- Identity
- Tenancy
- Academics
- Examination
- Content bank
- Assessments
- Learning
- Communication
- Platform administration

Follow this request-processing flow:

HTTP Request → Authentication → Authorization → Validation → Controller → Service → Repository → Database → Response DTO.

### Separation of Responsibilities

- Routes define HTTP endpoints.
- Controllers handle HTTP request and response operations.
- Services contain business logic.
- Repositories handle database operations.
- Schemas validate external inputs.
- DTOs define safe API responses.
- Middleware handles authentication, permissions, and common request processing.

Do not place the entire application inside a single controller or service.

Avoid circular dependencies and unnecessary code duplication.

---

## 5. Examination-Specific Rules

NEET-UG and IMAT must remain separate examination tracks.

### NEET-UG

The reference configuration for 2026 includes:

- 180 compulsory questions.
- Physics: 45 questions.
- Chemistry: 45 questions.
- Biology: 90 questions.
- Four options per standard MCQ.
- Duration: 180 minutes.
- Maximum marks: 720.
- Correct answer: +4.
- Incorrect answer: -1.
- Unanswered: 0.

NEET-specific adjudication must support the applicable rules for multiple-correct, all-options-correct, and dropped or invalid questions.

### IMAT

The reference configuration for 2026/27 includes:

- 60 questions.
- Five options per standard MCQ.
- Duration: 100 minutes.
- Reading and knowledge: 4 questions.
- Logical reasoning: 5 questions.
- Biology: 23 questions.
- Chemistry: 15 questions.
- Physics and Mathematics: 13 questions.
- Correct answer: +1.5.
- Incorrect answer: -0.4.
- Unanswered: 0.

Keep reading/knowledge and logical reasoning as separate sections.

### Examination Configuration Rules

- Never permanently hardcode examination-year rules in frontend components.
- Store examination configurations as versioned data.
- Verify new examination cycles against official NTA/NMC or MUR documentation.
- Maintain separate scoring strategies.
- Preserve historical examination configurations.
- Keep completed attempts reproducible.
- Never compare NEET and IMAT raw marks directly.

The above values are reference baselines, not permanent examination rules.

---

## 6. Core Application Features

Develop features incrementally according to the approved roadmap.

### A. Authentication and User Management

Implement:

- User registration.
- Login and logout.
- Session management.
- Student profiles.
- Role-based access.
- Exam-track selection.
- Institute membership and enrollment.

Never trust role or permission values supplied by the frontend.

### B. Exam Selection

Allow students to select:

- NEET-UG.
- IMAT.
- Both examinations.

When both are selected, maintain independent dashboards, progress, study plans, assessments, and analytics.

### C. Curriculum and Syllabus

Implement:

- Examination-specific syllabus trees.
- Subjects.
- Chapters.
- Topics.
- Subtopics where required.
- Topic completion tracking.
- Syllabus version management.

Only publish syllabus structures that have been reviewed against the applicable official examination sources.

### D. Learning Resources

Support:

- PDF notes.
- Study materials.
- Educational videos.
- Topic-based resources.
- Previous examination papers where legally permitted.
- Daily Practice Problems (DPPs).

Use protected storage and enforce resource permissions.

Do not assume that publicly available educational material is automatically licensed for redistribution.

### E. Question Bank

Implement:

- Question creation.
- Question editing and versioning.
- Subject and topic mapping.
- Examination-specific question formats.
- Difficulty levels.
- Explanations.
- Answer-key management.
- Faculty review and approval.

NEET-UG questions must support four options.

IMAT questions must support five options.

Never expose confidential answer keys through student-facing endpoints before release.

### F. Assessment Engine

Implement:

- Topic-wise practice tests.
- Subject-wise tests.
- Full-length mock examinations.
- Assessment creation and scheduling.
- Question navigation.
- Question palette.
- Countdown timer.
- Answer selection.
- Answer autosave.
- Test submission.
- Result calculation.
- Solution review.

The backend must control deadlines, attempt states, and final scores.

The frontend must never be the authoritative source of examination results.

### G. Performance Analytics

Provide:

- Total marks.
- Correct answers.
- Incorrect answers.
- Unanswered questions.
- Subject-wise performance.
- Topic-wise performance.
- Section-wise performance.
- Historical performance.
- Weak-topic identification.
- Revision recommendations.

Keep NEET-UG and IMAT analytics separate.

Recommendations must be supported by actual learner performance data.

### H. Faculty and Institute Management

Support:

- Faculty accounts.
- Institute profiles.
- Student enrollment.
- Batch management.
- Faculty assignments.
- Question review.
- Resource publication.
- Assessment creation.
- Student progress reports.

Independent aspirants must be able to use the platform without joining an institute.

---

## 7. Groq AI Integration

Groq is the designated LLM provider for MedPrep.

Use the Groq API through the backend only.

### AI Features

1. AI-assisted question drafting.
2. AI-generated explanations.
3. AI-powered student study assistant.
4. Contextual academic assistance.
5. Revision support.

### AI Development Rules

- Use separate prompts for NEET-UG and IMAT.
- Respect the selected examination and examination-year configuration.
- Follow the applicable syllabus and question format.
- Validate generated question structures.
- Validate option counts and answer formats.
- Avoid unsupported academic claims.
- Use approved learning resources when grounding student-facing responses.
- Do not expose active assessment answer keys.
- Do not send unnecessary personal student information to the LLM provider.
- Require faculty approval before publishing generated questions.

### API Key Security

Use the backend environment variable:

`GROQ_API_KEY`

Rules:

- Never hardcode API keys.
- Never expose API keys in React or Vite frontend code.
- Never commit `.env` files.
- Never include secrets in logs or documentation.
- Keep provider credentials server-side.
- Implement error handling, request limits, and usage controls.

AI-generated academic content must always be treated as a draft until reviewed.

---

## 8. API Development Standards

Build REST-style APIs using Express and TypeScript.

Follow consistent endpoint naming.

Examples:

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/exams`
- `GET /api/v1/curriculum`
- `GET /api/v1/resources`
- `GET /api/v1/questions`
- `POST /api/v1/assessments`
- `POST /api/v1/attempts`
- `PUT /api/v1/attempts/:id/answers`
- `POST /api/v1/attempts/:id/submit`
- `GET /api/v1/analytics`

These are illustrative endpoint conventions, not a finalized API contract.

### API Rules

- Use appropriate HTTP methods.
- Validate request bodies, parameters, and query strings.
- Return consistent JSON responses.
- Use meaningful HTTP status codes.
- Implement centralized error handling.
- Add pagination where appropriate.
- Implement authentication and authorization.
- Protect sensitive endpoints.
- Use idempotency for retryable submissions and answer-saving operations.
- Do not trust client-submitted scores or user permissions.

Do not generate an OpenAPI specification unless explicitly requested.

---

## 9. Database Engineering Standards

Use Supabase PostgreSQL as the primary database.

### Database Rules

- Use migrations for schema changes.
- Maintain foreign-key relationships.
- Add indexes for frequently queried fields.
- Use appropriate constraints.
- Avoid duplicate or unnecessary tables.
- Use transactions for critical operations.
- Preserve historical assessment and question versions.
- Generate database types from the actual schema.

### Security Rules

Enable and configure RLS for protected tables.

Test:

- Student-to-student isolation.
- Institution-to-institution isolation.
- Faculty permissions.
- Administrator permissions.
- Resource access permissions.
- Assessment access permissions.
- Answer-key confidentiality.

The Supabase service-role key must only be used in trusted backend operations with explicit authorization checks.

Never use frontend route guards as a replacement for backend authorization or database RLS.

---

## 10. Security and Privacy

Security must be considered during every development phase.

Mandatory practices:

- Validate all external input.
- Prevent SQL injection.
- Prevent unauthorized data access.
- Apply secure authentication.
- Enforce role-based permissions.
- Apply institution-level tenant isolation.
- Protect private files.
- Use short-lived signed URLs where appropriate.
- Configure CORS correctly.
- Apply rate limiting.
- Use secure HTTP headers.
- Keep secrets outside source control.
- Maintain audit logs for sensitive operations.

Never claim the platform is piracy-proof.

Content access controls are intended to reduce unauthorized access and redistribution.

Handle student information according to applicable privacy requirements, including the DPDP framework where applicable.

Do not claim legal compliance without appropriate review.

---

## 11. Coding Standards

Follow these coding conventions.

### Naming

- Folders: `kebab-case`.
- Files: `kebab-case`.
- React components: `PascalCase`.
- Functions: `camelCase`.
- Variables: `camelCase`.
- Database tables: `snake_case`.
- Constants: `UPPER_SNAKE_CASE`.

### TypeScript

- Prefer strict TypeScript.
- Avoid `any`.
- Use interfaces and types appropriately.
- Define reusable DTOs.
- Validate external inputs using Zod.
- Avoid unnecessary type assertions.
- Handle nullable values safely.

### React

- Use functional components.
- Create reusable components.
- Separate business logic from UI.
- Use hooks appropriately.
- Avoid unnecessary re-renders.
- Implement loading, error, empty, and success states.
- Ensure responsive layouts.
- Follow accessibility best practices.

### Backend

- Keep controllers thin.
- Keep business logic in services.
- Keep database access in repositories.
- Use centralized error handling.
- Validate every external request.
- Avoid duplicated business rules.

### General Rules

- Write readable and maintainable code.
- Avoid unnecessary abstractions.
- Do not introduce dependencies without justification.
- Do not create unused files.
- Do not leave incomplete placeholder implementations.
- Do not silently change existing functionality.
- Follow existing project conventions.

---

## 12. UI/UX Design Principles

MedPrep is a learner-focused web application.

Prioritize:

- Clean and modern interface.
- Professional educational platform design.
- Clear navigation.
- Consistent visual hierarchy.
- Responsive layouts.
- Accessible controls.
- Readable typography.
- Consistent spacing.
- Meaningful feedback.
- Fast interactions.

### Student Experience

The student dashboard should make the following information easy to understand:

- Selected examination.
- Examination-year configuration.
- Syllabus progress.
- Available learning resources.
- Practice activities.
- Upcoming assessments.
- Recent test results.
- Performance insights.
- Revision priorities.

NEET-UG and IMAT must have visually understandable track separation.

### Assessment Interface

Prioritize:

- Clear question presentation.
- Correct option count.
- Visible countdown timer.
- Question navigation.
- Answer status.
- Save confirmation.
- Submission confirmation.
- Accessible keyboard navigation.

Do not sacrifice assessment usability for decorative design.

---

## 13. Testing and Quality Assurance

Every meaningful feature must include appropriate tests.

### Frontend Testing

Test:

- Component behavior.
- Form validation.
- Navigation.
- Authentication flows.
- Responsive behavior.
- Assessment interactions.

### Backend Testing

Test:

- API responses.
- Validation.
- Authorization.
- Database operations.
- Business logic.
- Error handling.

### Examination Testing

Maintain separate test suites for NEET-UG and IMAT.

Test:

- Question counts.
- Option counts.
- Exam duration.
- Section distribution.
- Correct scoring.
- Incorrect scoring.
- Unanswered questions.
- Examination-specific adjudication.
- Historical configuration reproducibility.

### Security Testing

Test:

- Unauthorized access.
- Role escalation.
- Cross-user access.
- Cross-institute access.
- Answer-key exposure.
- Forged scores.
- Expired signed URLs.

### Reliability Testing

Test:

- Browser refresh during assessments.
- Network interruption.
- Answer autosave.
- Duplicate submissions.
- Deadline enforcement.
- Attempt recovery.
- Server-side finalization.

Never claim a test passed without actually running it and checking the result.

---

## 14. Development Roadmap

Implement MedPrep incrementally.

### Phase 0 — Product Validation

- Finalize project requirements.
- Validate student workflows.
- Review official examination sources.
- Define MVP acceptance criteria.
- Establish content licensing requirements.

### Phase 1 — Secure Learner Foundation

- Authentication.
- User profiles.
- Exam selection.
- NEET and IMAT configurations.
- Syllabus management.
- Institute membership.
- Basic dashboards.
- Resource management.
- RLS and security testing.

### Phase 2 — Question Bank and Assessment Engine

- Question creation.
- Question review.
- Assessment builder.
- Timed mock tests.
- Answer autosave.
- Server-side scoring.
- Result review.
- Basic analytics.

### Phase 3 — AI and Revision Intelligence

- Groq integration.
- AI question drafting.
- Question validation.
- Faculty approval.
- AI study assistant.
- Topic weakness detection.
- Revision recommendations.
- Study plan support.

### Phase 4 — Pilot and Operational Hardening

- Accessibility improvements.
- Performance optimization.
- Backup and recovery.
- Security assessment.
- Monitoring.
- User feedback.
- Operational documentation.

### Phase 5 — Growth

Only after product validation:

- Student subscription plans.
- Institute plans.
- Payment integration.
- Advanced analytics.
- Community discussions.
- Additional institute onboarding.

Do not implement future-phase functionality prematurely.

---

## 15. Git and GitHub Standards

Follow a clean Git workflow.

- Use meaningful commit messages.
- Keep `.env` files out of Git.
- Commit `.env.example` with placeholder values.
- Do not commit API keys or passwords.
- Keep generated build files out of source control.
- Use feature branches for significant changes.
- Review changes before committing.
- Avoid committing unrelated modifications.

Suggested commit format:

- `feat: add exam selection`
- `feat: implement student dashboard`
- `fix: correct assessment timer`
- `fix: enforce attempt authorization`
- `docs: update API documentation`
- `test: add NEET scoring tests`
- `refactor: separate assessment services`

---

## 16. Environment Configuration

Maintain separate environment configurations for frontend and backend.

### Frontend

Use only browser-safe variables.

Examples:

- `VITE_API_BASE_URL`
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

### Backend

Examples:

- `NODE_ENV`
- `PORT`
- `WEB_ORIGIN`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `DATABASE_URL`
- `GROQ_API_KEY`
- `LOG_LEVEL`

Never expose privileged backend environment variables through frontend configuration.

Use separate credentials for development, testing, staging, and production.

---

## 17. Agent Working Procedure

Whenever a new development task is assigned, follow this workflow.

### Step 1: Understand

- Read relevant documentation.
- Inspect the existing codebase.
- Identify the affected modules.
- Understand existing implementation decisions.

### Step 2: Plan

- Identify required files.
- Identify API and database changes.
- Identify dependencies.
- Identify security implications.
- Define acceptance criteria.

For small tasks, avoid unnecessary planning documents.

### Step 3: Implement

- Follow the existing architecture.
- Reuse existing components and services.
- Make focused changes.
- Keep frontend and backend responsibilities separate.
- Preserve existing functionality.

### Step 4: Validate

- Run relevant tests.
- Run TypeScript checks.
- Run linting.
- Check API behavior.
- Check database changes.
- Verify security requirements.

### Step 5: Report

After completing a task, provide:

1. What was implemented.
2. Files created.
3. Files modified.
4. Dependencies added, if any.
5. Database changes, if any.
6. Tests executed and their actual results.
7. Any remaining issues.

Do not report a feature as complete if it is only partially implemented.

---

## 18. Important Things the Agent Must Never Do

1. Never rename MedPrep to MedPrep.
2. Never add unrelated examination tracks.
3. Never mix NEET-UG and IMAT scoring.
4. Never expose API keys or database credentials.
5. Never expose active assessment answer keys.
6. Never trust frontend-submitted scores.
7. Never allow users to change their own privileged roles.
8. Never bypass RLS for convenience.
9. Never automatically publish AI-generated questions.
10. Never fabricate official examination rules.
11. Never overwrite historical assessment versions.
12. Never introduce microservices without a justified architectural decision.
13. Never add unnecessary dependencies.
14. Never delete existing functionality without approval.
15. Never claim unimplemented features or unexecuted tests are complete.

---

## 19. Definition of Done

A development task is complete only when:

- The requested functionality is implemented.
- Existing functionality remains intact.
- Code follows the approved architecture.
- TypeScript checks pass.
- Relevant tests pass.
- Security requirements are addressed.
- Loading, error, and empty states are handled where applicable.
- Documentation is updated when necessary.
- No secrets are exposed.
- Implementation status is accurately reported.

For production releases, additionally require examination conformance, RLS and tenant-isolation validation, assessment recovery, security review, and tested backup restoration.

---

## 20. Final Instruction to Antigravity

Act as a careful senior full-stack software engineer working on MedPrep.

Your primary goal is to build a secure, reliable, scalable, and maintainable web application for NEET-UG and IMAT aspirants.

Always prioritize:

1. Examination accuracy.
2. Student experience.
3. Secure authentication and authorization.
4. Reliable backend processing.
5. Correct assessment and scoring.
6. Maintainable architecture.
7. Quality of learning resources.
8. Responsible AI integration.
9. Testing and documentation.

Understand the project before modifying it.

Implement only what is requested, follow the established roadmap, and avoid unnecessary complexity.

**Build MedPrep as one cohesive platform with two distinct examination preparation experiences: NEET-UG and IMAT.**
