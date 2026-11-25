# Deploying on Vercel from GitHub

This guide puts the GxP Compliance Assessment System online at an address like `https://gxp-compliance.vercel.app`, with automatic redeployment every time you push to GitHub.

**What runs where on Vercel**

| Part | Service | Created in step |
|---|---|---|
| React application (pages, dashboard) | Vercel static hosting | 3 |
| API (login, assessments, CAPA, sharing) | Vercel Function `api/index.js` | 3 |
| Database | Neon PostgreSQL (Vercel Marketplace) | 4 |
| Evidence files | Vercel Blob, private store | 5 |
| Nightly clean-up of old session records | Vercel Cron | automatic (`vercel.json`) |

You need a GitHub account and a Vercel account (sign up at vercel.com with "Continue with GitHub").

---

## Step 1. Put the code on GitHub

### Option A: GitHub website (no tools needed)

1. Go to https://github.com/new. Name the repository, for example `gxp-compliance-assessment`, choose **Private**, and click **Create repository**.
2. On the next page click **uploading an existing file**.
3. Unzip the project on your computer, open the `gxp-compliance` folder, select everything inside it (including the hidden `.gitignore` file) and drag it into the browser. Do not upload any `node_modules` folders.
4. Click **Commit changes**.

### Option B: Git command line

The zip already contains a Git repository with one commit.

```bash
cd gxp-compliance
git remote add origin https://github.com/<your-account>/gxp-compliance-assessment.git
git push -u origin main
```

Create the empty repository on GitHub first (step A.1, without adding a README).

---

## Step 2. Before deploying, decide the first login

Pick a strong temporary password for the first administrator, for example `Change.Me.2026!`. You will enter it in step 6 as `INITIAL_ADMIN_PASSWORD`. The `admin` account must change it at first login.

For a **demo** installation instead, you can use `SEED_DEMO_USERS=true`, which creates `admin`, `contributor`, `reviewer`, `approver` and `viewer` with password `Welcome@123` plus example equipment. Do not use demo accounts on an installation that holds real records.

---

## Step 3. Import the repository into Vercel

1. In Vercel, click **Add New... > Project**.
2. Under **Import Git Repository**, choose your GitHub account and the repository. If it is not listed, click **Adjust GitHub App Permissions** and give Vercel access to it.
3. On the configuration screen:
   - **Framework Preset:** Other
   - **Root Directory:** leave as `./`
   - Build and output settings: leave them alone. They are set in `vercel.json` (build command `npm run vercel-build`, output `client/dist`).
4. **Do not click Deploy yet.** First add the database and storage (steps 4 and 5) and the environment variables (step 6). If you already deployed, that is fine: the first deployment fails with "DATABASE_URL is not set"; finish the steps below and redeploy.

---

## Step 4. Add the database (Neon PostgreSQL)

1. Open the project in Vercel and go to the **Storage** tab.
2. Click **Create Database**, choose **Neon** (Serverless Postgres) and follow the prompts. Choose a region close to your users (for India, Singapore `ap-southeast-1` is usually closest).
3. When asked, **connect it to this project** for the Production and Preview environments.

Vercel adds `DATABASE_URL` (and related variables) to the project automatically. Tables are created on the first request after deployment.

---

## Step 5. Add evidence file storage (Vercel Blob)

1. In the **Storage** tab click **Create Database** again and choose **Blob**.
2. Set the access to **Private**. Evidence files are then never reachable by URL; they are served only through the application after login and checksum verification.
3. Connect the store to this project. Vercel adds `BLOB_READ_WRITE_TOKEN`.

Without a Blob store, uploads go to temporary function storage and are **lost**. Always add the Blob store.

---

## Step 6. Environment variables

Project **Settings > Environment Variables**. Add these for **Production** (and Preview if you use previews):

| Name | Value | Notes |
|---|---|---|
| `SEED_DEMO_USERS` | `false` | `true` only for a demo installation |
| `INITIAL_ADMIN_PASSWORD` | your temporary password | used once, when the database is empty |
| `CRON_SECRET` | a long random string (for example from a password generator) | protects the nightly clean-up job |
| `DISPLAY_TZ` | `Asia/Kolkata` | optional, time zone in Word reports |
| `DISPLAY_TZ_LABEL` | `IST` | optional |

`DATABASE_URL` and `BLOB_READ_WRITE_TOKEN` are already there from steps 4 and 5.

---

## Step 7. Deploy and log in

1. Go to **Deployments** and click **Redeploy** (or **Deploy** on the import screen).
2. When the deployment is ready, open the address Vercel shows.
3. Log in with user ID `admin` and the `INITIAL_ADMIN_PASSWORD`. Change the password, read and acknowledge the privacy notice.
4. Go to **Administration > Settings** and set the company name, site and data protection contact.
5. Create named users under **Administration > Users** (Contributor, Reviewer, Approver, Viewer).

The first request after a quiet period takes a few seconds longer while the function starts.

### Optional: load demo data

On a demo installation (`SEED_DEMO_USERS=true`), run this on your computer from the project folder to fill the dashboard through the normal workflow:

```bash
npm install
APP_URL=https://<your-project>.vercel.app npm run demo-data
```

---

## Step 8. Share the dashboard with a client

Log in as an Approver or Admin, open **Client Links**, click **Create link**, choose the scope and expiry, and copy the link. It looks like `https://<your-project>.vercel.app/share/<token>`. The client opens it without logging in. Revoke it on the same page when it is no longer needed.

To use your own domain (for example `compliance.pharmaconnections.in`), go to **Settings > Domains**, add the domain and create the DNS record Vercel shows. Create client links after the domain is set up, because links use the address you are logged in on.

---

## Updating the application

Push changes to the `main` branch on GitHub. Vercel builds and deploys automatically, and database migrations run on the first request.

Pushes to other branches create **preview deployments**. By default they use the same database as production. To keep test data out of production, scope `DATABASE_URL` to Production only and connect a separate Neon branch for Preview (Neon offers this in the integration settings).

---

## Differences from a server installation

| Topic | On Vercel |
|---|---|
| Evidence file size | Up to 4 MB per file (Vercel request limit). Use the Docker installation for larger files |
| Live dashboard | Updates within about 4 seconds of a change. The browser reconnects to the live stream every 4 minutes, which is normal |
| Function time limit | 300 seconds per request (`vercel.json`). Word reports take a few seconds |
| Session clean-up | Daily at 01:30 UTC through Vercel Cron |
| Login rate limit | Counted per function instance |
| Backups | Use Neon's point-in-time restore for the database and keep the Blob store. Test a restore as part of periodic review |

### Vercel plan

Vercel's free Hobby plan is for personal, non-commercial use. For an installation used with clients or for regulated work, use a **Pro** (or Enterprise) plan, which also gives longer function limits, more cron jobs and team access controls.

### GxP note

Hosting on Vercel and Neon makes them service providers under EU Annex 11 §3 and processors under GDPR Art 28. Before regulated use, record the supplier assessment, check the data processing agreements and data location (choose the Neon and Vercel function region accordingly), and include the deployment configuration (`vercel.json`, environment variables, regions) in your validation and change control.

---

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| Page loads but login says "The application could not start: DATABASE_URL is not set" | Step 4 not done, or the database is not connected to this environment. Connect it and redeploy |
| Build fails at `vercel-build` | Check that the whole project was uploaded, including `client/package.json`, `client/package-lock.json` and `vercel.json` |
| "This link is not valid" on a client link | The link was revoked, has expired, or was created on a different deployment address |
| Uploaded evidence later shows "stored file is missing" | The Blob store was not connected when the file was uploaded (step 5) |
| Cannot log in as admin on a new deployment | The database already had users from an earlier deployment; `INITIAL_ADMIN_PASSWORD` is used only on an empty database. Use the earlier password, or reset via another administrator |
| Function logs show "Migration table is already locked" | Two instances started at once. It resolves on the next request |
