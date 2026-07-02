#!/usr/bin/env bash
set -eo pipefail

# Read-only guard that detects Duo Code Review instruction fences in
# .gitlab/duo/mr-review-instructions.yaml that are stale (recorded
# distilled_at_sha/source_checksum no longer match their distilled file),
# malformed (a BEGIN marker without exactly one matching region), or orphaned
# (a fence with no backing distilled file or manifest entry).
#
# Runs at commit/MR time (lefthook + the `ai-duo-review-instructions` CI job)
# so a bad fence introduced in an MR fails fast instead of silently landing.
# See gitlab-org/gitlab#604738.
#
# The command's only runtime dependency is the `rainbow` gem and it loads no
# Rails. Locally (lefthook) the host bundle already provides `rainbow`, so the
# default `bundle exec ruby` resolves it. The CI job runs on a bare Ruby image
# and sets RUBY_RUN="ruby" after a single `gem install rainbow`, skipping the
# full bundle install entirely.

GEM_DIR="gems/gitlab-ai-principles-distiller"
RUBY_RUN="${RUBY_RUN:-bundle exec ruby}"

exec ${RUBY_RUN} "${GEM_DIR}/bin/gitlab-ai-principles-distiller-sync" --check-duo-instructions --workspace .
