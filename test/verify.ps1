# ============================================================
#  PDF Order - verification suite
# ------------------------------------------------------------
#  Self-contained: builds its own synthetic PDFs with PDFsharp,
#  so it needs no sample files and touches nothing outside its
#  own temp folder.
#
#  Covers: script syntax, form construction, the interleave
#  order, custom-order parsing, the removal syntax, the
#  remove-pages box, output-name collision handling, run-2
#  rotation flag alignment, and a real PDF round-trip whose
#  page order is checked against the source.
#
#      pwsh -File test\verify.ps1
#      powershell -File test\verify.ps1     # 5.1 also fine
# ============================================================

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$fail = 0
$pass = 0
function Ok   { param([string]$m) $script:pass++; Write-Host "[ok]   $m" -ForegroundColor Green }
function Bad  { param([string]$m) $script:fail++; Write-Host "[FAIL] $m" -ForegroundColor Red }
function Note { param([string]$m) Write-Host "       $m" -ForegroundColor DarkGray }

# --- source ------------------------------------------------------------------
$source = Get-ChildItem -LiteralPath $root -Filter 'PDF Order *.ps1' |
          Sort-Object Name -Descending | Select-Object -First 1
if (-not $source) { Bad "no 'PDF Order <version>.ps1' in $root"; exit 1 }
Note "source: $($source.Name)"

# --- 1. syntax ---------------------------------------------------------------
$errs = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($source.FullName, [ref]$null, [ref]$errs)
if ($errs.Count) {
    $errs | ForEach-Object { Bad "syntax: $($_.Message) (line $($_.Extent.StartLineNumber))" }
    exit 1
}
Ok 'syntax is clean'

# --- 2. load the script without starting the UI ------------------------------
$tmpDir = Join-Path ([IO.Path]::GetTempPath()) "pdforder-test-$PID"
New-Item -ItemType Directory -Force $tmpDir | Out-Null
try {
    # The stub runs from a temp folder, so the script's own DLL search would not
    # find build\lib. Load it here instead - Import-PdfSharp sees it is already
    # in the AppDomain and returns.
    $dll = Join-Path $root 'build\lib\PdfSharp.dll'
    if (-not (Test-Path -LiteralPath $dll)) {
        Bad "build\lib\PdfSharp.dll missing - run: pwsh -File build\build.ps1 -SkipExe"
        exit 1
    }
    [void][System.Reflection.Assembly]::LoadFrom($dll)

    $lines = [IO.File]::ReadAllLines($source.FullName) | Where-Object { $_.Trim() -ne 'Start-App' }
    $stub  = Join-Path $tmpDir 'loaded.ps1'
    [IO.File]::WriteAllLines($stub, $lines)
    . $stub
    Ok 'script loads, form builds, PDFsharp resolves'

    # --- 3. interleave -------------------------------------------------------
    $r = Get-InterleaveOrder -Total 10 -SplitAt 5 -SecondDescending $true
    $want = @(1,10,2,9,3,8,4,7,5,6)
    if (($r.Order -join ',') -eq ($want -join ',')) { Ok "interleave 10/5/reversed = $($r.Order -join ', ')" }
    else { Bad "interleave gave $($r.Order -join ',')" }

    if ($r.FromSecond[0] -eq $false -and $r.FromSecond[1] -eq $true) { Ok 'run-2 flags alternate' }
    else { Bad 'run-2 flags wrong' }

    $a = Get-InterleaveOrder -Total 6 -SplitAt 3 -SecondDescending $false
    if (($a.Order -join ',') -eq '1,4,2,5,3,6') { Ok "forward run 2 = $($a.Order -join ', ')" }
    else { Bad "forward run 2 gave $($a.Order -join ',')" }

    $o = Get-InterleaveOrder -Total 9 -SplitAt 5 -SecondDescending $true
    if ($o.CountA -eq 5 -and $o.CountB -eq 4) { Ok 'odd total gives run 1 the extra page (9 -> 5 + 4)' }
    else { Bad "odd split gave $($o.CountA)/$($o.CountB)" }

    # --- 4. custom-order parser ---------------------------------------------
    $cases = @(
        @{ In = '1.5.4.3.6.2'; Max = 6;  Want = '1,5,4,3,6,2' }
        @{ In = '1..5';        Max = 10; Want = '1,2,3,4,5'   }
        @{ In = '10..6';       Max = 10; Want = '10,9,8,7,6'  }
        @{ In = '1..3.6..4';   Max = 6;  Want = '1,2,3,6,5,4' }
        @{ In = '1, 5 / 4; 3'; Max = 6;  Want = '1,5,4,3'     }
    )
    $bad = 0
    foreach ($c in $cases) {
        $p = ConvertFrom-OrderText -Text $c.In -MaxPage $c.Max
        if (-not $p.Ok -or ($p.Order -join ',') -ne $c.Want) { $bad++; Bad "parse '$($c.In)' -> '$($p.Order -join ',')' want '$($c.Want)'" }
    }
    if (-not $bad) { Ok "parser: $($cases.Count) cases (dot, range, descending, mixed, mixed separators)" }

    foreach ($b in @('', '99', '1..99', 'abc')) {
        $p = ConvertFrom-OrderText -Text $b -MaxPage 6
        if ($p.Ok) { Bad "'$b' should have been rejected" }
    }
    Ok 'parser rejects empty, out-of-range and garbage'

    # --- 5. removal syntax ---------------------------------------------------
    $rm = @(
        @{ In = '1..6 -4';  Max = 6; Want = '1,2,3,5,6'; Rem = 1 }
        @{ In = '-3';       Max = 6; Want = '1,2,4,5,6'; Rem = 1 }   # removals only = whole file minus
        @{ In = '-2..4';    Max = 6; Want = '1,5,6';     Rem = 3 }
        @{ In = '1.5.4';    Max = 6; Want = '1,5,4';     Rem = 0 }
        @{ In = '1-5-4';    Max = 6; Want = '1';         Rem = 0 }   # '-' removes, never separates
    )
    $bad = 0
    foreach ($c in $rm) {
        $p = ConvertFrom-OrderText -Text $c.In -MaxPage $c.Max
        if (-not $p.Ok -or ($p.Order -join ',') -ne $c.Want -or $p.Removed -ne $c.Rem) {
            $bad++; Bad "removal '$($c.In)' -> '$($p.Order -join ',')' removed=$($p.Removed)"
        }
    }
    if (-not $bad) { Ok "removal syntax: $($rm.Count) cases (incl. '-' removes, never separates)" }

    $p = ConvertFrom-OrderText -Text '1..6 -1..6' -MaxPage 6
    if (-not $p.Ok) { Ok 'removing every page is refused' } else { Bad 'removing everything was allowed' }

    # --- 6. remove-pages box -------------------------------------------------
    $r1 = ConvertFrom-RemoveText -Text '3,7'  -MaxPage 10
    $r2 = ConvertFrom-RemoveText -Text '3..5' -MaxPage 10
    $r3 = ConvertFrom-RemoveText -Text ''     -MaxPage 10
    $r4 = ConvertFrom-RemoveText -Text '99'   -MaxPage 10
    if ($r1.Ok -and $r1.Pages.Count -eq 2 -and
        $r2.Ok -and $r2.Pages.Count -eq 3 -and
        $r3.Ok -and $r3.Pages.Count -eq 0 -and -not $r4.Ok) {
        Ok 'remove-pages box: list, range, empty, out-of-range'
    } else { Bad 'remove-pages box behaved unexpectedly' }

    # --- 7. output names never collide --------------------------------------
    $cin = Join-Path $tmpDir 'x.pdf'
    Set-Content $cin 'dummy'
    $paths = @()
    foreach ($i in 1..4) { $p = Get-FreeOutputPath $cin; $paths += $p; Set-Content $p "v$i" }
    $names = $paths | ForEach-Object { Split-Path $_ -Leaf }
    $expect = 'x_ordered.pdf,x_ordered_2.pdf,x_ordered_3.pdf,x_ordered_4.pdf'
    $intact = ($paths | ForEach-Object { Get-Content $_ }) -join ',' -eq 'v1,v2,v3,v4'
    if (($names -join ',') -eq $expect -and $intact) { Ok 'output names never collide, existing files never touched' }
    else { Bad "collision handling: $($names -join ',')" }

    # --- 8. real PDF round-trip ---------------------------------------------
    # A synthetic 10-page PDF, each page tagged with its own number, so the
    # resulting order can be checked rather than assumed.
    $srcPdf = Join-Path $tmpDir 'sample.pdf'
    $doc  = New-Object PdfSharp.Pdf.PdfDocument
    $font = New-Object PdfSharp.Drawing.XFont('Arial', 48)
    foreach ($n in 1..10) {
        $pg  = $doc.AddPage()
        $gfx = [PdfSharp.Drawing.XGraphics]::FromPdfPage($pg)
        $gfx.DrawString("$n", $font, [PdfSharp.Drawing.XBrushes]::Black,
                        (New-Object PdfSharp.Drawing.XRect(0, 0, $pg.Width, $pg.Height)),
                        [PdfSharp.Drawing.XStringFormats]::Center)
        $gfx.Dispose()
    }
    $doc.Save($srcPdf)
    $doc.Close()

    $res    = Get-InterleaveOrder -Total 10 -SplitAt 5 -SecondDescending $true
    $outPdf = Get-FreeOutputPath $srcPdf
    $n = Invoke-Reorder -InputPath $srcPdf -OutputPath $outPdf `
                        -Order $res.Order -FromSecond $res.FromSecond -RotateSecond $false
    if ($n -eq 10) { Ok "round-trip wrote $n pages to $(Split-Path $outPdf -Leaf)" }
    else { Bad "round-trip wrote $n pages, expected 10" }

    # rotation must follow the run-2 pages only
    $rotPdf = Join-Path $tmpDir 'rotated.pdf'
    [void](Invoke-Reorder -InputPath $srcPdf -OutputPath $rotPdf `
                          -Order $res.Order -FromSecond $res.FromSecond -RotateSecond $true)
    $chk = [PdfSharp.Pdf.IO.PdfReader]::Open($rotPdf, [PdfSharp.Pdf.IO.PdfDocumentOpenMode]::InformationOnly)
    $rots = @(); foreach ($i in 0..5) { $rots += $chk.Pages[$i].Rotate }
    $chk.Close()
    if (($rots -join ',') -eq '0,180,0,180,0,180') { Ok "rotation hits run-2 pages only ($($rots -join ', '))" }
    else { Bad "rotation pattern was $($rots -join ',')" }

    # removals must keep the rotation flags aligned with their pages
    $drop = ConvertFrom-RemoveText -Text '10' -MaxPage 10
    $ord = New-Object System.Collections.Generic.List[int]
    $frm = New-Object System.Collections.Generic.List[bool]
    for ($i = 0; $i -lt $res.Order.Count; $i++) {
        if (-not $drop.Pages.Contains($res.Order[$i])) { $ord.Add($res.Order[$i]); $frm.Add($res.FromSecond[$i]) }
    }
    if ($ord[0] -eq 1 -and $frm[0] -eq $false -and $ord[1] -eq 2 -and $frm[1] -eq $false -and
        $ord[2] -eq 9 -and $frm[2] -eq $true) {
        Ok 'run-2 flags stay aligned after a removal'
    } else { Bad "flags misaligned: $($ord[0])/$($frm[0]) $($ord[1])/$($frm[1]) $($ord[2])/$($frm[2])" }

} finally {
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($fail) {
    Write-Host "$fail failed, $pass passed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "All $pass checks passed." -ForegroundColor Green
}
