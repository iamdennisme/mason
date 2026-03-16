param(
  [string]$OutDir = "resources\jre"
)

$ErrorActionPreference = "Stop"
$tempRoot = Join-Path $env:TEMP ("mason-jre-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

try {
  $arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "aarch64" } else { "x64" }
  $url = "https://api.adoptium.net/v3/binary/latest/17/ga/windows/$arch/jre/hotspot/normal/eclipse?project=jdk"
  $archive = Join-Path $tempRoot "jre.zip"
  $extract = Join-Path $tempRoot "extracted"

  Write-Host "Downloading JRE from: $url"
  Invoke-WebRequest -Uri $url -OutFile $archive
  Expand-Archive -Path $archive -DestinationPath $extract -Force

  $jreRoot = Get-ChildItem $extract -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName "bin\java.exe") } |
    Select-Object -First 1

  if (-not $jreRoot) {
    throw "Failed to locate extracted JRE root"
  }

  Remove-Item -Recurse -Force $OutDir -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
  Copy-Item -Recurse (Join-Path $jreRoot.FullName "*") $OutDir -Force

  Write-Host "Embedded JRE ready at: $OutDir"
} finally {
  Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
}
