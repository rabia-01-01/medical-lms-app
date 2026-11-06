# MedPrepOS — NEET-UG & IMAT Preparation Platform

A high-security, dual-track Learning Management & Assessment System tailored for NEET-UG and IMAT medical entrance candidates, faculty, and coaching institutes.

---

## 1. Overview

**MedPrepOS** maintains two distinct, officially aligned preparation tracks within a single high-performance platform:
- **NEET-UG Track:** Aligned with NTA & NMC guidelines (180 questions, 720 marks, 180 mins, 4 options, +4/-1/0 scoring with official adjudication rules).
- **IMAT Track:** Aligned with Italian Ministry of University and Research (MUR) decrees (60 questions, 90 marks, 100 mins, 5 options, +1.5/-0.4/0 scoring across 5 distinct sections).

---

## 2. Architecture & Technology Stack

The repository is organized as a high-scalability **TypeScript Monorepo** managed with **pnpm workspaces** and **Turborepo**:

- **Frontend (`apps/web`):** React 18, Vite, TypeScript, Tailwind CSS, Recharts.
- **Backend API (`apps/api`):** Node.js, Express, TypeScript, Modular Monolith partitioned into Domain Bounded Contexts.
- **Database & Platform (`supabase/`):** PostgreSQL 15+, Supabase Auth, Row-Level Security (RLS), private Supabase Storage.
- **Shared Packages (`packages/`):**
  - `@medprepos/database`: Database schema types and Supabase client factories.
  - `@medprepos/api-contracts`: Strongly typed Zod schemas and request/response DTOs.
  - `@medprepos/exam-engine`: Server-authoritative NEET-UG and IMAT scoring engines, section rules, and adjudication logic.
  - `@medprepos/config`: Shared ESLint and TypeScript presets.

---

## 3. Repository Structure

```text
medprepos/
├── apps/
│   ├── web/                    # React + Vite client (Student, Faculty, Admin portals)
│   └── api/                    # Express modular monolith backend & background worker
├── packages/
│   ├── api-contracts/          # Shared Zod schemas and API DTOs
│   ├── database/               # Supabase database types & client factories
│   ├── exam-engine/            # Authoritative NEET & IMAT scoring & rule engines
│   └── config/                 # Shared TypeScript & ESLint configurations
├── supabase/
│   ├── config.toml             # Supabase CLI configuration
│   ├── migrations/             # 13 ordered, immutable SQL migrations
│   └── seed/                   # Official exam cycle definitions (2026/27) & reference data
├── tests/
│   ├── exam-conformance/       # Official NEET & IMAT scoring regression tests
│   ├── security/               # RLS, tenant isolation & answer-key exposure tests
│   ├── reliability/            # Autosave, retry & timeout finalization tests
│   └── load/                   # High-concurrency assessment load benchmarks
├── infra/
│   ├── docker/                 # Container definitions
│   └── local/                  # Local orchestration configs
├── docs/                       # Architecture, exam specs, API specs & ADRs
├── pnpm-workspace.yaml         # Workspace definition
├── turbo.json                  # Turborepo task pipeline
└── package.json                # Monorepo scripts
```

---

## 4. Getting Started

### Prerequisites
- Node.js >= 20.0.0
- pnpm >= 9.0.0
- Docker & Docker Compose (for local Supabase and services)
- [Supabase CLI](https://supabase.com/docs/guides/cli)

### Installation

1. **Install dependencies across the monorepo:**
   ```bash
   pnpm install
   ```

2. **Configure Environment Variables:**
   ```bash
   cp .env.example .env
   ```

3. **Start Local Database & Services (Supabase):**
   ```bash
   pnpm db:start
   ```

4. **Run Database Migrations & Generate Types:**
   ```bash
   pnpm db:migrate
   pnpm db:types
   ```

5. **Start Development Servers (Turborepo):**
   ```bash
   pnpm dev
   ```
   - Web Application: [http://localhost:5173](http://localhost:5173)
   - Backend API: [http://localhost:8000](http://localhost:8000)
   - API Health Check: [http://localhost:8000/health](http://localhost:8000/health)

---

## 5. Key Scripts

| Command | Action |
|---|---|
| `pnpm dev` | Run all applications concurrently |
| `pnpm dev:web` | Run React frontend only |
| `pnpm dev:api` | Run Express API backend only |
| `pnpm build` | Typecheck and build all apps & packages |
| `pnpm typecheck` | Run TypeScript validation across all workspaces |
| `pnpm lint` | Run ESLint across all workspaces |
| `pnpm test` | Run all unit and integration tests |
| `pnpm test:exam-conformance` | Run NEET-UG and IMAT scoring compliance tests |
| `pnpm test:security` | Run RLS and multi-tenant security verification tests |
| `pnpm db:reset` | Reset local Supabase database and rerun all migrations |

---

## 6. License & Governance

Proprietary — All rights reserved. MedPrepOS.
