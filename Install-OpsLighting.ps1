# Install-OpsLighting.ps1 — Setup PowerShell Profile Alias & Environment Integration
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetScript = Join-Path $ScriptDir 'Set-OpsCode.ps1'

if (-not (Test-Path $TargetScript)) {
    throw "Set-OpsCode.ps1 not found in $ScriptDir"
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🛸 ORVILLE SHIP LIGHTING — OPS CODE ENVIRONMENT SETUP" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Check/Create PowerShell Profile
if (-not (Test-Path $PROFILE)) {
    $profileDir = Split-Path -Parent $PROFILE
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Write-Host "[+] Created PowerShell Profile: $PROFILE" -ForegroundColor Green
}

$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if (-not $profileContent) { $profileContent = "" }

# 2. Inject 'ops' helper function if not present
$marker = "# >>> Orville Ship Lighting Helper"
if ($profileContent -notmatch [regex]::Escape($marker)) {
    $snippet = @"

$marker
function ops {
    param([Parameter(Mandatory=`$false)][string]`$Code = 'Blue')
    `& '$TargetScript' -Code `$Code
}
# <<< Orville Ship Lighting Helper
"@
    Add-Content -Path $PROFILE -Value $snippet -Encoding UTF8
    Write-Host "[+] Registered 'ops' command in `$PROFILE" -ForegroundColor Green
} else {
    Write-Host "[i] 'ops' command already configured in `$PROFILE" -ForegroundColor Gray
}

Write-Host "`nInstallation Complete! Usage:" -ForegroundColor Cyan
Write-Host "  ops green       -> Active Engineering Mode" -ForegroundColor Green
Write-Host "  ops pink        -> Standby / Architecture / Planning Mode" -ForegroundColor Magenta
Write-Host "  ops blue        -> Watchstander / Diagnostics Mode" -ForegroundColor Blue
Write-Host "  ops red         -> Tactical Alert / Anomaly Mode" -ForegroundColor Red
Write-Host "  ops restore     -> Restore Normal Windows Baseline Lighting" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
