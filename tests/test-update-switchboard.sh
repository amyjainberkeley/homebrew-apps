#!/usr/bin/env bash
# Each case tests run_update's exit status, so this note does not apply:
# shellcheck disable=SC2310
set -euo pipefail

# test-update-switchboard.sh — update-switchboard.sh writes a release's version
# and the hash of its download into the cask only for a download that is that
# version of Switchboard, with what the cask runs. The downloads are made-up
# trees; the cask is a scratch copy.

TAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d -t switchboard-update-cask)"
trap 'rm -rf "${TMP_ROOT}"' EXIT

PASS_COUNT=0
FAIL_COUNT=0
pass() {
  printf 'PASS: %s\n' "$1"
  PASS_COUNT=$((PASS_COUNT + 1))
}
fail() {
  printf 'FAIL: %s\n' "$1" >&2
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

mkdir -p "${TMP_ROOT}/tap/Casks"
cp "${TAP_ROOT}/update-switchboard.sh" "${TMP_ROOT}/tap/"
cp "${TAP_ROOT}/Casks/switchboard.rb" "${TMP_ROOT}/tap/Casks/"
CASK="${TMP_ROOT}/tap/Casks/switchboard.rb"

# tarball NAME FOLDER VERSION [nopack]: a made-up download, as GitHub serves a tag
tarball() {
  local tree="${TMP_ROOT}/src/$1"
  mkdir -p "${tree}/$2/switchboard"
  printf "VERSION = '%s'\n" "$3" >"${tree}/$2/switchboard/core.py"
  : >"${tree}/$2/install.sh"
  if [[ "${4:-}" != "nopack" ]]
  then
    mkdir -p "${tree}/$2/packaging/homebrew"
    : >"${tree}/$2/packaging/homebrew/launcher"
    : >"${tree}/$2/packaging/homebrew/uninstall.sh"
  fi
  tar -czf "${TMP_ROOT}/$1.tar.gz" -C "${tree}" "$2"
}

run_update() {
  env UPDATE_CASK_SKIP_STYLE=1 SWITCHBOARD_TARBALL="${TMP_ROOT}/$1.tar.gz" \
    "${TMP_ROOT}/tap/update-switchboard.sh" "$2" >"${TMP_ROOT}/out" 2>&1
}

refuses() {
  local name="$1" download="$2" version="$3" says="$4"
  cp "${CASK}" "${TMP_ROOT}/before.rb"
  if run_update "${download}" "${version}"
  then
    fail "${name} (it was accepted)"
  elif grep -qF "${says}" "${TMP_ROOT}/out" && cmp -s "${CASK}" "${TMP_ROOT}/before.rb"
  then
    pass "${name}"
  else
    fail "${name}: $(cat "${TMP_ROOT}/out")"
  fi
}

tarball good switchboard-0.2.1 0.2.1
tarball other switchboard-0.2.1 0.2.0
tarball branch switchboard-main 0.2.1
tarball nopack switchboard-0.2.1 0.2.1 nopack

refuses 'a download of another version is refused' other 0.2.1 'is version 0.2.0, not 0.2.1'
refuses 'a download of a branch, not the tag, is refused' branch 0.2.1 'is not switchboard-0.2.1/'
refuses 'a download without packaging/homebrew is refused' nopack 0.2.1 'is not switchboard-0.2.1/'
refuses 'a version that is not one is refused' good v0.2.1 'expected a version like 0.2.0'

cp "${CASK}" "${TMP_ROOT}/before.rb"
SHA256="$(shasum -a 256 "${TMP_ROOT}/good.tar.gz" | awk '{ print $1 }')"
if run_update good 0.2.1 && grep -qx '  version "0.2.1"' "${CASK}" && grep -qx "  sha256 \"${SHA256}\"" "${CASK}" &&
  [[ "$(diff "${TMP_ROOT}/before.rb" "${CASK}" | grep -c '^>')" == 2 ]]
then
  pass 'the matching download sets version and sha256, and nothing else'
else
  fail "the matching download: $(cat "${TMP_ROOT}/out")"
fi

printf '%s passed, %s failed\n' "${PASS_COUNT}" "${FAIL_COUNT}"
[[ "${FAIL_COUNT}" == 0 ]]
