#!/usr/bin/env bash
# apply-labels.sh — Apply standard WarmShower OS labels to a GitHub repository.
# Usage: ./apply-labels.sh Warm-shower/<repo-name>
# Requires: gh CLI authenticated with a token that has repo:write scope.

set -euo pipefail

REPO="${1:-}"
if [ -z "$REPO" ]; then
  echo "Usage: $0 Warm-shower/<repo-name>"
  exit 1
fi

echo "Applying standard WarmShower OS labels to: $REPO"

apply_label() {
  local name="$1"
  local color="$2"
  local description="$3"

  # Try to create; if it already exists (422), update it instead
  gh api "repos/$REPO/labels" \
    --method POST \
    --field name="$name" \
    --field color="$color" \
    --field description="$description" 2>/dev/null || \
  gh api "repos/$REPO/labels/$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$name")" \
    --method PATCH \
    --field color="$color" \
    --field description="$description"

  echo "  ✓ $name"
}

apply_label "bug"             "d73a4a" "Something is broken"
apply_label "package-update"  "0075ca" "Package version update request"
apply_label "new-package"     "008672" "New package addition request"
apply_label "needs-review"    "e4e669" "Waiting for maintainer review"
apply_label "needs-triage"    "e4e669" "Not yet triaged"
apply_label "blocked"         "cc317c" "Blocked on another task"
apply_label "infrastructure"  "0052cc" "Affects CI or build infrastructure"
apply_label "security"        "b60205" "Security-related issue"
apply_label "good-first-issue" "7057ff" "Good starting point for new contributors"
apply_label "help-wanted"     "008672" "Extra attention needed"

echo ""
echo "Done. All standard labels applied to $REPO."
