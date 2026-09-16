# MCD — Design Decisions Log

This document explains the reasoning behind every relationship I added to complete the MCD (the ones linking `INCIDENT`, `INCIDENT_ASSET`, `INCIDENT_VULNERABILITY`, `INCIDENT_STATUS_HISTORY`, `RISK_ACCEPTANCE`, `REMEDIATION`, `AUDIT_LOG`, and `ACCESS_RECERTIFICATION` to the rest of the model). Keep it alongside the diagram so anyone reviewing the schema later understands *why* each link was drawn the way it was, not just *that* it exists.

Cardinality notation used throughout: **(min, max)** on each side of a relationship — e.g. `(0,N)` means "zero to many," `(1,1)` means "exactly one."

---

## 1. Fixed: the duplicate INCIDENT–ASSET link

**Problem found:** the original file had two competing designs at once — a raw, un-notated line directly from `INCIDENT` to `ASSET` (labeled "M"/"N"), *and* an `INCIDENT_ASSET` association entity meant to resolve that same many-to-many.

**Decision:** removed the raw line. In Merise/MCD, you resolve an M:N relationship *either* by leaving it as a direct M:N link *or* by creating an association entity to carry it — never both at once, since that's two contradictory statements about the same fact.

**Result:** `INCIDENT (1,N) — INCIDENT_ASSET`, `ASSET (1,N) — INCIDENT_ASSET`.

---

## 2. INCIDENT ↔ INCIDENT_ASSET ↔ ASSET

**Reasoning:** an incident typically touches more than one asset (e.g. a lateral-movement incident hits several servers), and a given asset can obviously be involved in more than one incident over its life. That's a textbook many-to-many, so it needs an association entity — exactly the role `INCIDENT_ASSET` already existed to play.

**Attributes added** (replacing the `Attribute1/2/3` placeholders):
- `incident_asset_id`
- `asset_role` — how this asset was involved (e.g. *impacted*, *source*, *compromised*)
- `impact_level`
- `containment_status`

---

## 3. INCIDENT ↔ INCIDENT_VULNERABILITY ↔ VULNERABILITY

**Reasoning:** identical shape to #2. An incident may involve several exploited CVEs, and a single CVE can be the root cause of multiple incidents across your environment.

**Attributes added:**
- `incident_vulnerability_id`
- `exploitation_confirmed`
- `linked_date`
- `notes`

**Alternative considered:** linking `INCIDENT_VULNERABILITY` to `VULNERABILITY_ASSET` instead of raw `VULNERABILITY`, which would pin the exploited vulnerability to the *specific asset* it was found on. I didn't do this because not every impacted asset necessarily has an associated vulnerability finding (e.g. a phishing incident that compromises a laptop with no relevant CVE). Keeping `INCIDENT_ASSET` and `INCIDENT_VULNERABILITY` as two independent associations is more flexible. Happy to switch to the tighter version if your use case always ties a vulnerability to one specific asset.

---

## 4. INCIDENT ↔ INCIDENT_STATUS_HISTORY

**Reasoning:** this is not a many-to-many — it's a dependent audit trail. Each history row records one status transition that belongs to exactly one incident; an incident can accumulate many such rows over its lifecycle (or zero, if it's brand new and hasn't changed status yet).

**Cardinality:** `INCIDENT (0,N) — INCIDENT_STATUS_HISTORY (1,1)`

**Also added:** `changed_by` is a person, not free text, so it should be a real relationship rather than a hidden attribute: `USER (0,N) — INCIDENT_STATUS_HISTORY (1,1)`.

---

## 5. RISK_ACCEPTANCE ↔ VULNERABILITY_ASSET (judgment call)

**The question:** what does "accepting risk" actually apply to — the abstract `VULNERABILITY`, the general `ASSET`, or something more specific?

**Decision:** attached it to `VULNERABILITY_ASSET` — the *finding* (this vulnerability, on this asset). Risk acceptance is always a decision about one concrete instance of exposure, not the CVE in the abstract or the asset in general. It's also naturally repeatable: an acceptance can expire and get renewed, or later be replaced by an actual fix, so a finding can have several acceptance records over time.

**Cardinality:** `VULNERABILITY_ASSET (0,N) — RISK_ACCEPTANCE (1,1)`

**Also added:** `accepting_authority` is a person → `USER (0,N) — RISK_ACCEPTANCE (1,1)`.

---

## 6. REMEDIATION ↔ VULNERABILITY_ASSET (judgment call)

**Decision:** same reasoning as risk acceptance — a remediation action fixes one specific finding, and a finding might go through multiple remediation attempts (partial fix, then full fix) before it's closed.

**Cardinality:** `VULNERABILITY_ASSET (0,N) — REMEDIATION (1,1)`

**Also added:** `verified_by` is a person → `USER (0,N) — REMEDIATION (1,1)`.

**Open question for you:** if you also want to track remediation actions taken specifically *in incident response* that aren't tied to any CVE (e.g. "isolated the host," "rotated credentials," "rebuilt the VM"), `REMEDIATION` would need a second, separate link directly to `INCIDENT`. I left this out because the original attribute list (`remediation_note`, `remediation_date`, `verified_date`, `verified_by`) reads like a vulnerability-fix record, not a general incident-response action log. Let me know if that's not the case and I'll add the link.

---

## 7. AUDIT_LOG ↔ USER only (deliberately not linked to everything)

**Reasoning:** `AUDIT_LOG` is a generic, polymorphic log — `entity_type` + `record_identifier` are a "soft" pointer that can point at a row in *any* table in the system. Drawing a formal conceptual-model line from `AUDIT_LOG` to every single entity it might reference would turn the diagram into an unreadable hairball, and it wouldn't add real information: the whole point of this pattern is that it stays generic at the conceptual/logical level and gets resolved by application logic, not by foreign keys to every table.

**The one relationship that IS worth modeling formally:** the actor. `acting_user` is always a real person, so:

**Cardinality:** `USER (0,N) — AUDIT_LOG (1,1)`

---

## 8. ACCESS_RECERTIFICATION ↔ ROLE_ASSIGNMENT

**Reasoning:** "access recertification" is the IAM/GRC process of periodically re-confirming that a granted access is still needed. What gets reviewed is the *grant itself* — i.e. a `ROLE_ASSIGNMENT` — not the `ROLE` or `USER` in the abstract. A single assignment can be reviewed more than once over its lifetime (quarterly/annual recertification cycles).

**Cardinality:** `ROLE_ASSIGNMENT (0,N) — ACCESS_RECERTIFICATION (1,1)`

**Also added:** `reviewer` is a person → `USER (0,N) — ACCESS_RECERTIFICATION (1,1)`.

---

## Summary table

| Relationship | Cardinality | Why |
|---|---|---|
| INCIDENT — INCIDENT_ASSET | (1,N) — (assoc.) | resolves incident↔asset M:N |
| ASSET — INCIDENT_ASSET | (1,N) — (assoc.) | resolves incident↔asset M:N |
| INCIDENT — INCIDENT_VULNERABILITY | (1,N) — (assoc.) | resolves incident↔CVE M:N |
| VULNERABILITY — INCIDENT_VULNERABILITY | (1,N) — (assoc.) | resolves incident↔CVE M:N |
| INCIDENT — INCIDENT_STATUS_HISTORY | (0,N) — (1,1) | dependent audit trail |
| USER — INCIDENT_STATUS_HISTORY | (0,N) — (1,1) | `changed_by` |
| VULNERABILITY_ASSET — RISK_ACCEPTANCE | (0,N) — (1,1) | risk decision on a specific finding |
| USER — RISK_ACCEPTANCE | (0,N) — (1,1) | `accepting_authority` |
| VULNERABILITY_ASSET — REMEDIATION | (0,N) — (1,1) | fix for a specific finding |
| USER — REMEDIATION | (0,N) — (1,1) | `verified_by` |
| USER — AUDIT_LOG | (0,N) — (1,1) | `acting_user` |
| ROLE_ASSIGNMENT — ACCESS_RECERTIFICATION | (0,N) — (1,1) | review of a specific grant |
| USER — ACCESS_RECERTIFICATION | (0,N) — (1,1) | `reviewer` |

---

## Not changed, but flagged for you

These were outside the scope of what you asked for, so I left the model as-is — but worth a decision on your end:

- **`ROLE_ASSIGNMENT.granted_by`** is a person but currently sits as a plain attribute with no drawn relationship — same pattern as `changed_by` / `verified_by` above. Say the word and I'll add `USER (0,N) — ROLE_ASSIGNMENT (1,1)` for it.
- **`ASSET_TAG.tag_name`** duplicates `TAG`'s own `tag_name` attribute. In a clean junction entity, `ASSET_TAG` should just carry the two foreign keys (asset + tag), not a copy of the tag's own data.
