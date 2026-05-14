@echo off
set SECRETS_DIR=%USERPROFILE%\.secrets\firebase_template
if not exist lib\firebase_options mkdir lib\firebase_options
copy /Y "%SECRETS_DIR%\dev\google-services.json" android\app\google-services.json
copy /Y "%SECRETS_DIR%\dev\GoogleService-Info.plist" ios\Runner\GoogleService-Info.plist
copy /Y "%SECRETS_DIR%\dev\firebase_options.dart" lib\firebase_options\firebase_options_dev.dart
fvm flutter run ^
  --dart-define-from-file="%SECRETS_DIR%\dev.json" ^
  --target=lib/main_dev.dart
