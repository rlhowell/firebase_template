#!/bin/bash
set -e
SECRETS_DIR="$HOME/.secrets/firebase_template"
mkdir -p lib/firebase_options
cp "$SECRETS_DIR/staging/google-services.json" android/app/google-services.json
cp "$SECRETS_DIR/staging/GoogleService-Info.plist" ios/Runner/GoogleService-Info.plist
cp "$SECRETS_DIR/staging/firebase_options.dart" lib/firebase_options/firebase_options_staging.dart
fvm flutter run \
  --dart-define-from-file="$SECRETS_DIR/staging.json" \
  --target=lib/main_staging.dart
