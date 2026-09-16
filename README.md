<div align="center">

```
 ██████╗ ███████╗ ██████╗██╗   ██╗██████╗ ███████╗
 ██╔════╝ ██╔════╝██╔════╝██║   ██║██╔══██╗██╔════╝
 ██║  ███╗█████╗  ██║     ██║   ██║██████╔╝█████╗
 ██║   ██║██╔══╝  ██║     ██║   ██║██╔══██╗██╔══╝
 ╚██████╔╝███████╗╚██████╗╚██████╔╝██║  ██║███████╗
  ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝
         C O R P   ·   D B   S E C U R I T Y   L A B
```

### `BUILD` → `BREACH` → `HARDEN`

**A controlled database security engineering laboratory — design a real schema, attack it, understand why it broke, fix it, and prove the fix.**

<br>

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18%2B-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.x-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-App%20Layer-000000?style=for-the-badge&logo=flask&logoColor=white)
![Status](https://img.shields.io/badge/Status-Phase%201%20·%20Build-yellow?style=for-the-badge)
![Security Lab](https://img.shields.io/badge/Type-Offensive%20%2B%20Defensive%20Lab-critical?style=for-the-badge)

<sub>⚠️ Static badges above are safe to keep as-is. If you want live GitHub stats (stars, last commit, issues), replace <code>OWNER/REPO</code> in the badge URLs at the bottom of this file with your actual GitHub path.</sub>

</div>

<br>

---

## 📑 Table of Contents

- [The Idea](#-the-idea)
- [What is SecureCorp?](#-what-is-securecorp)
- [Data Model](#-data-model)
- [Repository Structure](#-repository-structure)
- [Phase 1 — Build](#-phase-1--build)
- [Phase 2 — Breach](#-phase-2--breach)
- [Phase 3 — Harden](#-phase-3--harden)
- [Defense in Depth](#-defense-in-depth)
- [Performance Validation](#-performance-validation)
- [Tech Stack](#️-tech-stack)
- [Running the Lab](#-running-the-lab)
- [Learning Objectives](#-learning-objectives)
- [Roadmap](#-roadmap)
- [Definition of Done](#-definition-of-done)
- [Final Principle](#-final-principle)

---

## 💡 The Idea

SecureCorp DB is not a schema demo. It is a closed engineering loop, run twice — once broken, once fixed — with evidence at every step.

```mermaid
flowchart LR
    A[Business\nRequirements] --> B[MCD]
    B --> C[MLD]
    C --> D[(PostgreSQL)]
    D --> E[Application\nLayer]
    E --> F{{Attack}}
    F --> G[Root Cause]
    G --> H[Harden]
    H --> I[Retest]
    I --> J([Proof])

    style F fill:#ef4444,color:#fff,stroke:#7f1d1d
    style J fill:#22c55e,color:#fff,stroke:#14532d
```

> **Build it. Break it. Understand why it broke. Fix it. Prove that it is fixed.**

Every vulnerability in this lab is introduced deliberately, exploited manually first, documented with evidence, then remediated and re-tested against the exact same exploit. Nothing is "fixed" without a passing regression test to prove it.

---

## 🏢 What is SecureCorp?

A fictional internal security platform — small enough to reason about fully, realistic enough to produce genuine database and application security problems.

```mermaid
flowchart LR
    U([👤 Users]) --> R[🎭 Roles]
    R --> P[🔑 Permissions]
    U --> I[🚨 Incidents]
    U --> L[📜 Audit Logs]
    A([💻 Assets]) --> V[🐞 Vulnerabilities]
    V --> I
    I --> L
    A --> L

    classDef core fill:#1e293b,color:#f8fafc,stroke:#64748b
    class U,R,P,I,L,A,V core
```

| Entity | Purpose |
|---|---|
| **Users** | Identities interacting with the platform |
| **Roles / Permissions** | RBAC — the N:N relationship at the center of the privilege-escalation lab |
| **Assets** | Systems/resources tracked by SecureCorp |
| **Vulnerabilities** | Findings linked to assets — feeds the incident pipeline |
| **Incidents** | Triggered by users or vulnerabilities |
| **Audit Logs** | Immutable trail — every state change is observable |

---

## 🗄️ Data Model

```mermaid
erDiagram
    USERS ||--o{ USER_ROLES : has
    ROLES ||--o{ USER_ROLES : assigned_to
    ROLES ||--o{ ROLE_PERMISSIONS : grants
    PERMISSIONS ||--o{ ROLE_PERMISSIONS : included_in
    USERS ||--o{ INCIDENTS : reports
    USERS ||--o{ AUDIT_LOGS : generates
    ASSETS ||--o{ VULNERABILITIES : exposes
    VULNERABILITIES ||--o{ INCIDENTS : triggers
    INCIDENTS ||--o{ AUDIT_LOGS : logged_as

    USERS {
        uuid id PK
        text username
        text password_hash
        timestamptz created_at
    }
    ROLES {
        uuid id PK
        text name
    }
    PERMISSIONS {
        uuid id PK
        text action
    }
    ASSETS {
        uuid id PK
        text name
        text criticality
    }
    VULNERABILITIES {
        uuid id PK
        uuid asset_id FK
        text cve_ref
        text severity
    }
    INCIDENTS {
        uuid id PK
        uuid user_id FK
        uuid vuln_id FK
        text status
    }
    AUDIT_LOGS {
        uuid id PK
        uuid actor_id FK
        text action
        timestamptz occurred_at
    }
```

`MCD → MLD` documentation for this schema lives in [`docs/mcd.md`](docs/mcd.md) and [`docs/mld.md`](docs/mld.md), with source diagrams under [`diagrams/`](diagrams/).

---

## 📂 Repository Structure

```text
securecorp-db/
│
├── .github/                          # CI / workflow configuration
│
├── app/                              # Application layer (Flask / CLI) — vulnerable + hardened variants
│
├── database/                         # Schema, constraints, seed data, DB roles
│
├── diagrams/
│   ├── MCD_Project_Sentinel_V1.drawio
│   ├── Mcd secops completed_v2.drawio
│   └── .gitkeep
│
├── docs/
│   ├── business-requirements.md      # Functional & security requirements
│   ├── decisions.md                  # Architecture Decision Records (ADR-style)
│   ├── mcd.md                        # Conceptual data model
│   └── mld.md                        # Logical data model
│
├── exploits/                         # Proof-of-concept exploit scripts, one per vulnerability
│
├── report/                           # Evidence: before/after, EXPLAIN ANALYZE output, retest logs
│
├── .env.example                      # Environment variable template
├── .gitignore
├── docker-compose.yml                # PostgreSQL + app orchestration
└── README.md
```

<details>
<summary><strong>📌 Naming note (click to expand)</strong></summary>

<br>

The two `.drawio` files in `diagrams/` currently carry version suffixes and inconsistent casing/spacing (`MCD_Project_Sentinel_V1.drawio`, `Mcd secops completed_v2.drawio`). Git already tracks version history, so a single `mcd.drawio` (kept current via commits, not filename suffixes) would be more maintainable going forward — worth a quick rename pass before the repo is portfolio-facing.

</details>

---

## 🟢 Phase 1 — Build

Design precedes implementation. No table is created before the business rule behind it is written down.

```mermaid
flowchart LR
    A[📋 Business\nRequirements] --> B[🧩 MCD]
    B --> C[⚙️ MLD]
    C --> D[🐘 PostgreSQL\nSchema]
    D --> E[🌱 Seed Data]
    E --> F[🖥️ Application]
```

**Conceptual model defines:** entities · attributes · identifiers · associations · cardinalities · N:N relationships · association properties · historization

**N:N → associative relation:**

```text
ROLE  N ───────< ROLE_PERMISSION >─────── N  PERMISSION
```

**Enforced at the database level:**

`PRIMARY KEY` · `FOREIGN KEY` · `NOT NULL` · `UNIQUE` · `CHECK`

**Deliverables:**

- [x] `docs/business-requirements.md`
- [x] `docs/mcd.md`
- [x] `docs/mld.md`
- [ ] `docs/normalization.md`
- [ ] `database/schema.sql`
- [ ] `database/seed.sql`

---

## 🔴 Phase 2 — Breach

The application layer is deliberately vulnerable. The target is our own lab, not third-party infrastructure — every exploit here runs against `localhost`.

### 01 · SQL Injection

```mermaid
sequenceDiagram
    actor A as Attacker
    participant App as Application
    participant DB as PostgreSQL

    A->>App: input = " OR 1=1 --"
    App->>App: query = "SELECT * FROM users WHERE name = '" + input + "'"
    Note over App: ⚠️ String concatenation, no parameterization
    App->>DB: Unexpected query executes
    DB-->>App: Full table returned
    App-->>A: Unauthorized data disclosure
```

Covered manually before any automation: **error-based · UNION-based · boolean-blind · time-blind**. `sqlmap` is used only as an independent validation pass afterward, never as the discovery method.

### 02 · Race Condition

```mermaid
sequenceDiagram
    participant Req_A as Request A
    participant Req_B as Request B
    participant DB as Database

    Req_A->>DB: SELECT balance
    Req_B->>DB: SELECT balance
    Note over Req_A,Req_B: 🏁 Both read the same pre-update state
    Req_A->>DB: CHECK balance >= amount ✅
    Req_B->>DB: CHECK balance >= amount ✅
    Req_A->>DB: UPDATE balance
    Req_B->>DB: UPDATE balance
    Note over DB: 💥 Double-spend — the race window
```

Connects application behavior directly to `transactions` · `MVCC` · `isolation levels` · `locking` · `concurrency`.

### 03 · Excessive Privileges

```mermaid
flowchart TB
    APP[Application] --> ACC[Over-Provisioned\nDB Account]
    ACC --> READ[Read]
    ACC --> WRITE[Write]
    ACC --> SENS[⚠️ Sensitive\nModification]

    style ACC fill:#7f1d1d,color:#fff
    style SENS fill:#ef4444,color:#fff
```

Demonstrates how a weak privilege boundary amplifies the blast radius of any single application compromise.

---

## 🔵 Phase 3 — Harden

Hardening is not a sentence in a report saying "fixed." The original exploit is re-run against the patched system, and the result is recorded as evidence.

```mermaid
flowchart LR
    A([Vulnerable]) --> B[Exploit]
    B --> C[Evidence]
    C --> D[Root Cause]
    D --> E[Remediation]
    E --> F[Repeat Attack]
    F --> G{Blocked?}
    G -->|Yes| H([✅ Proof])
    G -->|No| D

    style A fill:#7f1d1d,color:#fff
    style H fill:#14532d,color:#fff
```

<table>
<tr>
<th>Vulnerability</th>
<th>Root Cause</th>
<th>Fix</th>
</tr>
<tr>
<td><strong>SQL Injection</strong></td>
<td>User input concatenated into SQL text</td>
<td>

```python
query = "SELECT * FROM users WHERE name = %s"
cursor.execute(query, (username,))
```

Separates **data** from **instructions** — the actual fix, not the syntax.

</td>
</tr>
<tr>
<td><strong>Race Condition</strong></td>
<td>Unprotected check-then-act sequence</td>
<td>

```sql
BEGIN;
SELECT ... FOR UPDATE;
UPDATE ...;
COMMIT;
```

Row-level locking (or a stricter isolation level, depending on the state transition) closes the race window.

</td>
</tr>
<tr>
<td><strong>Excessive Privilege</strong></td>
<td>One account, all permissions</td>
<td>

```text
app_readonly  → read-only operations
app_write     → required DML only
app_admin     → restricted admin tasks
```

Each role receives only what its function requires.

</td>
</tr>
</table>

---

## 🧱 Defense in Depth

```mermaid
flowchart TB
    A[Application Controls] --> F[🛡️ Defense in Depth]
    B[Database Constraints] --> F
    C[Transactions] --> F
    D[Locks] --> F
    E[Roles / Privileges] --> F

    style F fill:#1e3a8a,color:#fff,stroke:#1e40af,stroke-width:2px
```

> **An application bug should never automatically become a valid database state.**

---

## 🔬 Performance Validation

Security controls are validated, not assumed — performance is measured, not guessed at.

```mermaid
flowchart LR
    M[📏 Measure] --> O[👁️ Observe] --> R[🧠 Reason] --> C[🔧 Change] --> M
```

`EXPLAIN ANALYZE` drives every indexing decision. Indexes are added when the query plan justifies them — not because the project happens to contain the word "database."

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| 🐘 Database | PostgreSQL |
| 🐍 Application | Python + Flask / minimal CLI |
| 🔌 Driver | psycopg / psycopg2 |
| 🐳 Infrastructure | Docker + Docker Compose |
| 🧭 DB Clients | `psql`, pgAdmin, DBeaver |
| 🎯 Security Testing | Manual testing, sqlmap |
| 🌐 HTTP Testing | Burp Suite Community |
| 📐 Modeling | Merise MCD / MLD |
| 🔀 Version Control | Git + GitHub |
| 📝 Documentation | Markdown + Mermaid |

---

## 🚀 Running the Lab

```mermaid
flowchart LR
    A[git clone] --> B[cp .env.example .env] --> C[docker compose up -d] --> D[docker compose ps] --> E[Connect via psql]
```

```bash
git clone <repository-url>
cd securecorp-db
cp .env.example .env
docker compose up -d
docker compose ps
```

Exact environment variables, ports, and startup sequence live in [`docs/business-requirements.md`](docs/business-requirements.md) and `.env.example`.

---

## 🎓 Learning Objectives

<table>
<tr><td width="25%" valign="top">

**🗄️ Database Engineering**

- Requirements analysis
- Merise MCD/MLD
- Relational design & keys
- Cardinalities, N:N
- Historization
- Normalization
- PostgreSQL DDL
- Integrity constraints

</td><td width="25%" valign="top">

**📊 SQL**

- `SELECT` / `JOIN`
- `GROUP BY`
- Subqueries
- `CASE`
- CTEs
- Window functions
- Transactions & locking
- `EXPLAIN ANALYZE`

</td><td width="25%" valign="top">

**🔓 Offensive Security**

- SQL injection (all 4 classes)
- Blind SQLi
- Race conditions
- Excessive DB privileges
- App/DB trust boundaries
- Integrity failures

</td><td width="25%" valign="top">

**🛡️ Defensive Engineering**

- Parameterized SQL
- Transactional protection
- Least privilege
- Constraints as controls
- Defense in depth
- Security regression testing

</td></tr>
</table>

---

## 🧭 Roadmap

```mermaid
flowchart TD
    m1[01 · Business Model] --> m2[02 · MCD / MLD]
    m2 --> m3[03 · PostgreSQL Live]
    m3 --> m4[04 · Seed Data]
    m4 --> m5[05 · Vulnerable App]
    m5 --> m6[06 · First Exploit]
    m6 --> m7[07 · Race Condition]
    m7 --> m8[08 · Privilege Escalation]
    m8 --> m9[09 · Hardening]
    m9 --> m10[10 · Retest]
    m10 --> m11[11 · Performance]
    m11 --> m12[12 · Final Report]

    style m1 fill:#166534,color:#fff
    style m2 fill:#166534,color:#fff
    style m3 fill:#166534,color:#fff
    style m4 fill:#78716c,color:#fff
    style m5 fill:#78716c,color:#fff
    style m6 fill:#78716c,color:#fff
    style m7 fill:#78716c,color:#fff
    style m8 fill:#78716c,color:#fff
    style m9 fill:#78716c,color:#fff
    style m10 fill:#78716c,color:#fff
    style m11 fill:#78716c,color:#fff
    style m12 fill:#78716c,color:#fff
```

> Green = complete based on current `docs/` contents. Update the styling as milestones close.

---

## ✅ Definition of Done

The project is complete when another engineer can, without asking a single question:

```text
clone → start → inspect → understand → exploit →
collect evidence → harden → retest → measure → verify
```

The finish line is **not** "the tables exist." It is **reproducibility + exploitation + remediation + verification.**

---

## 🔐 Final Principle

<div align="center">

```
DESIGN → IMPLEMENT → MEASURE → BREAK → UNDERSTAND → HARDEN → RETEST → PROVE
```

**The database is the system.**
**The attack is the experiment.**
**The fix is the engineering.**
**The retest is the proof.**

<br>

<sub>SecureCorp DB · Build → Breach → Harden</sub>

</div>

<!--
Optional dynamic badges — replace OWNER/REPO and uncomment:
![Last Commit](https://img.shields.io/github/last-commit/OWNER/REPO?style=flat-square)
![Repo Size](https://img.shields.io/github/repo-size/OWNER/REPO?style=flat-square)
![License](https://img.shields.io/github/license/OWNER/REPO?style=flat-square)
-->
