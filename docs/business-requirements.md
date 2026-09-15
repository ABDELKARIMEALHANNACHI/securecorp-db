# Project Sentinel — Business Requirements Document

**SecureCorp Solutions Inc. — Information Security Division**
**Classification: CONFIDENTIAL — INTERNAL USE ONLY**

| | |
|---|---|
| **Document Owner** | Priya Nair, Lead Business Analyst, Security Engineering |
| **Executive Sponsor** | Rebecca Hsu, Chief Information Security Officer (CISO) |
| **Business Owner** | Daniel Okoye, Director of Security Operations |
| **Status** | Approved for Design (v1.0) |
| **Version** | 1.0 |
| **Date Issued** | September 11, 2026 |
| **Related Deliverables** | Feeds directly into MCD / MLD conceptual and logical data modeling and the PostgreSQL schema design for Project Sentinel. |

> **Purpose of this document.** This Business Requirements Document (BRD) captures the functional and non-functional requirements for Project Sentinel as elicited directly from SecureCorp's Information Security leadership during the discovery session of September 8, 2026 (see Section 4). It represents the agreed business scope prior to any conceptual (MCD) or logical (MLD) data modeling, and prior to any PostgreSQL schema or application development work. No technical design decisions are finalized in this document — it defines *what* the business needs; *how* it will be built is addressed in the subsequent Data Modeling and Technical Design deliverables.

---

## Table of Contents

1. [Document Control](#1-document-control)
2. [Executive Summary](#2-executive-summary)
3. [Business Context](#3-business-context)
4. [Discovery Session Overview](#4-discovery-session-overview)
5. [Stakeholders](#5-stakeholders)
6. [Objectives & Success Criteria](#6-objectives--success-criteria)
7. [Scope](#7-scope)
8. [Functional Requirements](#8-functional-requirements)
9. [Business Rules](#9-business-rules)
10. [Non-Functional Requirements](#10-non-functional-requirements)
11. [Assumptions & Constraints](#11-assumptions--constraints)
12. [Data Sensitivity & Compliance Considerations](#12-data-sensitivity--compliance-considerations)
13. [Glossary of Terms](#13-glossary-of-terms)
14. [Appendix A — Open Questions & Risks](#14-appendix-a--open-questions--risks)
15. [Approval & Sign-off](#15-approval--sign-off)

---

## 1. Document Control

### 1.1 Revision History

| Version | Date | Author | Description |
|---|---|---|---|
| 0.1 (Draft) | 2026-09-08 | P. Nair | Initial draft compiled immediately following the requirements discovery session with the Executive Sponsor. |
| 0.2 (Draft) | 2026-09-10 | P. Nair | Incorporated review comments from the CISO and Director of Security Operations; added SLA and risk-acceptance rules. |
| 1.0 (Approved) | 2026-09-11 | P. Nair | Approved for design. Baseline for MCD / MLD and PostgreSQL schema work. |

### 1.2 Distribution List

- Rebecca Hsu — Chief Information Security Officer (Executive Sponsor)
- Daniel Okoye — Director of Security Operations (Business Owner)
- Ana Kowalski — Compliance & Internal Audit Liaison
- Security Engineering Team (Development Squad)
- Project archive — repository `/docs/requirements/`

### 1.3 Document Conventions

Requirements are numbered by domain (e.g., **FR-VUL-03** for the third functional requirement in the Vulnerability Management domain). Each requirement is prioritized using the MoSCoW method: **Must** (mandatory for Phase 1 / MVP), **Should** (important but not release-blocking), **Could** (desirable if time permits). The word "System" refers to the Project Sentinel platform being specified; the word "Business" refers to SecureCorp Solutions Inc.

---

## 2. Executive Summary

SecureCorp Solutions Inc. currently manages its internal security posture — IT asset inventory, known vulnerabilities, security incidents, and the access history behind all of it — across a patchwork of spreadsheets, chat threads, and personal notes. This has been flagged as an exception in the most recent SOC 2 Type II audit and creates real operational risk: ownership of critical assets is unclear, vulnerability remediation is not consistently tracked against a service-level target, and there is no reliable, tamper-evident record of who changed what, when.

The Information Security Division has commissioned an internal engineering squad to design and deliver **Project Sentinel**: a single, authoritative database and lightweight internal application for tracking users and access, IT assets, vulnerabilities, security incidents, and an immutable audit trail of all of the above. This document records the business requirements gathered directly from the Executive Sponsor and Business Owner during the discovery session described in Section 4, and is the baseline from which the data model (MCD/MLD) and PostgreSQL implementation will be derived.

Phase 1 targets a working pilot within one quarter, built by a small internal team on an open-source stack, without requiring changes to existing HR or ticketing systems. Directory integration (SSO/Active Directory), automated vulnerability-scanner ingestion, and any customer-facing component are explicitly deferred to a later phase (Section 7.2).

---

## 3. Business Context

### 3.1 Company Background

SecureCorp Solutions Inc. is a mid-market business-payments technology provider (≈ 600 employees) headquartered in Denver, Colorado, with an engineering office in Lisbon, Portugal. The company processes commercial invoicing and payment workflows on behalf of small and mid-sized business clients, which places it in scope for annual SOC 2 Type II attestation and, for a subset of its payment-adjacent infrastructure, PCI-DSS obligations. The Information Security Division reports to the CISO and is organizationally distinct from the Product Engineering organization that builds SecureCorp's customer-facing product.

### 3.2 Problem Statement

The Division's Q3 2026 SOC 2 Type II audit identified a formal exception: the Business could not produce, on request, a complete and current inventory of in-scope IT assets with assigned owners, nor a reliable history of who had modified vulnerability or access records over the audit period. The underlying cause is organizational, not technical — the relevant data exists, but it is scattered across spreadsheets maintained by individual analysts, none of which is access-controlled, versioned, or backed by an audit trail. A recent case where an analyst left the company while holding the only up-to-date copy of the vulnerability tracker underscored the risk of continuing this way.

### 3.3 Strategic Drivers

- **SOC 2 Type II renewal** — remediation of the current-cycle exception is required before the Q1 2027 audit window.
- **Investor due diligence** — an upcoming financing round's security review is expected to request evidence of a formal vulnerability management program.
- **Cyber-insurance renewal** — the Business's insurer has begun asking applicants to demonstrate an active vulnerability and incident tracking process, not just a policy document.
- **Operational risk reduction** — leadership wants a measurable reduction in mean time to remediate (MTTR) for critical vulnerabilities and a faster, auditable incident response process.

---

## 4. Discovery Session Overview

The requirements in this document were gathered in a single structured discovery session between the Business Analysis team and the Business's security leadership. This section summarizes that session for traceability; every functional requirement in Section 8 references the stakeholder who raised it.

### 4.1 Session Details & Attendees

| Name | Title | Role in Session |
|---|---|---|
| Rebecca Hsu | Chief Information Security Officer | Executive Sponsor |
| Daniel Okoye | Director of Security Operations | Business Owner |
| Ana Kowalski | Compliance & Internal Audit Liaison | Subject-matter input (joined final segment) |
| Priya Nair | Lead Business Analyst | Facilitator / minute-taker |
| Tomás Ferreira | Database Architect | Technical listener |
| Sam Whitlock | Backend Engineer | Technical listener |

**Date/Time:** Tuesday, September 8, 2026, 10:00–11:30 MT
**Location:** Conference Room "Everest", Denver HQ (hybrid, Lisbon team via video)

### 4.2 Discussion Notes

**Opening — current state and pain points.** R. Hsu opened by framing the discovery session around the SOC 2 exception (Section 3.2), stating plainly that the audit finding was the forcing function for prioritizing this project this quarter. D. Okoye added that the vulnerability tracker had, until recently, lived in a spreadsheet maintained by a single analyst, and that the team had no good answer when asked how long a given critical finding had been open.

**Identity, roles and access.** R. Hsu was firm that access should be built around least-privilege from day one: "I don't want a system where everyone is an admin because it was easier to build that way." She asked that roles map to real job functions (SOC Analyst, Vulnerability Manager, Asset Owner, Compliance Auditor, Platform Administrator), that permissions be assignable to a role without a code change, and that the system record who granted a given permission and when — to support a recurring access review. D. Okoye asked that access be automatically revoked the moment an employee's status changes to terminated.

**Asset inventory.** D. Okoye described the intended inventory scope as broad but bounded: servers, workstations and laptops, network devices, cloud resources, and approved third-party SaaS applications — explicitly *not* a customer-data inventory. He asked that every asset have exactly one accountable owner and a lifecycle status, and that decommissioned assets be retained (not deleted) for historical traceability, since deleting an asset that still had open findings against it would corrupt the audit history.

**Vulnerability management.** This was the most detailed portion of the discussion. R. Hsu asked for CVSS-based severity scoring, a defined remediation SLA by severity (the team agreed on Critical: 15 days, High: 30 days, Medium: 90 days, Low: best-effort), and automatic flagging of anything past its SLA. She was equally insistent on a formal **risk acceptance** path for findings the Business chooses not to fix immediately: "If we're going to accept a risk, I want a name attached to that decision and a date we're forced to look at it again — not a finding that just quietly disappears."

**Incident management.** D. Okoye asked that every incident be traceable back to the assets involved and, where relevant, the specific vulnerability that was exploited, so the team can answer "did we know about this already?" during a post-incident review. He asked that only an Incident Commander or Platform Administrator be able to formally close an incident.

**Audit & compliance.** A. Kowalski joined for this segment and was direct about the core requirement: an audit trail that is genuinely tamper-evident, not merely a "last modified by" column that an administrator could edit. She asked for a minimum of twelve months of readily queryable history, a longer archive in line with SecureCorp's records retention schedule, and an export format she could hand directly to an external auditor without reformatting it.

**Scope and pragmatism.** Closing the session, R. Hsu was explicit that she did not want the team to "boil the ocean": single sign-on integration, ingesting findings automatically from a vulnerability scanner, and any replacement of the existing ticketing tool are all real needs, but not this quarter's needs. She asked for a focused pilot, built on the Business's already-approved open-source database standard, using only synthetic data until the pilot is reviewed and approved for production rollout.

---

## 5. Stakeholders

| Name | Role | Interest |
|---|---|---|
| Rebecca Hsu | Executive Sponsor (CISO) | Accountable for closing the SOC 2 exception; final approver of scope and priority. |
| Daniel Okoye | Business Owner | Owns day-to-day security operations; primary source of functional requirements and acceptance criteria. |
| Ana Kowalski | Compliance & Internal Audit Liaison | Represents external-audit evidence requirements; owner of retention and export requirements. |
| SOC Analysts & Vuln. Mgmt. Analysts | End Users | Daily users of the incident and vulnerability workflows. |
| IT Asset Owners | End Users | Accountable for the accuracy of their assigned assets. |
| Security Engineering Team | Delivery Team | Designs and builds the data model and application; translates this BRD into MCD / MLD / schema. |

---

## 6. Objectives & Success Criteria

| # | Business Objective | Success Criterion (KPI) |
|---|---|---|
| O1 | Establish a single source of truth for the internal IT asset inventory. | 100% of in-scope assets have an assigned, active owner and a current lifecycle status. |
| O2 | Track vulnerabilities against a defined remediation SLA. | ≥ 95% of Critical and High findings are remediated or formally risk-accepted within SLA. |
| O3 | Reduce mean time to remediate (MTTR) for critical vulnerabilities. | MTTR for Critical findings trends downward quarter-over-quarter, tracked from pilot launch. |
| O4 | Produce audit evidence on demand. | An auditor's request for "who changed record X, and when" is answerable same-day, down from ≈ 3 business days today. |
| O5 | Enforce least-privilege access to security data. | Zero users hold a role granting permissions beyond their documented job function after the first access review. |
| O6 | Give leadership a reliable risk picture. | A monthly report of open critical vulnerabilities and MTTR is available without manual data collection. |

---

## 7. Scope

### 7.1 In Scope — Phase 1 (MVP)

- A normalized relational data model covering users, roles/permissions, assets, vulnerabilities, incidents, and audit logs.
- A minimal internal application layer (CLI or lightweight web tool) allowing the security team to record and query the above.
- Role-based access control enforced for all in-scope entities.
- An immutable, exportable audit trail of all create/update/delete actions.
- Basic reporting sufficient for a monthly leadership summary (Section 8.6).
- A one-command, reproducible local/lab environment for development and demonstration purposes.

### 7.2 Out of Scope — Deferred to a Later Phase

- Single sign-on / Active Directory integration for user authentication.
- Automated ingestion of findings from third-party vulnerability scanners (e.g., via API feed).
- Integration with, or replacement of, the existing external ticketing tool.
- Any customer-facing portal or mobile application.
- Formal production SLA / high-availability hosting (Phase 1 is a reviewed pilot, not a production system).
- Storage of customer payment data, cardholder data, or any customer PII — explicitly excluded from this platform's data scope.

---

## 8. Functional Requirements

Requirements below use "shall" to denote a binding requirement. Priority follows MoSCoW (Section 1.3). "Source" cites the stakeholder or discussion topic from Section 4.2 for traceability.

### 8.1 Identity, Users & Roles

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-USR-01 | The System shall maintain a record for each internal user, including full name, corporate email, department, employment status, and start date. | Must | D. Okoye |
| FR-USR-02 | The System shall support assigning one or more roles to each user (e.g., SOC Analyst, Vulnerability Manager, Asset Owner, Compliance Auditor, Platform Administrator). | Must | R. Hsu |
| FR-USR-03 | Each role shall be composed of a defined, editable set of permissions (e.g., view_asset, edit_vulnerability, close_incident, export_audit_log) without requiring a code change. | Must | R. Hsu |
| FR-USR-04 | The System shall record, for every role-permission assignment, who granted it and on what date, to support periodic least-privilege review. | Must | R. Hsu |
| FR-USR-05 | When a user's employment status changes to terminated, the System shall automatically revoke all active role assignments. | Must | D. Okoye |
| FR-USR-06 | The System shall support a periodic access-recertification workflow in which each user's role assignments are reviewed and re-approved. | Should | Compliance |

### 8.2 Asset Management

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-AST-01 | The System shall maintain an inventory of in-scope IT assets: servers, workstations/laptops, network devices, cloud resources, and approved third-party SaaS applications. | Must | D. Okoye |
| FR-AST-02 | Each asset record shall include a unique identifier, asset type, name, environment (production/staging/development), and exactly one assigned owner. | Must | D. Okoye |
| FR-AST-03 | The System shall track an asset's lifecycle status (e.g., active, in maintenance, decommissioned). | Must | D. Okoye |
| FR-AST-04 | The System shall allow assets to be tagged (e.g., by business unit or compliance scope such as "PCI" or "SOC2") to support scoped reporting. | Should | D. Okoye |
| FR-AST-05 | The System shall prevent hard deletion of an asset with associated vulnerabilities or incidents; such assets may only be marked decommissioned. | Must | D. Okoye |

### 8.3 Vulnerability Management

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-VUL-01 | The System shall record each vulnerability finding against one or more affected assets, including description, CVSS base score, severity, discovery date, and discovery source. | Must | R. Hsu |
| FR-VUL-02 | The System shall track vulnerability status through a defined lifecycle: Open → In Remediation → Remediated → Verified Closed, or Open → Risk Accepted. | Must | R. Hsu |
| FR-VUL-03 | The System shall enforce a remediation SLA by severity (Critical: 15 days, High: 30 days, Medium: 90 days, Low: best-effort) and flag findings that exceed it. | Must | R. Hsu |
| FR-VUL-04 | Marking a finding "Risk Accepted" shall require a documented justification, an accepting authority, and a mandatory review/expiration date. | Must | R. Hsu |
| FR-VUL-05 | The System shall not permit a finding to be marked "Verified Closed" without a linked remediation note and the identity of the verifier. | Must | R. Hsu |
| FR-VUL-06 | The System shall support linking one vulnerability finding to multiple affected assets without duplicating the underlying finding data. | Should | D. Okoye |

### 8.4 Incident Management

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-INC-01 | The System shall allow creation of a security incident record capturing detection time, reporting source, severity, and a narrative description. | Must | D. Okoye |
| FR-INC-02 | Each incident shall be linkable to one or more affected assets and, where applicable, the vulnerability or vulnerabilities exploited. | Must | D. Okoye |
| FR-INC-03 | The System shall track incident status (New, Investigating, Contained, Resolved, Closed) and timestamp each status transition. | Must | D. Okoye |
| FR-INC-04 | The System shall calculate time-to-detect and time-to-resolve for each incident. | Should | D. Okoye |
| FR-INC-05 | Only a user holding the Incident Commander or Platform Administrator role shall be permitted to close an incident. | Must | R. Hsu |

### 8.5 Audit & Compliance Logging

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-AUD-01 | The System shall automatically record an audit entry for every create, update, or delete action on user, role, asset, vulnerability, or incident records, capturing the acting user, timestamp, action type, and before/after values. | Must | A. Kowalski |
| FR-AUD-02 | Audit log entries shall not be editable or deletable by any application user, including Platform Administrators. | Must | A. Kowalski |
| FR-AUD-03 | The System shall retain audit log entries online for a minimum of twelve months, with longer archival per the Business's records retention policy. | Must | A. Kowalski |
| FR-AUD-04 | The System shall support exporting a filtered audit trail (by user, date range, or record) in a format suitable for delivery to an external auditor. | Must | A. Kowalski |

### 8.6 Reporting & Dashboards

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-RPT-01 | The System shall provide a summary of open vulnerabilities by severity and SLA status, suitable for a monthly leadership report. | Should | R. Hsu |
| FR-RPT-02 | The System shall report mean-time-to-remediate by severity over a selectable date range. | Should | R. Hsu |
| FR-RPT-03 | The System shall list assets with no assigned owner, or whose owner is no longer an active employee. | Could | D. Okoye |

---

## 9. Business Rules

| ID | Rule |
|---|---|
| BR-01 | Every asset must have exactly one accountable owner at all times; ownership may be reassigned but never left blank. |
| BR-02 | A vulnerability finding cannot move to "Verified Closed" without linked remediation evidence (FR-VUL-05). |
| BR-03 | A "Risk Accepted" finding must carry a review/expiration date; on expiration it reverts to "Open" pending re-assessment. |
| BR-04 | An incident must reference at least one affected asset before it can leave "New" status. |
| BR-05 | No record in the audit log may be altered or removed by any role, under any circumstance, through the application layer. |
| BR-06 | A terminated user's role assignments are revoked automatically and immediately; no grace period. |

---

## 10. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Security | Role-based access shall be enforced at the data layer, not only in the application layer; secrets and credentials shall never be stored in plaintext. |
| Performance | Common queries (asset lookup, open-vulnerability list) shall return in under 2 seconds at a target scale of ≈ 5,000 assets and ≈ 50,000 historical vulnerability records. |
| Availability | Business-hours availability is sufficient for the Phase 1 pilot; a formal uptime SLA is deferred to a production-hardening phase. |
| Compliance | The design shall support SOC 2 Type II evidence requirements as advised by the Compliance liaison (Section 4.2). |
| Data minimization | The platform shall not ingest customer PII or cardholder data; scope is limited to internal corporate infrastructure and personnel records. |
| Maintainability | All schema changes shall be scripted and version-controlled (migrations), never applied ad hoc against a live database. |

---

## 11. Assumptions & Constraints

### 11.1 Assumptions

- The existing HR system remains the system of record for employee identity; Phase 1 maintains a lightweight local user table, with directory integration deferred (Section 7.2).
- Stakeholders will be available for a two-week user-acceptance testing (UAT) window prior to pilot sign-off.
- PostgreSQL is confirmed as the Business's approved open-source database standard.

### 11.2 Constraints

- Delivery target of one quarter, staffed by a small internal team (2–3 engineers).
- No incremental Phase 1 budget for commercial software licenses.
- No real employee or customer data may be used in any non-production environment; seed/synthetic data only.

---

## 12. Data Sensitivity & Compliance Considerations

| Data Category | Classification | Notes |
|---|---|---|
| User / employee directory data | Internal | Limited to fields needed for access administration; no HR-sensitive data (compensation, performance reviews, etc.). |
| Asset inventory | Internal / Confidential | Production asset details are Confidential; non-production inventory is Internal. |
| Vulnerability findings | Confidential | Pre-remediation details are sensitive; access restricted to relevant roles (FR-USR-02). |
| Incident records | Confidential | Escalation follows the existing Incident Response Policy; not superseded by this BRD. |
| Audit logs | Confidential — Restricted | Tamper-evident and read-only by design (FR-AUD-01 – FR-AUD-04). |

---

## 13. Glossary of Terms

| Term | Definition |
|---|---|
| Asset | Any IT resource in scope for security tracking: server, workstation, network device, cloud resource, or approved SaaS application. |
| CVSS | Common Vulnerability Scoring System — an industry-standard method for rating vulnerability severity. |
| MoSCoW | A prioritization method: Must have, Should have, Could have, Won't have (this phase). |
| MTTR | Mean Time to Remediate — the average time between a finding's discovery and its resolution. |
| MVP | Minimum Viable Product — the smallest release that delivers real business value (Phase 1 here). |
| RBAC | Role-Based Access Control — granting permissions via roles rather than directly to individual users. |
| Risk Acceptance | A formal, time-bound decision to knowingly leave a finding unremediated, with a named accepting authority. |
| SLA | Service-Level Agreement / target — here, the maximum time allowed to remediate a finding of a given severity. |
| SOC 2 Type II | An independent audit attesting that a company's security controls operate effectively over a period of time. |
| Tamper-evident | Designed so that any unauthorized alteration is detectable, even if not physically preventable. |

---

## 14. Appendix A — Open Questions & Risks

| # | Item | Owner | Status |
|---|---|---|---|
| Q1 | Will Phase 2 replace the existing ticketing tool for incidents, or integrate alongside it? | D. Okoye | Open — due before Phase 2 kickoff |
| Q2 | Should contractor accounts follow the same termination-triggered revocation as employees (FR-USR-05)? | D. Okoye | Open |
| R1 | The one-quarter timeline may require descoping any stretch item beyond Section 7.1 if UAT feedback expands scope. | P. Nair | Monitoring |

---

## 15. Approval & Sign-off

By signing below, the undersigned confirm that this document accurately reflects the business requirements discussed and agreed for Project Sentinel Phase 1, and authorize the Security Engineering team to proceed to conceptual and logical data modeling (MCD/MLD) on this basis.

| Name | Title | Signature | Date |
|---|---|---|---|
| Rebecca Hsu | Chief Information Security Officer (Executive Sponsor) | | |
| Daniel Okoye | Director of Security Operations (Business Owner) | | |
| Priya Nair | Lead Business Analyst | | |

---
*SecureCorp Solutions Inc. — Confidential — Not for external distribution*
