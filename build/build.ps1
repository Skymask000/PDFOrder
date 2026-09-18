# ============================================================
#  PDF Order - build script
# ------------------------------------------------------------
#  Produces a single self-contained .exe from the .ps1 source.
#
#    1. Makes sure PdfSharp.dll is cached in build\lib
#       (downloads the MIT-licensed NuGet package if missing).
#    2. Writes a temporary copy of the source with the DLL
#       inlined as base64 between the PDFSHARP-EMBED markers.
#    3. Compiles that copy with PS2EXE.
#    4. Deletes the temporary copy.
#
#  The source .ps1 is never modified, which is why the base64
#  never lands in source control.
#
#  Requires PowerShell 7 (pwsh): the ps2exe module is installed
#  there, not in Windows PowerShell 5.1.
#
#      pwsh -File build\build.ps1
#      pwsh -File build\build.ps1 -Run        # launch when done
#      pwsh -File build\build.ps1 -SkipExe    # just cache the DLL
# ============================================================

[CmdletBinding()]
param(
    [switch]$Run,
    [switch]$SkipExe
)

$ErrorActionPreference = 'Stop'

$PdfSharpVersion = '1.50.5147'
$PdfSharpUrl     = "https://www.nuget.org/api/v2/package/PDFsharp/$PdfSharpVersion"

$root   = Split-Path -Parent $PSScriptRoot
$libDir = Join-Path $PSScriptRoot 'lib'
$dll    = Join-Path $libDir 'PdfSharp.dll'

function Write-Step { param([string]$m) Write-Host "==> $m" -ForegroundColor Cyan }

# --- 1. source ---------------------------------------------------------------
$source = Get-ChildItem -LiteralPath $root -Filter 'PDF Order *.ps1' |
          Sort-Object Name -Descending | Select-Object -First 1
if (-not $source) { throw "No 'PDF Order <version>.ps1' found in $root" }
if ($source.Name -notmatch 'PDF Order (\d+\.\d+\.\d+\.\d+)\.ps1$') {
    throw "Cannot read a version out of '$($source.Name)'"
}
$version = $Matches[1]
Write-Step "Source: $($source.Name)  (version $version)"

# --- 2. PDFsharp -------------------------------------------------------------
if (Test-Path -LiteralPath $dll) {
    Write-Step "PDFsharp already cached: build\lib\PdfSharp.dll"
} else {
    Write-Step "Fetching PDFsharp $PdfSharpVersion from NuGet"
    New-Item -ItemType Directory -Force $libDir | Out-Null
    $tmpPkg = Join-Path ([IO.Path]::GetTempPath()) "pdfsharp-$PdfSharpVersion.zip"
    $tmpEx  = Join-Path ([IO.Path]::GetTempPath()) "pdfsharp-$PdfSharpVersion"
    Invoke-WebRequest -Uri $PdfSharpUrl -OutFile $tmpPkg
    if (Test-Path $tmpEx) { Remove-Item $tmpEx -Recurse -Force }
    Expand-Archive -LiteralPath $tmpPkg -DestinationPath $tmpEx -Force
    $found = Join-Path $tmpEx 'lib\net20\PdfSharp.dll'
    if (-not (Test-Path $found)) { throw "PdfSharp.dll not found inside the package" }
    Copy-Item $found $dll -Force
    Copy-Item (Join-Path $tmpEx 'LICENSE.md') (Join-Path $libDir 'PDFsharp-LICENSE.md') -ErrorAction SilentlyContinue
    Remove-Item $tmpPkg -Force
    Remove-Item $tmpEx -Recurse -Force
    Write-Step "Cached to build\lib\PdfSharp.dll"
}

if ($SkipExe) { Write-Host "Done (DLL cached, .exe skipped)." -ForegroundColor Green; return }

# --- 3. inline the DLL -------------------------------------------------------
Write-Step 'Embedding PDFsharp as base64'
$b64   = [Convert]::ToBase64String([IO.File]::ReadAllBytes($dll))
$lines = [System.Collections.Generic.List[string]][IO.File]::ReadAllLines($source.FullName)

$mb = $lines.FindIndex({ param($x) $x.Trim() -eq '# PDFSHARP-EMBED-BEGIN' })
$me = $lines.FindIndex({ param($x) $x.Trim() -eq '# PDFSHARP-EMBED-END' })
if ($mb -lt 0 -or $me -lt 0 -or $me -le $mb) {
    throw 'PDFSHARP-EMBED markers not found in the source .ps1'
}

$block = New-Object System.Collections.Generic.List[string]
$block.Add('$PdfSharpB64 = @''')
for ($i = 0; $i -lt $b64.Length; $i += 1000) {
    $block.Add($b64.Substring($i, [Math]::Min(1000, $b64.Length - $i)))
}
$block.Add('''@')

$out = New-Object System.Collections.Generic.List[string]
$out.AddRange($lines.GetRange(0, $mb + 1))
$out.AddRange($block)
$out.AddRange($lines.GetRange($me, $lines.Count - $me))

$tmpPs1 = Join-Path ([IO.Path]::GetTempPath()) "PDF Order $version.build.ps1"
[IO.File]::WriteAllLines($tmpPs1, $out)
Write-Step "Staged build source: $($out.Count) lines"

# --- 4. compile --------------------------------------------------------------
try {
    Import-Module ps2exe -ErrorAction Stop
} catch {
    throw "The ps2exe module is not available. Install it with: Install-Module ps2exe -Scope CurrentUser"
}

$outputFile = Join-Path $root "PDF Order $version.exe"
Get-Process | Where-Object { $_.ProcessName -like '*PDF*Order*' } |
    Stop-Process -Force -ErrorAction SilentlyContinue

Write-Step 'Compiling with PS2EXE'
Invoke-PS2EXE -InputFile  $tmpPs1 `
              -OutputFile $outputFile `
              -Title      'PDF Order' `
              -Version    $version `
              -NoConsole `
              -Copyright  'Copyright (c) 2026 Sky' `
              -x64 `
              -STA `
              -IconFile   (Join-Path $root 'icon.ico')

Remove-Item $tmpPs1 -Force

if (-not (Test-Path -LiteralPath $outputFile)) { throw 'PS2EXE produced no output' }
$size = [math]::Round((Get-Item $outputFile).Length / 1MB, 2)
Write-Host ""
Write-Host "Built: PDF Order $version.exe  ($size MB)" -ForegroundColor Green

if ($Run) { Start-Process -FilePath $outputFile }
