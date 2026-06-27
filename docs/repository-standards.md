# WarmShower OS — Repository Standards

> **Status:** APPROVED — applies to all Warm-shower org repositories
> **Date:** 2026-06-28

All repositories under the `Warm-shower` GitHub organization must conform to these standards.
New repositories should be created from the organization template when available.

---

## Required Files

Every repository must contain:

| File | Description |
|---|---|
| `README.md` | Purpose, build instructions, and WarmShower OS branding (no CachyOS logos) |
| `LICENSE.md` | License file (GPL-3.0-or-later for OS packages, MIT for tools) |
| `CODEOWNERS` | Points to `@Warm-shower/maintainers` |
| `CONTRIBUTING.md` | How to contribute; references this standards document |
| `CODE_OF_CONDUCT.md` | Standard contributor covenant |
| `.github/ISSUE_TEMPLATE/` | At minimum: bug report and update request templates |

---

## Branch Protection Rules

Apply the following to the `master` branch of every repository:

```
✅ Require a pull request before merging
✅ Require approvals: 1 (or 2 for infrastructure repositories)
✅ Dismiss stale PR approvals when new commits are pushed
✅ Require status checks to pass before merging
   - CI workflows must be listed as required checks
✅ Require conversation resolution before merging
✅ Restrict who can push to matching branches: @Warm-shower/maintainers
✅ Do not allow bypassing the above settings
```

To apply via GitHub CLI after org is established (WS-010):

```bash
gh api repos/Warm-shower/<repo>/branches/master/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["validate-pkgbuilds"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null
```

---

## Standard Labels

Every repository must have these labels. Apply via:

```bash
# Run from warmshower-pkgbuilds or any repo after org is established
.github/scripts/apply-labels.sh Warm-shower/<repo>
```

| Label | Color | Description |
|---|---|---|
| `bug` | `#d73a4a` | Something is broken |
| `package-update` | `#0075ca` | Package version update request |
| `new-package` | `#008672` | New package addition request |
| `needs-review` | `#e4e669` | Waiting for maintainer review |
| `needs-triage` | `#e4e669` | Not yet triaged |
| `blocked` | `#cc317c` | Blocked on another task |
| `infrastructure` | `#0052cc` | Affects CI or build infrastructure |
| `security` | `#b60205` | Security-related issue |
| `good-first-issue` | `#7057ff` | Good starting point for new contributors |
| `help-wanted` | `#008672` | Extra attention needed |

---

## CI Requirements

Every repository must have GitHub Actions workflows covering:

| Workflow | Trigger | Purpose |
|---|---|---|
| Lint / Validate | push to master, PRs | namcap + PKGBUILD validation |
| Build | push touching PKGBUILD, workflow_dispatch | Full `makepkg` build |
| Checksum Verify | PRs touching PKGBUILD | `makepkg --verifysource` |
| Version Check | schedule (4h) | nvchecker upstream version tracking |
| Release | push of `v*` tag | Build, sign, publish |

Package repositories (repos with PKGBUILDs only, no source code) need at minimum:
Lint + Checksum Verify + Version Check.

Source repositories (repos with actual Rust/C/Go code) need all five.

---

## PKGBUILD Standards

Every PKGBUILD in `warmshower-pkgbuilds` must:

1. Have `# Maintainer: WarmShower OS <admin@warmshower.ai>` as the first line
2. Set `url=` to the Warm-shower GitHub URL (not Rawknee-69, not CachyOS)
3. Not contain `SKIP` checksums unless source is a VCS URL (`git+`, `svn+`, `hg+`, `bzr+`)
4. Pass `namcap PKGBUILD` with no errors (warnings are reviewed case-by-case)
5. Not use `--skipchecksums`, `--skipinteg`, or `--skipverify` flags
6. Update `validpgpkeys` to WarmShower or upstream keys when source URL changes

---

## Commit Message Format

```
<scope>: <short description (under 72 chars)>

[optional body — explain why, not what]

[optional footer: Fixes #123, Closes #456]
```

Scopes:
- `pkgbuild` — PKGBUILD change
- `ci` — CI workflow change
- `infra` — infrastructure/signing/repo change
- `docs` — documentation
- `branding` — URL or name change (CachyOS → WarmShower)
- `chore` — housekeeping (version bump, dep update)
- `fix` — bug fix
- `feat` — new feature / new package

Examples:
```
ci: fix actions/checkout@v6 → @v4 in all workflows
branding: replace warmshower.example.org with warmshower.ai
pkgbuild: warmshower-settings — replace CachyOS debuginfod URL
infra: update keyring PKGBUILD URL to Warm-shower org
```

---

## Organization Setup Checklist

To be completed as part of WS-005/WS-010:

- [ ] Create `Warm-shower` GitHub organization
- [ ] Verify `warmshower.ai` domain in org settings
- [ ] Create `maintainers` team, add project owner
- [ ] Enable 2FA enforcement for all org members
- [ ] Set default repository visibility to Public
- [ ] Set default branch name to `master`
- [ ] Enable "Require contributors to sign off on web-based commits"
- [ ] Add org-level secrets: `WS_SIGNING_KEY`, `WS_SIGNING_KEY_PASSPHRASE`, `REPO_PUBLISH_TOKEN`
- [ ] Create `.github` repository in org with org-level README and profile
- [ ] Apply branch protection to all transferred repositories
- [ ] Apply standard labels to all repositories
