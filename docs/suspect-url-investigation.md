# WarmShower OS — SUSPECT URL Investigation

> **Task:** WS-004 + WS-004a
> **Status:** PENDING — run investigation before modifying any source= URLs
> **Date:** 2026-06-28

---

## Instructions

Run the following verification commands on a Linux machine with `git` and `curl` installed.
Document the result (EXISTS / 404) for each URL below.
Do NOT modify any PKGBUILD source= URL until this document is complete.

```bash
# For each URL, run:
git ls-remote https://github.com/<org>/<repo>.git HEAD 2>&1 | head -1
# If output starts with a SHA: EXISTS
# If output contains "not found" or "403": DOES NOT EXIST / NO ACCESS
```

---

## URLs to Verify

| URL | Used By Package | Result | Action If Exists | Action If 404 |
|---|---|---|---|---|
| `https://github.com/CachyOS/warmshower-update` | warmshower-update | **PENDING** | Fork to Warm-shower org | Create from hooks/scripts; track as WS-040 |
| `https://github.com/CachyOS/warmshower-calamares` | warmshower-calamares | **PENDING** | Fork to Warm-shower org | Locate cachyos-calamares; track as WS-041 |
| `https://github.com/CachyOS/warmshower-chroot` | warmshower-chroot | **PENDING** | Fork to Warm-shower org | Locate cachyos/cachyos-chroot; track as WS-042 |
| `https://github.com/CachyOS/warmshower-hooks` | warmshower-hooks | **PENDING** | Fork to Warm-shower org | Create from local PKGBUILD install files; track as WS-043 |
| `https://github.com/CachyOS/warmshower-zsh-config` | warmshower-zsh-config | **PENDING** | Fork to Warm-shower org | Fork from cachyos/cachyos-zsh-config; track as WS-044 |
| `https://github.com/CachyOS/warmshower-plymouth-theme` | warmshower-plymouth-theme | **PENDING** | Fork to Warm-shower org | Create from upstream plymouth theme; track as WS-045 |
| `https://github.com/cachyos/warmshower-kde-settings` | warmshower-kde-settings | **PENDING** | Fork to Warm-shower org | Fork from cachyos/cachyos-kde-settings; track as WS-046 |
| `https://github.com/cachyos/warmshower-gnome-settings` | warmshower-gnome-settings | **PENDING** | Fork to Warm-shower org | Fork from cachyos/cachyos-gnome-settings; track as WS-047 |
| `https://github.com/cachyos/warmshower-hyprland-settings` | warmshower-hyprland-settings | **PENDING** | Fork to Warm-shower org | Fork from cachyos/cachyos-hyprland-settings; track as WS-048 |

---

## Investigation Script

```bash
#!/usr/bin/env bash
# Run this script and paste the output into the table above.

URLS=(
  "https://github.com/CachyOS/warmshower-update"
  "https://github.com/CachyOS/warmshower-calamares"
  "https://github.com/CachyOS/warmshower-chroot"
  "https://github.com/CachyOS/warmshower-hooks"
  "https://github.com/CachyOS/warmshower-zsh-config"
  "https://github.com/CachyOS/warmshower-plymouth-theme"
  "https://github.com/cachyos/warmshower-kde-settings"
  "https://github.com/cachyos/warmshower-gnome-settings"
  "https://github.com/cachyos/warmshower-hyprland-settings"
)

for url in "${URLS[@]}"; do
  result=$(git ls-remote "${url}.git" HEAD 2>&1)
  if echo "$result" | grep -qE '^[0-9a-f]{40}'; then
    status="EXISTS"
  else
    status="DOES NOT EXIST (${result})"
  fi
  echo "$url: $status"
done
```

---

## Post-Investigation Actions

After filling in the table above:

1. For every row marked **EXISTS**:
   - Fork the repository to `github.com/Warm-shower/<name>`
   - Create a tracking task (WS-04x) for updating the PKGBUILD source= URL
   - Do NOT update the source= URL until after the fork is complete and verified

2. For every row marked **DOES NOT EXIST**:
   - Identify the correct upstream source (usually `cachyos/<original-name>`)
   - Fork the correct upstream to `github.com/Warm-shower/warmshower-<name>`
   - Update the PKGBUILD source= URL to point to the new Warm-shower fork
   - Regenerate checksums after updating source=

3. Commit this document with the filled-in results to the repository:
   ```
   docs: WS-004 — document SUSPECT URL investigation results
   ```

---

## Constraint

**No PKGBUILD source= URL that targets a SUSPECT repository may be modified
before this document shows a result in its Result column.**

Building against a broken URL is better than building against a non-existent one,
because at least the build will produce a useful error message.
