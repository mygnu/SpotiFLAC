#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v wails >/dev/null 2>&1; then
  echo "Error: wails CLI is not installed or not in PATH."
  exit 1
fi

if ! command -v nfpm >/dev/null 2>&1; then
  echo "Error: nfpm is not installed or not in PATH."
  echo "Install with: go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest"
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Error: node is not installed or not in PATH."
  exit 1
fi

VERSION="$(node -e "const c=require('./wails.json');process.stdout.write(c.info.productVersion)")"
if [[ -z "$VERSION" ]]; then
  echo "Error: failed to read version from wails.json"
  exit 1
fi

mkdir -p build/dist

# Generate the app icon from SVG
echo "Generating app icon..."
cd frontend
pnpm install
node scripts/generate-icon.js
cd ..

# Fedora/newer distros use WebKitGTK 4.1 pkg-config name.
echo "Building with Wails..."
wails build -tags webkit2_41

echo "Creating packages..."

# Build RPM
RPM_TARGET="build/dist/SpotiFLAC_${VERSION}_linux_x86_64.rpm"
VERSION="$VERSION" nfpm package --packager rpm --config packaging/linux/nfpm.rpm.yaml --target "$RPM_TARGET"
echo "✓ RPM package created: $RPM_TARGET"

# Build DEB
DEB_TARGET="build/dist/SpotiFLAC_${VERSION}_linux_amd64.deb"
VERSION="$VERSION" nfpm package --packager deb --config packaging/linux/nfpm.deb.yaml --target "$DEB_TARGET"
echo "✓ DEB package created: $DEB_TARGET"

echo "Packages ready in: build/dist/"
