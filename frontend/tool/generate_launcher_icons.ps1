# Rebuild Android launcher resources from the supplied RentMark artwork.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$frontendRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $frontendRoot 'assets\branding\rentmark_logo.png'
$resourceRoot = Join-Path $frontendRoot 'android\app\src\main\res'
$source = [System.Drawing.Image]::FromFile($sourcePath)

function Write-LauncherImage([string]$Target, [int]$Size, [double]$Scale) {
    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear([System.Drawing.Color]::White)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $ratio = $Size * $Scale / [Math]::Max($source.Width, $source.Height)
        $width = [int][Math]::Round($source.Width * $ratio)
        $height = [int][Math]::Round($source.Height * $ratio)
        $destination = New-Object System.Drawing.Rectangle(
            [int](($Size - $width) / 2), [int](($Size - $height) / 2), $width, $height
        )
        $graphics.DrawImage($source, $destination)
        $directory = Split-Path -Parent $Target
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
        $bitmap.Save($Target, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

try {
    foreach ($entry in @{'mdpi'=48; 'hdpi'=72; 'xhdpi'=96; 'xxhdpi'=144; 'xxxhdpi'=192}.GetEnumerator()) {
        Write-LauncherImage (Join-Path $resourceRoot "mipmap-$($entry.Key)\ic_launcher.png") $entry.Value 1.0
    }
    # 108dp adaptive layer at xxxhdpi; center the complete logo inside the safe area.
    Write-LauncherImage (Join-Path $resourceRoot 'mipmap-xxxhdpi\ic_launcher_foreground.png') 432 0.66
} finally {
    $source.Dispose()
}
Write-Output 'Generated RentMark Android launcher icons.'
