# PowerShell script to generate Windows ICO file from PNG files
# Usage: .\generate_windows_icon.ps1

$ErrorActionPreference = "Stop"

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SvgFile = Join-Path $ScriptDir "mason_icon.svg"
$WindowsIconDir = Join-Path $ProjectRoot "windows\runner\resources"
$WindowsIcon = Join-Path $WindowsIconDir "app_icon.ico"

Write-Host "Generating Windows icon from SVG..."
Write-Host "Project Root: $ProjectRoot"

# Create temp directory
$TempDir = Join-Path $env:TEMP "mason_icon_$(Get-Random)"
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # Windows icon needs these sizes
    $Sizes = @(16, 32, 48, 256)

    # Generate PNG files using rsvg-convert
    foreach ($Size in $Sizes) {
        $PngFile = Join-Path $TempDir "app_icon_${Size}.png"
        & rsvg-convert -w $Size -h $Size -o $PngFile $SvgFile
        if ($LASTEXITCODE -ne 0) {
            throw "rsvg-convert failed for size ${Size}x${Size}"
        }
        Write-Host "Generated: app_icon_${Size}.png"
    }

    # Create ICO file
    Write-Host "`nCreating Windows ICO file..."

    # Ensure output directory exists
    if (!(Test-Path $WindowsIconDir)) {
        New-Item -ItemType Directory -Path $WindowsIconDir -Force | Out-Null
    }

    # Use ImageMagick if available
    $MagickExists = Get-Command "magick" -ErrorAction SilentlyContinue
    if ($MagickExists) {
        $PngFiles = $Sizes | ForEach-Object { Join-Path $TempDir "app_icon_${_}.png" }
        & magick $PngFiles $WindowsIcon
        Write-Host "✓ Windows icon created with ImageMagick: $WindowsIcon"
    } else {
        # Use Python script as fallback
        $PythonScript = @"
import struct
import os
from PIL import Image

def create_ico(png_files, ico_path):
    """Create ICO file from multiple PNG files"""
    images = []
    for png_file in png_files:
        img = Image.open(png_file)
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        images.append(img)

    with open(ico_path, 'wb') as f:
        # ICO header
        f.write(struct.pack('<H', 0))  # Reserved
        f.write(struct.pack('<H', 1))  # Type: 1 = ICO
        f.write(struct.pack('<H', len(images)))  # Number of images

        # Write directory entries
        data_offset = 6 + (16 * len(images))
        file_data = []

        for img in images:
            width = img.width if img.width < 256 else 0
            height = img.height if img.height < 256 else 0
            img.save(f'.tmp.png', format='PNG')
            with open('.tmp.png', 'rb') as tmp:
                png_data = tmp.read()
            os.remove('.tmp.png')

            size = len(png_data)
            file_data.append(png_data)

            # Directory entry
            f.write(struct.pack('B', width))  # Width
            f.write(struct.pack('B', height))  # Height
            f.write(struct.pack('B', 0))  # Color palette
            f.write(struct.pack('B', 0))  # Reserved
            f.write(struct.pack('<H', 1))  # Color planes
            f.write(struct.pack('<H', 32))  # Bits per pixel
            f.write(struct.pack('<I', size))  # Size of image data
            f.write(struct.pack('<I', data_offset))  # Offset to image data

            data_offset += size

        # Write image data
        for data in file_data:
            f.write(data)

if __name__ == '__main__':
    png_files = $("$($Sizes | ForEach-Object { "'$(Join-Path $TempDir "app_icon_$_.png")'" })" -join ', ')
    create_ico([png_files], r'$WindowsIcon')
    print('ICO file created successfully')
"@

        $PythonFile = Join-Path $TempDir "create_ico.py"
        $PythonScript | Out-File -FilePath $PythonFile -Encoding ASCII

        & python $PythonFile
        Write-Host "✓ Windows icon created with Python: $WindowsIcon"
    }

    Write-Host "`n✓ Windows icon generation complete!"
}
finally {
    # Clean up temp directory
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
