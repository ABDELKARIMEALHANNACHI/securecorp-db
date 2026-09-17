from pathlib import Path
import random
from datetime import date, datetime, timedelta
import json

random.seed(20260917)

out = Path("/mnt/data/securecorp_seed.sql")

departments = [
    ("IT Infrastructure", 14), ("Cybersecurity", 10), ("Software Engineering", 18),
    ("Finance", 8), ("Human Resources", 5), ("Sales", 7), ("Operations", 9),
    ("Legal & Compliance", 4), ("Executive", 3), ("Data & Analytics", 6)
]
first_names = ["Youssef","Adam","Omar","Ayoub","Hamza","Anas","Mehdi","Zakaria","Ilyas","Reda",
               "Karim","Amine","Soufiane","Hicham","Nabil","Imane","Salma","Sara","Nour","Aya",
               "Meryem","Hajar","Lina","Ines","Samira","Khadija","Mouna","Sanae","Zineb","Ikram"]
last_names = ["El Amrani","Bennani","Alaoui","Tazi","Fassi","Idrissi","Berrada","Chraibi","Naciri",
              "Benjelloun","Lahlou","Tahiri","Mansouri","El Haddad","Ouazzani","Kettani","Raji",
              "El Alami","Belkadi","Ait Lahcen"]

def q(s):
    return "'" + str(s).replace("'", "''") + "'"

def sql_json(d):
    return q(json.dumps(d, separators=(",", ":")))

lines = []
lines += [
"-- SecureCorp DB realistic seed dataset",
"-- PostgreSQL / generated with deterministic seed 20260917",
"-- Designed for security analytics: non-uniform distributions, correlated records and valid FK/temporal constraints.",
"BEGIN;",
"SET search_path TO public;",
"",
"-- Reset generated identity sequences after explicit IDs.",
""
]

# USERS
users = []
uid = 1
for dept, n in departments:
    for _ in range(n):
        name = f"{random.choice(first_names)} {random.choice(last_names)}"
        # unique enough
        email = name.lower().replace(" ", ".").replace("'", "").replace("é","e") + f".{uid}@securecorp.ma"
        # longer-tenured staff more likely; a few recent hires
        start = date(2018,1,8) + timedelta(days=random.randint(0, 3150))
        status = random.choices(["active","suspended","terminated"], weights=[92,3,5])[0]
        users.append((uid,name,email,dept,status,start))
        uid += 1

lines.append("-- 1. USER")
for u in users:
    lines.append("INSERT INTO \"USER\" (user_id, full_name, corporate_email, department, employment_status, start_date) VALUES "
                 + "(" + ",".join([str(u[0]),q(u[1]),q(u[2]),q(u[3]),q(u[4]),q(u[5])]) + ");")
lines.append("")

# ROLES
roles = [
(1,"Employee","Standard corporate access."),
(2,"Developer","Software development and deployment access."),
(3,"System Administrator","Privileged infrastructure administration."),
(4,"Security Analyst","Security monitoring, investigation and vulnerability management."),
(5,"Security Engineer","Security engineering and remediation capabilities."),
(6,"Database Administrator","Database administration and maintenance."),
(7,"Network Administrator","Network infrastructure administration."),
(8,"IT Support","Endpoint and user support."),
(9,"Finance Analyst","Finance systems access."),
(10,"HR Specialist","Human resources systems access."),
(11,"Compliance Officer","Compliance and audit oversight."),
(12,"Incident Commander","Authority to coordinate major security incidents."),
(13,"Executive","Executive-level business access."),
(14,"Auditor","Read-oriented audit and recertification access."),
]
lines.append("-- 2. ROLE")
for r in roles:
    lines.append(f"INSERT INTO ROLE (role_id, role_name, description) VALUES ({r[0]},{q(r[1])},{q(r[2])});")
lines.append("")

# PERMISSIONS
perm_names = [
("user.read","Read user profiles and employment metadata."),
("user.manage","Create, update and suspend user accounts."),
("role.read","View role assignments."),
("role.manage","Grant and revoke roles."),
("asset.read","View enterprise asset inventory."),
("asset.manage","Register and update assets."),
("vulnerability.read","View vulnerability findings."),
("vulnerability.manage","Triage and update vulnerability findings."),
("remediation.manage","Create and verify remediation actions."),
("incident.read","View security incidents."),
("incident.manage","Manage incident lifecycle."),
("incident.contain","Perform incident containment actions."),
("incident.command","Coordinate critical incident response."),
("audit.read","Read audit records."),
("audit.export","Export audit records."),
("database.admin","Administrative database access."),
("network.admin","Administrative network access."),
("deployment.deploy","Deploy application releases."),
("finance.read","Read finance data."),
("hr.read","Read HR data."),
("compliance.review","Perform compliance reviews."),
("access.recertify","Review access recertifications."),
("executive.read","Read executive dashboards."),
]
lines.append("-- 3. PERMISSION")
for i,(n,d) in enumerate(perm_names,1):
    lines.append(f"INSERT INTO PERMISSION (permission_id, permission_name, description) VALUES ({i},{q(n)},{q(d)});")
lines.append("")

# TAGS
tags = ["production","internet-facing","internal","critical-service","customer-facing","pci-scope","pii","contains-secrets",
        "linux","windows","cloud","aws","database","api","legacy","high-value","remote-access","monitoring","backup","deprecated"]
lines.append("-- 4. TAG")
for i,t in enumerate(tags,1):
    lines.append(f"INSERT INTO TAG (tag_id, tag_name) VALUES ({i},{q(t)});")
lines.append("")

# ASSETS
asset_specs = []
owners_by_dept = {}
for u in users:
    owners_by_dept.setdefault(u[3],[]).append(u[0])

asset_id = 1
asset_types = (
    [("server","production")]*30 + [("application","production")]*18 + [("database","production")]*10 +
    [("network_device","production")]*10 + [("cloud_resource","production")]*12 +
    [("workstation","production")]*10 + [("server","staging")]*6 + [("application","staging")]*5 +
    [("database","staging")]*2 + [("server","development")]*5 + [("application","development")]*7 +
    [("workstation","test")]*8 + [("server","test")]*3 + [("application","test")]*3
)
names = {
"server":["ERP-APP","PAYROLL-APP","AD-CORE","FILE-SRV","MONITORING","CI-RUNNER","BACKUP","LOG","VPN","MAIL",
          "WEB","API","BATCH","JUMP","AUTH","DNS","NTP","PRINT"],
"application":["Customer Portal","Partner Portal","Identity API","Payment Gateway","HR Portal","Finance API",
               "Mobile API","Document Service","Notification Service","Reporting Platform","CRM","Data Lake UI"],
"database":["ERP PostgreSQL","Finance PostgreSQL","HR PostgreSQL","Customer PostgreSQL","Audit PostgreSQL",
            "Analytics PostgreSQL","Identity PostgreSQL","Logging PostgreSQL"],
"network_device":["CORE-SW","EDGE-RTR","FW-PERIMETER","VPN-GW","WIFI-CONTROLLER","DIST-SW"],
"cloud_resource":["AWS S3 Data Lake","AWS EC2 API","AWS RDS CustomerDB","AWS EKS Cluster","AWS CloudFront",
                  "AWS Secrets Store","AWS Backup Vault","AWS Lambda Processor"],
"workstation":["Finance-Laptop","HR-Laptop","SOC-Workstation","Developer-Workstation","Executive-Laptop"]
}
for typ, env in asset_types:
    prefix = {"server":"SRV","application":"APP","database":"DB","network_device":"NET","cloud_resource":"CLOUD","workstation":"WKST"}[typ]
    base = random.choice(names[typ])
    identifier = f"{prefix}-{asset_id:04d}"
    name = f"{base} {asset_id:02d}" if base.split()[-1].isdigit() else base
    if env != "production": name += f" [{env}]"
    # owner correlated with asset type
    if typ in ("network_device",): dept = "IT Infrastructure"
    elif typ == "database": dept = random.choices(["Data & Analytics","IT Infrastructure","Finance","Cybersecurity"],[4,4,2,1])[0]
    elif typ == "application": dept = random.choices(["Software Engineering","Operations","Finance","Human Resources","Sales"],[7,2,2,1,1])[0]
    elif typ == "cloud_resource": dept = random.choices(["IT Infrastructure","Software Engineering","Cybersecurity","Data & Analytics"],[4,4,2,2])[0]
    elif typ == "workstation": dept = random.choice(["Finance","Human Resources","Sales","Executive","Software Engineering","Operations"])
    else: dept = random.choice(["IT Infrastructure","Software Engineering","Operations","Cybersecurity"])
    owner = random.choice(owners_by_dept[dept])
    life = random.choices(["active","decommissioned","planned"],[91,6,3])[0]
    asset_specs.append((asset_id,identifier,name,typ,env,life,owner))
    asset_id += 1

lines.append("-- 5. ASSET")
for a in asset_specs:
    lines.append(f"INSERT INTO ASSET (asset_id, asset_identifier, name, asset_type, environment, lifecycle_status, owner_user_id) VALUES "
                 f"({a[0]},{q(a[1])},{q(a[2])},{q(a[3])},{q(a[4])},{q(a[5])},{a[6]});")
lines.append("")

# VULNERABILITIES
vuln_templates = [
("Outdated OpenSSL permits remote denial of service on exposed service", "high", "Nessus"),
("Missing security headers on customer-facing web application", "low", "Burp Suite"),
("Broken access control permits cross-tenant object access", "critical", "Manual security test"),
("TLS configuration permits deprecated cipher suites", "medium", "Qualys"),
("Unpatched Linux kernel vulnerability detected", "high", "Nessus"),
("Stored cross-site scripting in administrative reporting workflow", "high", "DAST"),
("Database account has excessive privileges", "high", "Configuration review"),
("Verbose error messages expose internal implementation details", "low", "Burp Suite"),
("Weak password policy for legacy application", "medium", "Security audit"),
("Remote management service exposed to an untrusted network", "critical", "External scan"),
("Dependency with known CVE requires upgrade", "medium", "SCA pipeline"),
("Cloud storage bucket permits unintended read access", "high", "Cloud posture scan"),
("JWT validation accepts an insecure signing configuration", "critical", "Manual security test"),
("Missing rate limiting on authentication endpoint", "medium", "Burp Suite"),
("Legacy framework version no longer receives security updates", "high", "Asset inventory"),
("Endpoint reveals excessive user metadata", "low", "API review"),
]
lines.append("-- 6. VULNERABILITY")
vulns=[]
for vid in range(1,61):
    desc,severity,source=random.choice(vuln_templates)
    cvss_ranges={"low":(2.1,3.9),"medium":(4.0,6.9),"high":(7.0,8.9),"critical":(9.0,10.0)}
    lo,hi=cvss_ranges[severity]
    cvss=round(random.uniform(lo,hi),1)
    disc=date(2023,1,1)+timedelta(days=random.randint(0,1320))
    status=random.choices(["open","triaged","closed","false_positive"],{"low":[18,15,60,7],"medium":[25,20,48,7],"high":[30,30,35,5],"critical":[35,35,27,3]}[severity])[0]
    vulns.append((vid,desc,cvss,severity,disc,source,status))
    lines.append(f"INSERT INTO VULNERABILITY (vulnerability_id, description, cvss_base_score, severity, discovery_date, discovery_source, status) VALUES "
                 f"({vid},{q(desc)},{cvss},{q(severity)},{q(disc)},{q(source)},{q(status)});")
lines.append("")

# ROLE_PERMISSION
role_perm = {
1:[1,3,5,7,10,11], 2:[1,3,5,7,8,18], 3:[1,2,3,4,5,6,7,8,9,10,11,12,15,16,17,18],
4:[1,3,5,7,8,9,10,11,12,13,14,21,22], 5:[1,3,4,5,6,7,8,9,10,11,12,13,14,16,17,18],
6:[1,3,5,6,7,16], 7:[1,3,5,6,7,17], 8:[1,3,5,7], 9:[1,3,5,19], 10:[1,3,5,20],
11:[1,3,5,7,14,21,22], 12:[1,3,5,7,8,9,10,11,12,13,14,21], 13:[1,3,5,23],
14:[1,3,5,7,14,21,22]
}
lines.append("-- 9. ROLE_PERMISSION")
for rid,pids in role_perm.items():
    for pid in pids:
        gd=date(2023,1,1)+timedelta(days=random.randint(0,1000))
        lines.append(f"INSERT INTO ROLE_PERMISSION (role_id, permission_id, granted_date) VALUES ({rid},{pid},{q(gd)});")
lines.append("")

# ROLE_ASSIGNMENT
dept_role_weights = {
"IT Infrastructure":[(1,2),(3,7),(7,6),(8,3),(14,1)],
"Cybersecurity":[(1,2),(4,8),(5,6),(12,2),(14,2)],
"Software Engineering":[(1,7),(2,10),(5,2)],
"Finance":[(1,5),(9,6),(13,1)],
"Human Resources":[(1,4),(10,5)],
"Sales":[(1,7)],
"Operations":[(1,7),(2,2)],
"Legal & Compliance":[(1,2),(11,4),(14,2)],
"Executive":[(1,1),(13,3)],
"Data & Analytics":[(1,3),(2,2),(6,4),(5,1)]
}
role_assignments=[]
aid=1
active_users=[u for u in users if u[4]=="active"]
for u in active_users:
    choices=dept_role_weights[u[3]]
    # one primary; privileged users occasionally get a second role
    total=sum(w for _,w in choices)
    x=random.uniform(0,total); acc=0; rid=choices[0][0]
    for rr,w in choices:
        acc+=w
        if x<=acc: rid=rr; break
    assigned=max(u[5],date(2023,1,1))+timedelta(days=random.randint(0,700))
    if assigned>date(2026,8,31): assigned=date(2026,8,31)-timedelta(days=random.randint(0,30))
    granted_by=random.choice([x[0] for x in active_users if x[3] in ("Cybersecurity","IT Infrastructure","Legal & Compliance","Executive")])
    role_assignments.append((aid,u[0],rid,granted_by,assigned,None,"active")); aid+=1
    if rid in (1,2,4,5,6,7) and random.random()<0.12:
        alt=random.choice([r[0] for r in choices if r[0]!=rid]) if len(choices)>1 else None
        if alt:
            assigned2=assigned+timedelta(days=random.randint(30,400))
            if assigned2<=date(2026,8,31):
                role_assignments.append((aid,u[0],alt,granted_by,assigned2,None,"active")); aid+=1

# add historical revoked assignments
for _ in range(35):
    u=random.choice(users)
    rid=random.choice(range(1,15))
    assigned=date(2022,1,1)+timedelta(days=random.randint(0,1300))
    revoked=assigned+timedelta(days=random.randint(30,600))
    if revoked>date(2026,8,31): revoked=date(2026,8,31)
    role_assignments.append((aid,u[0],rid,random.choice([x[0] for x in active_users]),assigned,revoked,random.choice(["revoked","expired"])))
    aid+=1

lines.append("-- 8. ROLE_ASSIGNMENT")
for a in role_assignments:
    lines.append(f"INSERT INTO ROLE_ASSIGNMENT (assignment_id,user_id,role_id,granted_by_user_id,assigned_date,revoked_date,status) VALUES "
                 f"({a[0]},{a[1]},{a[2]},{a[3]},{q(a[4])},{'NULL' if a[5] is None else q(a[5])},{q(a[6])});")
lines.append("")

# ASSET_TAG
lines.append("-- 10. ASSET_TAG")
for a in asset_specs:
    typ,env=a[3],a[4]
    candidates=[]
    if env=="production": candidates += [1]
    else: candidates += [3]
    if a[1].startswith(("APP","CLOUD")): candidates += [5,14]
    if typ=="database": candidates += [7,13]
    if typ=="server": candidates += [9,10]
    if env=="production" and random.random()<0.18: candidates += [4,6]
    if random.random()<0.12: candidates += [15]
    if random.random()<0.10: candidates += [16]
    if random.random()<0.08: candidates += [17]
    for tid in set(random.sample(candidates, k=min(len(set(candidates)), random.randint(1, min(4,len(set(candidates))))))):
        lines.append(f"INSERT INTO ASSET_TAG (asset_id,tag_id) VALUES ({a[0]},{tid});")
lines.append("")

# VULN-ASSET
lines.append("-- 11. VULNERABILITY_ASSET")
va=[]
vaid=1
for v in vulns:
    vid,severity=v[0],v[3]
    count=random.choices([1,2,3,4,5,6,8],[45,24,14,8,5,3,1])[0]
    if severity=="critical": count=random.choices([1,2,3],[65,28,7])[0]
    if severity=="low": count=random.choices([1,2,3,4,5],[35,30,20,10,5])[0]
    candidates=random.sample(asset_specs,min(count,len(asset_specs)))
    for a in candidates:
        detection=max(v[4],date(2023,1,1))+timedelta(days=random.randint(0,500))
        if detection>date(2026,8,31): detection=date(2026,8,31)-timedelta(days=random.randint(0,60))
        fs=random.choices(["open","remediated","risk_accepted","false_positive"],[38,38,16,8])[0]
        va.append((vaid,vid,a[0],random.choice(["1.2.4","2.7.18","3.1.9","4.8.2","5.4.0","7.6.1"]),detection,fs))
        lines.append(f"INSERT INTO VULNERABILITY_ASSET (vuln_asset_id,vulnerability_id,asset_id,affected_version,detection_date,finding_status) VALUES "
                     f"({vaid},{vid},{a[0]},{q(va[-1][3])},{q(detection)},{q(fs)});")
        vaid+=1
lines.append("")

# Risk acceptance
lines.append("-- 12. RISK_ACCEPTANCE")
risk_id=1
risk_rows=[]
for row in va:
    if row[5]=="risk_accepted":
        authority=random.choice([u for u in active_users if u[3] in ("Cybersecurity","Legal & Compliance","Executive")])
        acc=max(row[4],date(2024,1,1))
        exp=acc+timedelta(days=random.randint(45,365))
        risk_rows.append((risk_id,row[0],authority[0],
                          random.choice(["Compensating control is deployed and monitored.","Business dependency prevents immediate upgrade.","Vendor patch is pending and service is operationally constrained.","Legacy integration requires scheduled maintenance window."]),
                          acc,exp))
        lines.append(f"INSERT INTO RISK_ACCEPTANCE (risk_acceptance_id,vuln_asset_id,accepting_authority_user_id,justification,acceptance_date,expiration_date) VALUES "
                     f"({risk_id},{row[0]},{authority[0]},{q(risk_rows[-1][3])},{q(acc)},{q(exp)});")
        risk_id+=1
lines.append("")

# Remediation
lines.append("-- 13. REMEDIATION")
remid=1
rem_rows=[]
for row in va:
    if row[5]=="remediated":
        rem_date=row[4]+timedelta(days=random.randint(5,180))
        if rem_date>date(2026,8,31): rem_date=date(2026,8,31)
        verified=None
        verifier=None
        if random.random()<0.82:
            verified=rem_date+timedelta(days=random.randint(1,30))
            if verified>date(2026,8,31): verified=date(2026,8,31)
            verifier=random.choice([u[0] for u in active_users if u[3] in ("Cybersecurity","IT Infrastructure","Software Engineering")])
        note=random.choice(["Patched affected package and restarted service.","Configuration hardened according to internal baseline.","Access control corrected and regression tests completed.","Deprecated protocol disabled and validated with external scan.","Dependency upgraded and CI security checks passed."])
        rem_rows.append((remid,row[0],note,rem_date,verified,verifier))
        lines.append(f"INSERT INTO REMEDIATION (remediation_id,vuln_asset_id,remediation_note,remediation_date,verified_date,verified_by_user_id) VALUES "
                     f"({remid},{row[0]},{q(note)},{q(rem_date)},{'NULL' if verified is None else q(verified)},{'NULL' if verifier is None else verifier});")
        remid+=1
lines.append("")

# INCIDENTS
lines.append("-- 7. INCIDENT")
incident_templates=[
("Repeated authentication failures detected against identity service","SIEM"),
("Suspicious PowerShell activity on corporate workstation","EDR"),
("Unusual outbound traffic from application server","Network IDS"),
("Cloud storage access pattern deviated from baseline","Cloud monitoring"),
("Potential credential compromise reported by employee","Service Desk"),
("Malware detection on endpoint","EDR"),
("API authentication anomaly detected","WAF"),
("Database account performed unexpected administrative query","Database audit"),
("Phishing email campaign reported by multiple employees","Email security"),
("External scanning activity against perimeter assets","Firewall")
]
incidents=[]
for iid in range(1,76):
    desc,src=random.choice(incident_templates)
    sev=random.choices(["low","medium","high","critical"],[44,36,16,4])[0]
    dt=datetime(2024,1,1)+timedelta(days=random.randint(0,985),hours=random.randint(0,23),minutes=random.randint(0,59))
    status=random.choices(["open","investigating","contained","resolved","closed"],[8,18,12,38,24])[0]
    incidents.append((iid,dt,src,sev,desc,status))
    lines.append(f"INSERT INTO INCIDENT (incident_id,detection_time,reporting_source,severity,description,status) VALUES "
                 f"({iid},{q(dt)},{q(src)},{q(sev)},{q(desc)},{q(status)});")
lines.append("")

# Incident assets
lines.append("-- 14. INCIDENT_ASSET")
iaid=1
incident_asset_rows=[]
for inc in incidents:
    iid,dt,src,sev,desc,status=inc
    n=random.choices([1,2,3,4],[58,28,11,3])[0]
    assets=random.sample(asset_specs,n)
    for j,a in enumerate(assets):
        role="source" if j==0 and random.random()<0.45 else random.choice(["impacted","compromised","other"])
        impact=random.choices(["low","medium","high","critical"],[35,40,20,5])[0]
        if sev=="critical": impact=random.choices(["high","critical"],[55,45])[0]
        containment=random.choices(["not_contained","contained","isolated"],[45,35,20])[0]
        incident_asset_rows.append((iaid,iid,a[0],role,impact,containment))
        lines.append(f"INSERT INTO INCIDENT_ASSET (incident_asset_id,incident_id,asset_id,asset_role,impact_level,containment_status) VALUES "
                     f"({iaid},{iid},{a[0]},{q(role)},{q(impact)},{q(containment)});")
        iaid+=1
lines.append("")

# Incident vulnerabilities, correlate some incidents with known vulns
lines.append("-- 15. INCIDENT_VULNERABILITY")
iv_id=1
for inc in incidents:
    iid,dt,src,sev,desc,status=inc
    if random.random()<0.34:
        candidate=[v for v in vulns if v[3] in ([sev] if sev in ["critical","high"] else ["low","medium","high"])]
        for v in random.sample(candidate,min(len(candidate),random.choice([1,1,1,2]))):
            confirmed=(sev in ("high","critical") and v[3] in ("high","critical") and random.random()<0.55)
            linked=dt.date()+timedelta(days=random.randint(0,30))
            if linked>date(2026,8,31): linked=date(2026,8,31)
            note=random.choice(["Correlation identified during investigation.","Finding matched observed attack path.","Potential contributing control weakness.","No direct exploitation evidence, but retained for investigation."])
            lines.append(f"INSERT INTO INCIDENT_VULNERABILITY (incident_vulnerability_id,incident_id,vulnerability_id,exploitation_confirmed,linked_date,notes) VALUES "
                         f"({iv_id},{iid},{v[0]},{str(confirmed).upper()},{q(linked)},{q(note)});")
            iv_id+=1
lines.append("")

# Status history
lines.append("-- 16. INCIDENT_STATUS_HISTORY")
shid=1
status_order={"open":["investigating"],"investigating":["contained","resolved"],"contained":["resolved"],"resolved":["closed"],"closed":[]}
for inc in incidents:
    iid,dt,src,sev,desc,status=inc
    # Always create initial event
    actor=random.choice(active_users)[0]
    lines.append(f"INSERT INTO INCIDENT_STATUS_HISTORY (status_history_id,incident_id,old_status,new_status,changed_at,changed_by_user_id) VALUES "
                 f"({shid},{iid},NULL,'open',{q(dt)},{actor});")
    shid+=1
    current="open"
    chain=["investigating","contained","resolved","closed"]
    target=status
    for ns in chain:
        if ns==target or (target=="closed") or (target=="resolved" and ns in ["investigating","contained","resolved"]):
            if current=="open" and ns=="investigating" or current=="investigating" and ns in ("contained","resolved") or current=="contained" and ns=="resolved" or current=="resolved" and ns=="closed":
                changed=dt+timedelta(hours=random.randint(1,72))
                actor=random.choice(active_users)[0]
                lines.append(f"INSERT INTO INCIDENT_STATUS_HISTORY (status_history_id,incident_id,old_status,new_status,changed_at,changed_by_user_id) VALUES "
                             f"({shid},{iid},{q(current)},{q(ns)},{q(changed)},{actor});")
                shid+=1
                current=ns
                if current==target: break
lines.append("")

# Audit log
lines.append("-- 17. AUDIT_LOG")
actions=["create","update","delete","login","export","other"]
entities=["USER","ROLE_ASSIGNMENT","ASSET","VULNERABILITY","VULNERABILITY_ASSET","INCIDENT","REMEDIATION","RISK_ACCEPTANCE","ACCESS_RECERTIFICATION"]
audit_id=1
for _ in range(420):
    actor=random.choice(active_users)
    action=random.choices(actions,[12,34,3,38,5,8])[0]
    entity=random.choice(entities)
    rid=str(random.randint(1, max(1,{"USER":len(users),"ROLE_ASSIGNMENT":len(role_assignments),"ASSET":len(asset_specs),
        "VULNERABILITY":len(vulns),"VULNERABILITY_ASSET":len(va),"INCIDENT":len(incidents),"REMEDIATION":max(1,len(rem_rows)),
        "RISK_ACCEPTANCE":max(1,len(risk_rows)),"ACCESS_RECERTIFICATION":50}[entity])))
    ts=datetime(2024,1,1)+timedelta(days=random.randint(0,985),hours=random.randint(0,23),minutes=random.randint(0,59))
    before=None if action in ("create","login","export") else {"status":"old","source":"application"}
    after=None if action in ("delete","login") else {"status":"new","source":"application"}
    lines.append(f"INSERT INTO AUDIT_LOG (audit_log_id,acting_user_id,action_timestamp,action_type,entity_type,record_identifier,before_values,after_values) VALUES "
                 f"({audit_id},{actor[0]},{q(ts)},{q(action)},{q(entity)},{q(rid)},{'NULL' if before is None else sql_json(before)},{'NULL' if after is None else sql_json(after)});")
    audit_id+=1
lines.append("")

# Access recertification
lines.append("-- 18. ACCESS_RECERTIFICATION")
rec_id=1
# focus on active assignments, plus some old revoked
for a in random.sample(role_assignments,min(95,len(role_assignments))):
    assignment_id,user_id,role_id,granted_by,assigned,revoked,status=a
    reviewer=random.choice([u for u in active_users if u[0]!=user_id])[0]
    review=assigned+timedelta(days=random.randint(90,600))
    if review>date(2026,8,31): review=date(2026,8,31)
    rstatus=random.choices(["pending","completed","overdue"],[8,77,15])[0]
    decision=None
    if rstatus=="completed":
        decision=random.choices(["confirmed","revoked"],[91,9])[0]
    elif rstatus=="overdue" and review<date(2026,6,1):
        decision=None
    lines.append(f"INSERT INTO ACCESS_RECERTIFICATION (recertification_id,assignment_id,reviewer_user_id,review_date,status,decision) VALUES "
                 f"({rec_id},{assignment_id},{reviewer},{q(review)},{q(rstatus)},{'NULL' if decision is None else q(decision)});")
    rec_id+=1

lines += [
"",
"-- Keep SERIAL sequences above the explicit seed IDs.",
"SELECT setval(pg_get_serial_sequence('\"USER\"','user_id'), COALESCE((SELECT MAX(user_id) FROM \"USER\"),1), true);",
"SELECT setval(pg_get_serial_sequence('role','role_id'), COALESCE((SELECT MAX(role_id) FROM role),1), true);",
"SELECT setval(pg_get_serial_sequence('permission','permission_id'), COALESCE((SELECT MAX(permission_id) FROM permission),1), true);",
"SELECT setval(pg_get_serial_sequence('tag','tag_id'), COALESCE((SELECT MAX(tag_id) FROM tag),1), true);",
"SELECT setval(pg_get_serial_sequence('asset','asset_id'), COALESCE((SELECT MAX(asset_id) FROM asset),1), true);",
"SELECT setval(pg_get_serial_sequence('vulnerability','vulnerability_id'), COALESCE((SELECT MAX(vulnerability_id) FROM vulnerability),1), true);",
"SELECT setval(pg_get_serial_sequence('incident','incident_id'), COALESCE((SELECT MAX(incident_id) FROM incident),1), true);",
"SELECT setval(pg_get_serial_sequence('role_assignment','assignment_id'), COALESCE((SELECT MAX(assignment_id) FROM role_assignment),1), true);",
"SELECT setval(pg_get_serial_sequence('vulnerability_asset','vuln_asset_id'), COALESCE((SELECT MAX(vuln_asset_id) FROM vulnerability_asset),1), true);",
"SELECT setval(pg_get_serial_sequence('risk_acceptance','risk_acceptance_id'), COALESCE((SELECT MAX(risk_acceptance_id) FROM risk_acceptance),1), true);",
"SELECT setval(pg_get_serial_sequence('remediation','remediation_id'), COALESCE((SELECT MAX(remediation_id) FROM remediation),1), true);",
"SELECT setval(pg_get_serial_sequence('incident_asset','incident_asset_id'), COALESCE((SELECT MAX(incident_asset_id) FROM incident_asset),1), true);",
"SELECT setval(pg_get_serial_sequence('incident_vulnerability','incident_vulnerability_id'), COALESCE((SELECT MAX(incident_vulnerability_id) FROM incident_vulnerability),1), true);",
"SELECT setval(pg_get_serial_sequence('incident_status_history','status_history_id'), COALESCE((SELECT MAX(status_history_id) FROM incident_status_history),1), true);",
"SELECT setval(pg_get_serial_sequence('audit_log','audit_log_id'), COALESCE((SELECT MAX(audit_log_id) FROM audit_log),1), true);",
"SELECT setval(pg_get_serial_sequence('access_recertification','recertification_id'), COALESCE((SELECT MAX(recertification_id) FROM access_recertification),1), true);",
"",
"COMMIT;",
""
]

out.write_text("\n".join(lines), encoding="utf-8")
print(f"Created {out}")
print(f"Lines: {len(lines):,}")
print(f"Users: {len(users)} | Assets: {len(asset_specs)} | Vulnerabilities: {len(vulns)} | Vuln-Asset findings: {len(va)} | Incidents: {len(incidents)} | Role assignments: {len(role_assignments)} | Remediations: {len(rem_rows)}")

from pathlib import Path
import random, re, json
from datetime import date, datetime, timedelta

base = Path("/mnt/data/securecorp_seed.sql")
append = Path("/mnt/data/securecorp_seed_append.sql")
text = base.read_text(encoding="utf-8")

# Fixed continuation points based on the previously generated seed.
USER_START, USER_N = 85, 209
ROLE_START, ROLE_N = 15, 20          # expands role model from 14 -> 34 roles
PERM_START = 24
ASSET_START, ASSET_N = 130, 300
VULN_START, VULN_N = 61, 170
VA_START = 133
INC_START, INC_N = 76, 290
IA_START = 1
IV_START = 1
SH_START = 1
AUDIT_START, AUDIT_N = 421, 1100
REC_START = 1
REM_START = 47
RISK_START = 1

random.seed(20260917 + 2)

first_names = ["Youssef","Adam","Omar","Ayoub","Hamza","Anas","Mehdi","Zakaria","Ilyas","Reda",
"Karim","Amine","Soufiane","Hicham","Nabil","Imane","Salma","Sara","Nour","Aya","Meryem","Hajar",
"Lina","Ines","Samira","Khadija","Mouna","Sanae","Zineb","Ikram","Rayan","Bilal","Walid","Ismail"]
last_names = ["El Amrani","Bennani","Alaoui","Tazi","Fassi","Idrissi","Berrada","Chraibi","Naciri",
"Benjelloun","Lahlou","Tahiri","Mansouri","El Haddad","Ouazzani","Kettani","Raji","El Alami",
"Belkadi","Ait Lahcen","Benomar","Cherkaoui","Mernissi","Bouzid"]

departments = ["IT Infrastructure","Cybersecurity","Software Engineering","Finance","Human Resources",
"Sales","Operations","Legal & Compliance","Executive","Data & Analytics","Procurement",
"Customer Success","Product","Internal Audit","Research & Innovation","Marketing"]

def q(x):
    return "'" + str(x).replace("'", "''") + "'"

def js(x):
    return q(json.dumps(x, separators=(",",":")))

users=[]
for uid in range(USER_START, USER_START+USER_N):
    dept=random.choices(departments,[13,12,17,8,5,8,10,4,2,7,4,5,4,3,2,4])[0]
    name=f"{random.choice(first_names)} {random.choice(last_names)}"
    email=re.sub(r"[^a-z0-9.]", "", name.lower().replace(" ",".")) + f".{uid}@securecorp.ma"
    start=date(2017,1,1)+timedelta(days=random.randint(0,3500))
    status=random.choices(["active","suspended","terminated"],[94,2,4])[0]
    users.append((uid,name,email,dept,status,start))

roles = [
("Platform Engineer","Maintains internal platforms and shared engineering services."),
("Cloud Engineer","Manages cloud infrastructure, deployments and cloud security controls."),
("DevOps Engineer","Operates CI/CD pipelines and production deployment infrastructure."),
("SOC Analyst L2","Investigates escalated security alerts and endpoint/network telemetry."),
("SOC Analyst L3","Leads advanced detection engineering and complex investigations."),
("Threat Hunter","Performs proactive threat hunting across enterprise telemetry."),
("Vulnerability Manager","Owns vulnerability lifecycle, prioritization and remediation tracking."),
("IAM Administrator","Manages identity lifecycle, privileged access and authentication controls."),
("Application Security Engineer","Performs application security reviews and coordinates fixes."),
("Security Architect","Defines security architecture, control requirements and exceptions."),
("Cloud Security Analyst","Monitors cloud posture, identity and workload security."),
("Forensics Analyst","Performs digital forensic acquisition and analysis."),
("Penetration Tester","Conducts authorized security testing and validation."),
("GRC Analyst","Maintains governance, risk and control evidence."),
("Privacy Officer","Oversees privacy-related controls and data handling reviews."),
("Procurement Specialist","Manages procurement workflows and vendor records."),
("Product Manager","Owns product requirements, releases and operational priorities."),
("Customer Success Manager","Manages customer-facing service operations and escalations."),
("Data Engineer","Builds and operates data pipelines and analytics infrastructure."),
("BI Analyst","Produces operational and security reporting and analysis.")
]

lines=[]
lines += [
"-- =========================================================",
"-- SECURECORP DB - SECOND SEED BATCH",
"-- Appended to securecorp_seed.sql",
"-- Adds exactly: 209 users, 20 roles, 300 assets, 170 vulnerabilities,",
"-- 290 incidents and 1100 audit events, plus supporting relationships.",
"-- =========================================================",
"BEGIN;",
""
]

lines.append("-- ADDITIONAL USERS (209)")
for u in users:
    lines.append(f"INSERT INTO \"USER\" (user_id,full_name,corporate_email,department,employment_status,start_date) VALUES "
                 f"({u[0]},{q(u[1])},{q(u[2])},{q(u[3])},{q(u[4])},{q(u[5])});")
lines.append("")

lines.append("-- ADDITIONAL ROLES (20, total role catalogue becomes 34)")
for i,(name,desc) in enumerate(roles,ROLE_START):
    lines.append(f"INSERT INTO ROLE (role_id,role_name,description) VALUES ({i},{q(name)},{q(desc)});")
lines.append("")

# Add permissions needed by the new roles, so roles are meaningful.
new_perms = [
("platform.manage","Manage internal platform services."),
("cloud.manage","Manage cloud infrastructure resources."),
("pipeline.manage","Manage CI/CD pipelines and deployment automation."),
("threat_hunt.execute","Run authorized proactive threat-hunting activities."),
("iam.manage","Manage identity lifecycle and authentication controls."),
("security_architecture.review","Review security architecture and design controls."),
("forensics.read","Access forensic evidence and investigation records."),
("pentest.execute","Execute authorized penetration testing activities."),
("vendor.manage","Manage vendor and procurement security workflows."),
("privacy.review","Review privacy controls and data handling practices.")
]
lines.append("-- ADDITIONAL PERMISSIONS")
for i,(name,desc) in enumerate(new_perms,PERM_START):
    lines.append(f"INSERT INTO PERMISSION (permission_id,permission_name,description) VALUES ({i},{q(name)},{q(desc)});")
lines.append("")

# New role permissions, realistic privilege boundaries.
role_perm = {
15:[1,5,7,8,18,24], 16:[1,5,6,7,8,17,25], 17:[1,5,7,8,18,26],
18:[1,5,7,8,10,11,12,13], 19:[1,5,7,8,10,11,12,13,14],
20:[1,5,7,8,10,11,12,13,14,27], 21:[1,5,7,8,9,10,11,28],
22:[1,3,5,7,8,10,11,29], 23:[1,3,5,7,8,9,10,11,12,13,14,30],
24:[1,3,5,7,8,10,11,12,13,14,21,31], 25:[1,3,5,7,8,10,11,12,13,14,32],
26:[1,5,7,8,10,11,14,33], 27:[1,5,7,8,10,11,12,13,14,34],
28:[1,3,5,7,8,14,21,35], 29:[1,3,5,7,14,21,22,33,36],
30:[1,3,5,7,19,37], 31:[1,3,5,7,22,38], 32:[1,3,5,7,10,11,14,39],
33:[1,3,5,7,19,20,21,40], 34:[1,3,5,7,14,20,21,22,40]
}
lines.append("-- ROLE_PERMISSION for additional roles")
for rid,pids in role_perm.items():
    for pid in pids:
        gd=date(2024,1,1)+timedelta(days=random.randint(0,900))
        lines.append(f"INSERT INTO ROLE_PERMISSION(role_id,permission_id,granted_date) VALUES ({rid},{pid},{q(gd)});")
lines.append("")

# New assets, strongly skewed toward production but with useful lower environments.
asset_types = (
    [("server","production")]*72 + [("application","production")]*46 + [("database","production")]*25 +
    [("network_device","production")]*24 + [("cloud_resource","production")]*38 + [("workstation","production")]*15 +
    [("server","staging")]*16 + [("application","staging")]*12 + [("database","staging")]*4 +
    [("server","development")]*14 + [("application","development")]*14 +
    [("workstation","test")]*10 + [("server","test")]*5 + [("application","test")]*5
)
asset_names={
"server":["ERP Application","Identity Service","File Server","Monitoring Server","Backup Server","Log Collector",
"VPN Server","Mail Relay","API Gateway","CI Runner","Bastion Host","DNS Resolver","Patch Server","Jump Server"],
"application":["Customer Portal","Partner Portal","Identity API","Payment API","HR Portal","Finance API",
"Mobile API","Document Service","Notification Service","CRM","Reporting Platform","Vendor Portal","Order Service"],
"database":["ERP Database","Finance Database","HR Database","Customer Database","Audit Database","Analytics Database",
"Identity Database","Logging Database","Reporting Database"],
"network_device":["Core Switch","Distribution Switch","Perimeter Firewall","VPN Gateway","Wireless Controller","Edge Router"],
"cloud_resource":["AWS S3 Data Lake","AWS EC2 Workload","AWS RDS Database","AWS EKS Cluster","AWS CloudFront",
"AWS Secrets Store","AWS Backup Vault","AWS Lambda Function","Azure Blob Archive"],
"workstation":["Finance Workstation","SOC Workstation","Developer Workstation","Executive Laptop","HR Workstation","Operations Laptop"]
}
asset_rows=[]
for aid,(typ,env) in enumerate(asset_types,ASSET_START):
    prefix={"server":"SRV","application":"APP","database":"DB","network_device":"NET","cloud_resource":"CLOUD","workstation":"WKST"}[typ]
    identifier=f"{prefix}-{aid:04d}"
    name=f"{random.choice(asset_names[typ])} {aid-129}"
    if env!="production": name += f" [{env}]"
    dept = random.choice(departments)
    if typ=="network_device": dept="IT Infrastructure"
    elif typ=="database": dept=random.choices(["IT Infrastructure","Data & Analytics","Finance","Cybersecurity"],[4,4,2,1])[0]
    elif typ=="application": dept=random.choices(["Software Engineering","Product","Operations","Finance","Customer Success"],[6,2,2,1,2])[0]
    elif typ=="cloud_resource": dept=random.choices(["IT Infrastructure","Software Engineering","Cybersecurity","Data & Analytics"],[4,4,2,2])[0]
    elif typ=="workstation": dept=random.choice(["Finance","Human Resources","Sales","Executive","Operations","Software Engineering"])
    owner=random.choice([u[0] for u in users if u[3]==dept])
    life=random.choices(["active","decommissioned","planned"],[93,5,2])[0]
    asset_rows.append((aid,identifier,name,typ,env,life,owner))
lines.append("-- ADDITIONAL ASSETS (300)")
for a in asset_rows:
    lines.append(f"INSERT INTO ASSET(asset_id,asset_identifier,name,asset_type,environment,lifecycle_status,owner_user_id) VALUES "
                 f"({a[0]},{q(a[1])},{q(a[2])},{q(a[3])},{q(a[4])},{q(a[5])},{a[6]});")
lines.append("")

# Tags for new assets. Existing tag IDs 1-20.
lines.append("-- ASSET_TAG relationships for additional assets")
for a in asset_rows:
    aid,identifier,name,typ,env,life,owner=a
    candidates={1 if env=="production" else 3}
    if typ in ("application","cloud_resource"): candidates.update([5,14])
    if typ=="database": candidates.update([7,13])
    if typ in ("server","workstation"): candidates.update([9,10])
    if typ=="cloud_resource": candidates.update([11])
    if life=="decommissioned": candidates.add(15)
    if random.random()<.10: candidates.add(16)
    for tid in random.sample(list(candidates), random.randint(1,min(4,len(candidates)))):
        lines.append(f"INSERT INTO ASSET_TAG(asset_id,tag_id) VALUES ({aid},{tid});")
lines.append("")

# Vulnerabilities
templates=[
("Broken object-level authorization allows access to another tenant's record","critical","Manual security test"),
("Authentication endpoint lacks effective rate limiting","medium","Burp Suite"),
("Outdated third-party dependency with known security advisory","medium","SCA pipeline"),
("Public cloud storage resource exposes internal documents","high","Cloud posture scan"),
("Administrative endpoint lacks authorization enforcement","critical","Manual security test"),
("Legacy TLS protocol remains enabled","medium","Qualys"),
("Operating system package is missing current security patches","high","Nessus"),
("Sensitive information appears in application error responses","low","DAST"),
("Service account has broader privileges than required","high","Configuration review"),
("Stored cross-site scripting in internal workflow","high","DAST"),
("Excessive user information returned by API endpoint","low","API review"),
("Internet-facing management interface exposes unnecessary service","critical","External scan"),
("Weak session invalidation after password reset","high","Manual security test"),
("Cloud workload uses overly permissive security group rules","high","Cloud posture scan"),
("Deprecated framework version detected","high","Asset inventory"),
("Database backup is not encrypted according to baseline","medium","Configuration review"),
("Missing audit trail for sensitive administrative operation","medium","Control assessment"),
("JWT verification configuration accepts insecure algorithm","critical","Manual security test"),
("DNS service permits unintended recursive queries","medium","Network assessment"),
("Endpoint software exposes obsolete remote service","high","Nessus")
]
vulns=[]
for vid in range(VULN_START,VULN_START+VULN_N):
    desc,sev,src=random.choice(templates)
    lo,hi={"low":(2.0,3.9),"medium":(4.0,6.9),"high":(7.0,8.9),"critical":(9.0,10.0)}[sev]
    cvss=round(random.uniform(lo,hi),1)
    disc=date(2023,1,1)+timedelta(days=random.randint(0,1330))
    status=random.choices(["open","triaged","closed","false_positive"],
                           {"low":[15,15,62,8],"medium":[25,20,48,7],"high":[31,29,35,5],"critical":[37,34,26,3]}[sev])[0]
    vulns.append((vid,desc,cvss,sev,disc,src,status))
lines.append("-- ADDITIONAL VULNERABILITIES (170)")
for v in vulns:
    lines.append(f"INSERT INTO VULNERABILITY(vulnerability_id,description,cvss_base_score,severity,discovery_date,discovery_source,status) VALUES "
                 f"({v[0]},{q(v[1])},{v[2]},{q(v[3])},{q(v[4])},{q(v[5])},{q(v[6])});")
lines.append("")

# New vulnerability-asset findings, enough for meaningful analytics.
va_rows=[]
vaid=VA_START
for v in vulns:
    sev=v[3]
    n=random.choices([1,2,3,4,5,6,8,10],[34,24,17,10,7,4,3,1])[0]
    if sev=="critical": n=random.choices([1,2,3],[65,27,8])[0]
    for a in random.sample(asset_rows,min(n,len(asset_rows))):
        det=max(v[4],date(2023,1,1))+timedelta(days=random.randint(0,600))
        if det>date(2026,8,31): det=date(2026,8,31)
        fs=random.choices(["open","remediated","risk_accepted","false_positive"],
                          [42,37,15,6])[0]
        va_rows.append((vaid,v[0],a[0],random.choice(["1.4.2","2.3.8","3.7.1","4.2.0","5.9.4","7.1.3"]),det,fs))
        vaid+=1
lines.append("-- VULNERABILITY_ASSET relationships")
for r in va_rows:
    lines.append(f"INSERT INTO VULNERABILITY_ASSET(vuln_asset_id,vulnerability_id,asset_id,affected_version,detection_date,finding_status) VALUES "
                 f"({r[0]},{r[1]},{r[2]},{q(r[3])},{q(r[4])},{q(r[5])});")
lines.append("")

# New incidents exactly 290.
incident_templates=[
("Repeated failed authentication attempts against identity service","SIEM"),
("Suspicious PowerShell execution detected on endpoint","EDR"),
("Unexpected outbound traffic from production workload","Network IDS"),
("Potential credential compromise reported by employee","Service Desk"),
("Malware detection on managed endpoint","EDR"),
("Authentication anomaly detected on API gateway","WAF"),
("Database account executed unusual administrative query","Database audit"),
("Phishing campaign reported by multiple employees","Email security"),
("External scanning activity against perimeter","Firewall"),
("Cloud resource access deviated from baseline","Cloud monitoring"),
("Privileged role assignment triggered monitoring alert","IAM monitoring"),
("Possible data exfiltration pattern detected","DLP"),
("Configuration drift detected on critical server","Configuration monitoring")
]
incidents=[]
for iid in range(INC_START,INC_START+INC_N):
    desc,src=random.choice(incident_templates)
    sev=random.choices(["low","medium","high","critical"],[45,35,16,4])[0]
    dt=datetime(2024,1,1)+timedelta(days=random.randint(0,985),hours=random.randint(0,23),minutes=random.randint(0,59))
    status=random.choices(["open","investigating","contained","resolved","closed"],[8,20,12,37,23])[0]
    incidents.append((iid,dt,src,sev,desc,status))
lines.append("-- ADDITIONAL INCIDENTS (290)")
for i in incidents:
    lines.append(f"INSERT INTO INCIDENT(incident_id,detection_time,reporting_source,severity,description,status) VALUES "
                 f"({i[0]},{q(i[1])},{q(i[2])},{q(i[3])},{q(i[4])},{q(i[5])});")
lines.append("")

# Supporting incident asset links and vulnerability links.
lines.append("-- INCIDENT_ASSET relationships")
iaid=IA_START
for inc in incidents:
    iid,dt,src,sev,desc,status=inc
    n=random.choices([1,2,3,4],[57,29,11,3])[0]
    for j,a in enumerate(random.sample(asset_rows,n)):
        role="source" if j==0 and random.random()<0.45 else random.choice(["impacted","compromised","other"])
        impact=random.choices(["low","medium","high","critical"],[35,40,20,5])[0]
        containment=random.choices(["not_contained","contained","isolated"],[42,37,21])[0]
        lines.append(f"INSERT INTO INCIDENT_ASSET(incident_asset_id,incident_id,asset_id,asset_role,impact_level,containment_status) VALUES "
                     f"({iaid},{iid},{a[0]},{q(role)},{q(impact)},{q(containment)});")
        iaid+=1
lines.append("")

lines.append("-- INCIDENT_VULNERABILITY relationships")
ivid=IV_START
for inc in incidents:
    iid,dt,src,sev,desc,status=inc
    if random.random()<0.37:
        candidates=[v for v in vulns if v[3] in (["critical","high"] if sev in ("critical","high") else ["low","medium","high"])]
        for v in random.sample(candidates,min(len(candidates),random.choice([1,1,1,2]))):
            confirmed=(sev in ("critical","high") and v[3] in ("critical","high") and random.random()<.58)
            linked=dt.date()+timedelta(days=random.randint(0,35))
            if linked>date(2026,8,31): linked=date(2026,8,31)
            note=random.choice(["Correlation identified during investigation.","Potential contributing weakness confirmed by review.",
                                 "Finding matched observed attack path.","No direct exploitation evidence established."])
            lines.append(f"INSERT INTO INCIDENT_VULNERABILITY(incident_vulnerability_id,incident_id,vulnerability_id,exploitation_confirmed,linked_date,notes) VALUES "
                         f"({ivid},{iid},{v[0]},{str(confirmed).upper()},{q(linked)},{q(note)});")
            ivid+=1
lines.append("")

# Incident status history.
lines.append("-- INCIDENT_STATUS_HISTORY")
shid=SH_START
for inc in incidents:
    iid,dt,src,sev,desc,target=inc
    actor=random.choice(users)[0]
    lines.append(f"INSERT INTO INCIDENT_STATUS_HISTORY(status_history_id,incident_id,old_status,new_status,changed_at,changed_by_user_id) VALUES "
                 f"({shid},{iid},NULL,'open',{q(dt)},{actor});")
    shid+=1
    current="open"
    transitions={"open":"investigating","investigating":"contained","contained":"resolved","resolved":"closed"}
    while current!=target and current in transitions:
        nxt=transitions[current]
        changed=dt+timedelta(hours=random.randint(1,96))
        actor=random.choice(users)[0]
        lines.append(f"INSERT INTO INCIDENT_STATUS_HISTORY(status_history_id,incident_id,old_status,new_status,changed_at,changed_by_user_id) VALUES "
                     f"({shid},{iid},{q(current)},{q(nxt)},{q(changed)},{actor});")
        shid+=1
        current=nxt
lines.append("")

# Additional audit events exactly 1100.
lines.append("-- ADDITIONAL AUDIT_LOG EVENTS (1100)")
actions=["create","update","delete","login","export","other"]
entities=["USER","ROLE","ROLE_ASSIGNMENT","ASSET","VULNERABILITY","VULNERABILITY_ASSET","INCIDENT",
          "REMEDIATION","RISK_ACCEPTANCE","ACCESS_RECERTIFICATION"]
for aid in range(AUDIT_START,AUDIT_START+AUDIT_N):
    actor=random.choice(users)
    action=random.choices(actions,[12,34,3,39,4,8])[0]
    entity=random.choice(entities)
    maxid={"USER":293,"ROLE":34,"ROLE_ASSIGNMENT":400,"ASSET":429,"VULNERABILITY":230,
           "VULNERABILITY_ASSET":max(VA_START+len(va_rows)-1,VA_START),"INCIDENT":365,
           "REMEDIATION":500,"RISK_ACCEPTANCE":400,"ACCESS_RECERTIFICATION":400}[entity]
    rid=str(random.randint(1,maxid))
    ts=datetime(2024,1,1)+timedelta(days=random.randint(0,985),hours=random.randint(0,23),minutes=random.randint(0,59),seconds=random.randint(0,59))
    before=None if action in ("create","login","export") else {"status":"previous","source":"application"}
    after=None if action in ("delete","login") else {"status":"current","source":"application"}
    lines.append(f"INSERT INTO AUDIT_LOG(audit_log_id,acting_user_id,action_timestamp,action_type,entity_type,record_identifier,before_values,after_values) VALUES "
                 f"({aid},{actor[0]},{q(ts)},{q(action)},{q(entity)},{q(rid)},{'NULL' if before is None else js(before)},{'NULL' if after is None else js(after)});")
lines.append("")

# A small realistic set of remediation/risk rows for the newly added findings.
lines.append("-- SUPPORTING REMEDIATION RECORDS")
remid=REM_START
for r in va_rows:
    if r[5]=="remediated":
        rem_date=r[4]+timedelta(days=random.randint(4,160))
        if rem_date>date(2026,8,31): rem_date=date(2026,8,31)
        verified=None
        verifier=None
        if random.random()<.84:
            verified=min(date(2026,8,31),rem_date+timedelta(days=random.randint(1,30)))
            verifier=random.choice(users)[0]
        note=random.choice(["Package upgraded and service restarted.","Authorization check corrected and regression-tested.",
                             "Cloud policy narrowed to required principals.","Deprecated protocol disabled and verified.",
                             "Database privilege reduced to least-privilege baseline."])
        lines.append(f"INSERT INTO REMEDIATION(remediation_id,vuln_asset_id,remediation_note,remediation_date,verified_date,verified_by_user_id) VALUES "
                     f"({remid},{r[0]},{q(note)},{q(rem_date)},{'NULL' if verified is None else q(verified)},{'NULL' if verifier is None else verifier});")
        remid+=1
lines.append("")

lines.append("-- SUPPORTING RISK ACCEPTANCE RECORDS")
riskid=RISK_START
authorities=[u[0] for u in users if u[3] in ("Cybersecurity","Legal & Compliance","Executive","Internal Audit")]
for r in va_rows:
    if r[5]=="risk_accepted":
        acc=max(r[4],date(2024,1,1))
        exp=acc+timedelta(days=random.randint(45,365))
        lines.append(f"INSERT INTO RISK_ACCEPTANCE(risk_acceptance_id,vuln_asset_id,accepting_authority_user_id,justification,acceptance_date,expiration_date) VALUES "
                     f"({riskid},{r[0]},{random.choice(authorities)},{q(random.choice([
                     "Compensating control is active and monitored.",
                     "Vendor dependency prevents immediate remediation.",
                     "Business service requires a scheduled maintenance window.",
                     "Legacy integration is awaiting planned replacement."
                     ]))},{q(acc)},{q(exp)});")
        riskid+=1
lines.append("")

lines += [
"-- Reset sequences to include both seed batches.",
"SELECT setval(pg_get_serial_sequence('\"USER\"','user_id'), COALESCE((SELECT MAX(user_id) FROM \"USER\"),1), true);",
"SELECT setval(pg_get_serial_sequence('role','role_id'), COALESCE((SELECT MAX(role_id) FROM role),1), true);",
"SELECT setval(pg_get_serial_sequence('permission','permission_id'), COALESCE((SELECT MAX(permission_id) FROM permission),1), true);",
"SELECT setval(pg_get_serial_sequence('asset','asset_id'), COALESCE((SELECT MAX(asset_id) FROM asset),1), true);",
"SELECT setval(pg_get_serial_sequence('vulnerability','vulnerability_id'), COALESCE((SELECT MAX(vulnerability_id) FROM vulnerability),1), true);",
"SELECT setval(pg_get_serial_sequence('incident','incident_id'), COALESCE((SELECT MAX(incident_id) FROM incident),1), true);",
"SELECT setval(pg_get_serial_sequence('role_assignment','assignment_id'), COALESCE((SELECT MAX(assignment_id) FROM role_assignment),1), true);",
"SELECT setval(pg_get_serial_sequence('vulnerability_asset','vuln_asset_id'), COALESCE((SELECT MAX(vuln_asset_id) FROM vulnerability_asset),1), true);",
"SELECT setval(pg_get_serial_sequence('incident_asset','incident_asset_id'), COALESCE((SELECT MAX(incident_asset_id) FROM incident_asset),1), true);",
"SELECT setval(pg_get_serial_sequence('incident_vulnerability','incident_vulnerability_id'), COALESCE((SELECT MAX(incident_vulnerability_id) FROM incident_vulnerability),1), true);",
"SELECT setval(pg_get_serial_sequence('incident_status_history','status_history_id'), COALESCE((SELECT MAX(status_history_id) FROM incident_status_history),1), true);",
"SELECT setval(pg_get_serial_sequence('audit_log','audit_log_id'), COALESCE((SELECT MAX(audit_log_id) FROM audit_log),1), true);",
"SELECT setval(pg_get_serial_sequence('remediation','remediation_id'), COALESCE((SELECT MAX(remediation_id) FROM remediation),1), true);",
"SELECT setval(pg_get_serial_sequence('risk_acceptance','risk_acceptance_id'), COALESCE((SELECT MAX(risk_acceptance_id) FROM risk_acceptance),1), true);",
"COMMIT;",
""
]

append.write_text("\n".join(lines), encoding="utf-8")

print(f"Created: {append}")
print(f"Lines: {len(lines):,}")
print(f"Exact requested additions: users={len(users)}, roles={len(roles)}, assets={len(asset_rows)}, vulnerabilities={len(vulns)}, incidents={len(incidents)}, audit_events={AUDIT_N}")
print(f"Supporting records: vuln_asset={len(va_rows)}, incident_asset={iaid-1}, incident_vulnerability={ivid-1}, incident_history={shid-1}, remediation={remid-REM_START}, risk_acceptance={riskid-RISK_START}")

