# 📋 Jira Daily Summary — n8n Workflow

An automated workflow built with [n8n](https://n8n.io) that sends a daily email summarizing all Jira tickets you worked on the previous day. Designed for QA engineers and developers who need a quick overview of their daily work for timesheet reporting.

---

## ✨ Features

- **Automatic daily email** at 9 AM (configurable) covering the previous working day
- **Smart date logic** — Saturday automatically looks back to Wednesday (skipping Thu/Fri weekends)
- **Three ticket sources** combined into one report:
  - Tickets assigned to you
  - Bugs/tickets you reported
  - Tickets you commented on (even if not assigned to you)
- **Two sections** in the email:
  - ✅ Tickets I Tested
  - 🐛 Bugs I Opened
- **Copy-paste ready** links for timesheet filling
- **No duplicate tickets** across sections
- **Hides canceled bugs** automatically
- **Skips sending** if no tickets were worked on
- **Manual webhook trigger** — run anytime via browser URL
- **Error notification** email if the workflow fails

---

## 🛠️ Tech Stack

- [n8n](https://n8n.io) — Workflow automation
- [Docker](https://www.docker.com) — Local n8n hosting
- [Jira Software Cloud API](https://developer.atlassian.com/cloud/jira/software/) — Ticket data
- [Gmail API (OAuth2)](https://developers.google.com/gmail/api) — Email delivery

---

## 📋 Prerequisites

Before setting up, make sure you have:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed
- A **Jira Cloud** account with API access (`*.atlassian.net`)
- A **Gmail** account
- A **Google Cloud** account (free) for OAuth credentials

---

## 🚀 Setup Guide

### Step 1 — Install & Run n8n with Docker

Open your terminal and run:

```bash
docker run -it --rm --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n
```

Then open your browser and go to:
```
http://localhost:5678
```

Create your n8n account when prompted.

---

### Step 2 — Get Your Jira API Token

1. Go to [https://id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Click **Create API token**
3. Name it `n8n-jira` and copy the token

---

### Step 3 — Set Up Jira Credentials in n8n

1. In n8n, go to **Settings → Credentials → New Credential**
2. Search for **Jira SW Cloud API**
3. Fill in:
   - **Host:** `https://your-domain.atlassian.net`
   - **Email:** your Atlassian account email
   - **API Token:** the token from Step 2
4. Save & Test

---

### Step 4 — Set Up Gmail OAuth Credentials

1. Go to [https://console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project (e.g. `n8n-local`)
3. Go to **APIs & Services → Library** → Enable **Gmail API**
4. Go to **APIs & Services → Credentials → Create Credentials → OAuth Client ID**
5. Configure consent screen (External, fill in app name and your email)
6. Application type: **Web Application**
7. Add redirect URI:
   ```
   http://localhost:5678/rest/oauth2-credential/callback
   ```
8. Copy the **Client ID** and **Client Secret**
9. Go to **OAuth consent screen → Test users** → Add your Gmail address
10. In n8n, go to **Settings → Credentials → New Credential → Gmail OAuth2 API**
11. Paste Client ID and Client Secret → Connect

---

### Step 5 — Find Your Jira Account ID

1. In Jira, click your profile picture → **Profile**
2. Copy the ID from the URL:
   ```
   https://your-domain.atlassian.net/jira/people/YOUR_ACCOUNT_ID
   ```

---

### Step 6 — Import the Workflow

1. In n8n, click **New Workflow → Import from file**
2. Upload the `JIRA Daily Summary.json` file from this repository
3. Open the workflow

---

### Step 7 — Configure the Workflow

After importing, update the following:

#### 7a. Jira Nodes (all 3)
Open each Jira node and select your Jira credential.

#### 7b. Calculate Report Date Node
This node handles the smart date logic. No changes needed unless your weekend days differ from Thu/Fri.

If your weekend is different, update this section:
```javascript
if (dayOfWeek === 6) {
  // Saturday → look back 3 days to Wednesday
  daysBack = 3;
} else {
  daysBack = 1;
}
```
`dayOfWeek` values: 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat

#### 7c. Split & Deduplicate Node
Replace your Account ID:
```javascript
const myAccountId = 'YOUR_ACCOUNT_ID_HERE';
```

Also update your Jira base URL:
```javascript
const link = `https://YOUR-DOMAIN.atlassian.net/browse/${key}`;
```

#### 7d. Tag as Commented Node
Replace your Account ID:
```javascript
const myAccountId = 'YOUR_ACCOUNT_ID_HERE';
```

#### 7e. Send Daily Summary Node
- Set **To** field to your work email
- The subject and body are already configured dynamically

#### 7f. Daily Trigger Node
Set your working days and preferred time. Default is **Sun–Wed at 9 AM**.

---

### Step 8 — Set Up Error Notifications (Optional but Recommended)

1. Create a **new workflow** in n8n
2. Add an **Error Trigger** node
3. Add a **Gmail node** → Send a message to yourself
4. Use this message template:
   ```
   Workflow: {{ $json.workflow.name }}
   Error: {{ $json.execution.error.message }}
   Failed Node: {{ $json.execution.error.node.name }}
   ```
5. **Activate** this error workflow
6. In your main workflow **Settings → Error Workflow**, select this workflow

---

### Step 9 — Activate & Test

1. Click **Publish/Activate** on the main workflow
2. Test the webhook manually by visiting:
   ```
   http://localhost:5678/webhook/jira-report
   ```
3. Check your inbox for the report email

---

## 📧 Email Format

```
📋 Your Jira Summary

✅ Tickets I Tested
• JO26-123 — Ticket Title
  Status: Ready for Production
  https://your-domain.atlassian.net/browse/JO26-123

🐛 Bugs I Opened
• JO26-456 — Bug Title
  Status: To Do
  https://your-domain.atlassian.net/browse/JO26-456

────────────────────
📋 Copy-Paste for Timesheet

I tested:
https://your-domain.atlassian.net/browse/JO26-123

I opened:
https://your-domain.atlassian.net/browse/JO26-456
```

---

## 🔖 Manual Trigger

To get yesterday's report at any time, open this URL in your browser:
```
http://localhost:5678/webhook/jira-report
```

To report on a specific calendar day, supply a valid `YYYY-MM-DD` date query parameter:
```
http://localhost:5678/webhook/jira-report?date=2026-07-21
```

The workflow rejects malformed or impossible dates (for example, `2026-02-30`). It uses the provided date for every Jira query; without `date`, it retains the previous-working-day behavior.

> ⚠️ Docker must be running for this to work.

---

## ⚙️ How the Workflow Detects "Worked On"

The workflow fetches the full **changelog and comments** for each ticket via the Jira API.
A ticket only appears if **you personally performed an action on it** on the report date.

### 🔍 Detection Logic

```
Did YOU comment or change the status today?
├── YES → ✅ Tested
└── NO  → skipped (unless you created it)

Did YOU create/report it today?
├── YES + not Canceled/Ready for QA → 🐛 Bugs
└── NO  → not in Bugs

Did YOU both create it AND act on it today?
└── YES → ✅ Tested + 🐛 Bugs (appears in both)
```

### 📊 Quick Reference

| Situation | ✅ Tested | 🐛 Bugs |
|---|:---:|:---:|
| You changed status or commented today | ✅ | ❌ |
| You created it today (no action yet) | ❌ | ✅ |
| You created it AND acted on it today | ✅ | ✅ |
| Status is `Ready for QA` | ❌ | ❌ |
| Status is `Canceled` / `Cancel` | ❌ | ❌ |
| Developer acted on it, not you | ❌ | ❌ |

> ⚠️ **Important:** The report is based on the **previous working day**, not today.
> Saturday automatically looks back to Wednesday (skipping Thu/Fri weekend).

---

## 📁 Repository Structure

```
├── JIRA Daily Summary.json   # n8n workflow export
└── README.md                 # This file
```

---

## 🔄 Updating Credentials

## Recommended local startup

Docker Desktop must be installed and its engine must be running before n8n can start. The `compose.yaml` in this repository keeps n8n data in the named `n8n_data` volume and configures the Asia/Amman timezone.

The port is deliberately bound to `127.0.0.1`, so the webhook is reachable only from this computer. Do not change it to `5678:5678` unless you also add suitable access controls.

```powershell
Copy-Item .env.example .env
# Edit .env and replace N8N_ENCRYPTION_KEY with a new long random secret.
docker compose up -d
```

Open `http://localhost:5678` and create the new n8n owner account. Import `JIRA Daily Summary.json`, reconnect the Jira and Gmail credentials in the nodes, test the webhook, and only then activate the workflow.

## Back up n8n data

Run this from PowerShell in the repository folder whenever you make an important n8n change:

```powershell
.\backup-n8n.ps1
```

The archive is saved in `backups/`, which is intentionally excluded from Git. Keep both the archive and the `.env` encryption key somewhere safe; the backup contains credentials encrypted with that key.

---

If your Gmail OAuth token expires:
1. Open the **Send Daily Summary** node
2. Click the credential field → edit
3. Click **Reconnect** and sign in again

---

## 👤 Author

Built by **Odai Mohammad** — Junior QA Officer  
[LinkedIn](https://linkedin.com/in/your-profile) · [GitHub](https://github.com/your-username)

---

## 📄 License

MIT License — free to use, modify, and share.
