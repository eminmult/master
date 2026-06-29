#!/usr/bin/env bash
# Сборка release APK в Docker (без локального Flutter SDK).
# Артефакт остаётся на хосте в build/app/outputs/flutter-apk/app-release.apk.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

API_BASE_URL="${API_BASE_URL:-https://itez.app/api/v1}"
SITE_URL="${SITE_URL:-https://itez.app}"
REVERB_HOST="${REVERB_HOST:-ws.itez.app}"
REVERB_KEY="${REVERB_KEY:-}"
REVERB_PORT="${REVERB_PORT:-443}"

# Используем тот же Flutter docker-образ, что и для web-сборки.
docker run --rm \
  -v "$ROOT":/app \
  -w /app \
  ghcr.io/cirruslabs/flutter:3.24.5 \
  bash -lc '
    set -e
    flutter --version
    flutter create . --org az.gasimov.itez --platforms=android --project-name itez_mobile
    flutter pub get
    dart run build_runner build --delete-conflicting-outputs || true
    flutter gen-l10n || true
    flutter build apk --release \
      --dart-define=API_BASE_URL='"$API_BASE_URL"' \
      --dart-define=SITE_URL='"$SITE_URL"' \
      --dart-define=REVERB_HOST='"$REVERB_HOST"' \
      --dart-define=REVERB_KEY='"$REVERB_KEY"' \
      --dart-define=REVERB_PORT='"$REVERB_PORT"'
  '

echo
echo "APK готов: $ROOT/build/app/outputs/flutter-apk/app-release.apk"
ls -lh build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || true
