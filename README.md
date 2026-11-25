# GxP Compliance Assessment System

Pharma Connections (Eduteq Connections Pvt. Ltd.) · Version 3.1

Web application for assessing **equipment / instruments, stand-alone and networked computerised systems** against **21 CFR Part 11, EU GMP Annex 11, data integrity (ALCOA+) and GDPR**, approving the assessment with electronic signatures, tracking the resulting CAPA, and showing the compliance position on a **live dashboard** that can be **shared with clients through a link**.

- **Frontend:** React 18, React Router, Recharts, Vite
- **Backend:** Node.js 18+ and Express, with Server-Sent Events for live updates
- **Database:** SQLite (default, no setup) or PostgreSQL (`DATABASE_URL`), with Knex migrations
- **Reports:** Word (.docx) controlled-document report, and CSV registers

---

## 1. What it does

| Area | Description |
|---|---|
| **Login gateway and roles** | Unique accounts, role-based access: **Contributor, Reviewer, Approver**, Viewer and Admin. Password policy, expiry and history, lockout, idle timeout, forced change after reset, privacy notice acknowledgement at first login |
| **Equipment and system register** | Four system classes: equipment / instrument (firmware only), instrument with stand-alone PC software, stand-alone computerised system, and networked system. Records USP <1058> group, manufacturer, model, serial number, asset ID, firmware, software, OS, connected PC, data storage, location, regulatory markets and personal data |
| **Unified control library** | 97 controls in 12 domains, each cross-referenced to Part 11 clauses, Annex 11 sections, ALCOA+ attributes and GDPR articles, with expected evidence and risk rating. Exported in `docs/control_library.csv` |
| **Scoped assessments** | Frameworks are suggested from the register (markets, personal data) and can be changed with a justification for each exclusion. Controls are filtered for the system class (56 for a firmware-only instrument, up to 95 for an instrument with PC software). A control that maps to several frameworks is assessed once |
| **Scoring** | Score per framework and per domain: (Yes + 0.5 × Partial) / (Yes + Partial + No), N/A excluded. A framework is "Not compliant" when a critical observation is open against one of its controls |
| **Workflow and e-signatures** | Draft → Under Review → Pending Approval → Approved. Each step signed with user ID and password, showing name, date/time and meaning. Return to Draft withdraws signatures. Approved assessments are revised into new versions for periodic review |
| **Evidence** | Files attached per control, stored with a SHA-256 checksum that is checked on every download |
| **CAPA** | Each observation becomes a CAPA record on approval. Open → In Progress → Pending Closure → Closed (Approver e-signature) |
| **Live dashboard** | Power BI-style analytics: overall score gauge, coverage, open and overdue CAPA, compliance status donut, framework scores, workflow, domain × framework heat map, CAPA by class and age, 12-month trend, score by system class, system risk ranking. Slicers for site, system class and framework. Updates by itself when anyone changes data |
| **Client share links** | Approver or Admin creates a link with an optional fixed scope and expiry. The client opens it without logging in and sees the same live dashboard, read-only, with aggregated data and no personal data. Links can be revoked; creation, revocation and view counts are recorded |
| **Audit trail** | Every create, change, signature, login, export, share and setting change. Append-only at database level, hash-chained, integrity check button, CSV export |
| **GDPR features of the application** | Privacy notice and acknowledgement, "Privacy and my data" self-service export (Art 15 / 20), data subject request register with one-month due dates, pseudonymisation of former users, retention of session records, no tracking cookies |

## 2. Roles

| Role | Can do |
|---|---|
| **Contributor** | Register equipment and systems, create and fill in assessments, attach evidence, sign "Prepared by", create new versions, work on CAPA |
| **Reviewer** | Review and sign "Reviewed by", or return to Draft; work on CAPA assigned to them |
| **Approver** | Approve, or return to Draft; verify and close, reject or cancel CAPA; create and revoke client dashboard links; view the system audit trail |
| **Viewer** | Read-only access (for example internal auditors) |
| **Admin** | Users, sessions, privacy requests, pseudonymisation, settings, client links, audit trail. Cannot sign assessments |

The same person can never sign one assessment in two roles.

---

## 3. Quick start (local, SQLite)

Needs Node.js 18 or later.

```bash
npm run install:all
npm run build
npm start
```

Open http://localhost:4000.

On an empty database the server creates demo accounts and four example instruments and systems:

| User ID | Role | Password |
|---|---|---|
| admin | Admin | Welcome@123 |
| contributor | Contributor | Welcome@123 |
| reviewer | Reviewer | Welcome@123 |
| approver | Approver | Welcome@123 |
| viewer | Viewer | Welcome@123 |

To fill the dashboard with example assessments, signatures and CAPA (through the normal workflow), run this in a second terminal while the server is running:

```bash
npm run demo-data
```

Development with hot reload: `npm run dev:server` (API on port 4000) and `npm run dev:client` (UI on http://localhost:5173).

Tests: `npm test` (login and privacy gate, roles, register, scoped assessment and scoring, signatures, CAPA, live analytics, client share links, GDPR features, audit trail integrity, session timeout). Set `DATABASE_URL` to an empty database to run them on PostgreSQL.

---

## 4a. Deploy on Vercel from GitHub

See **[DEPLOY_VERCEL.md](DEPLOY_VERCEL.md)**: GitHub repository, Vercel project import, Neon PostgreSQL, private Vercel Blob for evidence files, environment variables, client links on your own domain.

## 4b. Production on your own server (Docker + PostgreSQL)

```bash
cp .env.example .env        # set POSTGRES_PASSWORD and INITIAL_ADMIN_PASSWORD
docker compose up -d --build
```

Log in as `admin` with `INITIAL_ADMIN_PASSWORD`, change the password, acknowledge the privacy notice and create named users.

- Run behind HTTPS (nginx, Traefik or a cloud load balancer) and set `TRUST_PROXY=true`. The live stream uses Server-Sent Events: disable response buffering for `/api/dashboard/stream` and `/api/public/share/*/stream` (`proxy_buffering off;` in nginx).
- Client links use the address the Approver sees in the browser, so publish the application on its public HTTPS address before sharing links.
- Back up the database and the uploads volume together. Keep the server clock on NTP.
- Run `npm run verify-audit` (or Audit Trail → Verify integrity) during periodic review.

## 5. Configuration

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | 4000 | HTTP port |
| `DATABASE_URL` | (empty) | PostgreSQL connection string. Empty = SQLite |
| `DATA_DIR` | server/data | SQLite file and evidence files |
| `SEED_DEMO_USERS` | true | On an empty database: demo accounts and example systems (`true`), or only `admin` (`false`) |
| `INITIAL_ADMIN_PASSWORD` | random | Admin password when `SEED_DEMO_USERS=false` |
| `MAX_UPLOAD_MB` | 20 | Evidence file size limit |
| `DISPLAY_TZ` / `DISPLAY_TZ_LABEL` | Asia/Kolkata / IST | Time zone in Word reports |
| `TRUST_PROXY` | false | `true` behind a reverse proxy (automatic on Vercel) |
| `BLOB_READ_WRITE_TOKEN` | (empty) | Store evidence in a private Vercel Blob store instead of local disk |
| `LIVE_MODE` | push (poll on Vercel) | `poll` watches the database for changes, needed when several server instances run |
| `CRON_SECRET` | (empty) | Protects `/api/cron/purge` (Vercel Cron) |

In the application (Administration → Settings, each change audited with a reason): company and site, session timeout, lockout threshold, password length, expiry and history, periodic review interval, number prefixes, session record retention, and the data protection contact shown in the privacy notice.

---

## 6. How the application itself meets the requirements

### 21 CFR Part 11 and EU GMP Annex 11

| Requirement | Implementation |
|---|---|
| Part 11 §11.10(a), Annex 11 §4 | Server-side validation of all input and workflow; record hash with each signature; evidence checksums; audit trail hash chain. The user organisation validates the installation (section 8) |
| §11.10(b), Annex 11 §8 | Word report with all controls, responses, evidence references, signatures and revision history; CSV registers |
| §11.10(c), Annex 11 §7, §17 | Relational database; no delete functions for assessments, signatures, users or audit entries; superseded versions kept |
| §11.10(d), (g), Annex 11 §12 | Unique accounts, role checks on every API route, scrypt password hashes, hashed session tokens, idle timeout, login rate limit |
| §11.10(e), Annex 11 §9 | Audit trail of who, when, field, old and new value, reason, IP. Database triggers block UPDATE and DELETE; each entry carries the hash of the previous one |
| §11.10(f) | Workflow sequence enforced on the server |
| §11.50, §11.70, Annex 11 §14 | Printed name, date/time and meaning on screen and in the report; signatures bound to record content; return to Draft withdraws signatures |
| §11.100, §11.200, §11.300 | User IDs never reused; identity verification reference at user creation; user ID and password at every signing; passwords unknown to admins; password expiry and history; lockout after failed login or signature attempts |
| Annex 11 §10, §11 | Settings changes need a reason and are audited; periodic review due date per approved assessment |

### GDPR (the application as a processor of user data)

| Article | Implementation |
|---|---|
| Art 5(1)(c) minimisation | Only user ID, name, role, designation, department and optional e-mail. Client share links contain no personal data |
| Art 5(1)(e) storage limitation | Ended session records (IP, browser) deleted after the retention period (default 90 days) |
| Art 5(1)(f), Art 32 security | Hashed passwords and tokens, role-based access, lockout, timeout, security headers, no third-party scripts or tracking cookies |
| Art 12-14 transparency | Privacy notice shown and acknowledged at first login, and whenever its version changes |
| Art 15, Art 20 access and portability | Every user downloads their own data as JSON under "Privacy and my data" |
| Art 16-18 rectification, erasure, restriction | Data subject request register (Admin) with one-month due date; pseudonymisation of a former user's profile |
| Art 17(3)(b) | Signatures (printed name required by Part 11 and Annex 11) and audit entries are kept as a legal obligation. Audit entries store only the user ID; names are resolved from the profile, so pseudonymisation also applies to the displayed audit trail |
| Art 25 by design and default | Personal data visible only to roles that need it; analytics for clients are aggregated |
| Art 30 records of processing | The processing is described in the privacy notice and in this section for inclusion in the company ROPA |

## 7. Maintenance commands

```bash
npm run verify-audit --prefix server     # audit trail hash chain check (exit code 2 if broken)
npm run migrate --prefix server          # apply migrations
npm run seed --prefix server             # first accounts on an empty database
npm run demo-data                        # example data through the API (demo installations only)
```

## 8. Before GxP use

1. Supplier assessment and risk-based validation of the installation (GAMP 5 Category 4), including the control library content against your procedures.
2. SOPs for user access, audit trail review, backup and restore, periodic review, client link sharing and data subject requests.
3. FDA electronic signature certification letter (§11.100(c)) where signatures support FDA-regulated records.
4. `SEED_DEMO_USERS=false`, HTTPS, and settings under change control. Add the application to the record of processing activities.
5. The control library reflects EU GMP Annex 11 (2011). The revised Annex 11 was released for consultation in 2025; review the library when the final version is published.

## 9. Project layout

```
server/src/
  app.js, index.js, cli.js      Express app, startup, maintenance commands
  db.js, migrations/            Knex (SQLite / PostgreSQL) and schema
  controls.js                   control library, frameworks, system classes, scoring
  lib/                          audit trail, analytics, live events, security, settings
  middleware/auth.js            session, role, password-change and privacy gates
  routes/                       auth, users, settings, systems, assessments, capa, dashboard, share, privacy
  export.js                     Word report
server/scripts/demo-data.js     example data through the API
api/index.js, vercel.json       Vercel serverless entry and routing
server/test/api.test.js         API test suite
client/src/
  pages/                        Dashboard, PublicDashboard, Systems, Assessments, AssessmentEditor, Capa, Shares, AuditTrail, Admin, Privacy, Login
  components/                   DashboardView (charts), live data hook, dialogs and e-signature
docs/control_library.csv        all controls with references
docs/screenshots/
```
