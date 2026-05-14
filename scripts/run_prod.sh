#!/bin/bash
set -e
SECRETS_DIR="$HOME/.secrets/firebase_template"
mkdir -p lib/firebase_options
cp "$SECRETS_DIR/prod/google-services.json" android/app/google-services.json
cp "$SECRETS_DIR/prod/GoogleService-Info.plist" ios/Runner/GoogleService-Info.plist
cp "$SECRETS_DIR/prod/firebase_options.dart" lib/firebase_options/firebase_options_prod.dart
fvm flutter run --release \
  --dart-define-from-file="$SECRETS_DIR/prod.json" \
  --target=lib/main_prod.dart
