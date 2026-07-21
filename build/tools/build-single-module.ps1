# Build a single PowerShell module via ModuleBuilder.
# Used by per-module Docker stages to enable independent layer caching.
param(
    [Parameter(Mandatory)]
    [string]$Module,

    [switch]$KeepPublic
)

$src = "/src/$Module"
$out = '/out'

Import-Module -Name Metadata -RequiredVersion 1.5.7 -Force
Import-Module -Name Configuration -RequiredVersion 1.6.0 -Force
Import-Module -Name ModuleBuilder -RequiredVersion 3.1.8 -Force

Build-Module -SourcePath "$src/build.psd1" -OutputDirectory $out -ErrorAction Stop

Copy-Item "$out/$Module/$Module.psm1" "$src/$Module.psm1" -Force
Copy-Item "$out/$Module/$Module.psd1" "$src/$Module.psd1" -Force

# Fix RootModule relative path (ModuleBuilder outputs '.\Module.psm1' which Craft can't load)
$psd1Path = "$src/$Module.psd1"
$content = Get-Content $psd1Path -Raw
if ($content -match '\.\\\w+\.psm1') {
    ($content -replace '\.\\(\w+\.psm1)', '$1') | Set-Content $psd1Path -NoNewline -Force
}

Remove-Item $out -Recurse -Force -ErrorAction SilentlyContinue

# Remove source directories so the compiled .psm1 is used instead of the
# stub that dot-sources Public/*.ps1. Keep lib/ (binary dependencies).
foreach ($dir in 'Public', 'Private', 'Classes') {
    if ($dir -eq 'Public' -and $KeepPublic) { continue }
    $dirPath = Join-Path $src $dir
    if (Test-Path $dirPath) { Remove-Item $dirPath -Recurse -Force }
}
Remove-Item (Join-Path $src 'build.psd1') -Force -ErrorAction SilentlyContinue
