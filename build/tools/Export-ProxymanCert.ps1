#!/usr/bin/env pwsh
# Exports the Proxyman root CA to build/config/proxyman-ca.pem so the cipp-api dev
# container can trust it (see build/docker-compose-proxyman.yml).
#
# The cipp-api container runs on the distroless Craft image — no shell, no
# update-ca-certificates. Instead of baking the cert into the image, we mount this
# PEM and point OpenSSL (which PowerShell 7 / .NET use for TLS on Linux) at it via
# SSL_CERT_FILE. Re-run this whenever Proxyman regenerates its CA.
#
# Requires Proxyman's CA to be installed/trusted on this machine:
#   macOS   — Proxyman > Certificate > Install Certificate on this Mac (login keychain)
#   Windows — Proxyman > Certificate > Install Certificate on this Windows (Root store)
[CmdletBinding()]
param(
    # Output PEM path. Default lands in build/config/ (gitignored) next to appsettings.
    [string]$OutputPath = (Join-Path $PSScriptRoot '../config/proxyman-ca.pem'),
    # Substring matched against the certificate subject/common name in the trust store.
    [string]$NameMatch = 'Proxyman'
)

$ErrorActionPreference = 'Stop'

# Wrap a DER-encoded cert in a PEM block (works on Windows PowerShell 5.1 and pwsh 7).
function ConvertTo-Pem([byte[]]$der) {
    $b64 = [Convert]::ToBase64String($der, [Base64FormattingOptions]::InsertLineBreaks)
    "-----BEGIN CERTIFICATE-----`n$b64`n-----END CERTIFICATE-----"
}

$blocks = [System.Collections.Generic.List[string]]::new()

# $IsMacOS/$IsWindows exist in pwsh 6+. On Windows PowerShell 5.1 they're undefined,
# so fall back to the platform check that treats 5.1 (Desktop edition) as Windows.
$onWindows = if ($null -ne $IsWindows) { $IsWindows } else { $PSVersionTable.PSEdition -eq 'Desktop' -or $env:OS -eq 'Windows_NT' }
$onMac = [bool]$IsMacOS

if ($onMac) {
    # -a: every match (Proxyman names its CA e.g. "Proxyman CA (hostname)"); -p: PEM output.
    $pem = & security find-certificate -a -c $NameMatch -p 2>$null
    if (-not $pem) {
        throw "No certificate matching '$NameMatch' found in the keychain. In Proxyman: Certificate > Install Certificate on this Mac > Install for this device, then re-run."
    }
    $blocks.Add((($pem -join "`n").Trim()))
}
elseif ($onWindows) {
    # Proxyman installs its CA into the Trusted Root store — CurrentUser when installed
    # for the user, LocalMachine when installed for the whole device. Check both.
    $found = @(
        Get-ChildItem 'Cert:\CurrentUser\Root', 'Cert:\LocalMachine\Root' -ErrorAction SilentlyContinue |
            Where-Object { $_.Subject -match $NameMatch }
    ) | Sort-Object Thumbprint -Unique
    if (-not $found) {
        throw "No certificate matching '$NameMatch' found in the Windows Root store. In Proxyman: Certificate > Install Certificate on this Windows, then re-run. (LocalMachine install may require an elevated shell to read.)"
    }
    foreach ($cert in $found) { $blocks.Add((ConvertTo-Pem($cert.Export('Cert')))) }
}
else {
    throw "Unsupported OS. Export the Proxyman root cert as PEM by hand and save it to $OutputPath."
}

# Resolve the output path against the current directory unless it's already absolute
# (leading / on Unix, or a drive letter / UNC on Windows).
$resolved = if ($OutputPath -match '^(/|\\\\|[A-Za-z]:)') { $OutputPath } else { [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath)) }
$dir = Split-Path -Parent $resolved
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

# One PEM block per cert; join with LF (not CRLF) so the file is valid for OpenSSL
# regardless of the host OS, and Set-Content -NoNewline avoids a trailing CRLF on Windows.
$out = (($blocks -join "`n").Trim()) + "`n"
$out = $out -replace "`r`n", "`n"
Set-Content -Path $resolved -Value $out -NoNewline -Encoding ascii

$count = ([regex]::Matches($out, 'BEGIN CERTIFICATE')).Count
Write-Host "Wrote $count certificate block(s) to $resolved" -ForegroundColor Green
Write-Host "Start the dev stack with Proxyman interception via the launcher (auto-detects this file):" -ForegroundColor Cyan
if ($onWindows) {
    Write-Host "  build/tools/Start-Cipp-Dev-Windows-docker.ps1"
} else {
    Write-Host "  build/tools/Start-CippDev.sh"
}
