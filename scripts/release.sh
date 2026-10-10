#!/usr/bin/env bash
#
# Publishes a release of the SampleModules package:
#
#   1. Builds Network.xcframework / Logger.xcframework (scripts/build-xcframeworks.sh)
#   2. Computes SwiftPM checksums for the zipped artifacts
#   3. Renders the binary manifest from Distribution/Package.swift.template
#   4. Force-pushes the `source` branch (source package at repo root) + tag
#   5. Force-pushes the `binary` branch (binary manifest at repo root)
#   6. Creates a GitHub Release and uploads both xcframework zips
#
# Usage:
#   scripts/release.sh 1.0.0
#
# Environment:
#   GITHUB_REPO    default: amitkumar0000/sampleios
#   GITHUB_TOKEN   optional; when set, branch/tag pushes and the release use it
#                  (used automatically in GitHub Actions). Otherwise the local
#                  git credential helper and an authenticated `gh` are used.
#   SKIP_BUILD=1   reuse the existing artifacts in Modules/SampleModules/dist
#
set -euo pipefail

VERSION="${1:-}"
REPO="${GITHUB_REPO:-amitkumar0000/sampleios}"
SKIP_BUILD="${SKIP_BUILD:-0}"

if [[ -z "${VERSION}" ]]; then
  echo "Usage: $0 <version>   e.g. $0 1.0.0" >&2
  exit 1
fi
if ! [[ "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must be plain semver without a leading 'v' (e.g. 1.0.0)" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODULE_DIR="${REPO_ROOT}/Modules/SampleModules"
DIST_DIR="${MODULE_DIR}/dist"
TAG="${VERSION}"

GIT_NAME="$(git -C "${REPO_ROOT}" config user.name 2>/dev/null || true)"
GIT_EMAIL="$(git -C "${REPO_ROOT}" config user.email 2>/dev/null || true)"
GIT_NAME="${GIT_NAME:-sampleios-bot}"
GIT_EMAIL="${GIT_EMAIL:-sampleios-bot@users.noreply.github.com}"

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  PUSH_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${REPO}.git"
else
  PUSH_URL="$(git -C "${REPO_ROOT}" remote get-url origin)"
fi

echo "==> Releasing ${REPO} ${TAG}"

# 1. Build binaries ---------------------------------------------------------
if [[ "${SKIP_BUILD}" != "1" ]]; then
  "${SCRIPT_DIR}/build-xcframeworks.sh"
fi

# 2. Checksums --------------------------------------------------------------
NETWORK_SUM="$(swift package compute-checksum "${DIST_DIR}/Network.xcframework.zip")"
LOGGER_SUM="$(swift package compute-checksum "${DIST_DIR}/Logger.xcframework.zip")"
echo "    Network checksum: ${NETWORK_SUM}"
echo "    Logger  checksum: ${LOGGER_SUM}"

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

# 3. Render binary manifest -------------------------------------------------
BINARY_PKG="${WORK}/binary-Package.swift"
sed -e "s/__VERSION__/${TAG}/g" \
    -e "s/__NETWORK_CHECKSUM__/${NETWORK_SUM}/g" \
    -e "s/__LOGGER_CHECKSUM__/${LOGGER_SUM}/g" \
    "${MODULE_DIR}/Distribution/Package.swift.template" > "${BINARY_PKG}"

publish_branch() {
  local branch="$1" dir="$2"
  git -C "${dir}" init -q -b "${branch}"
  git -C "${dir}" add -A
  git -C "${dir}" -c user.name="${GIT_NAME}" -c user.email="${GIT_EMAIL}" \
      commit -q -m "Publish ${branch} ${TAG}"
  git -C "${dir}" remote add origin "${PUSH_URL}"
  git -C "${dir}" push -f origin "${branch}"
}

# 4. Publish `source` branch (package at repo root) + tag -------------------
SRC="${WORK}/source"
mkdir -p "${SRC}"
cp "${MODULE_DIR}/Package.swift" "${SRC}/Package.swift"
cp -R "${MODULE_DIR}/Sources" "${SRC}/Sources"
cp -R "${MODULE_DIR}/Tests" "${SRC}/Tests"
cp "${MODULE_DIR}/README.md" "${SRC}/README.md"
cp "${MODULE_DIR}/.gitignore" "${SRC}/.gitignore"
publish_branch source "${SRC}"
git -C "${SRC}" -c user.name="${GIT_NAME}" -c user.email="${GIT_EMAIL}" \
    tag -a "${TAG}" -m "Release ${TAG}"
git -C "${SRC}" push origin "${TAG}"

# 5. Publish `binary` branch ------------------------------------------------
BIN="${WORK}/binary"
mkdir -p "${BIN}"
cp "${BINARY_PKG}" "${BIN}/Package.swift"
cp "${MODULE_DIR}/Distribution/README.binary.md" "${BIN}/README.md"
cp "${MODULE_DIR}/.gitignore" "${BIN}/.gitignore"
publish_branch binary "${BIN}"

# 6. GitHub Release ---------------------------------------------------------
if command -v gh >/dev/null 2>&1; then
  echo "==> Creating GitHub release ${TAG}"
  gh release create "${TAG}" \
    --repo "${REPO}" \
    --title "${TAG}" \
    --notes "Source: tag \`${TAG}\` (branch \`source\`). Binary: branch \`binary\`." \
    "${DIST_DIR}/Network.xcframework.zip" \
    "${DIST_DIR}/Logger.xcframework.zip"
else
  echo "!! gh CLI not found — branches and tag were pushed, but no GitHub Release was created." >&2
  echo "   Install it with 'brew install gh && gh auth login', or upload the zip files manually:" >&2
  ls -1 "${DIST_DIR}"/*.zip >&2
fi

echo "==> Done: ${TAG}"
