# SecureCorp DB — Build → Breach → Harden

> An engineering project that designs, attacks, and hardens a realistic enterprise security database.

## Overview

**SecureCorp DB** is a complete database engineering and security project built around a realistic internal security platform.

The project follows a three-phase lifecycle:

```text
┌─────────────────────┐
│  PHASE 1            │
│  BUILD              │
│                     │
│  Business Model     │
│       ↓             │
│  MCD                │
│       ↓             │
│  MLD                │
│       ↓             │
│  PostgreSQL         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  PHASE 2            │
│  BREACH              │
│                     │
│  SQL Injection      │
│  Race Conditions    │
│  Privilege Escal.   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  PHASE 3            │
│  HARDEN & PROVE     │
│                     │
│  Parameterization   │
│  Transactions       │
│  Least Privilege    │
│  Constraints        │
│  Performance        │
│       ↓             │
│  Retest             │
└─────────────────────┘
```

The goal is not simply to build a database or exploit a vulnerable application.

The goal is to understand the complete engineering lifecycle:

**design → implementation → vulnerability → exploitation → remediation → verification**

Every vulnerability introduced during the project is intentional, documented, and understood.

---

## Project Objective

The primary objective is to build a realistic PostgreSQL-based security platform and use it as a controlled laboratory for learning both database engineering and cybersecurity.

The project combines:

* Database modeling
* Merise MCD/MLD
* Relational database design
* PostgreSQL
* SQL
* Database constraints
* Normalization
* Transactions and concurrency
* Database security
* SQL Injection
* Privilege management
* Performance analysis
* Python
* Docker
* Git/GitHub
* Security testing
* Technical documentation

The final result should be a reproducible security laboratory and a professional-style technical report.

---

# The System

SecureCorp represents an internal security operations platform.

The database manages information such as:

* Users
* Roles
* Permissions
* Assets
* Vulnerabilities
* Incidents
* Audit logs

These objects form the foundation of the relational model.

The database will later be connected to a small Python application layer. The application will intentionally contain vulnerable implementations during Phase 2 so that the security weaknesses can be demonstrated and exploited in a controlled environment.

---

# Why This Project Exists

This project is designed to solve a common problem in technical learning:

> Knowing individual concepts without understanding how they interact inside a real system.

Instead of studying SQL, database modeling, transactions, and security as isolated subjects, this project connects them into one system.

For example:

```text
Business requirement
        ↓
MCD
        ↓
MLD
        ↓
PostgreSQL schema
        ↓
Application
        ↓
SQL queries
        ↓
Security weakness
        ↓
Exploitation
        ↓
Fix
        ↓
Retest
```

This makes every technical decision traceable.

A database table should exist because of a business requirement.

A constraint should exist because of a data-integrity rule.

A vulnerability should exist because of a specific implementation decision.

A remediation should address the actual root cause.

A security fix should be verified by repeating the original attack.

---

# Phase 1 — Design & Build

## Objective

Build a correctly modeled, constrained PostgreSQL database representing the SecureCorp security platform.

### 1. Business Requirements

Define the system in business terms.

The requirements describe what SecureCorp needs to manage and what relationships exist between its objects.

Main domains:

```text
Users
Roles
Permissions
Assets
Vulnerabilities
Incidents
Audit Logs
```

Deliverable:

```text
docs/business-requirements.md
```

---

## 2. MCD — Conceptual Data Model

Transform the business requirements into a conceptual model using Merise.

The MCD will define:

* Entities
* Attributes
* Identifiers
* Associations
* Cardinalities
* N:N relationships
* Relationship properties
* Historization

The model must include:

### N:N relationship with properties

A role can have multiple permissions, and a permission can belong to multiple roles.

```text
ROLE
  │
  │ N:N
  │
PERMISSION
```

The association will have its own properties.

### Historization

The system must preserve information about actions performed over time through the audit-log mechanism.

Deliverables:

```text
docs/mcd.md
diagrams/mcd.png
```

---

## 3. MLD → PostgreSQL

Transform the MCD into a relational model and then into PostgreSQL `CREATE TABLE` statements.

The schema will use:

* Primary keys
* Foreign keys
* NOT NULL
* UNIQUE
* CHECK constraints

Deliverable:

```text
database/schema.sql
```

The objective is not merely to create tables.

The database itself should enforce as many business rules and integrity rules as reasonably possible.

---

## 4. Normalization

The schema will later be analyzed and normalized to Third Normal Form.

Any deliberate denormalization must be documented and justified.

This step is intentionally performed after the corresponding database-design coursework rather than pretending normalization is something you acquire through divine database inspiration.

Deliverable:

```text
docs/normalization.md
```

---

## 5. Seed Data

The database will eventually contain realistic but entirely fake data.

Target:

```text
50–200 rows per table
```

The data should represent realistic distributions rather than perfectly uniform test values.

Deliverable:

```text
database/seed.sql
```

No real personal data will be used.

---

## 6. Docker Environment

The project will provide a reproducible PostgreSQL environment using Docker Compose.

The objective is:

```bash
docker compose up
```

to create the database environment automatically.

The environment will include:

```text
Docker Compose
      ↓
PostgreSQL
      ↓
Persistent volume
      ↓
Schema initialization
      ↓
Seed data
```

Deliverable:

```text
docker-compose.yml
```

---

# Phase 2 — Breach

## Objective

Attack the system we built.

The vulnerabilities are intentionally introduced into a small Python application layer.

The purpose is not to attack third-party systems.

The purpose is to understand exactly how insecure database/application interactions become exploitable.

---

## SQL Injection

The vulnerable application will initially use deliberately unsafe string-concatenated SQL queries.

Examples of functionality include:

* Login
* Incident search
* Asset lookup

The project will demonstrate:

* Error-based SQL injection
* UNION-based SQL injection
* Boolean-based blind SQL injection
* Time-based blind SQL injection

Manual exploitation will be performed first.

`sqlmap` may then be used as an independent validation tool.

---

## Race Condition

A deliberately vulnerable check-then-act workflow will be created.

Conceptually:

```text
SELECT balance
      ↓
check balance
      ↓
UPDATE balance
```

Multiple concurrent requests will attempt to exploit the time window between the check and the update.

A Python concurrency script will be used to demonstrate the problem.

This section is particularly important because it connects:

```text
Transactions
Isolation
MVCC
Concurrency
Application logic
Database locking
```

---

## Privilege Escalation

The project will deliberately configure an over-permissioned database application account.

The objective is to demonstrate how excessive database privileges can turn application compromise into broader database access.

For example, an application account that should not modify audit logs may nevertheless be granted enough permissions to do so.

---

## Attack Documentation

Every vulnerability will be documented with:

* Scope
* Preconditions
* Reproduction steps
* Technical explanation
* Evidence
* Impact
* Remediation

The objective is to produce evidence that another engineer can reproduce.

---

# Phase 3 — Harden & Prove

## Objective

Fix the vulnerabilities and prove that the fixes work.

This phase is deliberately different from simply saying:

> "The vulnerability is fixed."

The project will repeat the same attacks against the hardened system.

```text
Vulnerable
    ↓
Exploit
    ↓
Evidence
    ↓
Root cause
    ↓
Remediation
    ↓
Same exploit
    ↓
Blocked
    ↓
Evidence
```

---

## SQL Injection Remediation

Replace unsafe string concatenation with parameterized SQL statements.

Conceptually:

```text
User input
    ↓
Parameterized query
    ↓
Database
```

instead of:

```text
User input
    ↓
String concatenation
    ↓
SQL parser
```

The original exploit will then be repeated to verify that the attack no longer works.

---

## Race Condition Remediation

The vulnerable check-then-act operation will be redesigned using appropriate transactional protection.

Possible mechanisms include:

* Transactions
* `SELECT ... FOR UPDATE`
* Appropriate isolation levels

The same concurrency script will be executed again.

Expected result:

```text
Before:
20 concurrent requests
       ↓
Multiple successful redemptions

After:
20 concurrent requests
       ↓
Database synchronization
       ↓
Only valid redemption
```

---

## Least Privilege

Database roles will be redesigned around the minimum permissions required by each application component.

Example:

```text
app_readonly
app_write
app_admin
```

The application will use the least-privileged account appropriate for its operation.

---

## Defense in Depth

Database constraints will be strengthened where necessary.

Examples:

```text
NOT NULL
CHECK
UNIQUE
FOREIGN KEY
```

The principle is:

> Even if the application contains a bug, the database should still prevent invalid states whenever possible.

---

# Performance Validation

Security changes should not automatically become an excuse to ignore performance.

Key queries will be analyzed using:

```sql
EXPLAIN ANALYZE
```

The project will compare relevant queries before and after hardening.

If necessary, indexes will be introduced based on evidence rather than guesswork.

---

# Technology Stack

## Database

* PostgreSQL

## Application

* Python
* Flask or a minimal CLI
* psycopg2 or psycopg3

## Infrastructure

* Docker
* Docker Compose

## Security Testing

* Manual SQL injection testing
* sqlmap
* Burp Suite Community when HTTP endpoints are used

## Database Tools

* `psql`
* pgAdmin or DBeaver

## Development

* Git
* GitHub
* Markdown

All primary project tools are free/open-source.

---

# Repository Structure

```text
securecorp-db/
│
├── README.md
├── docker-compose.yml
├── .env.example
├── .gitignore
│
├── docs/
│   ├── business-requirements.md
│   ├── mcd.md
│   ├── mld.md
│   ├── decisions.md
│   └── normalization.md
│
├── database/
│   ├── schema.sql
│   └── seed.sql
│
├── diagrams/
│   ├── mcd.png
│   └── mld.png
│
├── app/
│
├── exploits/
│
└── report/
```

The repository will evolve as the project progresses.

---

# Learning Objectives

This project is designed to develop several levels of engineering ability.

## Database Engineering

Understand how to:

* Translate business requirements into data models
* Build MCDs
* Transform MCD → MLD
* Design relational schemas
* Select appropriate keys
* Model cardinalities
* Handle N:N relationships
* Model historical information
* Normalize relational data
* Enforce integrity through constraints
* Write PostgreSQL DDL
* Generate realistic data
* Analyze query performance

## SQL

Develop practical ability with:

* SELECT
* JOIN
* GROUP BY
* Subqueries
* CASE
* CTEs
* Window functions
* Transactions
* Locking
* `EXPLAIN ANALYZE`

## Cybersecurity

Understand database/application vulnerabilities through direct experimentation:

* SQL Injection
* Blind SQL Injection
* Race Conditions
* Privilege Escalation
* Excessive database privileges
* Weak integrity enforcement

## Defensive Security

Learn how to:

* Parameterize SQL queries
* Design secure transactions
* Control concurrency
* Apply least privilege
* Use database constraints as defense in depth
* Verify remediation through retesting

## Engineering Practice

Develop:

* Git workflow
* Repository organization
* Docker-based reproducibility
* Technical documentation
* Security evidence collection
* Reproducible testing
* Professional reporting

---

# Project Philosophy

The central philosophy of SecureCorp DB is:

> **Build it. Break it. Understand why it broke. Fix it. Prove that it is fixed.**

The project therefore treats security as part of engineering rather than something added at the end.

A secure system requires more than secure code.

It requires:

```text
Correct requirements
        +
Correct data model
        +
Correct relational design
        +
Correct constraints
        +
Correct application logic
        +
Correct database permissions
        +
Correct transaction handling
        +
Testing
        +
Evidence
```

---

# Project Milestones

### M1 — Schema Live

Docker Compose starts the PostgreSQL environment and initializes the database.

### M2 — First Successful Exploit

A SQL injection vulnerability is manually exploited against the intentionally vulnerable application.

### M3 — Race Condition Proven

Concurrent requests demonstrate the vulnerable check-then-act behavior.

### M4 — Full Attack Chain

SQL injection, race condition, and privilege escalation are documented.

### M5 — Hardened Version Passes

The same attacks are executed again and demonstrated to fail after remediation.

### M6 — Report & Repository Published

The final report, documentation, architecture, and reproducible environment are published.

---

# Current Status

## Completed

* Bloc A — Database fundamentals
* Bloc B — Merise and relational modeling
* Initial Git repository structure
* GitHub repository initialization

## In Progress

* Business requirements
* MCD
* MLD
* PostgreSQL schema
* Docker Compose environment

## Planned

* SQL seed data
* Normalization
* Vulnerable application
* SQL injection laboratory
* Race-condition laboratory
* Privilege escalation laboratory
* Database hardening
* Performance validation
* Final security report
* Repository publication

---

# Expected Final Result

At completion, this repository should provide a reproducible security engineering laboratory where another person can clone the project, start the environment, understand the architecture, reproduce the vulnerabilities, examine the remediation, and verify the final hardened state.

The final deliverable is therefore not just:

```text
a database
```

It is:

```text
Database Engineering
        +
Application Security
        +
Offensive Testing
        +
Defensive Engineering
        +
Performance Analysis
        +
Professional Documentation
```

The project directly exercises the database concepts covered throughout the corresponding Domaine 3 blocks, including modeling, SQL, normalization, transactions, PostgreSQL internals, and database security.
