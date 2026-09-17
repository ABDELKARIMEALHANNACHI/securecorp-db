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

---

