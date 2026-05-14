#!/bin/bash
set -e
SECRETS_DIR="$HOME/.secrets/firebase_template"
mkdir -p lib/firebase_options
cp "$SECRETS_DIR/dev/google-services.json" android/app/google-services.json
cp "$SECRETS_DIR/dev/GoogleService-Info.plist" ios/Runner/GoogleService-Info.plist
cp "$SECRETS_DIR/dev/firebase_options.dart" lib/firebase_options/firebase_options_dev.dart
fvm flutter run \
  --dart-define-from-file="$SECRETS_DIR/dev.json" \
  --target=lib/main_dev.dart
