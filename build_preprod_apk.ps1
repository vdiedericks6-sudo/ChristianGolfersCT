param(
  [Parameter(Mandatory = $true)][string]$SupabaseUrl,
  [Parameter(Mandatory = $true)][string]$SupabasePublishableKey
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$testUrl = $SupabaseUrl.TrimEnd('/')
$productionUrl = 'https://cegmyadsnrvzlgpwoezu.supabase.co'

if ($testUrl -eq $productionUrl -or $testUrl -notmatch '^https://[a-z0-9-]+\.supabase\.co$') {
  throw 'Provide a separate Supabase test project URL. The production project cannot be used for this build.'
}
if ($SupabasePublishableKey -notmatch '^sb_publishable_') {
  throw 'Provide the test project publishable key. Never use a secret or service-role key.'
}

$socketDirectory = Join-Path $projectRoot '.tmp-jdk-sockets'
New-Item -ItemType Directory -Path $socketDirectory -Force | Out-Null
$env:JAVA_TOOL_OPTIONS = "-Djdk.net.unixdomain.tmpdir=$socketDirectory"
Push-Location $projectRoot
try {
  & flutter build apk --debug --no-pub "--dart-define=SUPABASE_URL=$testUrl" "--dart-define=SUPABASE_PUBLISHABLE_KEY=$SupabasePublishableKey"
  if ($LASTEXITCODE -ne 0) { throw "Flutter build failed with exit code $LASTEXITCODE." }
  Write-Host 'Pre-production debug APK: build/app/outputs/flutter-apk/app-debug.apk'
} finally {
  Pop-Location
}
