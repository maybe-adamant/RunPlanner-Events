#!/usr/bin/env bash
# Validates every event folder with a local Run Planner checkout, as the pull request check does:
#   scripts/check-local.sh <path-to-RunPlanner-checkout>
# The checkout needs its dependencies installed (npm ci) and a Rust toolchain.
set -euo pipefail

planner="${1:?usage: scripts/check-local.sh <path-to-RunPlanner-checkout>}"
repository="$(cd "$(dirname "$0")/.." && pwd)"
out="$(mktemp -d)"
trap 'rm -rf "${out}"' EXIT

if [ ! -f "${planner}/scripts/events-build.mjs" ]; then
  echo "${planner} has no scripts/events-build.mjs; use a planner release with community events." >&2
  exit 1
fi
build=0000000000000000000000000000000000000000000000000000000000000000
(cd "${planner}" && npm run --silent events:build -- --events "${repository}/events" --out "${out}" \
  --build-id "${build}" --now 2000-01-01T00:00:00Z)
(cd "${planner}" && cargo run --quiet --manifest-path apps/planner/src-tauri/Cargo.toml \
  -p run-planner-game-host --example events_ci -- check "${out}/events.json" "${build}")
cat "${out}/summary.txt"
