#!/usr/bin/env bash
# scratch-repo.sh
# Builds a sample local git repository with a branched commit history
# for the next meeting's git exercises.
# Run once to build; run again to reset.
# Never modifies the repository it is started from.
#
# Usage: bash scripts/scratch-repo.sh [TARGET_DIR]
#
# Target directory resolution (first match wins):
#   1. The first argument on the command line.
#   2. The SCRATCH_DIR environment variable.
#   3. $HOME/scratch-repo (default).

set -euo pipefail

MARKER=".scratch-repo"

# --- target directory resolution ---
if [[ $# -ge 1 ]]; then
  TARGET="$1"
elif [[ -n "${SCRATCH_DIR:-}" ]]; then
  TARGET="${SCRATCH_DIR}"
else
  TARGET="${HOME}/scratch-repo"
fi

# --- safety: refuse to touch a folder not created by this script ---
if [[ -d "${TARGET}" ]]; then
  if [[ ! -f "${TARGET}/${MARKER}" ]]; then
    printf 'Error: "%s" already exists and was not created by this script.\n' "${TARGET}" >&2
    printf 'Remove it yourself or choose a different path.\n' >&2
    exit 1
  fi
  rm -rf "${TARGET}"
fi

mkdir -p "${TARGET}"
cd "${TARGET}"

# Leave a marker so a re-run recognises and rebuilds this folder
touch "${MARKER}"

# --- fixed identity and timestamps: graph is identical on every run ---
export GIT_AUTHOR_NAME="Dev Student"
export GIT_AUTHOR_EMAIL="student@example.com"
export GIT_COMMITTER_NAME="Dev Student"
export GIT_COMMITTER_EMAIL="student@example.com"

git init --quiet -b main
git config user.email "${GIT_AUTHOR_EMAIL}"
git config user.name "${GIT_AUTHOR_NAME}"

# commit MSG TIMESTAMP — stage everything tracked and commit with a fixed time
commit() {
  local msg="$1" ts="$2"
  GIT_AUTHOR_DATE="${ts}" GIT_COMMITTER_DATE="${ts}" \
    git commit --quiet -m "${msg}"
}

# ---------------------------------------------------------------------------
# main: 8 commits
# ---------------------------------------------------------------------------

printf '# Project\n\nA sample project.\n' > README.md
printf 'status = pending\n' > tasks.txt
git add README.md tasks.txt
commit "Add README and task list" "2026-11-01T10:00:00+00:00"

printf '## Notes\n\nKeep notes here.\n' > notes.txt
git add notes.txt
commit "Add notes file" "2026-11-01T10:05:00+00:00"

printf 'status = pending\nowner = alice\n' > tasks.txt
git add tasks.txt
commit "Assign task owner" "2026-11-01T10:10:00+00:00"

printf 'mode = development\nlog = off\n' > config.txt
git add config.txt
commit "Add config file" "2026-11-01T10:15:00+00:00"
sha_fa_base="$(git rev-parse HEAD)"   # feature-a branches from here

printf '# Project\n\nA sample project. See tasks.txt for open work.\n' > README.md
git add README.md
commit "Update README with task reference" "2026-11-01T10:20:00+00:00"

printf 'status = in-progress\nowner = alice\n' > tasks.txt
git add tasks.txt
commit "Start task" "2026-11-01T10:25:00+00:00"
sha_fb_base="$(git rev-parse HEAD)"   # feature-b branches from here

printf 'mode = production\nlog = off\n' > config.txt
git add config.txt
commit "Set mode to production" "2026-11-01T10:30:00+00:00"
sha_hf_base="$(git rev-parse HEAD)"   # hotfix branches from here

# main final commit — changes config.txt line 1; conflicts with hotfix on the same line
printf 'mode = staging\nlog = off\n' > config.txt
git add config.txt
commit "Promote to staging" "2026-11-01T10:35:00+00:00"

# ---------------------------------------------------------------------------
# feature-a: one commit that stands alone (cherry-pick candidate; not in main)
# ---------------------------------------------------------------------------

git checkout --quiet -b feature-a "${sha_fa_base}"

printf '## Notes\n\nKeep notes here.\nReview weekly.\n' > notes.txt
git add notes.txt
commit "Add weekly review reminder to notes" "2026-11-01T11:00:00+00:00"

# ---------------------------------------------------------------------------
# feature-b: two commits
# ---------------------------------------------------------------------------

git checkout --quiet -b feature-b "${sha_fb_base}"

printf 'feature-b = on\n' > feature-b.txt
git add feature-b.txt
commit "Start feature-b" "2026-11-01T11:05:00+00:00"

printf 'feature-b = on\nstatus = complete\n' > feature-b.txt
git add feature-b.txt
commit "Complete feature-b" "2026-11-01T11:10:00+00:00"

# ---------------------------------------------------------------------------
# hotfix: one commit that conflicts with main on config.txt line 1
# ---------------------------------------------------------------------------

git checkout --quiet -b hotfix "${sha_hf_base}"

# Changes the same line as main's last commit (config.txt line 1 — mode = ...)
printf 'mode = debug\nlog = off\n' > config.txt
git add config.txt
commit "Enable debug mode for hotfix" "2026-11-01T11:15:00+00:00"

# ---------------------------------------------------------------------------

git checkout --quiet main

printf '\n'
git log --graph --oneline --all --decorate
printf '\nNothing to push. Run it again to reset.\n'
