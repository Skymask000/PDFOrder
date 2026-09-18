# ============================================================
#  PDF Order | by Sky - skymask000@gmail.com
# ============================================================

$version = '1.0.0.0'

#  PATCH NOTES (newest first)
# ------------------------------------------------------------
#  1.0.0.0 - Initial release.
#
#            Two modes:
#
#            INTERLEAVE - for a duplex scan made in two passes
#            where the second pass was fed as a flipped stack
#            and so arrives reversed. Inputs: total pages
#            (auto-detected, overridable), split point (auto =
#            even), second-run direction, and an optional 180
#            degree rotation applied to second-run pages only.
#
#            CUSTOM ORDER - type the exact order by hand. The
#            separator is '.' and ranges use '..', so
#            1.5.4.3.6.2 lists six pages and 1..5 is a run.
#            Descending ranges work (10..6). ',' ';' '/' and
#            whitespace also separate, so pasted lists parse.
#            The in-box hint shows the syntax until you type.
#
#            REMOVING PAGES - both modes can drop pages.
#            Custom order uses a '-' marker inline:
#              1..5 -3 10..6
#            Interleave has its own 'Remove pages' box, where
#            every entry is a removal so no marker is needed:
#              3   /   3,7   /   3..5
#            Removals apply to the finished list, wherever the
#            page sits, and rotation still follows the correct
#            pages because the run-2 flags are filtered with
#            the order. In custom mode, typing ONLY removals
#            means "the whole file, minus these".
#
#            NOTE ON '-': it is the removal marker, so it is
#            NOT a separator. '1-5-4' means page 1, remove 5,
#            remove 4 - not the list 1, 5, 4. Use '.' instead.
#
#            Jargon ('interleave', 'run', 'split') is explained
#            in hover tooltips, each with a worked numeric
#            example, since the app is read by non-native
#            English speakers.
#
#            RESULT ROW - sits under the action button the way
#            a browser puts a finished download under the page.
#            Before the run it shows the name that will be
#            written; after it, what was written, plus two icon
#            buttons: open the file, or open its folder with
#            the file selected. They stay disabled until a file
#            actually exists, and changing any option resets
#            the row so the buttons can never point at a stale
#            result.
#
#            BUSY CUE - the write is synchronous, so the button
#            greys out and relabels, the cursor goes to wait,
#            and the result row says 'Writing ...', all pushed
#            to screen with DoEvents before work starts.
#
#            COFFEE BUTTON - bottom right of the action row,
#            same '(coffee) = (heart)' idea as the YouTube
#            add-ons, opening revolut.me/rebe000 with the QR.
#
#            GLYPH FONTS matter here and were picked by
#            rendering candidates and looking at them:
#              U+2615 coffee -> Segoe UI Symbol at 14pt. Segoe
#                UI Emoji draws it top-down so it reads as a
#                plain circle, and below 14pt it is unreadable.
#              U+1F4C4 / U+1F4C2 file+folder -> Segoe UI Emoji.
#                Segoe MDL2 Assets clips at this size.
#
#            Both modes show a live preview of the resulting
#            source-page order before anything is written.
#            Source PDF arrives by Browse, drag-drop onto the
#            window, or as a command-line argument (drag onto
#            the .exe). Output is written beside the input as
#            <name>_ordered.pdf and never overwrites - it
#            auto-numbers on collision.
#
#            PDF engine is PDFsharp 1.50, embedded in this
#            script as base64 at the bottom, so the compiled
#            .exe stays a single self-contained file.
# ------------------------------------------------------------

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# NO Application.EnableVisualStyles() - on Win11 the OS theme overrides
# custom BackColors on TextBox borders. Family-wide convention.

# ============================================================
#  PALETTE - derived from icon.ico (PDFOrder_v2)
# ------------------------------------------------------------
#  The icon is three colors: a near-black field, a teal-blue
#  linework accent, and pure black document rules. The blue
#  takes the slot the family accent $purple (114,72,234) holds
#  in the other apps - same role, different hue.
# ============================================================

# --- Raw: sampled straight out of the icon ---
$icoBlack      = [System.Drawing.Color]::FromArgb(14, 14, 14)     # icon field, 54.5% of pixels
$icoBlue       = [System.Drawing.Color]::FromArgb(26, 119, 145)   # icon accent, 33.2% of pixels  <- ACCENT
$icoInk        = [System.Drawing.Color]::FromArgb(0, 0, 0)        # document rules inside the icon

# --- Raw: derived from $icoBlue - same hue, different value ---
$blueBright    = [System.Drawing.Color]::FromArgb(38, 150, 182)   # hover + accent text (5.6:1 on $icoBlack)
$blueDark      = [System.Drawing.Color]::FromArgb(21, 62, 76)     # active / selected bg ($darkPurple analogue)
$blueDeep      = [System.Drawing.Color]::FromArgb(16, 40, 49)     # tinted panel fill

# --- Raw: family neutrals - names kept so they grep cross-app ---
$primaryWhite  = [System.Drawing.Color]::FromArgb(245, 245, 245)
$disabledGray  = [System.Drawing.Color]::Gray
$lightGray     = [System.Drawing.Color]::FromArgb(82, 82, 82)
$darkGray      = [System.Drawing.Color]::FromArgb(30, 30, 35)
$blackNew      = [System.Drawing.Color]::FromArgb(18, 18, 22)
$lightBlackNew = [System.Drawing.Color]::FromArgb(28, 28, 34)
$darkGrayNew   = [System.Drawing.Color]::FromArgb(36, 36, 42)

# --- Raw: family status colors (unchanged - status meaning is cross-app) ---
$green         = [System.Drawing.Color]::FromArgb(108, 221, 128)
$redStrong     = [System.Drawing.Color]::FromArgb(235, 70, 70)
$gold          = [System.Drawing.Color]::FromArgb(230, 190, 90)

# --- Semantic aliases: UI code references ONLY these ---
$bgForm        = $icoBlack
$bgCard        = $darkGrayNew
$bgCardAccent  = $blueDeep
$bgInput       = $lightBlackNew

$accent        = $icoBlue        # fills, rules, primary button bg
$accentHover   = $blueBright
$accentActive  = $blueDark

$bgButton      = $darkGray
$bgButtonHover = $lightGray

$textPrimary   = $primaryWhite
$textMuted     = $disabledGray
$textAccent    = $blueBright     # accent-colored TEXT - brighter, for contrast
$textLink      = $blueBright

$btnPrimary    = $accent
$btnGeneric    = $blackNew

$statusOk      = $green
$statusWarn    = $gold
$statusError   = $redStrong

# Busy state for the action button (family convention, QA Report's values)
$bgLoading     = [System.Drawing.Color]::FromArgb(80, 80, 80)
$textLoading   = [System.Drawing.Color]::FromArgb(160, 160, 160)

# --- Spacing baseline ---
$margin      = 20
$innerMargin = 10

# ============================================================
#  STYLE HELPERS
# ============================================================

function Style-Label {
    param($Ctrl, [System.Drawing.Color]$Fore = $textPrimary)
    $Ctrl.ForeColor = $Fore
    $Ctrl.BackColor = [System.Drawing.Color]::Transparent
}

function Style-Button {
    param($Btn, [System.Drawing.Color]$Bg, [System.Drawing.Color]$Fore = $textPrimary)
    $Btn.FlatStyle                 = 'Flat'
    $Btn.FlatAppearance.BorderSize = 0
    $Btn.BackColor                 = $Bg
    $Btn.ForeColor                 = $Fore
    $Btn.Cursor                    = [System.Windows.Forms.Cursors]::Hand
    $Btn.Font                      = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
    $Btn.TabStop                   = $false
}

function Style-TextBox {
    param($Tb)
    $Tb.BackColor   = $bgInput
    $Tb.ForeColor   = $textPrimary
    $Tb.BorderStyle = 'FixedSingle'
    $Tb.Font        = New-Object System.Drawing.Font('Segoe UI', 9)
}

function Style-Toggle {
    # CheckBox / RadioButton share this treatment.
    # Deliberately NO FlatStyle here. With visual styles off (family rule),
    # FlatStyle='Flat' makes WinForms owner-draw the glyph against the
    # control's BackColor - which is Transparent - so the box renders as a
    # blank white square and checked/unchecked become indistinguishable.
    # The default 'Standard' style draws a legible classic glyph. This
    # matches ConsoleClipboard, which also leaves FlatStyle alone.
    param($Ctrl)
    $Ctrl.ForeColor = $textPrimary
    $Ctrl.BackColor = [System.Drawing.Color]::Transparent
    $Ctrl.Font      = New-Object System.Drawing.Font('Segoe UI', 9)
    $Ctrl.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $Ctrl.TabStop   = $false
}

function Pin-Size {
    # NumericUpDown ignores Size.Height and auto-fits its Font - pin all three.
    param($Ctrl, [int]$W, [int]$H)
    $sz = New-Object System.Drawing.Size($W, $H)
    $Ctrl.MinimumSize = $sz
    $Ctrl.MaximumSize = $sz
    $Ctrl.Size        = $sz
}

function Add-NoFocusOutline {
    param([System.Windows.Forms.Control]$Ctrl)
    $Ctrl.TabStop = $false
    $Ctrl.Add_Click({
        $script:form.BeginInvoke([Action]{
            if (-not $script:form.IsDisposed) { $script:form.ActiveControl = $null }
        }) | Out-Null
    })
}

# ============================================================
#  CORE LOGIC - pure, no UI and no PDF calls
# ============================================================

function Get-InterleaveOrder {
    <#
      Total            pages to treat as the scan
      SplitAt          last page of the ascending first run
      SecondDescending $true when the second run arrived reversed
      Returns @{ Order; FromSecond; CountA; CountB }
      FromSecond[i] marks whether Order[i] came from the second run.
      That flag is what the 180 rotation keys off.
    #>
    param([int]$Total, [int]$SplitAt, [bool]$SecondDescending)

    $a = @(1..$SplitAt)
    $b = if ($SplitAt -lt $Total) { @(($SplitAt + 1)..$Total) } else { @() }
    if ($SecondDescending -and $b.Count -gt 1) { [array]::Reverse($b) }

    $order      = New-Object System.Collections.Generic.List[int]
    $fromSecond = New-Object System.Collections.Generic.List[bool]
    $max        = [Math]::Max($a.Count, $b.Count)
    for ($i = 0; $i -lt $max; $i++) {
        if ($i -lt $a.Count) { $order.Add($a[$i]); $fromSecond.Add($false) }
        if ($i -lt $b.Count) { $order.Add($b[$i]); $fromSecond.Add($true)  }
    }
    return @{
        Order      = $order.ToArray()
        FromSecond = $fromSecond.ToArray()
        CountA     = $a.Count
        CountB     = $b.Count
    }
}

$script:PageTokenCharset = '^[0-9~.,;/\s-]+$'

function Test-PageTextCharset {
    # $Norm has already had '..' folded to '~'.
    param([string]$Norm)
    if ($Norm -notmatch $script:PageTokenCharset) {
        $bad = ([regex]::Match($Norm, '[^0-9~.,;/\s-]')).Value
        return "Unexpected character '$bad'."
    }
    return ''
}

function ConvertFrom-OrderText {
    <#
      Parses a hand-typed order.
        .    separates pages        1.5.4.3.6.2
        ..   makes a range          1..5       10..6 (descends)
        -N   removes a page         1..5 -3
      ',' ';' '/' and whitespace also separate, so pasted lists parse.
      '-' is NOT a separator - it is the removal marker.
      Removals apply to the finished list, wherever the page sits.
      Removals with no inclusions mean "the whole file, minus these".
      Returns @{ Ok; Order; Removed; Error; Empty }
    #>
    param([string]$Text, [int]$MaxPage)

    $t = "$Text".Trim()
    if (-not $t) { return @{ Ok = $false; Empty = $true; Error = 'Type a page order above, e.g. 1.5.4.3.6.2' } }

    $norm = $t -replace '\.\.', '~'
    $bad  = Test-PageTextCharset $norm
    if ($bad) { return @{ Ok = $false; Error = $bad } }

    $include = New-Object System.Collections.Generic.List[int]
    $exclude = New-Object System.Collections.Generic.HashSet[int]

    foreach ($m in [regex]::Matches($norm, '(-)?(\d+)(?:~(\d+))?')) {
        $neg  = $m.Groups[1].Success
        $from = [int]$m.Groups[2].Value
        $to   = if ($m.Groups[3].Success) { [int]$m.Groups[3].Value } else { $from }
        foreach ($v in @($from, $to)) {
            if ($v -lt 1 -or $v -gt $MaxPage) {
                return @{ Ok = $false; Error = "Page $v is outside 1-$MaxPage." }
            }
        }
        foreach ($p in $from..$to) {
            if ($neg) { [void]$exclude.Add($p) } else { $include.Add($p) }
        }
        if ($include.Count -gt 20000) { return @{ Ok = $false; Error = 'Order is too long.' } }
    }

    if ($include.Count -eq 0 -and $exclude.Count -eq 0) {
        return @{ Ok = $false; Empty = $true; Error = 'Type a page order above, e.g. 1.5.4.3.6.2' }
    }
    # Removals on their own read as "everything except these".
    if ($include.Count -eq 0) { 1..$MaxPage | ForEach-Object { $include.Add($_) } }

    $final = @($include | Where-Object { -not $exclude.Contains($_) })
    if ($final.Count -eq 0) {
        return @{ Ok = $false; Error = 'Every page listed was also removed - nothing left to write.' }
    }
    return @{
        Ok      = $true
        Order   = $final
        Removed = ($include.Count - $final.Count)
        Error   = ''
    }
}

function ConvertFrom-RemoveText {
    <#
      Parses the interleave mode's "Remove pages" box, where every entry is a
      removal, so no '-' marker is needed (a stray one is simply ignored).
        3         3,7          3..5
      Returns @{ Ok; Pages (HashSet[int]); Error }
    #>
    param([string]$Text, [int]$MaxPage)

    $empty = New-Object System.Collections.Generic.HashSet[int]
    $t = "$Text".Trim()
    if (-not $t) { return @{ Ok = $true; Pages = $empty; Error = '' } }

    $norm = $t -replace '\.\.', '~'
    $bad  = Test-PageTextCharset $norm
    if ($bad) { return @{ Ok = $false; Pages = $empty; Error = $bad } }

    $set = New-Object System.Collections.Generic.HashSet[int]
    foreach ($m in [regex]::Matches($norm, '(\d+)(?:~(\d+))?')) {
        $from = [int]$m.Groups[1].Value
        $to   = if ($m.Groups[2].Success) { [int]$m.Groups[2].Value } else { $from }
        foreach ($v in @($from, $to)) {
            if ($v -lt 1 -or $v -gt $MaxPage) {
                return @{ Ok = $false; Pages = $empty; Error = "Page $v is outside 1-$MaxPage." }
            }
        }
        foreach ($p in $from..$to) { [void]$set.Add($p) }
    }
    return @{ Ok = $true; Pages = $set; Error = '' }
}

function Format-OrderPreview {
    param([int[]]$Order, [int]$Head = 8, [int]$Tail = 2)
    if ($null -eq $Order -or $Order.Count -eq 0) { return '' }
    if ($Order.Count -le ($Head + $Tail + 1)) { return ($Order -join ', ') }
    $h = $Order[0..($Head - 1)] -join ', '
    $t = $Order[($Order.Count - $Tail)..($Order.Count - 1)] -join ', '
    return "$h,  ...  , $t"
}

function Get-FreeOutputPath {
    param([string]$InputPath)
    $dir  = [IO.Path]::GetDirectoryName($InputPath)
    $base = [IO.Path]::GetFileNameWithoutExtension($InputPath)
    $try  = Join-Path $dir ($base + '_ordered.pdf')
    $n    = 2
    while (Test-Path -LiteralPath $try) {
        $try = Join-Path $dir ($base + '_ordered_' + $n + '.pdf')
        $n++
    }
    return $try
}

# ============================================================
#  PDF ENGINE
# ============================================================

function Get-PdfPageCount {
    param([string]$Path)
    $doc = [PdfSharp.Pdf.IO.PdfReader]::Open($Path, [PdfSharp.Pdf.IO.PdfDocumentOpenMode]::InformationOnly)
    try     { return $doc.PageCount }
    finally { $doc.Close() }
}

function Invoke-Reorder {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [int[]]$Order,
        [bool[]]$FromSecond,
        [bool]$RotateSecond
    )
    $src = [PdfSharp.Pdf.IO.PdfReader]::Open($InputPath, [PdfSharp.Pdf.IO.PdfDocumentOpenMode]::Import)
    try {
        $out = New-Object PdfSharp.Pdf.PdfDocument
        for ($i = 0; $i -lt $Order.Count; $i++) {
            $page = $out.AddPage($src.Pages[$Order[$i] - 1])
            if ($RotateSecond -and $null -ne $FromSecond -and $FromSecond[$i]) {
                $page.Rotate = ($page.Rotate + 180) % 360
            }
        }
        $out.Save($OutputPath)
        return $out.PageCount
    } finally {
        $src.Close()
    }
}

# ============================================================
#  STATE
# ============================================================

$script:PdfPath  = ''
$script:PdfPages = 0
$script:Plan     = $null   # @{ Order; FromSecond; TrailingFrom; Rotate }

# ============================================================
#  FORM
# ============================================================

$script:form                 = New-Object System.Windows.Forms.Form
$form                        = $script:form
$form.Text                   = "PDF Order $version"
$form.ClientSize             = New-Object System.Drawing.Size(560, 608)
$form.BackColor              = $bgForm
$form.ForeColor              = $textPrimary
$form.Font                   = New-Object System.Drawing.Font('Segoe UI', 9)
$form.FormBorderStyle        = 'FixedSingle'
$form.StartPosition          = 'CenterScreen'
$form.MaximizeBox            = $false
$form.AllowDrop              = $true

# Titlebar / taskbar / Alt+Tab icon - the compiled -IconFile does NOT drive these.
try {
    $exePath   = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($exePath)
} catch {
    $iconPath = Join-Path (Split-Path -Parent $PSCommandPath) 'icon.ico'
    if (Test-Path $iconPath) { $form.Icon = New-Object System.Drawing.Icon($iconPath) }
}

# No in-window title - the titlebar already reads "PDF Order <version>",
# so repeating it inside just cost 50px of height.

function New-SectionLabel {
    param([string]$Text, [int]$Y)
    $l          = New-Object System.Windows.Forms.Label
    $l.Text     = $Text
    $l.Font     = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $l.Location = New-Object System.Drawing.Point($margin, $Y)
    $l.Size     = New-Object System.Drawing.Size(520, 20)
    Style-Label $l $textAccent
    $script:form.Controls.Add($l)
    return $l
}

# --- 1 - Source PDF --------------------------------------------------------
$lblSec1 = New-SectionLabel '1  Source PDF' 20

# Drop zone. Everything inside it is drawn in Paint rather than placed as
# child labels - a child label would swallow the clicks and the drag events
# that have to reach the panel itself.
$script:DropHot = $false

$dropZone           = New-Object System.Windows.Forms.Panel
$dropZone.Location  = New-Object System.Drawing.Point($margin, 43)
$dropZone.Size      = New-Object System.Drawing.Size(520, 70)
$dropZone.BackColor = $bgCard
$dropZone.AllowDrop = $true
$dropZone.Cursor    = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($dropZone)

# Cached GDI objects - never allocate per paint.
$script:fontDropMain          = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$script:fontDropSub           = New-Object System.Drawing.Font('Segoe UI', 9)
$script:fontDropPath          = New-Object System.Drawing.Font('Segoe UI', 8)
$script:fmtCenter             = New-Object System.Drawing.StringFormat
$script:fmtCenter.Alignment   = [System.Drawing.StringAlignment]::Center
$script:fmtCenter.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap
$script:fmtCenter.Trimming    = [System.Drawing.StringTrimming]::EllipsisPath

$dropZone.Add_Paint({
    param($s, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $w = $s.ClientSize.Width
    $h = $s.ClientSize.Height

    # Always accent, brighter while a file is hovering over it. The zone is the
    # only live control before a PDF is loaded, so a grey outline would read as
    # disabled alongside the genuinely-disabled section below it.
    $edge = if ($script:DropHot) { $accentHover } else { $accent }
    $pen = New-Object System.Drawing.Pen($edge, 2)
    $pen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
    $g.DrawRectangle($pen, 1, 1, ($w - 3), ($h - 3))
    $pen.Dispose()

    if ($script:PdfPath) {
        $b1 = New-Object System.Drawing.SolidBrush($textPrimary)
        $b2 = New-Object System.Drawing.SolidBrush($textAccent)
        $b3 = New-Object System.Drawing.SolidBrush($textMuted)
        $g.DrawString([IO.Path]::GetFileName($script:PdfPath), $script:fontDropMain, $b1,
                      (New-Object System.Drawing.RectangleF(10, 9,  ($w - 20), 22)), $script:fmtCenter)
        $g.DrawString("$($script:PdfPages) pages", $script:fontDropSub, $b2,
                      (New-Object System.Drawing.RectangleF(10, 31, ($w - 20), 18)), $script:fmtCenter)
        $g.DrawString($script:PdfPath, $script:fontDropPath, $b3,
                      (New-Object System.Drawing.RectangleF(10, 49, ($w - 20), 16)), $script:fmtCenter)
        $b1.Dispose(); $b2.Dispose(); $b3.Dispose()
    } else {
        $b1 = New-Object System.Drawing.SolidBrush($textPrimary)
        $b2 = New-Object System.Drawing.SolidBrush($textMuted)
        # Single '&' is correct - DrawString draws raw text, so there is no
        # mnemonic to escape the way a Button/Label caption would need.
        $g.DrawString('Drag & drop your .pdf file here', $script:fontDropMain, $b1,
                      (New-Object System.Drawing.RectangleF(10, 16, ($w - 20), 24)), $script:fmtCenter)
        $g.DrawString('or click to browse', $script:fontDropSub, $b2,
                      (New-Object System.Drawing.RectangleF(10, 40, ($w - 20), 18)), $script:fmtCenter)
        $b1.Dispose(); $b2.Dispose()
    }
})

# No Browse button by design - the drop zone already takes both a drop and a
# click, so a separate button would be a second door into the same room.

# --- 2 - Mode --------------------------------------------------------------
$lblSecMode = New-SectionLabel '2  Mode' 132

$rbInterleave         = New-Object System.Windows.Forms.RadioButton
$rbInterleave.Text    = 'Interleave two scan runs'
$rbInterleave.Location = New-Object System.Drawing.Point($margin, 155)
$rbInterleave.Size    = New-Object System.Drawing.Size(250, 22)
$rbInterleave.Checked = $true
Style-Toggle $rbInterleave
$form.Controls.Add($rbInterleave)

$rbCustom          = New-Object System.Windows.Forms.RadioButton
$rbCustom.Text     = 'Custom order'
$rbCustom.Location = New-Object System.Drawing.Point(290, 155)
$rbCustom.Size     = New-Object System.Drawing.Size(250, 22)
Style-Toggle $rbCustom
$form.Controls.Add($rbCustom)

# --- 3 - Mode panels (swap in the same region) -----------------------------
$panelY = 185
$panelH = 202

$pnlInterleave           = New-Object System.Windows.Forms.Panel
$pnlInterleave.Location  = New-Object System.Drawing.Point($margin, $panelY)
$pnlInterleave.Size      = New-Object System.Drawing.Size(520, $panelH)
$pnlInterleave.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($pnlInterleave)

$pnlCustom           = New-Object System.Windows.Forms.Panel
$pnlCustom.Location  = New-Object System.Drawing.Point($margin, $panelY)
$pnlCustom.Size      = New-Object System.Drawing.Size(520, $panelH)
$pnlCustom.BackColor = [System.Drawing.Color]::Transparent
$pnlCustom.Visible   = $false
$form.Controls.Add($pnlCustom)

# ---- Interleave panel ----
$lblTotal          = New-Object System.Windows.Forms.Label
$lblTotal.Text     = 'Total pages'
$lblTotal.Location = New-Object System.Drawing.Point(0, 5)
$lblTotal.Size     = New-Object System.Drawing.Size(115, 20)
Style-Label $lblTotal
$pnlInterleave.Controls.Add($lblTotal)

$numTotal           = New-Object System.Windows.Forms.NumericUpDown
$numTotal.Location  = New-Object System.Drawing.Point(125, 2)
$numTotal.Minimum   = 1
$numTotal.Maximum   = 100000
$numTotal.Value     = 1
$numTotal.BackColor = $bgInput
$numTotal.ForeColor = $textPrimary
$numTotal.BorderStyle = 'FixedSingle'
$numTotal.TabStop   = $false
Pin-Size $numTotal 70 24
$pnlInterleave.Controls.Add($numTotal)

$lblOfN          = New-Object System.Windows.Forms.Label
$lblOfN.Location = New-Object System.Drawing.Point(205, 5)
$lblOfN.Size     = New-Object System.Drawing.Size(310, 20)
Style-Label $lblOfN $textMuted
$pnlInterleave.Controls.Add($lblOfN)

$chkEven          = New-Object System.Windows.Forms.CheckBox
$chkEven.Text     = 'Even split - both runs the same length'
$chkEven.Location = New-Object System.Drawing.Point(0, 34)
$chkEven.Size     = New-Object System.Drawing.Size(360, 22)
$chkEven.Checked  = $true
Style-Toggle $chkEven
$pnlInterleave.Controls.Add($chkEven)

$lblSplit          = New-Object System.Windows.Forms.Label
$lblSplit.Text     = 'Last page of run 1'
$lblSplit.Location = New-Object System.Drawing.Point(0, 65)
$lblSplit.Size     = New-Object System.Drawing.Size(115, 20)
Style-Label $lblSplit
$pnlInterleave.Controls.Add($lblSplit)

$numSplit           = New-Object System.Windows.Forms.NumericUpDown
$numSplit.Location  = New-Object System.Drawing.Point(125, 62)
$numSplit.Minimum   = 1
$numSplit.Maximum   = 100000
$numSplit.Value     = 1
$numSplit.BackColor = $bgInput
$numSplit.ForeColor = $textPrimary
$numSplit.BorderStyle = 'FixedSingle'
$numSplit.Enabled   = $false
$numSplit.TabStop   = $false
Pin-Size $numSplit 70 24
$pnlInterleave.Controls.Add($numSplit)

$lblSplitHint          = New-Object System.Windows.Forms.Label
$lblSplitHint.Location = New-Object System.Drawing.Point(205, 65)
$lblSplitHint.Size     = New-Object System.Drawing.Size(310, 20)
Style-Label $lblSplitHint $textMuted
$pnlInterleave.Controls.Add($lblSplitHint)

$rbDesc          = New-Object System.Windows.Forms.RadioButton
$rbDesc.Text     = 'Run 2 is reversed - the stack was flipped as a whole (usual case)'
$rbDesc.Location = New-Object System.Drawing.Point(0, 96)
$rbDesc.Size     = New-Object System.Drawing.Size(515, 22)
$rbDesc.Checked  = $true
Style-Toggle $rbDesc
$pnlInterleave.Controls.Add($rbDesc)

$rbAsc          = New-Object System.Windows.Forms.RadioButton
$rbAsc.Text     = 'Run 2 runs forward - same direction as run 1'
$rbAsc.Location = New-Object System.Drawing.Point(0, 120)
$rbAsc.Size     = New-Object System.Drawing.Size(515, 22)
Style-Toggle $rbAsc
$pnlInterleave.Controls.Add($rbAsc)

$chkRotate          = New-Object System.Windows.Forms.CheckBox
$chkRotate.Text     = 'Rotate run 2 pages 180 degrees'
$chkRotate.Location = New-Object System.Drawing.Point(0, 144)
$chkRotate.Size     = New-Object System.Drawing.Size(515, 22)
Style-Toggle $chkRotate
$pnlInterleave.Controls.Add($chkRotate)

$lblRemove          = New-Object System.Windows.Forms.Label
$lblRemove.Text     = 'Remove pages'
$lblRemove.Location = New-Object System.Drawing.Point(0, 177)
$lblRemove.Size     = New-Object System.Drawing.Size(115, 20)
Style-Label $lblRemove
$pnlInterleave.Controls.Add($lblRemove)

$txtRemove             = New-Object System.Windows.Forms.TextBox
$txtRemove.Location    = New-Object System.Drawing.Point(125, 174)
$txtRemove.Size        = New-Object System.Drawing.Size(150, 24)
$txtRemove.Font        = New-Object System.Drawing.Font('Consolas', 10)
$txtRemove.BackColor   = $bgInput
$txtRemove.ForeColor   = $textPrimary
$txtRemove.BorderStyle = 'FixedSingle'
$pnlInterleave.Controls.Add($txtRemove)

$lblRemoveHint          = New-Object System.Windows.Forms.Label
$lblRemoveHint.Text     = 'e.g.  3   /   3,7   /   3..5'
$lblRemoveHint.Location = New-Object System.Drawing.Point(285, 177)
$lblRemoveHint.Size     = New-Object System.Drawing.Size(230, 20)
Style-Label $lblRemoveHint $textMuted
$pnlInterleave.Controls.Add($lblRemoveHint)

# ---- Custom panel ----
$lblOrder          = New-Object System.Windows.Forms.Label
$lblOrder.Text     = 'Page order'
$lblOrder.Location = New-Object System.Drawing.Point(0, 3)
$lblOrder.Size     = New-Object System.Drawing.Size(200, 20)
Style-Label $lblOrder
$pnlCustom.Controls.Add($lblOrder)

$txtOrder           = New-Object System.Windows.Forms.TextBox
$txtOrder.Location  = New-Object System.Drawing.Point(0, 26)
$txtOrder.Size      = New-Object System.Drawing.Size(515, 26)
$txtOrder.Font      = New-Object System.Drawing.Font('Consolas', 10)
$txtOrder.BackColor = $bgInput
$txtOrder.ForeColor = $textPrimary
$txtOrder.BorderStyle = 'FixedSingle'
$pnlCustom.Controls.Add($txtOrder)

# In-box hint. WinForms on .NET Framework has no PlaceholderText, so it is
# drawn as real text and tracked by a flag - Update-Plan treats it as empty.
$script:OrderHintText = '1.5.4.3.6.2      or      1..5 -3 10..6'
$script:OrderIsHint   = $false

function Show-OrderHint {
    if ($txtOrder.Text -eq '') {
        $script:OrderIsHint = $true
        $txtOrder.ForeColor = $textMuted
        $txtOrder.Font      = New-Object System.Drawing.Font('Consolas', 10, [System.Drawing.FontStyle]::Italic)
        $txtOrder.Text      = $script:OrderHintText
    }
}

function Hide-OrderHint {
    if ($script:OrderIsHint) {
        $script:OrderIsHint = $false
        $txtOrder.ForeColor = $textPrimary
        $txtOrder.Font      = New-Object System.Drawing.Font('Consolas', 10)
        $txtOrder.Text      = ''
    }
}

function Get-OrderText {
    if ($script:OrderIsHint) { return '' }
    return $txtOrder.Text
}

$txtOrder.Add_Enter({ Hide-OrderHint })
$txtOrder.Add_Leave({ Show-OrderHint })

$lblOrderHint          = New-Object System.Windows.Forms.Label
$lblOrderHint.Text     = "1.5.4.3.6.2   one dot separates pages  ->  1, 5, 4, 3, 6, 2" + [Environment]::NewLine +
                         "1..5          two dots make a range  ->  1, 2, 3, 4, 5   (10..6 descends)" + [Environment]::NewLine +
                         "-3            a minus removes a page  ->  e.g.  1..5 -3 10..6" + [Environment]::NewLine +
                         "Only removals = the whole file minus them.  , ; / and spaces also separate."
$lblOrderHint.Location = New-Object System.Drawing.Point(0, 58)
$lblOrderHint.Size     = New-Object System.Drawing.Size(515, 72)
Style-Label $lblOrderHint $textMuted
$pnlCustom.Controls.Add($lblOrderHint)

$lblOrderStats          = New-Object System.Windows.Forms.Label
$lblOrderStats.Location = New-Object System.Drawing.Point(0, 136)
$lblOrderStats.Size     = New-Object System.Drawing.Size(515, 20)
Style-Label $lblOrderStats $textMuted
$pnlCustom.Controls.Add($lblOrderStats)

# --- 4 - Preview card ------------------------------------------------------
$card           = New-Object System.Windows.Forms.Panel
$card.Location  = New-Object System.Drawing.Point($margin, 400)
$card.Size      = New-Object System.Drawing.Size(520, 82)
$card.BackColor = $bgCard
$form.Controls.Add($card)

$lblPreviewCap          = New-Object System.Windows.Forms.Label
$lblPreviewCap.Text     = 'Resulting page order'
$lblPreviewCap.Font     = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$lblPreviewCap.Location = New-Object System.Drawing.Point(12, 8)
$lblPreviewCap.Size     = New-Object System.Drawing.Size(300, 18)
Style-Label $lblPreviewCap $textAccent
$card.Controls.Add($lblPreviewCap)

$lblPreview          = New-Object System.Windows.Forms.Label
$lblPreview.Font     = New-Object System.Drawing.Font('Consolas', 10)
$lblPreview.Location = New-Object System.Drawing.Point(12, 30)
$lblPreview.Size     = New-Object System.Drawing.Size(496, 22)
Style-Label $lblPreview $textPrimary
$card.Controls.Add($lblPreview)

$lblNote          = New-Object System.Windows.Forms.Label
$lblNote.Location = New-Object System.Drawing.Point(12, 56)
$lblNote.Size     = New-Object System.Drawing.Size(496, 18)
Style-Label $lblNote $textMuted
$card.Controls.Add($lblNote)

# --- 5 - Action, then the result row ---------------------------------------
$btnGo          = New-Object System.Windows.Forms.Button
$btnGo.Text     = 'Reorder PDF'
$btnGo.Location = New-Object System.Drawing.Point($margin, 496)
$btnGo.Size     = New-Object System.Drawing.Size(180, 36)
$btnGo.Font     = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
Style-Button $btnGo $btnPrimary
$btnGo.Font     = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$btnGo.FlatAppearance.MouseOverBackColor = $accentHover
$btnGo.FlatAppearance.MouseDownBackColor = $accentActive
# initial state is applied by Set-GoEnabled once the helpers exist (Start-App)
$form.Controls.Add($btnGo)

# No Close button - the titlebar X already does that, and removing it frees
# the right end of this row for the coffee button.

# Coffee button - shares the action row, sitting at the far right so it reads
# as an aside rather than a second action. Same '(coffee) = (heart)' idea as
# the YouTube add-ons.
$btnTip          = New-Object System.Windows.Forms.Button
$btnTip.Text     = ([string][char]0x2615) + ' = ' + ([string][char]0x2665)
$btnTip.Location = New-Object System.Drawing.Point(430, 496)
$btnTip.Size     = New-Object System.Drawing.Size(110, 36)
Style-Button $btnTip $btnGeneric $textMuted
# Segoe UI Symbol, NOT Segoe UI Emoji. Emoji draws U+2615 as a top-down cup
# that reads as a plain circle; Symbol draws the side view with steam. And it
# wants 14pt - at 9-11pt the cup is too small to recognise.
$btnTip.Font     = New-Object System.Drawing.Font('Segoe UI Symbol', 14)
$btnTip.FlatAppearance.MouseOverBackColor = $bgButtonHover
$btnTip.FlatAppearance.MouseDownBackColor = $bgButtonHover
$btnTip.Add_MouseEnter({ $btnTip.ForeColor = $textAccent }.GetNewClosure())
$btnTip.Add_MouseLeave({ $btnTip.ForeColor = $textMuted  }.GetNewClosure())
$form.Controls.Add($btnTip)

# Result row - sits UNDER the action button, the way a browser puts a finished
# download under the page. Shows where the file goes, and once it exists, the
# two buttons open the file itself or the folder holding it.
$pnlResult           = New-Object System.Windows.Forms.Panel
$pnlResult.Location  = New-Object System.Drawing.Point($margin, 544)
$pnlResult.Size      = New-Object System.Drawing.Size(520, 46)
$pnlResult.BackColor = $bgCard
$form.Controls.Add($pnlResult)

$lblResult          = New-Object System.Windows.Forms.Label
$lblResult.Location = New-Object System.Drawing.Point(12, 6)
$lblResult.Size     = New-Object System.Drawing.Size(404, 34)
$lblResult.Font     = New-Object System.Drawing.Font('Segoe UI', 9)
$lblResult.TextAlign = 'MiddleLeft'
Style-Label $lblResult $textMuted
$pnlResult.Controls.Add($lblResult)

function New-IconButton {
    param([string]$Glyph, [int]$X)
    $b          = New-Object System.Windows.Forms.Button
    $b.Text     = $Glyph
    $b.Location = New-Object System.Drawing.Point($X, 5)
    $b.Size     = New-Object System.Drawing.Size(36, 36)
    Style-Button $b $bgButton $textPrimary
    # Segoe UI Emoji renders U+1F4C4 / U+1F4C2 as clean outline icons. MDL2
    # clips at this size and Segoe UI Symbol draws them as solid blobs.
    $b.Font     = New-Object System.Drawing.Font('Segoe UI Emoji', 13)
    $b.FlatAppearance.MouseOverBackColor = $bgButtonHover
    $b.FlatAppearance.MouseDownBackColor = $bgButtonHover
    $b.Enabled  = $false
    return $b
}

$btnOpenFile   = New-IconButton ([char]::ConvertFromUtf32(0x1F4C4)) 428
$btnOpenFolder = New-IconButton ([char]::ConvertFromUtf32(0x1F4C2)) 472
$pnlResult.Controls.Add($btnOpenFile)
$pnlResult.Controls.Add($btnOpenFolder)


# ============================================================
#  BEHAVIOUR
# ============================================================

function Set-GoEnabled {
    <#
      A flat button keeps its BackColor when disabled, so the primary action
      would sit there in full accent blue while doing nothing. Appearance has
      to follow state, so every enable/disable goes through here.
    #>
    param([bool]$On)
    $btnGo.Enabled   = $On
    $btnGo.BackColor = if ($On) { $btnPrimary }  else { $bgLoading }
    $btnGo.ForeColor = if ($On) { $textPrimary } else { $textLoading }
}

function Set-OptionsEnabled {
    <#
      Nothing in section 2 means anything until a PDF is loaded - the page
      count is unknown, so every field would be editing a plan that cannot
      exist. Grey the whole section out rather than letting it look ready.
      Disabling the two panels cascades to every control inside them.
    #>
    param([bool]$On)
    $rbInterleave.Enabled  = $On
    $rbCustom.Enabled      = $On
    $pnlInterleave.Enabled = $On
    $pnlCustom.Enabled     = $On
    # Section headings are plain labels, so they need colouring by hand.
    $lblSecMode.ForeColor    = if ($On) { $textAccent } else { $textMuted }
    $lblPreviewCap.ForeColor = if ($On) { $textAccent } else { $textMuted }
    # An empty preview card reads as a dead slab; fade it into the form until
    # there is something to show.
    $card.BackColor          = if ($On) { $bgCard } else { $bgForm }
    $pnlResult.BackColor     = if ($On) { $bgCard } else { $bgForm }
}

function Set-Status {
    <#
      Writes the result row. Passing -ResultPath means a file now exists, which
      is the only thing that switches the two open buttons on.
    #>
    param([string]$Text, [System.Drawing.Color]$Color = $textMuted, [string]$ResultPath = '')
    $lblResult.Text      = $Text
    $lblResult.ForeColor = $Color
    $script:ResultPath   = $ResultPath
    $has                 = [bool]$ResultPath
    $btnOpenFile.Enabled   = $has
    $btnOpenFolder.Enabled = $has
    $btnOpenFile.ForeColor   = if ($has) { $textPrimary } else { $textMuted }
    $btnOpenFolder.ForeColor = if ($has) { $textPrimary } else { $textMuted }
}

function Update-Plan {
    # Recomputes the plan + preview from current UI state. Never touches disk.
    $lblPreview.Text = ''
    $lblNote.Text    = ''
    $lblNote.ForeColor = $textMuted
    $script:Plan     = $null
    Set-GoEnabled $false

    if (-not $script:PdfPath) {
        Set-Status ''
        return
    }

    if ($rbCustom.Checked) {
        $parsed = ConvertFrom-OrderText -Text (Get-OrderText) -MaxPage $script:PdfPages
        if (-not $parsed.Ok) {
            $lblOrderStats.Text = ''
            $lblNote.Text       = $parsed.Error
            $lblNote.ForeColor  = if ($parsed.Empty) { $textMuted } else { $statusError }
            return
        }
        $order  = $parsed.Order
        $uniq   = @($order | Sort-Object -Unique)
        $dupes  = $order.Count - $uniq.Count
        $missed = $script:PdfPages - $uniq.Count

        $lblOrderStats.Text = "$($order.Count) pages listed - $($uniq.Count) distinct of $($script:PdfPages)"
        $lblPreview.Text    = Format-OrderPreview $order

        $notes = @()
        if ($parsed.Removed -gt 0) { $notes += "$($parsed.Removed) removed" }
        if ($dupes  -gt 0)         { $notes += "$dupes repeated" }
        if ($missed -gt 0)         { $notes += "$missed of the PDF's pages left out" }
        if ($notes.Count -gt 0) {
            $lblNote.Text      = 'Heads up: ' + ($notes -join ', ') + '.'
            $lblNote.ForeColor = $statusWarn
        } else {
            $lblNote.Text = "All $($script:PdfPages) pages used exactly once."
        }

        $script:Plan = @{
            Order      = $order
            FromSecond = $null
            Rotate     = $false
        }
        Set-GoEnabled $true
    }
    else {
        $total = [int]$numTotal.Value
        if ($total -gt $script:PdfPages) {
            $total = $script:PdfPages
            $numTotal.Value = $total
        }
        if ($chkEven.Checked) {
            $numSplit.Value = [Math]::Ceiling($total / 2)
        }
        $split = [int]$numSplit.Value
        if ($split -lt 1 -or $split -gt $total) {
            $lblNote.Text      = "Split must be between 1 and $total."
            $lblNote.ForeColor = $statusError
            return
        }

        $rem = ConvertFrom-RemoveText -Text $txtRemove.Text -MaxPage $script:PdfPages
        if (-not $rem.Ok) {
            $lblNote.Text      = "Remove pages: $($rem.Error)"
            $lblNote.ForeColor = $statusError
            return
        }

        $res = Get-InterleaveOrder -Total $total -SplitAt $split -SecondDescending ($rbDesc.Checked)
        $lblSplitHint.Text = "run 1 = pages 1-$split  ($($res.CountA))   run 2 = pages $($split + 1)-$total  ($($res.CountB))"

        # Build the full list first - interleaved pages, then anything past the
        # declared total kept as-is - so removals apply uniformly across both.
        $ord = New-Object System.Collections.Generic.List[int]
        $frm = New-Object System.Collections.Generic.List[bool]
        for ($i = 0; $i -lt $res.Order.Count; $i++) {
            $ord.Add($res.Order[$i]); $frm.Add($res.FromSecond[$i])
        }
        $trailing = 0
        if ($total -lt $script:PdfPages) {
            $trailing = $script:PdfPages - $total
            for ($p = $total + 1; $p -le $script:PdfPages; $p++) { $ord.Add($p); $frm.Add($false) }
        }

        $order      = New-Object System.Collections.Generic.List[int]
        $fromSecond = New-Object System.Collections.Generic.List[bool]
        for ($i = 0; $i -lt $ord.Count; $i++) {
            if (-not $rem.Pages.Contains($ord[$i])) {
                $order.Add($ord[$i]); $fromSecond.Add($frm[$i])
            }
        }
        if ($order.Count -eq 0) {
            $lblNote.Text      = 'Every page was removed - nothing left to write.'
            $lblNote.ForeColor = $statusError
            return
        }
        $removed = $ord.Count - $order.Count

        $lblPreview.Text = Format-OrderPreview $order.ToArray()

        $notes = @()
        $diff  = [Math]::Abs($res.CountA - $res.CountB)
        if ($diff -gt 1)     { $notes += "the two runs differ by $diff pages" }
        if ($trailing -gt 0) { $notes += "$trailing page(s) past $total kept as-is at the end" }
        if ($removed -gt 0)  { $notes += "$removed removed" }
        if ($notes.Count -gt 0) {
            $lblNote.Text      = 'Heads up: ' + ($notes -join '; ') + '.'
            $lblNote.ForeColor = $statusWarn
        } else {
            $lblNote.Text = "$($order.Count) pages, each used exactly once."
        }

        $script:Plan = @{
            Order      = $order.ToArray()
            FromSecond = $fromSecond.ToArray()
            Rotate     = $chkRotate.Checked
        }
        Set-GoEnabled $true
    }

    # Options changed, so any earlier result is stale - reset the row.
    Set-Status ('Will write:  ' + [IO.Path]::GetFileName((Get-FreeOutputPath $script:PdfPath))) $textMuted
}

function Load-Pdf {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        Set-Status "No such file: $Path" $statusError
        return
    }
    if ([IO.Path]::GetExtension($Path) -notmatch '^\.pdf$') {
        Set-Status 'That is not a PDF.' $statusError
        return
    }
    try {
        $count = Get-PdfPageCount $Path
    } catch {
        Set-Status "Could not open that PDF: $($_.Exception.Message)" $statusError
        return
    }
    $script:PdfPath  = $Path
    $script:PdfPages = $count
    $lblOfN.Text     = "of $count in the file"
    $dropZone.Invalidate()   # zone repaints as the loaded-file readout
    Set-OptionsEnabled $true

    $numTotal.Maximum = $count
    $numTotal.Value   = $count
    $numSplit.Maximum = $count
    $numSplit.Value   = [Math]::Ceiling($count / 2)

    Set-Status ''
    Update-Plan
}

function Invoke-BrowseForPdf {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = 'PDF files (*.pdf)|*.pdf'
    $dlg.Title  = 'Pick the scanned PDF'
    if ($script:PdfPath) { $dlg.InitialDirectory = [IO.Path]::GetDirectoryName($script:PdfPath) }
    if ($dlg.ShowDialog($script:form) -eq [System.Windows.Forms.DialogResult]::OK) {
        Load-Pdf $dlg.FileName
    }
    $dlg.Dispose()
}


$dropZone.Add_Click({ Invoke-BrowseForPdf })

# Drop handling. The zone lights up on hover; the form accepts a drop anywhere
# so a near-miss still lands.
function Test-FileDrop {
    param($e)
    return $e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)
}

function Complete-FileDrop {
    param($e)
    $script:DropHot = $false
    $dropZone.Invalidate()
    $files = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    if ($files -and $files.Count -gt 0) { Load-Pdf $files[0] }
}

$dropZone.Add_DragEnter({
    param($s, $e)
    if (Test-FileDrop $e) {
        $e.Effect       = [System.Windows.Forms.DragDropEffects]::Copy
        $script:DropHot = $true
        $dropZone.Invalidate()
    }
})
$dropZone.Add_DragLeave({
    $script:DropHot = $false
    $dropZone.Invalidate()
})
$dropZone.Add_DragDrop({ param($s, $e) Complete-FileDrop $e })

$form.Add_DragEnter({
    param($s, $e)
    if (Test-FileDrop $e) { $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy }
})
$form.Add_DragDrop({ param($s, $e) Complete-FileDrop $e })

$rbInterleave.Add_CheckedChanged({
    $pnlInterleave.Visible = $rbInterleave.Checked
    $pnlCustom.Visible     = -not $rbInterleave.Checked
    Update-Plan
})

$chkEven.Add_CheckedChanged({
    $numSplit.Enabled = -not $chkEven.Checked
    Update-Plan
})

$numTotal.Add_ValueChanged({ Update-Plan })
$numSplit.Add_ValueChanged({ Update-Plan })
$rbDesc.Add_CheckedChanged({ Update-Plan })
$chkRotate.Add_CheckedChanged({ Update-Plan })
$txtOrder.Add_TextChanged({ Update-Plan })
$txtRemove.Add_TextChanged({ Update-Plan })

$btnOpenFile.Add_Click({
    if ($script:ResultPath -and (Test-Path -LiteralPath $script:ResultPath)) {
        Start-Process -FilePath $script:ResultPath
    }
})

$btnOpenFolder.Add_Click({
    if ($script:ResultPath -and (Test-Path -LiteralPath $script:ResultPath)) {
        # /select, highlights the file inside the folder rather than just opening it
        Start-Process explorer.exe "/select,`"$($script:ResultPath)`""
    }
})

$btnGo.Add_Click({
    if (-not $script:Plan) { return }
    $out = Get-FreeOutputPath $script:PdfPath

    # Busy cue. The write is synchronous and a big scan takes a few seconds, so
    # without this the window just sits there and you cannot tell the click
    # registered. Greyed + relabelled button, wait cursor, and a live status
    # line - all pushed to the screen with DoEvents before the work starts.
    Set-GoEnabled $false
    $btnGo.Text      = 'Working...'
    $btnGo.BackColor = $bgLoading
    $btnGo.ForeColor = $textLoading
    $script:form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    Set-Status ('Writing ' + [IO.Path]::GetFileName($out) + ' ...') $textMuted
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $written = Invoke-Reorder -InputPath    $script:PdfPath `
                                  -OutputPath   $out `
                                  -Order        $script:Plan.Order `
                                  -FromSecond   $script:Plan.FromSecond `
                                  -RotateSecond $script:Plan.Rotate
        Set-Status "$([IO.Path]::GetFileName($out))   -   $written pages written" $statusOk $out
    } catch {
        Set-Status "Failed: $($_.Exception.Message)" $statusError
    } finally {
        $btnGo.Text      = 'Reorder PDF'
        $btnGo.BackColor = $btnPrimary
        $btnGo.ForeColor = $textPrimary
        Set-GoEnabled $true
        $script:form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
})



$script:TipUrl = 'https://revolut.me/rebe000'

function Show-TipDialog {
    $dlg                 = New-Object System.Windows.Forms.Form
    $dlg.Text            = 'Thank you'
    $dlg.StartPosition   = 'CenterParent'
    $dlg.FormBorderStyle = 'FixedDialog'
    $dlg.MinimizeBox     = $false
    $dlg.MaximizeBox     = $false
    $dlg.BackColor       = $bgForm
    $dlg.ForeColor       = $textPrimary
    $dlg.Font            = New-Object System.Drawing.Font('Segoe UI', 9)
    try { $dlg.Icon = $script:form.Icon } catch { }

    # Everything is centred on one column and stacked with a running cursor, so
    # the height falls out of the content and the bottom padding always equals
    # the top. The QR is the only optional piece - if it fails to decode the
    # stack simply closes up instead of leaving a hole.
    $dlgW     = 360
    $contentW = $dlgW - (2 * $margin)
    $y        = $margin

    $t           = New-Object System.Windows.Forms.Label
    $t.Text      = 'This app is free and always will be.' + [Environment]::NewLine +
                   'A coffee is never expected, but always appreciated.'
    $t.Location  = New-Object System.Drawing.Point($margin, $y)
    $t.Size      = New-Object System.Drawing.Size($contentW, 40)
    $t.TextAlign = 'MiddleCenter'
    Style-Label $t $textPrimary
    $dlg.Controls.Add($t)
    $y += 46

    $lnk                  = New-Object System.Windows.Forms.LinkLabel
    $lnk.Text             = 'revolut.me/rebe000'
    $lnk.Font             = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $lnk.Location         = New-Object System.Drawing.Point($margin, $y)
    $lnk.Size             = New-Object System.Drawing.Size($contentW, 24)
    $lnk.TextAlign        = 'MiddleCenter'
    $lnk.LinkColor        = $textLink
    $lnk.ActiveLinkColor  = $textLink
    $lnk.VisitedLinkColor = $textLink
    $lnk.BackColor        = [System.Drawing.Color]::Transparent
    $lnk.Add_LinkClicked({ Start-Process $script:TipUrl })
    $dlg.Controls.Add($lnk)
    $y += 36

    if ($script:TipQrB64) {
        try {
            $bytes = [Convert]::FromBase64String(($script:TipQrB64 -replace '\s', ''))
            $ms    = New-Object System.IO.MemoryStream(,$bytes)
            $qr    = 150
            $pb    = New-Object System.Windows.Forms.PictureBox
            $pb.Image    = [System.Drawing.Image]::FromStream($ms)
            $pb.SizeMode = 'Zoom'
            $pb.Location = New-Object System.Drawing.Point(([int](($dlgW - $qr) / 2)), $y)
            $pb.Size     = New-Object System.Drawing.Size($qr, $qr)
            $dlg.Controls.Add($pb)
            $y += $qr + 20
        } catch { }
    }

    $okW         = 110
    $ok          = New-Object System.Windows.Forms.Button
    $ok.Text     = 'Close'
    $ok.Location = New-Object System.Drawing.Point(([int](($dlgW - $okW) / 2)), $y)
    $ok.Size     = New-Object System.Drawing.Size($okW, 32)
    Style-Button $ok $btnGeneric
    $ok.FlatAppearance.MouseOverBackColor = $bgButtonHover
    $ok.Add_Click({ $dlg.Close() }.GetNewClosure())
    $dlg.Controls.Add($ok)
    $y += 32

    $dlg.ClientSize = New-Object System.Drawing.Size($dlgW, ($y + $margin))

    $dlg.Add_Shown({ $dlg.ActiveControl = $null }.GetNewClosure())
    [void]$dlg.ShowDialog($script:form)
    $dlg.Dispose()
}

$btnTip.Add_Click({ Show-TipDialog })

foreach ($c in @($btnGo, $btnTip, $rbInterleave, $rbCustom,
                 $chkEven, $chkRotate, $rbDesc, $rbAsc)) {
    Add-NoFocusOutline $c
}

# ============================================================
#  TOOLTIPS
# ------------------------------------------------------------
#  Every hint spells the idea out with real numbers rather than
#  relying on the term itself - "interleave", "run" and "split"
#  are jargon, and the app is used by non-native readers.
# ============================================================

$tip                 = New-Object System.Windows.Forms.ToolTip
$tip.InitialDelay    = 350
$tip.ReshowDelay     = 150
$tip.AutoPopDelay    = 32000     # long enough to read a worked example
$tip.ShowAlways      = $true

$NL = [Environment]::NewLine

# Every example below uses a 10 page document. Small enough that the whole
# resulting order can be written out and checked by eye, which is the point -
# a 58 page example has to trail off into "..." and stops teaching anything.

$tip.SetToolTip($dropZone,
    'Drop a PDF file here, or click to pick one.' + $NL + $NL +
    'The file you drop is never changed. A new file is written next to it.')

$tip.SetToolTip($rbInterleave,
    'INTERLEAVE = mix two scan runs back together, one page from each, turn by turn.' + $NL + $NL +
    'Use this when your scanner cannot do both sides at once, so you scanned' + $NL +
    'all the front sides first, flipped the whole stack, then scanned the backs.' + $NL + $NL +
    'Example, a 10 page scan:' + $NL +
    '   run 1 (fronts) =  1, 2, 3, 4, 5' + $NL +
    '   run 2 (backs)  =  6, 7, 8, 9, 10   but in reverse order' + $NL +
    '   result         =  1, 10, 2, 9, 3, 8, 4, 7, 5, 6')

$tip.SetToolTip($rbCustom,
    'You type the exact page order yourself.' + $NL + $NL +
    'Example:  1.5.4.3.6.2' + $NL +
    'means page 1, then 5, then 4, then 3, then 6, then 2.')

$tip.SetToolTip($lblTotal, 'How many pages take part in the reordering.')
$tip.SetToolTip($numTotal,
    'How many pages take part in the reordering.' + $NL + $NL +
    'Normally the whole file. If a 10 page file is set to 8, then pages 9' + $NL +
    'and 10 take no part and are simply kept at the end.')

$tip.SetToolTip($chkEven,
    'Cuts the file into two runs of the same length.' + $NL + $NL +
    '10 pages  ->  run 1 = pages 1-5,  run 2 = pages 6-10.' + $NL +
    'An odd count gives run 1 the extra page: 9  ->  5 and 4.' + $NL + $NL +
    'Untick it to set the cut point yourself.')

$tip.SetToolTip($lblSplit, 'The last page of the first scan run.')
$tip.SetToolTip($numSplit,
    'The last page of the first scan run.' + $NL + $NL +
    'If your first scan produced 5 pages, type 5.' + $NL +
    'Run 2 is then everything from page 6 to the end.')

$tip.SetToolTip($rbDesc,
    'The second run came out BACKWARDS.' + $NL + $NL +
    'This is what happens when you flip the whole paper stack and scan again:' + $NL +
    'the sheet that was last is now scanned first.' + $NL + $NL +
    'In a 10 page scan, pages 6, 7, 8, 9, 10 are read as 10, 9, 8, 7, 6,' + $NL +
    'so the result is  1, 10, 2, 9, 3, 8, 4, 7, 5, 6')

$tip.SetToolTip($rbAsc,
    'The second run is already in the right direction.' + $NL + $NL +
    'Use this if you re-sorted the stack before scanning the backs.' + $NL + $NL +
    'In a 10 page scan the result is  1, 6, 2, 7, 3, 8, 4, 9, 5, 10')

$tip.SetToolTip($chkRotate,
    'Turns the run 2 pages upside down (180 degrees).' + $NL + $NL +
    'Some scanners produce upside-down back sides when the stack is flipped.' + $NL +
    'Tick this only if the back pages really do look inverted.')

$tip.SetToolTip($lblRemove, 'Pages to throw away.')
$tip.SetToolTip($txtRemove,
    'Pages to throw away - blank backs, for example. Optional.' + $NL + $NL +
    '   3        removes page 3' + $NL +
    '   3,7      removes pages 3 and 7' + $NL +
    '   3..5     removes pages 3, 4 and 5' + $NL + $NL +
    'These are page numbers of the ORIGINAL file, before reordering.')

$tip.SetToolTip($lblOrder, 'Type the page order you want.')
$tip.SetToolTip($txtOrder,
    'Type the page order you want.' + $NL + $NL +
    '   1.5.4.3.6.2    six pages, in that order' + $NL +
    '   1..5           pages 1 to 5' + $NL +
    '   10..6          pages 10 down to 6' + $NL +
    '   -3             removes page 3' + $NL + $NL +
    'Example:  1..5 -3 10..6' + $NL +
    'gives  1, 2, 4, 5, 10, 9, 8, 7, 6' + $NL + $NL +
    'A minus is NOT a separator - it always means remove.' + $NL +
    'If you type only removals, you get the whole file minus those pages.')

$tip.SetToolTip($lblPreviewCap,
    'The order the pages will be written in.' + $NL + $NL +
    'The numbers are page numbers of the ORIGINAL file.' + $NL +
    '"1, 10, 2, 9" means: original page 1 first, then original page 10,' + $NL +
    'then original page 2, then original page 9.')

$tip.SetToolTip($btnTip, 'Say thanks with a coffee. Entirely optional.')

$tip.SetToolTip($btnOpenFile,
    'Open the new PDF.' + $NL + $NL +
    'Available once the file has been written.')
$tip.SetToolTip($btnOpenFolder,
    'Open the folder holding the new PDF, with the file selected.' + $NL + $NL +
    'Available once the file has been written.')
$tip.SetToolTip($lblResult,
    'Where the new file goes.' + $NL + $NL +
    'Before you press Reorder it shows the name that will be used;' + $NL +
    'afterwards it shows what was actually written.')

$tip.SetToolTip($btnGo,
    'Writes the reordered PDF next to the original.' + $NL + $NL +
    'The original is never changed, and an existing result is never' + $NL +
    'overwritten - a number is added to the name instead.')

# $args is script-scope only - capture it before it goes out of reach.
$script:CliArgs = $args

function Start-App {
    Show-OrderHint
    Set-GoEnabled $false        # greyed until there is a plan to run
    Set-OptionsEnabled $false   # nothing is editable until a PDF is loaded
    # Accept a path handed in on the command line (drag a PDF onto the .exe).
    if ($script:CliArgs.Count -gt 0 -and $script:CliArgs[0]) {
        Load-Pdf ([string]$script:CliArgs[0])
    }
    $script:form.Add_Shown({ $script:form.ActiveControl = $null })
    [void]$script:form.ShowDialog()
    $script:form.Dispose()
}

# ============================================================
#  PDF ENGINE - PDFsharp 1.50.5147 (MIT)
# ------------------------------------------------------------
#  PowerShell ships no PDF engine, so PDFsharp is pulled in
#  here. There are two ways in, tried in order:
#
#    1. An embedded base64 copy, injected by build\build.ps1
#       between the markers below when the .exe is compiled.
#       That is what keeps the shipped .exe a single
#       self-contained file. It is deliberately NOT committed -
#       the marker block is empty in source control, so the
#       repository stays readable and diffable.
#
#    2. A PdfSharp.dll next to this script or in build\lib,
#       which is how the .ps1 is run during development.
#       build\build.ps1 fetches it once and caches it there.
#
#  Licence: PDFsharp is MIT licensed. The full notice ships in
#  THIRD-PARTY.md and must travel with any redistribution.
# ============================================================

# PDFSHARP-EMBED-BEGIN
$PdfSharpB64 = ''
# PDFSHARP-EMBED-END

function Import-PdfSharp {
    # Already in the AppDomain (a test harness pre-loaded it, or this script was
    # dot-sourced twice) - nothing to do.
    if ([AppDomain]::CurrentDomain.GetAssemblies() |
            Where-Object { $_.GetName().Name -eq 'PdfSharp' }) { return }

    # Embedded copy, injected by build\build.ps1. This is the path the compiled
    # .exe always takes.
    if ($PdfSharpB64) {
        [void][System.Reflection.Assembly]::Load(
            [Convert]::FromBase64String(($PdfSharpB64 -replace '\s', '')))
        return
    }

    # Development path. Which of these is populated depends on how the script was
    # launched, so collect every plausible base directory rather than trusting one.
    $bases = New-Object System.Collections.Generic.List[string]
    foreach ($c in @(
        $PSScriptRoot,
        $(if ($PSCommandPath) { Split-Path -Parent $PSCommandPath }),
        $(if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path }),
        $(try { Split-Path -Parent ([Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) } catch { $null }),
        (Get-Location).Path
    )) {
        if ($c -and -not $bases.Contains($c)) { $bases.Add($c) }
    }

    $tried = New-Object System.Collections.Generic.List[string]
    foreach ($b in $bases) {
        foreach ($sub in @('', 'build\lib', 'lib')) {
            $dir = if ($sub) { Join-Path $b $sub } else { $b }
            $dll = Join-Path $dir 'PdfSharp.dll'
            $tried.Add($dll)
            if (Test-Path -LiteralPath $dll) {
                [void][System.Reflection.Assembly]::LoadFrom($dll)
                return
            }
        }
    }

    throw ("PdfSharp.dll was not found." + [Environment]::NewLine + [Environment]::NewLine +
           "Run this once to fetch it:" + [Environment]::NewLine +
           "    pwsh -File build\build.ps1 -SkipExe" + [Environment]::NewLine + [Environment]::NewLine +
           "Looked in:" + [Environment]::NewLine + ($tried -join [Environment]::NewLine))
}

try {
    Import-PdfSharp
} catch {
    # -NoConsole means an unhandled error here would kill the app silently.
    [void][System.Windows.Forms.MessageBox]::Show(
        $_.Exception.Message, 'PDF Order', 'OK', 'Error')
    return
}
$PdfSharpB64 = $null

# --- Coffee QR (Revolut), embedded so the .exe stays one file ---
$TipQrB64 = @'
iVBORw0KGgoAAAANSUhEUgAAAgAAAAIACAYAAAD0eNT6AAAAAklEQVR4AewaftIAAA3ESURBVO3BQW4lh44EwCSh+185x9sG/mJUaJelx4iY/iMAwCkbAOCcDQBwzgYAOGcDAJyzAQDO2QAA52wAgHM2AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOBgA4ZwMAnLMBAM7ZAADnbACAczYAwDkbAOCcDQBwzgYAOOcrL5uZ8N9qm081M3mibZ6Ymbypbd4yM3lT27xpZvKWtnliZvJE2zwxM+G/1TZv2QAA52wAgHM2AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOV36JtuFPM5M3zUyeaJsnZiY/Xdu8aWbyRNt8V9u8aWbyprZ5Ymbylrb5DdqGP81MfroNAHDOBgA4ZwMAnLMBAM7ZAADnbACAczYAwDkbAOCcDQBwzgYAOGcDAJyzAQDO2QAA53zlw81Mfrq2+WQzkyfa5i0zkze1zRNt85aZySebmfx0M5Mn2uY3mJn8dG3zqTYAwDkbAOCcDQBwzgYAOGcDAJyzAQDO2QAA52wAgHM2AMA5GwDgnA0AcM4GADhnAwCc8xX4l7XNW2YmT7TNEzOTJ2Ymb2qb72qbTzYzeaJtvmtmAj/NBgA4ZwMAnLMBAM7ZAADnbACAczYAwDkbAOCcDQBwzgYAOGcDAJyzAQDO2QAA52wAgHO+Av+ymckTbfNdbfPEzORNbcPfMTN508wEPsEGADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOBgA4ZwMAnLMBAM7ZAADnfOXDtQ2/08zku9rmibZ508zkU7XNEzOTJ9rmU81MPlnb8N/ZAADnbACAczYAwDkbAOCcDQBwzgYAOGcDAJyzAQDO2QAA52wAgHM2AMA5GwDgnA0AcM5XfomZCb9T2zwxM3nLzOSJtnlT2zwx
M/mutnliZvJE2zwxM3mibZ6YmXxX23yymQm/zwYAOGcDAJyzAQDO2QAA52wAgHM2AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzpv8I/ItmJk+0zXfNTD5Z2wD8DRsA4JwNAHDOBgA4ZwMAnLMBAM7ZAADnbACAczYAwDkbAOCcDQBwzgYAOGcDAJyzAQDO+cqHm5k80TZvmZl8srb5VG3zqWYm/Lfa5omZyRNt88TMhD+1zU+3AQDO2QAA52wAgHM2AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JzpP/Kimckna5tPNTP56drmTTOT36Btvmtm8kTb/AYzkyfa5qebmfwGbfNdM5Mn2uZNM5Mn2uYtGwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOBgA4ZwMAnLMBAM75yi/RNk/MTD7VzOSJtnmibZ6YmTzRNm+ZmbypbfjTzORNbfOWmckTbfNE27xpZvLEzOS72uaJmckTbfOpNgDAORsA4JwNAHDOBgA4ZwMAnLMBAM7ZAADnbACAczYAwDkbAOCcDQBwzgYAOOcrH65tnpiZPDEzeUvbPDEzeaJtnmibJ2Ym39U2T7TNm2Ym/B1t88TM5Im2+a62eWJm8sna5i1tw582AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOBgA4ZwMAnPOVl7XNEzOTN7XNTzczeaJtfoO2+a6ZyZva5om2edPM5Lva5omZCX+amTzRNm+ambxpZvKWtnliZvKpNgDAORsA4JwNAHDOBgA4ZwMAnLMBAM7ZAADnbACAczYAwDkbAOCcDQBwzgYAOGcDAJzzlZfNTJ5om99gZvJdbfNE2zwxM3lT2zwxM3lL2zwxM3lT2/x0bcPfMTN5om3408zkibZ5Ymby020AgHM2AMA5GwDgnA0AcM4GADhnAwCcswEAztkA
AOdsAIBzNgDAORsA4JwNAHDOBgA45ysva5s3zUyeaJu3zEx+g7b56drmiZnJE23zxMzkiZnJE23zlpnJE23zprb56drmk7XNd81Mnmgb/rQBAM7ZAADnbACAczYAwDkbAOCcDQBwzgYAOGcDAJyzAQDO2QAA52wAgHM2AMA5GwDgnK/wP81Mnmib75qZPNE2T8xMnpiZPNE2n2pm8qlmJm+amTzRNm+amXxX2zwxM3lT2zwxM3liZvKWmQl/2gAA52wAgHM2AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOVz5c2zwxM/npZiZPtM0TM5OfbmbyG7TNEzOTJ2Ym39U2T8xM3jQzeaJt3jIzeaJt3jQzeVPbfNfM5E1t88TM5KfbAADnbACAczYAwDkbAOCcDQBwzgYAOGcDAJyzAQDO2QAA52wAgHM2AMA5GwDgnK/8EjOTJ9rmTTOT72qb36Btfrq2eWJm8kTb/AZt89O1zZtmJk+0zXfNTPg72uaJmcmb2uan2wAA52wAgHM2AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOV142M3mibZ6YmTzRNk/MTN4yM/kN2uZTzUyeaJsn2uana5snZiZvaptPNTP5VDOTN81M3tQ2b9kAAOdsAIBzNgDAORsA4JwNAHDOBgA4ZwMAnLMBAM7ZAADnbACAczYAwDkbAOCcDQBwzlde1jb8HW3zxMzkibZ5YmbyqdrmiZnJE23Dn9qGv6NtPlXb8KcNAHDOBgA4ZwMAnLMBAM7ZAADnbACAczYAwDkbAOCcDQBwzgYAOGcDAJyzAQDO2QAA53yF/9zM5E1t88TM5Im2ecvM5Im2eWJmAv+WmcmbZiZvapvvaps3zUze1DZv2QAA52wAgHM2AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOV36JmckT
bfPTtc2bZia/wczkp2ubJ2Ym/B0zkze1zXe1zRMzkze1zRMzk7fMTJ5omyfa5omZyU+3AQDO2QAA52wAgHM2AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JyvvGxm8qaZyaeamfwGM5Mn2uYtM5Mn2uZNM5Mn2uYtM5Mn2uaJmQl/x8zkp2ubJ2YmT7TNp9oAAOdsAIBzNgDAORsA4JwNAHDOBgA4ZwMAnLMBAM7ZAADnbACAczYAwDkbAOCcr7ysbd40M3lT23zXzOSJtvkNZiZvmZm8aWbyRNs8MTN5Ymbylrb5DdrmLTOTN7XNm2Ymb5mZPNE2T8xMnmibn24DAJyzAQDO2QAA52wAgHM2AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAOdN/5EUzkze1zRMzk0/VNk/MTJ5omydmJj9d2zwxM3mibZ6YmXxX2/wGM5Ofrm2emJnwp7bh79gAAOdsAIBzNgDAORsA4JwNAHDOBgA4ZwMAnLMBAM7ZAADnbACAczYAwDkbAOCcDQBwzlde1ja/Qdvwd8xM3tI2b5qZPNE2P93M5E1t86a2+VRt8xvMTL5rZvLJ2uYtGwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOBgA4ZwMAnLMBAM75ystmJvy32uY3aJtPNTN5om3e0jZPzEx+g5nJW9rmN5iZPNE2b2mb32Bm8tNtAIBzNgDAORsA4JwNAHDOBgA4ZwMAnLMBAM7ZAADnbACAczYAwDkbAOCcDQBwzgYAOOcrv0Tb8KeZySebmXxX27ypbT7VzOQ3aJs3zUy+a2byG7TNTzczeaJtnpiZfKoNAHDOBgA4ZwMAnLMBAM7ZAADnbACAczYAwDkbAOCcDQBwzgYAOGcDAJyzAQDO2QAA53zlw81Mfrq2+Q3a5lPNTN7UNk/MTN7SNk/MTH6Dmcmnmpl8qrZ5U9t8qg0A
cM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOBgA4ZwMAnLMBAM75CvxQM5Pvapsn2uZNM5Mn2uaJmcl3zUyeaJs3zUyeaJsnZibf1TZPzEze1DZPzEw+1czkibb56TYAwDkbAOCcDQBwzgYAOGcDAJyzAQDO2QAA52wAgHM2AMA5GwDgnA0AcM4GADhnAwCc8xX4f5qZPNE2T7TNd81MnmibT9Y2P93M5Im2eWJm8kTbfNfM5E1t86a2eWJm8paZyZtmJk+0zVs2AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOBgA4ZwMAnPOVD9c2/B1t88TM5C1t88lmJk+0zXfNTJ5omyfa5omZyRNt86lmJm9qmyfa5i1tw582AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOBgA4ZwMAnDP9R140M+G/1Ta/wczkLW3zxMzkTW3zxMzkp2ub32Bm8l1t88TM5DdomydmJt/VNk/MTJ5omydmJk+0zVs2AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOBgA4ZwMAnDP9RwCAUzYAwDkbAOCcDQBwzgYAOGcDAJyzAQDO2QAA52wAgHM2AMA5GwDgnA0AcM4GADhnAwCcswEAztkAAOdsAIBzNgDAORsA4JwNAHDOBgA4ZwMAnLMBAM7ZAADnbACAczYAwDkbAOCc/wNCEQQvsX3p9wAAAABJRU5ErkJggg==
'@
$script:TipQrB64 = $TipQrB64

Start-App
