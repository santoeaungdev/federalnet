#!/usr/bin/env bash
set -euo pipefail

# Build debug APKs for all Flutter apps in this repo. Run locally where Flutter SDK is installed.

ROOT_DIR="$(dirname "$0")/.."
echo "Building APKs from $ROOT_DIR"

for app in admin_app owner_app customer_app; do
  APP_DIR="$ROOT_DIR/frontend/$app"
  echo "\n== Building $app =="
  if [ ! -d "$APP_DIR" ]; then
    echo "Directory not found: $APP_DIR" >&2
    continue
  fi
  (cd "$APP_DIR" && flutter pub get && flutter build apk --debug)
done

echo "Builds finished. APKs located in each app's build/app/outputs/flutter-apk/"
