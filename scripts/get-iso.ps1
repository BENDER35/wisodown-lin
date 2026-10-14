#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Download a Windows ISO link using the wisodown API.

.DESCRIPTION
    Interactive script that uses the wisodown API (wiso.krnl64.win) to
    generate a direct download link for a Windows ISO from Microsoft.

    Runs on Windows PowerShell 5.1+ and on PowerShell 7+ (pwsh) on Linux and
    macOS. On Linux/macOS, make it executable and run it directly, or invoke
    it through pwsh:

        chmod +x ./get-iso.ps1
        ./get-iso.ps1 -Edition x64 -Language English
        # or
        pwsh ./get-iso.ps1 -Edition x64 -Language English -Download

.PARAMETER ApiBase
    Base URL of the wisodown API. Defaults to https://wiso.krnl64.win

.PARAMETER Edition
    Edition alias: x64, arm64, win10, win11-cn-home, win11-cn-pro.
    If omitted, you'll be prompted to choose.

.PARAMETER Language
    Language name (e.g. English, French). If omitted, you'll be prompted.

.PARAMETER Download
    If set, downloads the ISO directly instead of just printing the link.

.EXAMPLE
    .\get-iso.ps1
    .\get-iso.ps1 -Edition x64 -Language English
    .\get-iso.ps1 -Edition arm64 -Language Japanese -Download
#>
[CmdletBinding()]
param(
    [string]$ApiBase = "https://wiso.krnl64.win",
    [string]$Edition,
    [string]$Language,
    [switch]$Download
)

$ErrorActionPreference = "Stop"
# Speeds up Invoke-WebRequest substantially on all platforms.
$ProgressPreference = "SilentlyContinue"

function Write-Step($msg) { Write-Host "-> $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Err($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# Reads and validates an integer in [$min, $max]. Works the same on every
# platform (previous versions compared raw strings, which behaved oddly).
function Read-Choice([string]$Prompt, [int]$Min, [int]$Max) {
    while ($true) {
        $raw = Read-Host $Prompt
        $value = 0
        if ([int]::TryParse($raw, [ref]$value) -and $value -ge $Min -and $value -le $Max) {
            return $value
        }
        Write-Err "Please enter a number between $Min and $Max."
    }
}

# ── 1. Select edition ────────────────────────────────────────────────────────

$editions = @(
    @{ key = "x64";           label = "Windows 11 (x64)" }
    @{ key = "arm64";         label = "Windows 11 (ARM64)" }
    @{ key = "win10";         label = "Windows 10" }
    @{ key = "win11-cn-home"; label = "Windows 11 Home China" }
    @{ key = "win11-cn-pro";  label = "Windows 11 Pro China" }
)

if (-not $Edition) {
    Write-Host "`nWindows ISO Downloader" -ForegroundColor White
    Write-Host "======================" -ForegroundColor DarkGray
    Write-Host ""
    for ($i = 0; $i -lt $editions.Count; $i++) {
        Write-Host "  [$($i + 1)] $($editions[$i].label)"
    }
    Write-Host ""
    $choice = Read-Choice "Select edition (1-$($editions.Count))" 1 $editions.Count
    $Edition = $editions[$choice - 1].key
}

# ── 2. Fetch languages ───────────────────────────────────────────────────────

Write-Step "Fetching languages for '$Edition'..."
try {
    $skus = @(Invoke-RestMethod -Uri "$ApiBase/api/skus?edition=$([uri]::EscapeDataString($Edition))")
} catch {
    Write-Err "Request failed: $($_.Exception.Message)"
    exit 1
}
if ($skus.Count -eq 1 -and $skus[0].PSObject.Properties['error']) {
    Write-Err $skus[0].error
    exit 1
}

if (-not $Language) {
    Write-Host ""
    for ($i = 0; $i -lt $skus.Count; $i++) {
        Write-Host "  [$($i + 1)] $($skus[$i].LocalizedLanguage) ($($skus[$i].Language))"
    }
    Write-Host ""
    $choice = Read-Choice "Select language (1-$($skus.Count))" 1 $skus.Count
    $Language = $skus[$choice - 1].Language
}

# ── 3. Get download links ────────────────────────────────────────────────────

Write-Step "Generating download link..."
$langEncoded = [uri]::EscapeDataString($Language)
try {
    $links = Invoke-RestMethod -Uri "$ApiBase/api/links?edition=$([uri]::EscapeDataString($Edition))&language=$langEncoded"
} catch {
    Write-Err "Request failed: $($_.Exception.Message)"
    exit 1
}
if ($links.PSObject.Properties['error']) {
    Write-Err $links.error
    exit 1
}

Write-Host ""
Write-Ok "$($links.localizedLanguage)"
if ($links.filename) {
    Write-Host "  File: $($links.filename)" -ForegroundColor DarkGray
}
if ($links.expiresAt) {
    Write-Host "  Expires: $($links.expiresAt)" -ForegroundColor DarkGray
}

$downloads = @($links.downloads)
Write-Host ""
foreach ($dl in $downloads) {
    Write-Host "  $($dl.name)" -ForegroundColor White
    Write-Host "  $($dl.url)" -ForegroundColor Yellow
    Write-Host ""
}

# ── 4. Show hashes ───────────────────────────────────────────────────────────

if ($links.hashes -and $links.hashes.PSObject.Properties.Count -gt 0) {
    Write-Host "SHA-256 Hashes:" -ForegroundColor White
    foreach ($prop in $links.hashes.PSObject.Properties) {
        Write-Host "  $($prop.Name): $($prop.Value)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# ── 5. Download if requested ─────────────────────────────────────────────────

if ($Download -and $downloads.Count -gt 0) {
    $url = $downloads[0].url
    $filename = if ($links.filename) { $links.filename } else { "windows.iso" }
    Write-Step "Downloading $filename..."
    Invoke-WebRequest -Uri $url -OutFile $filename -UseBasicParsing
    Write-Ok "Saved to $filename"
}
