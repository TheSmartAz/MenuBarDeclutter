#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="${SCHEME:-MenuBarDeclutterLogicTests}"
DESTINATION="${DESTINATION:-platform=macOS,arch=arm64}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedData/logic-tests}"
RESULT_DIR="${RESULT_DIR:-$ROOT_DIR/build/TestResults/logic-tests}"
TEST_BUNDLE="$DERIVED_DATA_PATH/Build/Products/Debug/MenuBarDeclutterLogicTests.xctest"
PROFILE_DIR="$RESULT_DIR/profiles"

cd "$ROOT_DIR"

mkdir -p "$RESULT_DIR"
rm -rf "$PROFILE_DIR"
mkdir -p "$PROFILE_DIR"

build_command=(
  xcodebuild
  build-for-testing
  -scheme "$SCHEME"
  -destination "$DESTINATION"
  -derivedDataPath "$DERIVED_DATA_PATH"
  ENABLE_DEBUG_DYLIB=YES
)

printf "+"
printf " %q" "${build_command[@]}" "$@"
printf "\n"
"${build_command[@]}" "$@"

if [[ ! -d "$TEST_BUNDLE" ]]; then
  echo "ERROR: Expected test bundle was not built: $TEST_BUNDLE" >&2
  exit 1
fi

test_command=(xcrun xctest "$TEST_BUNDLE")

printf "+"
printf " %q" "${test_command[@]}"
printf "\n"
LLVM_PROFILE_FILE="$PROFILE_DIR/MenuBarDeclutterLogicTests-%p.profraw" "${test_command[@]}"
