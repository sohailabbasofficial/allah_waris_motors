$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '..\lib' | Resolve-Path
$fixed = @()

Get-ChildItem -Path $root -Recurse -Filter '*.dart' | ForEach-Object {
  $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
  if ($bytes.Length -lt 4) { return }

  $isUtf16 = $false
  if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { $isUtf16 = $true }
  elseif ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) { $isUtf16 = $true }
  else {
    $sampleLen = [Math]::Min(200, $bytes.Length)
    $nulls = 0
    for ($i = 1; $i -lt $sampleLen; $i += 2) {
      if ($bytes[$i] -eq 0) { $nulls++ }
    }
    if ($nulls -ge [Math]::Floor($sampleLen / 4)) { $isUtf16 = $true }
  }

  if (-not $isUtf16) { return }

  if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
    $text = [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
  } elseif ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
    $text = [System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)
  } else {
    $text = [System.Text.Encoding]::Unicode.GetString($bytes)
  }

  $utf8NoBom = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($_.FullName, $text, $utf8NoBom)
  $fixed += $_.FullName
}

Write-Host ("fixed={0}" -f $fixed.Count)
$fixed | ForEach-Object { Write-Host $_ }
