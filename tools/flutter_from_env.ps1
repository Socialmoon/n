param(
  [ValidateSet('run', 'build-apk')]
  [string]$Mode = 'run'
)

$envFile = Join-Path $PSScriptRoot '..\.env'
if (-not (Test-Path $envFile)) {
  throw "Missing .env file at $envFile"
}

function Get-EnvValue {
  param([string]$Name)

  foreach ($line in Get-Content $envFile) {
    if ($line -match "^$Name=(.*)$") {
      return $matches[1].Trim()
    }
  }

  return ''
}

$supabaseUrl = Get-EnvValue 'SUPABASE_URL'
$supabaseAnonKey = Get-EnvValue 'SUPABASE_ANON_KEY'
$cdnBaseUrl = Get-EnvValue 'CLOUDFLARE_CDN_BASE_URL'
if ([string]::IsNullOrWhiteSpace($cdnBaseUrl)) {
  $cdnBaseUrl = Get-EnvValue 'CDN_BASE_URL'
}

if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or [string]::IsNullOrWhiteSpace($supabaseAnonKey)) {
  throw 'SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env'
}

$defines = @(
  "--dart-define=SUPABASE_URL=$supabaseUrl",
  "--dart-define=SUPABASE_ANON_KEY=$supabaseAnonKey"
)

if (-not [string]::IsNullOrWhiteSpace($cdnBaseUrl)) {
  $defines += "--dart-define=CDN_BASE_URL=$cdnBaseUrl"
}

switch ($Mode) {
  'run' {
    flutter run @defines
  }
  'build-apk' {
    flutter build apk --release @defines
  }
}