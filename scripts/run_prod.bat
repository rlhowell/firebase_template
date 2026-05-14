@echo off
set SECRETS_DIR=%USERPROFILE%\.secrets\firebase_template
if not exist lib\firebase_options mkdir lib\firebase_options
copy /Y "%SECRETS_DIR%\prod\google-services.json" android\app\google-services.json
copy /Y "%SECRETS_DIR%\prod\GoogleService-Info.plist" ios\Runner\GoogleService-Info.plist
copy /Y "%SECRETS_DIR%\prod\firebase_options.dart" lib\firebase_options\firebase_options_prod.dart
fvm flutter run --release ^
  --dart-define-from-file="%SECRETS_DIR%\prod.json" ^
  --target=lib/main_prod.dart
