#!/usr/bin/env bash
#
# Builds Network.xcframework and Logger.xcframework (device + simulator slices)
# and zips them, ready to be attached to a GitHub Release.
#
# Output: Modules/SampleModules/dist/{Network,Logger}.xcframework[.zip]
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODULE_DIR="${REPO_ROOT}/Modules/SampleModules"
DIST_DIR="${MODULE_DIR}/dist"
BUILD_DIR="${MODULE_DIR}/.build/xcframework"

MODULES=("Network" "Logger")
DEPLOYMENT_TARGET="${IPHONEOS_DEPLOYMENT_TARGET:-15.0}"

cd "${MODULE_DIR}"

if [[ ! -d "SampleModules.xcodeproj" ]]; then
  echo "==> Generating Xcode project with XcodeGen"
  xcodegen generate
fi

rm -rf "${DIST_DIR}" "${BUILD_DIR}"
mkdir -p "${DIST_DIR}" "${BUILD_DIR}"

archive() {
  local module="$1" dest_name="$2" archs="$3"
  echo "==> Archiving ${module} (${dest_name})"
  xcodebuild archive \
    -project SampleModules.xcodeproj \
    -scheme "${module}" \
    -configuration Release \
    -destination "${dest_name}" \
    -archivePath "${BUILD_DIR}/${module}-${archs// /_}.xcarchive" \
    -quiet \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO \
    ARCHS="${archs}" \
    IPHONEOS_DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}"
}

for MODULE in "${MODULES[@]}"; do
  archive "${MODULE}" "generic/platform=iOS" "arm64"
  archive "${MODULE}" "generic/platform=iOS Simulator" "arm64 x86_64"

  echo "==> Creating ${MODULE}.xcframework"
  xcodebuild -create-xcframework \
    -framework "${BUILD_DIR}/${MODULE}-arm64.xcarchive/Products/Library/Frameworks/${MODULE}.framework" \
    -framework "${BUILD_DIR}/${MODULE}-arm64_x86_64.xcarchive/Products/Library/Frameworks/${MODULE}.framework" \
    -output "${DIST_DIR}/${MODULE}.xcframework"

  echo "==> Zipping ${MODULE}.xcframework"
  ditto -c -k --sequesterRsrc --keepParent \
    "${DIST_DIR}/${MODULE}.xcframework" \
    "${DIST_DIR}/${MODULE}.xcframework.zip"
done

echo
echo "Done. Artifacts in ${DIST_DIR}:"
ls -la "${DIST_DIR}"
