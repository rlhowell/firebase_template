@echo off
set SECRETS_DIR=%USERPROFILE%\.secrets\firebase_template
if not exist lib\firebase_options mkdir lib\firebase_options
copy /Y "%SECRETS_DIR%\staging\google-services.json" android\app\google-services.json
copy /Y "%SECRETS_DIR%\staging\GoogleService-Info.plist" ios\Runner\GoogleService-Info.plist
copy /Y "%SECRETS_DIR%\staging\firebase_options.dart" lib\firebase_options\firebase_options_staging.dart
fvm flutter run ^
  --dart-define-from-file="%SECRETS_DIR%\staging.json" ^
  --target=lib/main_staging.dart
