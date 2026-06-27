# WarmShower OS — CI Signing Architecture

> **Task:** WS-000
> **Status:** APPROVED DESIGN — implement via WS-001
> **Date:** 2026-06-28

---

## Decision

WarmShower OS uses a **three-tier GPG key structure**:

```
[Master Key]  — Ed25519, no expiry, kept permanently air-gapped offline
      │
      ├── [CI Signing Subkey]    — Ed25519 sign-only, 1-year validity, stored as GitHub Actions secret
      └── [Release Signing Subkey] — Ed25519 sign-only, 1-year validity, used for ISO + release tags
```

The master key never touches any online system after the initial subkey signing.

---

## Key Generation Procedure (WS-001)

Run on an air-gapped machine or a live USB session that will not retain state.

```bash
# Generate master key
gpg --expert --full-generate-key
# Choose: (11) ECC (set your own capabilities)
# Toggle to: Sign only
# Curve: Ed25519
# Expiry: 0 (no expiry — master key is revoked, not expired)
# Name: WarmShower OS
# Email: admin@warmshower.ai
# Comment: (leave blank)

# Record the fingerprint
FINGERPRINT=$(gpg --list-secret-keys --with-colons admin@warmshower.ai | awk -F: '/^fpr/ { print $10; exit }')
echo "Master key fingerprint: $FINGERPRINT"

# Generate CI signing subkey (sign only, Ed25519, 1 year)
gpg --expert --edit-key "$FINGERPRINT"
# gpg> addkey
# Choose: (10) ECC (sign only)
# Curve: Ed25519
# Expiry: 1y
# Save and quit: save

# Generate release signing subkey (sign only, Ed25519, 1 year)
gpg --expert --edit-key "$FINGERPRINT"
# gpg> addkey
# Same as above
# Save and quit: save

# Export public key for warmshower-keyring
gpg --export --armor "$FINGERPRINT" > warmshower.gpg

# Export CI subkey secret material (subkey only — not the master key)
# The subkey keygrip will be needed for the GitHub secret
gpg --export-secret-subkeys --armor "$FINGERPRINT" > warmshower-ci-subkey.asc
```

---

## Backup Procedure

Before any online work:

1. Export full key (master + subkeys) to an encrypted USB:
   ```bash
   gpg --export-secret-keys --armor "$FINGERPRINT" > warmshower-master-full.asc
   # Encrypt with a strong passphrase before writing to USB
   gpg --symmetric warmshower-master-full.asc
   # Write warmshower-master-full.asc.gpg to at least two offline USB drives
   # Store in separate physical locations
   ```

2. Export public key to the warmshower-pkgbuilds repository (committed):
   ```bash
   cp warmshower.gpg warmshower-pkgbuilds/warmshower-keyring-pkg/warmshower.gpg
   ```

3. Print the fingerprint and store with the offline backup media.

4. Delete the master key from the online machine:
   ```bash
   gpg --delete-secret-key "$FINGERPRINT"
   # Verify only subkeys remain:
   gpg --list-secret-keys "$FINGERPRINT"
   # Output should show '#' next to master key (sec#) indicating it is not present
   ```

---

## GitHub Actions Secrets

Add the following secrets to the `Warm-shower` organization (org-level, not repo-level):

| Secret Name | Value | Used By |
|---|---|---|
| `WS_SIGNING_KEY` | Output of `gpg --export-secret-subkeys --armor <FINGERPRINT>` | All package-publishing CI workflows |
| `WS_SIGNING_KEY_PASSPHRASE` | GPG key passphrase | All package-publishing CI workflows |
| `REPO_PUBLISH_TOKEN` | Cloudflare R2 / hosting API token | Package repository upload step |

**Important:** `WS_SIGNING_KEY` contains only the CI signing subkey, not the master key. Even if this secret is leaked, the master key cannot be recovered from it.

---

## CI Signing Workflow

Every CI workflow that publishes a package must include:

```yaml
- name: Import WarmShower signing key
  env:
    WS_SIGNING_KEY: ${{ secrets.WS_SIGNING_KEY }}
    WS_SIGNING_KEY_PASSPHRASE: ${{ secrets.WS_SIGNING_KEY_PASSPHRASE }}
  run: |
    echo "$WS_SIGNING_KEY" | gpg --batch --import
    echo "$WS_SIGNING_KEY_PASSPHRASE" | gpg --batch --passphrase-fd 0 \
      --pinentry-mode loopback --sign /dev/null 2>/dev/null || true

- name: Sign package
  env:
    WS_SIGNING_KEY_PASSPHRASE: ${{ secrets.WS_SIGNING_KEY_PASSPHRASE }}
  run: |
    for pkg in *.pkg.tar.zst; do
      gpg --batch --passphrase "$WS_SIGNING_KEY_PASSPHRASE" \
          --pinentry-mode loopback \
          --detach-sign --no-armor "$pkg"
    done
```

---

## Key Rotation Policy

- CI subkey: rotate annually (before expiry date)
- Release subkey: rotate annually
- Master key: rotate only on compromise or loss of all offline backups

**Rotation procedure:**
1. Generate new subkey from master key (on air-gapped machine)
2. Update `WS_SIGNING_KEY` GitHub secret
3. Bump `warmshower-keyring` `pkgver` and publish updated package
4. Revoke old subkey: `gpg --edit-key <FINGERPRINT>` → `key <N>` → `revkey`
5. Publish updated public key (run `gpg --export --armor` → update warmshower.gpg)
6. Re-sign all packages in the repository with the new key

---

## Revocation

A revocation certificate must be generated at key creation time and stored with offline backups:

```bash
gpg --gen-revoke "$FINGERPRINT" > warmshower-revocation-cert.asc
# Store this alongside the full key export on offline media
```

---

## Trust Chain for Users

When a user installs `warmshower-keyring`:

1. `pacman-key --populate warmshower` imports `warmshower.gpg`
2. The key is locally signed by `pacman-key`
3. All `[warmshower]` packages are verified against this key before installation
4. If the key has been rotated, users update via `pacman -Sy warmshower-keyring`

The entire trust chain depends on the security of this master key.
**Losing the master key without a revocation certificate means the distribution cannot be trusted by its own users.**
