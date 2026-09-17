# MLD — Security Operations / GRC Data Model

Logical data model derived from `mcd.md` / `MCD_SecOps_completed.drawio`. SQL syntax assumes **PostgreSQL** (`SERIAL`, `BOOLEAN`, `JSONB`) — swap `SERIAL` for `AUTO_INCREMENT` and `JSONB` for `JSON`/`TEXT` if you're targeting MySQL or SQL Server.

---

## 1. MCD → MLD transformation rules applied

1. **Every entity → a table**, its identifier → primary key.
2. **Hierarchical relationship (parent `(0,N)`/`(1,N)` ↔ child `(1,1)`)**: the foreign key is placed on the child (the side with max cardinality 1), referencing the parent's PK. This covers every relationship in this model except the pure many-to-many junctions below — e.g. `ROLE (1,N) — ROLE_ASSIGNMENT (1,1)` becomes `ROLE_ASSIGNMENT.role_id → ROLE.role_id`.
3. **Association entities that already carry their own attributes** (`ROLE_ASSIGNMENT`, `VULNERABILITY_ASSET`, `INCIDENT_ASSET`, `INCIDENT_VULNERABILITY`) keep their own surrogate PK *and* get FK columns to both parents.
4. **Pure many-to-many junctions with no attributes of their own** (`ROLE_PERMISSION`, `ASSET_TAG`) don't need a surrogate key — their PK becomes the composite of the two FKs.
5. **Placeholders left unresolved at the MCD stage were finished here** — see §5.

---

## 2. Referential integrity policy

Applied consistently across every FK, so the rule set is small enough to remember instead of re-deciding per table:

| Situation | Rule | Why |
|---|---|---|
| Any FK pointing to `USER` | `ON DELETE RESTRICT` | Every link to a user is either an identity relationship or an accountability trail (who granted, approved, verified, reviewed, acted). None of that may silently disappear. Offboarding = set `employment_status`, never delete the row. |
| Pure M:N junction, no independent meaning (`ROLE_PERMISSION`, `ASSET_TAG`) | `ON DELETE CASCADE` on both FKs | The link has no life of its own outside the two parents. |
| Detail row with one clear owning aggregate (`INCIDENT_ASSET`, `INCIDENT_VULNERABILITY`, `INCIDENT_STATUS_HISTORY` → `INCIDENT`; `RISK_ACCEPTANCE`, `REMEDIATION` → `VULNERABILITY_ASSET`; `ACCESS_RECERTIFICATION` → `ROLE_ASSIGNMENT`) | `CASCADE` from the owning aggregate | Deleting the aggregate root should clean up its own dependent rows. |
| FK to the *secondary*, reference-data side of a detail row (`INCIDENT_ASSET.asset_id`, `INCIDENT_VULNERABILITY.vulnerability_id`, `ROLE_ASSIGNMENT.role_id`) | `RESTRICT` | You can't silently delete a `ROLE` or `ASSET` that's still referenced elsewhere — the deletion has to be a conscious decision. |
| `VULNERABILITY_ASSET` → `VULNERABILITY` / `ASSET` | `RESTRICT` both sides | A finding sits at the intersection of two masters with no single clear owner — block deletion of either until the finding is closed. |
| Simple current-state pointer, not historical evidence (`ASSET.owner_user_id`) | Still `RESTRICT` (see USER rule above) | Consistency wins over a marginally more "convenient" `SET NULL` here. |

`ON UPDATE CASCADE` is applied everywhere for consistency, even though surrogate integer keys rarely change in practice.

---

## 3. Relational schema — classic Merise notation

`TABLE(**PK**, attribute, #foreign_key)` — PK in bold, FK prefixed with `#`.

```
USER(**user_id**, full_name, corporate_email, department, employment_status, start_date)
ROLE(**role_id**, role_name, description)
PERMISSION(**permission_id**, permission_name, description)
TAG(**tag_id**, tag_name)
ASSET(**asset_id**, asset_identifier, name, asset_type, environment, lifecycle_status, #owner_user_id)
VULNERABILITY(**vulnerability_id**, description, cvss_base_score, severity, discovery_date, discovery_source, status)
INCIDENT(**incident_id**, detection_time, reporting_source, severity, description, status)

ROLE_ASSIGNMENT(**assignment_id**, #user_id, #role_id, #granted_by_user_id, assigned_date, revoked_date, status)
ROLE_PERMISSION(**#role_id, #permission_id**, granted_date)
ASSET_TAG(**#asset_id, #tag_id**)
VULNERABILITY_ASSET(**vuln_asset_id**, #vulnerability_id, #asset_id, affected_version, detection_date, finding_status)
RISK_ACCEPTANCE(**risk_acceptance_id**, #vuln_asset_id, #accepting_authority_user_id, justification, acceptance_date, expiration_date)
REMEDIATION(**remediation_id**, #vuln_asset_id, remediation_note, remediation_date, verified_date, #verified_by_user_id)
INCIDENT_ASSET(**incident_asset_id**, #incident_id, #asset_id, asset_role, impact_level, containment_status)
INCIDENT_VULNERABILITY(**incident_vulnerability_id**, #incident_id, #vulnerability_id, exploitation_confirmed, linked_date, notes)
INCIDENT_STATUS_HISTORY(**status_history_id**, #incident_id, old_status, new_status, changed_at, #changed_by_user_id)
AUDIT_LOG(**audit_log_id**, #acting_user_id, action_timestamp, action_type, entity_type, record_identifier, before_values, after_values)
ACCESS_RECERTIFICATION(**recertification_id**, #assignment_id, #reviewer_user_id, review_date, status, decision)
```

---

## 4. Full SQL DDL (with constraints)

```sql
-- =========================================================
-- 1. USER  (quoted — "user" is a reserved word in several
--    engines; consider renaming to APP_USER in production)
-- =========================================================
CREATE TABLE "USER" (
    user_id           SERIAL PRIMARY KEY,
    full_name         VARCHAR(150) NOT NULL,
    corporate_email   VARCHAR(150) NOT NULL UNIQUE,
    department        VARCHAR(100),
    employment_status VARCHAR(20)  NOT NULL DEFAULT 'active'
                       CHECK (employment_status IN ('active','suspended','terminated')),
    start_date        DATE NOT NULL
);

-- =========================================================
-- 2. ROLE
-- =========================================================
CREATE TABLE ROLE (
    role_id      SERIAL PRIMARY KEY,
    role_name    VARCHAR(100) NOT NULL UNIQUE,
    description  TEXT
);

-- =========================================================
-- 3. PERMISSION
-- =========================================================
CREATE TABLE PERMISSION (
    permission_id    SERIAL PRIMARY KEY,
    permission_name  VARCHAR(100) NOT NULL UNIQUE,
    description      TEXT
);

-- =========================================================
-- 4. TAG
-- =========================================================
CREATE TABLE TAG (
    tag_id    SERIAL PRIMARY KEY,
    tag_name  VARCHAR(50) NOT NULL UNIQUE
);

-- =========================================================
-- 5. ASSET
-- =========================================================
CREATE TABLE ASSET (
    asset_id          SERIAL PRIMARY KEY,
    asset_identifier  VARCHAR(100) NOT NULL UNIQUE,
    name              VARCHAR(150) NOT NULL,
    asset_type        VARCHAR(50)  NOT NULL
                       CHECK (asset_type IN ('server','workstation','network_device','application','database','cloud_resource','other')),
    environment       VARCHAR(20)  NOT NULL DEFAULT 'production'
                       CHECK (environment IN ('production','staging','development','test')),
    lifecycle_status  VARCHAR(20)  NOT NULL DEFAULT 'active'
                       CHECK (lifecycle_status IN ('active','decommissioned','planned')),
    owner_user_id     INT REFERENCES "USER"(user_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- =========================================================
-- 6. VULNERABILITY
-- =========================================================
CREATE TABLE VULNERABILITY (
    vulnerability_id  SERIAL PRIMARY KEY,
    description       TEXT NOT NULL,
    cvss_base_score   DECIMAL(3,1) CHECK (cvss_base_score BETWEEN 0.0 AND 10.0),
    severity          VARCHAR(10) NOT NULL CHECK (severity IN ('low','medium','high','critical')),
    discovery_date    DATE NOT NULL,
    discovery_source  VARCHAR(100),
    status            VARCHAR(20) NOT NULL DEFAULT 'open'
                       CHECK (status IN ('open','triaged','closed','false_positive'))
);

-- =========================================================
-- 7. INCIDENT
-- =========================================================
CREATE TABLE INCIDENT (
    incident_id       SERIAL PRIMARY KEY,
    detection_time    TIMESTAMP NOT NULL,
    reporting_source  VARCHAR(100),
    severity          VARCHAR(10) NOT NULL CHECK (severity IN ('low','medium','high','critical')),
    description       TEXT NOT NULL,
    status            VARCHAR(20) NOT NULL DEFAULT 'open'
                       CHECK (status IN ('open','investigating','contained','resolved','closed'))
);

-- =========================================================
-- 8. ROLE_ASSIGNMENT
-- =========================================================
CREATE TABLE ROLE_ASSIGNMENT (
    assignment_id       SERIAL PRIMARY KEY,
    user_id             INT NOT NULL REFERENCES "USER"(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    role_id             INT NOT NULL REFERENCES ROLE(role_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    granted_by_user_id  INT REFERENCES "USER"(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    assigned_date       DATE NOT NULL DEFAULT CURRENT_DATE,
    revoked_date        DATE,
    status              VARCHAR(20) NOT NULL DEFAULT 'active'
                         CHECK (status IN ('active','revoked','expired')),
    CHECK (revoked_date IS NULL OR revoked_date >= assigned_date)
);

-- =========================================================
-- 9. ROLE_PERMISSION  (pure junction — composite PK, no
--    surrogate key needed; real attributes replace the
--    MCD-stage placeholder)
-- =========================================================
CREATE TABLE ROLE_PERMISSION (
    role_id        INT NOT NULL REFERENCES ROLE(role_id) ON DELETE CASCADE ON UPDATE CASCADE,
    permission_id  INT NOT NULL REFERENCES PERMISSION(permission_id) ON DELETE CASCADE ON UPDATE CASCADE,
    granted_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (role_id, permission_id)
);

-- =========================================================
-- 10. ASSET_TAG  (pure junction — tag_name dropped, it
--     already lives on TAG)
-- =========================================================
CREATE TABLE ASSET_TAG (
    asset_id  INT NOT NULL REFERENCES ASSET(asset_id) ON DELETE CASCADE ON UPDATE CASCADE,
    tag_id    INT NOT NULL REFERENCES TAG(tag_id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (asset_id, tag_id)
);

-- =========================================================
-- 11. VULNERABILITY_ASSET  ("a finding" — PK typo from the
--     MCD, vuln_assest, corrected to vuln_asset_id)
-- =========================================================
CREATE TABLE VULNERABILITY_ASSET (
    vuln_asset_id     SERIAL PRIMARY KEY,
    vulnerability_id  INT NOT NULL REFERENCES VULNERABILITY(vulnerability_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    asset_id          INT NOT NULL REFERENCES ASSET(asset_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    affected_version  VARCHAR(50),
    detection_date    DATE NOT NULL,
    finding_status    VARCHAR(20) NOT NULL DEFAULT 'open'
                       CHECK (finding_status IN ('open','remediated','risk_accepted','false_positive')),
    UNIQUE (vulnerability_id, asset_id)
);

-- =========================================================
-- 12. RISK_ACCEPTANCE
-- =========================================================
CREATE TABLE RISK_ACCEPTANCE (
    risk_acceptance_id           SERIAL PRIMARY KEY,
    vuln_asset_id                INT NOT NULL REFERENCES VULNERABILITY_ASSET(vuln_asset_id) ON DELETE CASCADE ON UPDATE CASCADE,
    accepting_authority_user_id  INT NOT NULL REFERENCES "USER"(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    justification                TEXT NOT NULL,
    acceptance_date              DATE NOT NULL DEFAULT CURRENT_DATE,
    expiration_date              DATE NOT NULL,
    CHECK (expiration_date > acceptance_date)
);

-- =========================================================
-- 13. REMEDIATION
-- =========================================================
CREATE TABLE REMEDIATION (
    remediation_id       SERIAL PRIMARY KEY,
    vuln_asset_id        INT NOT NULL REFERENCES VULNERABILITY_ASSET(vuln_asset_id) ON DELETE CASCADE ON UPDATE CASCADE,
    remediation_note     TEXT NOT NULL,
    remediation_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    verified_date        DATE,
    verified_by_user_id  INT REFERENCES "USER"(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (verified_date IS NULL OR verified_date >= remediation_date)
);

-- =========================================================
-- 14. INCIDENT_ASSET
-- =========================================================
CREATE TABLE INCIDENT_ASSET (
    incident_asset_id   SERIAL PRIMARY KEY,
    incident_id         INT NOT NULL REFERENCES INCIDENT(incident_id) ON DELETE CASCADE ON UPDATE CASCADE,
    asset_id            INT NOT NULL REFERENCES ASSET(asset_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    asset_role          VARCHAR(20) NOT NULL CHECK (asset_role IN ('impacted','source','compromised','other')),
    impact_level        VARCHAR(10) CHECK (impact_level IN ('low','medium','high','critical')),
    containment_status  VARCHAR(20) CHECK (containment_status IN ('not_contained','contained','isolated')),
    UNIQUE (incident_id, asset_id)
);

-- =========================================================
-- 15. INCIDENT_VULNERABILITY
-- =========================================================
CREATE TABLE INCIDENT_VULNERABILITY (
    incident_vulnerability_id  SERIAL PRIMARY KEY,
    incident_id                INT NOT NULL REFERENCES INCIDENT(incident_id) ON DELETE CASCADE ON UPDATE CASCADE,
    vulnerability_id           INT NOT NULL REFERENCES VULNERABILITY(vulnerability_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    exploitation_confirmed     BOOLEAN NOT NULL DEFAULT FALSE,
    linked_date                DATE NOT NULL DEFAULT CURRENT_DATE,
    notes                      TEXT,
    UNIQUE (incident_id, vulnerability_id)
);

-- =========================================================
-- 16. INCIDENT_STATUS_HISTORY
-- =========================================================
CREATE TABLE INCIDENT_STATUS_HISTORY (
    status_history_id  SERIAL PRIMARY KEY,
    incident_id         INT NOT NULL REFERENCES INCIDENT(incident_id) ON DELETE CASCADE ON UPDATE CASCADE,
    old_status          VARCHAR(20),
    new_status          VARCHAR(20) NOT NULL,
    changed_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by_user_id  INT NOT NULL REFERENCES "USER"(user_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- =========================================================
-- 17. AUDIT_LOG  (timestamp renamed to action_timestamp —
--     "timestamp" is a reserved type name in most engines)
-- =========================================================
CREATE TABLE AUDIT_LOG (
    audit_log_id       SERIAL PRIMARY KEY,
    acting_user_id     INT NOT NULL REFERENCES "USER"(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    action_timestamp   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    action_type        VARCHAR(20) NOT NULL CHECK (action_type IN ('create','update','delete','login','export','other')),
    entity_type        VARCHAR(100) NOT NULL,
    record_identifier  VARCHAR(100) NOT NULL,
    before_values       JSONB,
    after_values        JSONB
);

-- =========================================================
-- 18. ACCESS_RECERTIFICATION
-- =========================================================
CREATE TABLE ACCESS_RECERTIFICATION (
    recertification_id  SERIAL PRIMARY KEY,
    assignment_id        INT NOT NULL REFERENCES ROLE_ASSIGNMENT(assignment_id) ON DELETE CASCADE ON UPDATE CASCADE,
    reviewer_user_id      INT NOT NULL REFERENCES "USER"(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    review_date           DATE NOT NULL DEFAULT CURRENT_DATE,
    status                VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','completed','overdue')),
    decision              VARCHAR(20) CHECK (decision IN ('confirmed','revoked'))
);
```

---

