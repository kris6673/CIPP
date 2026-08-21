<#
.SYNOPSIS
    Splits intuneCollection.json into one file per setting definition for the frontend to fetch.

.DESCRIPTION
    A settings catalog policy references around 2% of the ~18k definitions in the catalog, so the
    UI fetches the definitions it needs individually instead of downloading the whole 17MB file.
    This writes that per-definition layout into frontend\public\intune-definitions.

    Files are named by the SHA-256 of the setting definition id rather than by the id itself:
    ids run up to 278 characters, and frontend\public\intune-definitions\<id>.json exceeds the
    260-character Windows MAX_PATH, which would break checkout and build on Windows. The first
    byte of the hash is also used as a subdirectory so no single folder holds all 18k files.

    The frontend computes the same path with SubtleCrypto - see src\hooks\use-intune-collection.js.
    Both sides hash the UTF-8 bytes of the id and take the first 16 hex characters, so any change
    to the scheme has to be made in both places.

    The bundled backend\Config\intuneCollection.json is left alone: Compare-CIPPIntuneObject.ps1
    reads it directly and needs the whole catalog in one file.

.PARAMETER CollectionPath
    Source catalog. Defaults to backend\Config\intuneCollection.json.

.PARAMETER OutputPath
    Destination folder. Defaults to frontend\public\intune-definitions.

.EXAMPLE
    .\Split-IntuneCollection.ps1

.NOTES
    Run after Update-IntuneCollection.ps1, which calls this automatically.
#>

[CmdletBinding()]
param(
    [string]$CollectionPath = (Join-Path $PSScriptRoot '..\..\backend\Config\intuneCollection.json'),
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\..\frontend\public\intune-definitions')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $CollectionPath)) {
    throw "Collection not found: $CollectionPath"
}

$CollectionPath = (Resolve-Path $CollectionPath).Path
Write-Host "Reading $CollectionPath..." -ForegroundColor Yellow

# JsonDocument rather than ConvertFrom-Json: GetRawText hands back each definition's original JSON,
# so nothing is reserialised and the output matches the source byte for byte.
$Document = [System.Text.Json.JsonDocument]::Parse([System.IO.File]::ReadAllText($CollectionPath))

# Rebuilt from scratch so definitions Intune has retired do not linger as stale files.
if (Test-Path $OutputPath) {
    Write-Host 'Removing previous output...' -ForegroundColor Yellow
    Remove-Item -Path $OutputPath -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $OutputPath -Force
$OutputPath = (Resolve-Path $OutputPath).Path

$Sha = [System.Security.Cryptography.SHA256]::Create()
$Buckets = [System.Collections.Generic.HashSet[string]]::new()
$Hashes = @{}
$Written = 0
$Skipped = 0

try {
    foreach ($Element in $Document.RootElement.EnumerateArray()) {
        # TryGetProperty takes a by-ref out parameter PowerShell cannot bind, so a missing 'id'
        # is caught rather than tested for.
        $Id = $null
        try { $Id = $Element.GetProperty('id').GetString() } catch { $Id = $null }

        if ([string]::IsNullOrWhiteSpace($Id)) {
            $Skipped++
            continue
        }

        $Hash = [System.Convert]::ToHexString(
            $Sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Id))
        ).ToLowerInvariant().Substring(0, 16)

        # 64 bits over 18k ids makes a collision astronomically unlikely, but a silent one would
        # serve the wrong setting's name, so it is checked rather than assumed.
        if ($Hashes.ContainsKey($Hash)) {
            throw "Hash collision on '$Hash': '$Id' and '$($Hashes[$Hash])'. The naming scheme needs more bits."
        }
        $Hashes[$Hash] = $Id

        $Bucket = $Hash.Substring(0, 2)
        if ($Buckets.Add($Bucket)) {
            $null = New-Item -ItemType Directory -Path (Join-Path $OutputPath $Bucket) -Force
        }

        [System.IO.File]::WriteAllText(
            (Join-Path $OutputPath "$Bucket\$Hash.json"),
            $Element.GetRawText(),
            [System.Text.UTF8Encoding]::new($false)
        )
        $Written++
    }
} finally {
    $Sha.Dispose()
    $Document.Dispose()
}

Write-Host ''
Write-Host "Wrote $Written definitions across $($Buckets.Count) folders to $OutputPath" -ForegroundColor Green
if ($Skipped -gt 0) {
    Write-Host "Skipped $Skipped entries with no id." -ForegroundColor Yellow
}
