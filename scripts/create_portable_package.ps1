# Create portable package script for Mason Windows application

$ErrorActionPreference = "Stop"

# Configuration
$ProjectRoot = "E:\dev\source\mason"
$Version = "1.0.0"
$AppName = "Mason"
$SourceDir = Join-Path $ProjectRoot "build\windows\x64\runner\Release"
$OutputDir = Join-Path $ProjectRoot "installers"
$ZipFileName = "$AppName-portable-windows-x64-v$Version.zip"

Write-Host "Creating portable package for $AppName v$Version..."
Write-Host "Source: $SourceDir"
Write-Host "Output: $OutputDir\$ZipFileName"

# Ensure output directory exists
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Create temporary staging directory
$StagingDir = Join-Path $env:TEMP "mason_portable_$([Guid]::NewGuid())"
New-Item -ItemType Directory -Path $StagingDir -Force | Out-Null

try {
    # Copy application files
    Write-Host "Copying application files..."
    Copy-Item -Path "$SourceDir\*" -Destination $StagingDir -Recurse -Force

    # Create README file
    $ReadmeContent = @"
Mason - 便携版使用说明
====================

版本: $Version
平台: Windows x64

安装方法：
---------
这是一个便携版本，无需安装。

1. 将此 ZIP 文件解压到任意目录
2. 双击运行 mason.exe 即可启动应用

卸载：
---------
直接删除解压后的文件夹即可。

系统要求：
---------
- Windows 10 或更高版本
- x64 架构

更多信息：
---------
项目主页: https://github.com/yourusername/mason
"@

    $ReadmeContent | Out-File -FilePath (Join-Path $StagingDir "README.txt") -Encoding UTF8

    # Create ZIP file
    $ZipPath = Join-Path $OutputDir $ZipFileName
    Write-Host "Creating ZIP package: $ZipPath"

    if (Test-Path $ZipPath) {
        Remove-Item $ZipPath -Force
    }

    # Using PowerShell's Compress-Archive
    Compress-Archive -Path "$StagingDir\*" -DestinationPath $ZipPath -CompressionLevel Optimal -Force

    $ZipSize = (Get-Item $ZipPath).Length / 1MB
    Write-Host ""
    Write-Host "✓ 便携式安装包创建成功!"
    Write-Host "  文件位置: $ZipPath"
    Write-Host "  文件大小: $([math]::Round($ZipSize, 2)) MB"
}
finally {
    # Clean up staging directory
    Remove-Item -Path $StagingDir -Recurse -Force -ErrorAction SilentlyContinue
}
