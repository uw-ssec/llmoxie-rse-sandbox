# GitHub Codespaces API Research for Agent Debugging

**Issue:** UWS-97  
**Status:** Research complete  
**Date:** 2026-05-07

---

## Table of Contents

1. [GitHub Codespaces REST API](#1-github-codespaces-rest-api)
2. [GitHub CLI `gh codespace` Capabilities](#2-github-cli-gh-codespace-capabilities)
3. [Authentication, Scopes, and Organization Policies](#3-authentication-scopes-and-organization-policies)
4. [Debugging Workflows for Common Failures](#4-debugging-workflows-for-common-failures)
5. [Recommended Agent Interface](#5-recommended-agent-interface)
6. [Gaps Requiring Human or Admin Intervention](#6-gaps-requiring-human-or-admin-intervention)

---

## 1. GitHub Codespaces REST API

**Reference:** https://docs.github.com/en/rest/codespaces/codespaces

### 1.1 Core Lifecycle Endpoints

All endpoints require `Authorization: Bearer <token>` and `Accept: application/vnd.github+json`.

| Operation | Method | Path |
|-----------|--------|------|
| List user's codespaces | GET | `/user/codespaces` |
| Create codespace (user) | POST | `/user/codespaces` |
| Get codespace | GET | `/user/codespaces/{codespace_name}` |
| Update codespace | PATCH | `/user/codespaces/{codespace_name}` |
| Delete codespace | DELETE | `/user/codespaces/{codespace_name}` |
| Start codespace | POST | `/user/codespaces/{codespace_name}/start` |
| Stop codespace | POST | `/user/codespaces/{codespace_name}/stop` |
| List codespaces in repo | GET | `/repos/{owner}/{repo}/codespaces` |
| Create codespace in repo | POST | `/repos/{owner}/{repo}/codespaces` |
| Create codespace from PR | POST | `/repos/{owner}/{repo}/pulls/{pull_number}/codespaces` |
| Get devcontainer configs | GET | `/repos/{owner}/{repo}/codespaces/devcontainers` |
| Check permissions | GET | `/repos/{owner}/{repo}/codespaces/permissions_check` |
| Get default attributes | GET | `/repos/{owner}/{repo}/codespaces/new` |

**Key create parameters:** `ref` (branch/commit), `machine` (machine type name), `location` (EastUs, SouthEastAsia, WestEurope, WestUs2), `idle_timeout_minutes`, `devcontainer_path`, `geo`.

**Codespace state values:** `Unknown`, `Created`, `Queued`, `Provisioning`, `Available`, `Unavailable`, `Deleted`.

### 1.2 Export Endpoints

| Operation | Method | Path |
|-----------|--------|------|
| Export codespace | POST | `/user/codespaces/{codespace_name}/exports` |
| Get export status | GET | `/user/codespaces/{codespace_name}/exports/{export_id}` |
| Publish codespace as repo | POST | `/user/codespaces/{codespace_name}/publish` |

### 1.3 Machine Types

**Reference:** https://docs.github.com/en/rest/codespaces/machines

| Operation | Method | Path |
|-----------|--------|------|
| List machines for repo | GET | `/repos/{owner}/{repo}/codespaces/machines` |
| List machines for codespace | GET | `/user/codespaces/{codespace_name}/machines` |

Response includes per machine: `name`, `display_name`, `operating_system`, `storage_in_bytes`, `memory_in_bytes`, `cpus`, `prebuild_availability`.

### 1.4 Organization-Level Management

**Reference:** https://docs.github.com/en/rest/codespaces/organizations

| Operation | Method | Path |
|-----------|--------|------|
| List org codespaces | GET | `/orgs/{org}/codespaces` |
| Get org access settings | GET | `/orgs/{org}/codespaces/access` |
| Set org access settings | PUT | `/orgs/{org}/codespaces/access` |
| Grant user billing access | POST | `/orgs/{org}/codespaces/access/selected_users` |
| Revoke user billing access | DELETE | `/orgs/{org}/codespaces/access/selected_users` |
| List member codespaces | GET | `/orgs/{org}/members/{username}/codespaces` |
| Stop member's codespace | POST | `/orgs/{org}/members/{username}/codespaces/{codespace_name}/stop` |
| Delete member's codespace | DELETE | `/orgs/{org}/members/{username}/codespaces/{codespace_name}` |

### 1.5 Secrets Management

**Reference:** https://docs.github.com/en/rest/codespaces/secrets (user), https://docs.github.com/en/rest/codespaces/repository-secrets, https://docs.github.com/en/rest/codespaces/organization-secrets

Secrets at three scopes: **user**, **repository**, and **organization**. All secret values are write-only — the API never returns plaintext values. Secrets must be encrypted with LibSodium using the public key from the corresponding `GET .../secrets/public-key` endpoint before being stored.

| Scope | List | Create/Update | Delete | Repo association |
|-------|------|---------------|--------|-----------------|
| User | `GET /user/codespaces/secrets` | `PUT /user/codespaces/secrets/{name}` | `DELETE` | `PUT/DELETE /user/codespaces/secrets/{name}/repositories[/{id}]` |
| Repo | `GET /repos/{owner}/{repo}/codespaces/secrets` | `PUT` | `DELETE` | N/A (implicit) |
| Org | `GET /orgs/{org}/codespaces/secrets` | `PUT` | `DELETE` | `PUT/DELETE /orgs/{org}/codespaces/secrets/{name}/repositories[/{id}]` |

### 1.6 Codespace Response Object — Key Fields

```json
{
  "id": 1234567,
  "name": "octocat-repo-abc123",
  "display_name": "My Codespace",
  "state": "Available",
  "machine": {
    "name": "standardLinux32gb",
    "cpus": 4,
    "memory_in_bytes": 34359738368,
    "storage_in_bytes": 34359738368
  },
  "git_status": {
    "ahead": 0,
    "behind": 0,
    "has_uncommitted_changes": false,
    "has_unpushed_changes": false
  },
  "idle_timeout_minutes": 30,
  "retention_period_minutes": 43200,
  "last_used_at": "2026-05-07T00:00:00Z",
  "created_at": "2026-05-01T00:00:00Z",
  "web_url": "https://github.com/codespaces/octocat-repo-abc123"
}
```

`git_status` is valuable for agents to detect unsaved or unpushed work before stopping or deleting.

### 1.7 Rate Limits

**Reference:** https://docs.github.com/en/rest/overview/rate-limits-for-the-rest-api

- **Authenticated users:** 5,000 requests/hour
- **GitHub Enterprise Cloud:** 15,000 requests/hour
- **Concurrent requests:** ≤ 100
- **Points/minute:** ≤ 900 (mutating requests cost more points than reads)
- **Headers:** `x-ratelimit-limit`, `x-ratelimit-remaining`, `x-ratelimit-reset`, `x-ratelimit-used`
- Check current limits: `GET /rate_limit`

For agents making many sequential start/stop/create calls, budget ~10–20 points per operation and monitor `x-ratelimit-remaining` proactively.

### 1.8 REST API Gaps (What Cannot Be Done)

The following operations are **not available** via REST API and require GitHub CLI, WebSocket, or manual action:

| Gap | Why It Matters for Agents |
|-----|--------------------------|
| SSH/terminal access | Cannot run commands inside a running codespace |
| Real-time log streaming | Must poll for status; no live build log feed |
| Port forwarding setup/teardown | Cannot expose or tunnel codespace ports programmatically via REST |
| File transfer (upload/download) | No single-file GET/PUT; export only ships whole codespace state |
| Devcontainer modification | Cannot write `.devcontainer/devcontainer.json` without a git push |
| Container performance metrics | No CPU/memory/disk usage endpoint |
| Prebuild management | Cannot trigger or inspect prebuilds |
| Billing breakdown per codespace | No cost-per-codespace endpoint |
| Collaboration/sharing | Cannot add collaborators to a running codespace |
| IDE/editor configuration | No endpoint for extensions, settings, themes |

---

## 2. GitHub CLI `gh codespace` Capabilities

**Reference:** https://cli.github.com/manual/gh_codespace

The `gh codespace` command group (alias `gh cs`) fills the gaps left by the REST API and is the practical tool for agent-driven debugging workflows.

### 2.1 Subcommand Reference

| Subcommand | Purpose | Key Flags |
|------------|---------|-----------|
| `gh codespace create` | Create a new codespace | `-R repo`, `-b branch`, `-m machine`, `--devcontainer-path`, `--idle-timeout`, `--retention-period`, `-s` (show post-create status) |
| `gh codespace list` | List codespaces | `--json <fields>`, `-q jq-expr`, `-L limit`, `-o org`, `-u user` |
| `gh codespace view` | Detailed info on one codespace | `-c name`, `--json <fields>` |
| `gh codespace stop` | Stop a running codespace | `-c name`, `-o org`, `-u user` |
| `gh codespace delete` | Delete one or more codespaces | `-c name`, `--all`, `--days N`, `-f force`, `-o org` |
| `gh codespace edit` | Change machine type or display name | `-c name`, `-m machine`, `-d display-name` |
| `gh codespace rebuild` | Rebuild devcontainer | `-c name`, `--full` (clears Docker cache) |
| `gh codespace ssh` | SSH into a running codespace | `-c name`, `--config` (print OpenSSH config) |
| `gh codespace logs` | View creation/build logs | `-c name`, `-f` (follow/tail) |
| `gh codespace ports` | List forwarded ports | `-c name`, `--json browseUrl,label,sourcePort,visibility` |
| `gh codespace ports forward` | Forward ports to localhost | `<remote>:<local>` pairs |
| `gh codespace ports visibility` | Set port visibility | `<port>:{public\|private\|org}` |
| `gh codespace cp` | Copy files to/from codespace | `-c name`, `-r` (recursive), `remote:path` prefix for remote files |
| `gh codespace code` | Open in VS Code | `-c name`, `-w` (browser), `--insiders` |
| `gh codespace jupyter` | Open in JupyterLab | `-c name` |

**Docs:** https://cli.github.com/manual/gh_codespace_ssh · https://cli.github.com/manual/gh_codespace_logs · https://cli.github.com/manual/gh_codespace_ports · https://cli.github.com/manual/gh_codespace_rebuild

### 2.2 CLI vs REST API — Decision Matrix

| Operation | Use CLI | Use REST API | Notes |
|-----------|---------|-------------|-------|
| Create codespace | Either | Either | CLI is simpler for scripting |
| List / inspect | Either | Either | REST API easier for programmatic JSON parsing |
| Start / stop | Either | Either | REST API preferred for automation pipelines |
| Delete / cleanup | Either | Either | CLI `--days` flag convenient for batch cleanup |
| SSH into codespace | **CLI only** | ✗ | Only interactive debugging path |
| View build/creation logs | **CLI only** | ✗ | Essential for diagnosing build failures |
| Forward ports | **CLI only** | ✗ | REST API cannot open tunnels |
| Copy files in/out | **CLI only** | ✗ | No REST equivalent |
| Rebuild devcontainer | Either | ✗ (no direct endpoint) | CLI `--full` clears Docker cache |
| Open IDE | **CLI only** | ✗ | Rarely needed by agents |
| Manage secrets | REST API preferred | Either | LibSodium encryption cleaner via API |
| Org admin operations | REST API preferred | CLI `--org` flag | API offers more control |

### 2.3 CLI Authentication

**Reference:** https://cli.github.com/manual/gh_auth_login

For agent use the recommended approach is the `GH_TOKEN` environment variable:

```bash
export GH_TOKEN="<fine-grained-PAT-or-github-app-installation-token>"
gh codespace list --json name,state,repository
```

This avoids interactive login flows and works in headless environments. For GitHub Actions, use `${{ github.token }}` or a dedicated PAT stored as a repo/org secret.

---

## 3. Authentication, Scopes, and Organization Policies

**References:** https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens · https://docs.github.com/en/rest/authentication

### 3.1 Token Types and Recommended Hierarchy

| Token Type | Recommended For | Pros | Cons |
|------------|----------------|------|------|
| **GitHub App installation token** | Automated service integrations | Short-lived (1 hr), scoped per installation, auditable | Requires App setup, JWT signing |
| **Fine-grained PAT** | Agent automation (no App yet) | Repo-scoped, explicit permissions, no broad org access | Expires, must rotate |
| **Classic PAT (`codespace` scope)** | Legacy/simple automation | Easy to create | Overly broad, no repo scoping |
| **OAuth user token** | User-delegated workflows | Web-flow based | 8 hr expiry, complex flow |

**For UW SSEC agents:** use fine-grained PATs or GitHub App installation tokens. Do not use classic PATs in production.

### 3.2 Required Fine-Grained PAT Permissions

| Permission | Level | Operations Unlocked |
|-----------|-------|-------------------|
| `Codespaces` | Read + Write | Full lifecycle CRUD for user codespaces |
| `Codespaces lifecycle admin` | Read + Write | Admin start/stop/delete |
| `Codespaces metadata` | Read | Inspect codespace state, machine type |
| `Codespaces secrets` | Write | Manage codespace-level secrets |
| `Codespaces user secrets` | Read + Write | Manage user-scoped secrets |
| `Organization codespaces` | Read + Write | Org-level codespace listing and control |
| `Organization codespaces secrets` | Read + Write | Org-level secret management |
| `Organization codespaces settings` | Read + Write | Policy configuration (machine types, timeout limits) |

For most agent debugging tasks (list, inspect, stop, rebuild, read logs), `Codespaces` read + write and `Codespaces metadata` read are sufficient.

### 3.3 Organization Policy Constraints

**Reference:** https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization

Org admins can apply policies that restrict what agents can do:

| Policy | Effect on Agents |
|--------|-----------------|
| Restrict machine types | Agent cannot create/upgrade to restricted sizes |
| Maximum idle timeout | Agent-created codespaces auto-stop at policy limit |
| Retention period max | Codespaces auto-deleted after policy window |
| Allowed base images | Custom devcontainers using non-approved images will fail |
| Port forwarding visibility | Cannot set ports to `public` if restricted to `org` or `private` |
| Billing access restriction | Agent may not be able to create codespaces for users without org billing access |

**Implication:** Before an agent creates or modifies codespaces in an org, it should `GET /orgs/{org}/codespaces/access` to understand current policy.

### 3.4 Audit Logging

**Reference:** https://docs.github.com/en/organizations/keeping-your-organization-secure/reviewing-the-audit-log-for-your-organization

The `codespaces` audit category captures: create, delete, start, stop, rebuild, and configuration changes. Logs are retained for 180 days. Fine-grained tokens are traceable in audit logs — each token's `key_id` appears in log entries, enabling attribution per-agent-token.

For security monitoring, org admins should export audit logs and alert on:
- Unexpected codespace creation by bot accounts
- Org secrets being accessed from unexpected codespace names
- Port visibility changes to `public`

---

## 4. Debugging Workflows for Common Failures

This section documents the recommended diagnostic sequence for each failure class. All commands assume `GH_TOKEN` is set.

### 4.1 Failed Codespace Creation

**Symptoms:** `state: Unavailable` immediately after POST; creation API returns 422/500.

**Diagnostic sequence:**

```bash
# 1. Check codespace state immediately after creation attempt
gh codespace view -c <name> --json state,displayName,repository

# 2. Read creation logs — most failures surface here
gh codespace logs -c <name>

# 3. Check machine availability for the repo/org
curl -H "Authorization: Bearer $GH_TOKEN" \
  "https://api.github.com/repos/{owner}/{repo}/codespaces/machines"

# 4. Check org policy (may block machine type or region)
curl -H "Authorization: Bearer $GH_TOKEN" \
  "https://api.github.com/orgs/{org}/codespaces/access"

# 5. Verify permissions are accepted
curl -H "Authorization: Bearer $GH_TOKEN" \
  "https://api.github.com/repos/{owner}/{repo}/codespaces/permissions_check"
```

**Common root causes:**
- Machine type not available in selected region → retry with `geo` instead of `location`
- Org billing not enabled for the user → requires org admin to grant access
- Requested machine type blocked by org policy → use `machines` endpoint to find allowed types
- Permission prompt not accepted → `permissions_check` returns `accepted: false`

### 4.2 Devcontainer Build Failure

**Symptoms:** Codespace reaches `Provisioning` then transitions to `Unavailable`; SSH connection refused.

**Diagnostic sequence:**

```bash
# 1. Tail the build log — this is the primary evidence source
gh codespace logs -c <name> -f

# 2. After log review, attempt full rebuild (clears Docker cache)
gh codespace rebuild -c <name> --full

# 3. If rebuild fails again, SSH in if Available state is reached
gh codespace ssh -c <name>
# Inside codespace: check /tmp/codespace-*.log for post-create command output

# 4. Check devcontainer.json syntax — retrieve via git, not API
# The API can list devcontainer configs but not validate them:
curl -H "Authorization: Bearer $GH_TOKEN" \
  "https://api.github.com/repos/{owner}/{repo}/codespaces/devcontainers"
```

**Common root causes:**
- Syntax error in `devcontainer.json` → parse error appears in `gh codespace logs` output
- Docker image pull failure (rate limit or private registry) → visible in logs
- `postCreateCommand` throws non-zero exit → post-create script failure
- Missing `features` or `customizations` → devcontainer schema error in logs
- Base image no longer exists → update `image` field in devcontainer.json

**Agent remediation path:** If logs identify a devcontainer config error, the fix requires pushing a corrected `.devcontainer/devcontainer.json` to the branch, then calling `gh codespace rebuild --full`.

### 4.3 Port Forwarding Issues

**Symptoms:** Service running in codespace is not reachable externally; `browseUrl` returns 404/502.

**Diagnostic sequence:**

```bash
# 1. List current port state
gh codespace ports -c <name> --json sourcePort,visibility,label,browseUrl

# 2. Verify process is actually listening (requires SSH)
gh codespace ssh -c <name> -- netstat -tlnp
# or
gh codespace ssh -c <name> -- ss -tlnp

# 3. Forward port to local for direct testing
gh codespace ports forward 8080:8080 -c <name>

# 4. If port exists but is private, change visibility
gh codespace ports visibility 8080:org -c <name>
```

**Common root causes:**
- Process not started inside codespace → verify via SSH
- Port not yet forwarded → `gh codespace ports forward` establishes tunnel
- Visibility too restrictive → change to `org` or `public` as appropriate
- Org policy blocks public ports → check org settings; `org` visibility is the maximum available
- Port forwarding connection drops → gh CLI maintains the tunnel; re-run `ports forward` after disconnect

### 4.4 Environment / Secrets Problems

**Symptoms:** Application fails at startup citing missing env vars; credentials rejected.

**Diagnostic sequence:**

```bash
# 1. List secrets visible to the codespace's repo (no values returned)
curl -H "Authorization: Bearer $GH_TOKEN" \
  "https://api.github.com/repos/{owner}/{repo}/codespaces/secrets"

# 2. List user-level secrets (check repo associations)
curl -H "Authorization: Bearer $GH_TOKEN" \
  "https://api.github.com/user/codespaces/secrets"

# 3. Verify secret is mapped to the correct repo
curl -H "Authorization: Bearer $GH_TOKEN" \
  "https://api.github.com/user/codespaces/secrets/{secret_name}/repositories"

# 4. SSH into codespace and inspect actual env
gh codespace ssh -c <name> -- env | grep -i <SECRET_NAME>

# 5. If secret is missing, create/update it via API
# (Must encrypt with LibSodium public key first — see GitHub docs)
curl -X PUT -H "Authorization: Bearer $GH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"encrypted_value":"<base64-encrypted>","key_id":"<key-id>"}' \
  "https://api.github.com/user/codespaces/secrets/{secret_name}"
```

**Common root causes:**
- Secret not associated with the codespace's repository → add via `PUT /user/codespaces/secrets/{name}/repositories/{id}`
- Codespace created before secret was added → stop and restart; secrets are injected at startup
- Org secret not visible to repository → org admin must add repo to org secret's access list
- Secret value stale/rotated → re-encrypt and PUT the updated value

**Note:** Secrets are injected at codespace start. If a secret is updated while a codespace is running, the codespace must be stopped and restarted to pick up the new value.

### 4.5 Dependency Install Failures

**Symptoms:** `postCreateCommand` exits non-zero; packages missing inside codespace; build errors.

**Diagnostic sequence:**

```bash
# 1. View post-create command output in logs
gh codespace logs -c <name>
# Look for: "postCreateCommand" section, exit codes, error messages

# 2. SSH in and manually reproduce the failing command
gh codespace ssh -c <name>
# Inside: cd /workspaces/<repo> && <postCreateCommand>

# 3. Copy diagnostic files out (e.g. lock files, pip logs)
gh codespace cp -r remote:/tmp/pip-*.log ./debug-logs/

# 4. If network access issue, check DNS resolution inside codespace
gh codespace ssh -c <name> -- curl -v https://pypi.org
```

**Common root causes:**
- Network access to package registry blocked → codespace networking policy; may require VPN configuration (not automatable via API)
- Lock file conflict → run `pixi install` or `pip install` with `--no-deps` to diagnose
- Wrong Python/Node version → devcontainer `features` or `image` tag mismatch
- `postCreateCommand` assumes interactive shell → use non-interactive flags (`pip install -q --no-input`)

### 4.6 Stuck / Stale Codespaces

**Symptoms:** Codespace shows `Provisioning` for > 15 minutes; SSH timeouts; high idle age.

**Diagnostic sequence:**

```bash
# 1. Check state and last_used_at
gh codespace list --json name,state,lastUsedAt,repository

# 2. For stuck Provisioning state — stop and restart
gh codespace stop -c <name>
# Wait ~30s, then:
gh codespace start (via REST API): POST /user/codespaces/{name}/start

# 3. For truly stuck (stop doesn't transition): force delete and recreate
gh codespace delete -c <name> -f

# 4. Bulk clean up stale codespaces (>7 days old)
gh codespace delete --days 7 --repo {owner}/{repo}

# 5. For org-level cleanup of all member stale codespaces (admin only)
curl -H "Authorization: Bearer $GH_TOKEN" \
  "https://api.github.com/orgs/{org}/codespaces" \
  | jq '.codespaces[] | select(.state != "Available") | .name'
# Then DELETE each via API
```

**Common root causes:**
- GitHub infrastructure issue → stop + restart is sufficient; check https://githubstatus.com
- Codespace exceeded retention period → already deleted by GitHub; recreate
- Machine resource limits hit → upgrade machine type before recreating
- Git state diverged (ahead/behind) → check `git_status` field before deletion to warn about unsaved work

---

## 5. Recommended Agent Interface

### 5.1 Operating Model

Agents should interact with Codespaces using a **two-layer approach**:

**Layer 1 — Control plane (REST API):** Use for all state-management and configuration operations. REST API calls are stateless, easily retried, and produce machine-readable JSON.

**Layer 2 — Data plane (gh CLI):** Use for observability and remediation operations that require an in-band connection to the running codespace. All Layer 2 calls require `GH_TOKEN` injected as an environment variable.

### 5.2 Operation Routing Table

| Agent Operation | Recommended Tool | Endpoint / Command |
|----------------|-----------------|-------------------|
| Check codespace exists and state | REST API | `GET /user/codespaces/{name}` |
| Create codespace | REST API | `POST /repos/{owner}/{repo}/codespaces` |
| Stop codespace | REST API | `POST /user/codespaces/{name}/stop` |
| Start codespace | REST API | `POST /user/codespaces/{name}/start` |
| Delete codespace | REST API | `DELETE /user/codespaces/{name}` |
| Check machine options | REST API | `GET /repos/{owner}/{repo}/codespaces/machines` |
| Read build/creation logs | gh CLI | `gh codespace logs -c <name>` |
| Run command in codespace | gh CLI | `gh codespace ssh -c <name> -- <cmd>` |
| Copy output files out | gh CLI | `gh codespace cp remote:/path ./local/` |
| Forward port for testing | gh CLI | `gh codespace ports forward <r>:<l> -c <name>` |
| Change port visibility | gh CLI | `gh codespace ports visibility <port>:<level> -c <name>` |
| Rebuild after devcontainer fix | gh CLI | `gh codespace rebuild --full -c <name>` |
| List stale codespaces | Either | REST API for JSON; gh CLI for quick human-readable output |
| Manage secrets | REST API | `/user/codespaces/secrets` or `/repos/.../codespaces/secrets` |
| Check org policies | REST API | `GET /orgs/{org}/codespaces/access` |
| Audit org codespace inventory | REST API | `GET /orgs/{org}/codespaces` |

### 5.3 Logs and Status to Capture Per Incident

For every debugging incident, agents should record:

1. **Codespace metadata snapshot:** `gh codespace view -c <name> --json state,machineDisplayName,gitStatus,lastUsedAt,idleTimeoutMinutes`
2. **Build logs:** `gh codespace logs -c <name>` (full output)
3. **Port state:** `gh codespace ports -c <name> --json sourcePort,visibility,label`
4. **Org policy state:** `GET /orgs/{org}/codespaces/access` (for creation failures)
5. **Secrets index:** `GET /user/codespaces/secrets` (names only; no values)

### 5.4 Guardrails and Approval Boundaries

The following operations should require explicit human approval before an agent executes them:

| Operation | Risk Level | Why It Needs Approval |
|-----------|-----------|----------------------|
| `DELETE /user/codespaces/{name}` | High | Permanently destroys codespace including uncommitted work |
| `gh codespace delete --all` | Critical | Destroys all codespaces for a user/repo |
| `PUT /orgs/{org}/codespaces/access` | High | Changes who can create codespaces org-wide |
| `PUT .../secrets/{name}` (org-level) | High | Overwrites a secret used by all org members |
| `gh codespace ports visibility <port>:public` | Medium | Exposes internal service to public internet |
| `gh codespace rebuild --full` | Medium | Takes several minutes; interrupts any active work |
| `POST /user/codespaces` (new creation) | Low-Medium | Incurs billing; check budget first |

**Recommended agent policy:**
- **Auto-approve:** list, view, inspect, stop (not delete), logs, read secrets metadata, port status checks
- **Require confirmation:** delete, org policy changes, public port visibility, org-level secret writes
- **Escalate to human:** org admin operations, billing changes, security-sensitive secret management

### 5.5 Recommended Token Configuration for Agents

Create a dedicated GitHub fine-grained PAT per agent role with minimum permissions:

**Debug/read-only agent:**
```
Codespaces: Read
Codespaces metadata: Read
```

**Lifecycle management agent:**
```
Codespaces: Read + Write
Codespaces lifecycle admin: Read + Write
Codespaces metadata: Read
```

**Secrets management agent (separate, audited):**
```
Codespaces user secrets: Read + Write
Organization codespaces secrets: Read + Write (if org-level)
```

Store tokens as org-level Codespaces secrets (or GitHub Actions secrets). Rotate every 90 days.

### 5.6 Recommended Polling Strategy

The REST API does not have webhooks for Codespaces state transitions. Agents must poll.

**Recommended intervals:**

| Scenario | Poll interval | Max duration |
|----------|--------------|-------------|
| Waiting for `start` to complete | 5s | 5 min |
| Waiting for `create` to complete | 10s | 15 min |
| Waiting for `rebuild` to complete | 15s | 20 min |
| Detecting stale codespaces (maintenance job) | 1 hour | ongoing |

Poll `GET /user/codespaces/{name}` and check the `state` field. Exit polling loop when state reaches `Available`, `Unavailable`, or `Deleted`.

---

## 6. Gaps Requiring Human or Admin Intervention

The following Codespaces operations **cannot be safely automated** or require human/admin setup:

| Gap | Why It Cannot Be Automated | Required Action |
|-----|---------------------------|----------------|
| Enabling Codespaces for an org | Requires org billing setup | Org admin enables via Settings → Codespaces |
| Granting org billing access to users | Policy decision, not just API call | Org admin POSTs to `/orgs/{org}/codespaces/access/selected_users` |
| Creating/rotating GitHub App credentials | Requires GitHub app owner action | Human creates app, rotates private key |
| Accepting permission prompts on new devcontainer | Interactive approval step | User or admin must accept via UI or `--default-permissions` CLI flag |
| Configuring org spending limits | Billing admin action | Org admin sets via GitHub billing settings |
| Managing org-level machine type restrictions | Requires org admin token scope | Org admin configures via `/orgs/{org}/codespaces/access` |
| VPN/network policy for private registries | Infrastructure-level, not API-addressable | Network admin configures allowed egress |
| Custom container image publishing | Requires container registry credentials and push access | DevOps/platform team publishes images |
| Prebuild configuration and triggers | No REST API support | Repository admin configures prebuilds via GitHub UI |
| Enforcing devcontainer.json standards | No policy enforcement API | Enforce via repo template, branch protection, or PR checks |
| SSH key provisioning | Codespace SSH keys are ephemeral and auto-provisioned by gh CLI | Use `gh codespace ssh`; do not attempt manual key management |

---

## Summary and Recommendation

GitHub Codespaces provides a mature REST API for lifecycle management (create, start, stop, delete, machine selection, secrets, org access) and a capable CLI for in-band debugging (logs, SSH, port forwarding, file copy, rebuild). The two complement each other cleanly.

**For UW SSEC / Paperclip agents, the recommended operating model is:**

1. **Use REST API** for all control-plane automation: codespace inventory, lifecycle transitions, secrets management, and org policy reads. These are predictable, stateless, and retry-safe.

2. **Use gh CLI with `GH_TOKEN`** for all observability and remediation: reading build logs, running commands inside codespaces via SSH, transferring diagnostic files, and rebuilding after config changes.

3. **Gate destructive operations** (delete, org policy changes, public port exposure) behind explicit human confirmation. Only auto-approve read and soft-stop operations.

4. **Use fine-grained PATs scoped to minimum permissions** per agent role. Avoid classic PATs. Prefer GitHub App installation tokens for production automation.

5. **Log and retain** codespace metadata snapshots and full build logs for every incident — these are the primary debugging artifacts and are not persistently accessible after deletion.

6. **Do not attempt to automate** org billing setup, prebuild configuration, VPN/network policy, or container image publishing — these require human action and one-time admin setup.

---

*This document was produced for [UWS-97](/UWS/issues/UWS-97) under [UWS-96](/UWS/issues/UWS-96) (Research on API Interactions for Codespaces).*
