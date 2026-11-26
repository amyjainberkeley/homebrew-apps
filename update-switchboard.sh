#!/usr/bin/env bash
set -euo pipefail

# update-switchboard.sh — Point the Switchboard cask at a release: its version
# and the SHA-256 of the release tag's download from GitHub.
#
#   ./update-switchboard.sh 0.2.0
#
# It downloads the tag v<version> as GitHub serves it and refuses a download
# that is not that version of Switchboard: everything must be in
# switchboard-<version>/, its switchboard/core.py must say that version, and it
# must hold the installer and packaging/homebrew, which the cask runs.
# Then it rewrites version and sha256 in Casks/switchboard.rb and runs
# `brew style` on it. SWITCHBOARD_TARBALL names a file to use instead of the
# download and UPDATE_CASK_SKIP_STYLE=1 skips `brew style`, for its test.

TAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CASK="${TAP_ROOT}/Casks/switchboard.rb"

die() {
  printf 'update-switchboard: %s\n' "$*" >&2
  exit 1
}

[[ $# -eq 1 ]] || {
  sed -n '4,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
  exit 2
}
VERSION="$1"
[[ "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "expected a version like 0.2.0, got ${VERSION}"
# The release's own file, uploaded with it: its bytes never change. (The archive GitHub makes from a tag on
# request is not promised to stay the same byte for byte, and a changed byte would break every install.)
URL="https://github.com/amyjainberkeley/switchboard/releases/download/v${VERSION}/switchboard-${VERSION}.tar.gz"
TOP="switchboard-${VERSION}"

WORK="$(mktemp -d -t switchboard-cask)"
trap 'rm -rf "${WORK}"' EXIT
if [[ -n "${SWITCHBOARD_TARBALL:-}" ]]
then
  cp "${SWITCHBOARD_TARBALL}" "${WORK}/release.tar.gz"
else
  curl -fsSL --retry 2 -o "${WORK}/release.tar.gz" "${URL}" ||
    die "could not download ${URL} (is v${VERSION} released with that file, and the repository public?)"
fi

tar -xzf "${WORK}/release.tar.gz" -C "${WORK}" "${TOP}/switchboard/core.py" "${TOP}/install.sh" \
  "${TOP}/packaging/homebrew/launcher" "${TOP}/packaging/homebrew/uninstall.sh" 2>/dev/null ||
  die "the download is not ${TOP}/ with the installer and packaging/homebrew in it"
INSIDE="$(sed -n "s/^VERSION = '\([^']*\)'.*/\1/p" "${WORK}/${TOP}/switchboard/core.py" | head -n 1)"
[[ "${INSIDE}" == "${VERSION}" ]] || die "the download is version ${INSIDE:-unknown}, not ${VERSION}"

SHA256="$(shasum -a 256 "${WORK}/release.tar.gz" | awk '{ print $1 }')"
sed -i '' -E \
  -e "s/^  version \"[^\"]+\"$/  version \"${VERSION}\"/" \
  -e "s/^  sha256 \"[0-9a-f]{64}\"$/  sha256 \"${SHA256}\"/" \
  "${CASK}"
if ! grep -qx "  version \"${VERSION}\"" "${CASK}" || ! grep -qx "  sha256 \"${SHA256}\"" "${CASK}"
then
  die "could not write version ${VERSION} and its sha256 into ${CASK}"
fi

if [[ "${UPDATE_CASK_SKIP_STYLE:-0}" != "1" ]]
then
  HOMEBREW_NO_AUTO_UPDATE=1 brew style "${CASK}"
fi

echo "Casks/switchboard.rb: version ${VERSION}, sha256 ${SHA256}"
