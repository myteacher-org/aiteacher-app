#!/bin/bash
# Scans a built iOS app for the private/deprecated API symbols that App Store
# Connect rejects. Run before every submission:
#
#   flutter build ios --release
#   ios/patches/verify_private_apis.sh
#
# Optionally pass a path to a .app bundle (defaults to the Flutter release build).

set -u

APP="${1:-$(cd "$(dirname "$0")/../.." && pwd)/build/ios/iphoneos/Runner.app}"
SYMBOLS=("PGHostedWindow" "buttonPressed:")

if [ ! -d "$APP" ]; then
  echo "No app bundle at $APP — build it first with 'flutter build ios --release'." >&2
  exit 1
fi

echo "Scanning $APP"
status=0

while IFS= read -r binary; do
  file "$binary" | grep -q "Mach-O" || continue
  # strings covers literals and Objective-C selector/class name sections; nm
  # covers the symbol table, which strings does not reliably read.
  dump="$( { strings -a "$binary"; nm -a "$binary" 2>/dev/null; } )"
  for symbol in "${SYMBOLS[@]}"; do
    if grep -qF "$symbol" <<<"$dump"; then
      echo "FOUND $symbol in ${binary#"$APP"/}"
      status=1
    fi
  done
done < <(find "$APP" -type f -perm +111)

if [ "$status" -eq 0 ]; then
  echo "Clean: none of the flagged symbols are present."
fi

exit "$status"
