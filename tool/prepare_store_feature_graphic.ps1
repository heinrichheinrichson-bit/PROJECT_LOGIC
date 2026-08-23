param(
  [Parameter(Mandatory = $true)]
  [string]$Source,
  [string]$Destination = "docs/store_assets/thinkheim_feature_graphic_1024x500.png"
)

Add-Type -AssemblyName System.Drawing

$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$destinationPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Destination))
$destinationDirectory = Split-Path -Parent $destinationPath
[System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null

$inputImage = [System.Drawing.Image]::FromFile($sourcePath)
try {
  $targetWidth = 1024
  $targetHeight = 500
  $targetAspect = $targetWidth / $targetHeight
  $sourceAspect = $inputImage.Width / $inputImage.Height

  if ($sourceAspect -gt $targetAspect) {
    $cropHeight = $inputImage.Height
    $cropWidth = [int][Math]::Round($cropHeight * $targetAspect)
    $cropX = [int](($inputImage.Width - $cropWidth) / 2)
    $cropY = 0
  } else {
    $cropWidth = $inputImage.Width
    $cropHeight = [int][Math]::Round($cropWidth / $targetAspect)
    $cropX = 0
    $cropY = [int](($inputImage.Height - $cropHeight) / 2)
  }

  $outputImage = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  try {
    $graphics = [System.Drawing.Graphics]::FromImage($outputImage)
    try {
      $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
      $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
      $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
      $graphics.DrawImage(
        $inputImage,
        (New-Object System.Drawing.Rectangle(0, 0, $targetWidth, $targetHeight)),
        (New-Object System.Drawing.Rectangle($cropX, $cropY, $cropWidth, $cropHeight)),
        [System.Drawing.GraphicsUnit]::Pixel
      )
    } finally {
      $graphics.Dispose()
    }
    $outputImage.Save($destinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
  } finally {
    $outputImage.Dispose()
  }
} finally {
  $inputImage.Dispose()
}

$result = [System.Drawing.Image]::FromFile($destinationPath)
try {
  Write-Output ("Created {0} ({1}x{2}, {3} bytes)" -f $destinationPath, $result.Width, $result.Height, (Get-Item -LiteralPath $destinationPath).Length)
} finally {
  $result.Dispose()
}
