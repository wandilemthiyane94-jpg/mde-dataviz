# Recolours the JRC Global Surface Water mosaic for the story map.
# GSW occurrence tiles encode occurrence as blue (R = 255 - B). Permanent water (sea, dams; occurrence >= 50%)
# is dimmed to a dark navy; intermittent water (< 50%, the ground that floods and dries) is drawn bright.
# Input/output: prototype/story/durban_water.png (overwritten in place from the cached raw mosaic).
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$src = "$root\prototype\story\durban_water.png"; $rawCopy = "$root\data\raw\durban_water_raw.png"
if (-not (Test-Path $rawCopy)) { Copy-Item $src $rawCopy }
$bmp = [System.Drawing.Bitmap]::FromFile($rawCopy)
$rect = New-Object System.Drawing.Rectangle 0, 0, $bmp.Width, $bmp.Height
$out = $bmp.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb); $bmp.Dispose()
$data = $out.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, $out.PixelFormat)
$n = $data.Stride * $out.Height; $buf = New-Object byte[] $n
[Runtime.InteropServices.Marshal]::Copy($data.Scan0, $buf, 0, $n)
for ($i = 0; $i -lt $n; $i += 4) {            # BGRA
  if ($buf[$i + 3] -eq 0) { continue }
  if ($buf[$i] -ge 128) { $buf[$i] = 71; $buf[$i + 1] = 48; $buf[$i + 2] = 22; $buf[$i + 3] = 255 }   # permanent -> #163047
  else { $buf[$i] = 234; $buf[$i + 1] = 183; $buf[$i + 2] = 88; $buf[$i + 3] = 255 }                  # intermittent -> #58B7EA
}
[Runtime.InteropServices.Marshal]::Copy($buf, 0, $data.Scan0, $n); $out.UnlockBits($data)
$out.Save($src, [System.Drawing.Imaging.ImageFormat]::Png); $out.Dispose()
"recoloured $src"
