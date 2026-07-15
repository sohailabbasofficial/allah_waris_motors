$ErrorActionPreference = 'Stop'

# Fix pubspec UTF-16 if needed
$p = 'C:\src\car_rental_manager\pubspec.yaml'
$bytes = [System.IO.File]::ReadAllBytes($p)
Write-Host ("pubspec first bytes: " + ($bytes[0..7] -join ','))
if ($bytes.Length -gt 4 -and $bytes[1] -eq 0) {
  $text = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::Unicode)
  $utf8 = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($p, $text, $utf8)
  Write-Host 'Fixed pubspec to UTF-8'
}

Add-Type -AssemblyName System.Drawing
$srcPath = 'C:\src\car_rental_manager\assets\images\logo.png'
$outPath = 'C:\src\car_rental_manager\assets\images\app_icon.png'
$img = [System.Drawing.Image]::FromFile($srcPath)
Write-Host ("logo size: $($img.Width)x$($img.Height)")

# Crop top branding mark into a square (car + AW)
$cropH = [int]($img.Height * 0.52)
$side = [Math]::Min($img.Width, $cropH)
$x = [int](($img.Width - $side) / 2)
$y = [int](($cropH - $side) / 2)
if ($y -lt 0) { $y = 0 }

$rect = New-Object System.Drawing.Rectangle $x, $y, $side, $side
$bmp = New-Object System.Drawing.Bitmap $side, $side
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.Clear([System.Drawing.Color]::FromArgb(255, 248, 249, 250))
$dest = New-Object System.Drawing.Rectangle 0, 0, $side, $side
$g.DrawImage($img, $dest, $rect, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$img.Dispose()
Write-Host "Wrote app_icon ${side}x${side} -> $outPath"
Get-Item $outPath | Format-List FullName, Length
