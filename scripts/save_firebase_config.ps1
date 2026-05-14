param(
    [Parameter(Mandatory)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Env
)

$ProjectRoot = Resolve-Path "$PSScriptRoot\.."

$PubspecPath = Join-Path $ProjectRoot "pubspec.yaml"
$AppNameMatch = Get-Content $PubspecPath | Select-String "^name:\s+(\S+)"

if (-not $AppNameMatch) {
    throw "Could not find app name in pubspec.yaml"
}

$AppName = $AppNameMatch.Matches[0].Groups[1].Value
$SecretsDir = Join-Path $env:USERPROFILE ".secrets\$AppName"
$Dest = Join-Path $SecretsDir $Env

$OutFile = "firebase_options_$Env.dart"

$Files = @(
    @{
        Src = Join-Path $ProjectRoot "android\app\google-services.json"
        Dst = Join-Path $Dest "google-services.json"
    },
    @{
        Src = Join-Path $ProjectRoot "ios\Runner\GoogleService-Info.plist"
        Dst = Join-Path $Dest "GoogleService-Info.plist"
    },
    @{
        Src = Join-Path $ProjectRoot "lib\firebase_options\$OutFile"
        Dst = Join-Path $Dest "firebase_options.dart"
    }
)

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

$allOk = $true

foreach ($f in $Files) {
    if (Test-Path $f.Src) {
        Copy-Item $f.Src $f.Dst -Force
        Write-Host "Saved $($f.Src)"
    } else {
        Write-Warning "Not found, skipping: $($f.Src)"
        $allOk = $false
    }
}

if ($allOk) {
    Write-Host ""
    Write-Host "All $Env Firebase config saved to $Dest"
} else {
    Write-Host ""
    Write-Host "Some files were missing. Run flutterfire configure for '$Env' first."
}