# Export the user-authorized repaired cottage as nine 16x16 game tiles.
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
$source = [System.Drawing.Bitmap]::FromFile((Join-Path $PSScriptRoot 'art/cottage-repaired-source.png'))
$outputDirectory = Join-Path $projectRoot 'assets/overworld/cottage'
$house = [System.Drawing.Bitmap]::new(48,48,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($house)
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
# Align the roof to row 0 and facade to rows 1-2 of the existing map layout.
$g.DrawImage($source,[System.Drawing.Rectangle]::new(0,0,48,16),
    60,78,1136,443,[System.Drawing.GraphicsUnit]::Pixel)
$g.DrawImage($source,[System.Drawing.Rectangle]::new(0,16,48,32),
    60,521,1136,609,[System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$source.Dispose()
# Remove the source's opaque white/checkerboard backdrop. Only flood from
# canvas edges through light neutral pixels, preserving enclosed highlights.
$pending = [System.Collections.Generic.Queue[System.Drawing.Point]]::new()
for ($x=0; $x -lt $house.Width; $x++) {
    $pending.Enqueue([System.Drawing.Point]::new($x,0))
    $pending.Enqueue([System.Drawing.Point]::new($x,$house.Height-1))
}
for ($y=0; $y -lt $house.Height; $y++) {
    $pending.Enqueue([System.Drawing.Point]::new(0,$y))
    $pending.Enqueue([System.Drawing.Point]::new($house.Width-1,$y))
}
$visited = [bool[]]::new($house.Width*$house.Height)
while ($pending.Count -gt 0) {
    $p = $pending.Dequeue()
    if ($p.X -lt 0 -or $p.Y -lt 0 -or $p.X -ge $house.Width -or $p.Y -ge $house.Height) { continue }
    $index = $p.Y*$house.Width+$p.X
    if ($visited[$index]) { continue }
    $visited[$index] = $true
    $color = $house.GetPixel($p.X,$p.Y)
    $min = [Math]::Min($color.R,[Math]::Min($color.G,$color.B))
    $max = [Math]::Max($color.R,[Math]::Max($color.G,$color.B))
    if ($color.A -ne 0 -and ($min -lt 200 -or ($max-$min) -gt 12)) { continue }
    $house.SetPixel($p.X,$p.Y,[System.Drawing.Color]::FromArgb(0,$color.R,$color.G,$color.B))
    $pending.Enqueue([System.Drawing.Point]::new($p.X-1,$p.Y))
    $pending.Enqueue([System.Drawing.Point]::new($p.X+1,$p.Y))
    $pending.Enqueue([System.Drawing.Point]::new($p.X,$p.Y-1))
    $pending.Enqueue([System.Drawing.Point]::new($p.X,$p.Y+1))
}
$house.Save((Join-Path $outputDirectory 'cottage.png'),[System.Drawing.Imaging.ImageFormat]::Png)
for ($y=0; $y -lt 3; $y++) {
    for ($x=0; $x -lt 3; $x++) {
        $piece = $house.Clone([System.Drawing.Rectangle]::new($x*16,$y*16,16,16),
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $piece.Save((Join-Path $outputDirectory "tile_${y}_$x.png"),[System.Drawing.Imaging.ImageFormat]::Png)
        $piece.Dispose()
    }
}
$house.Dispose()
