const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const projectRoot = 'E:\\dev\\source\\mason';
const version = '1.0.0';
const appName = 'Mason';
const sourceDir = path.join(projectRoot, 'build\\windows\\x64\\runner\\Release');
const outputDir = path.join(projectRoot, 'installers');

async function createInstaller() {
    console.log(`Creating installer for ${appName} v${version}...`);

    // Ensure output directory exists
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    // Create a simple installer using nsis (if available)
    const nsisPath = 'C:\\Program Files (x86)\\NSIS\\makensis.exe';
    if (fs.existsSync(nsisPath)) {
        console.log('Using NSIS to create installer...');

        const nsisScript = `
!define APPNAME "${appName}"
!define VERSION "${version}"
!define PUBLISHER "tech.taicheng.mason"

Name "\${APPNAME}"
OutFile "${outputDir}\\${appName}-setup-${version}.exe"
InstallDir "$PROGRAMFILES64\\${APPNAME}"
RequestExecutionLevel admin

Page directory
Page instfiles

Section "MainSection" SEC01
    SetOutPath "$INSTDIR"
    File /r "${sourceDir}\\*.*"
    CreateDirectory "$SMPROGRAMS\\${APPNAME}"
    CreateShortcut "$SMPROGRAMS\\${APPNAME}\\${APPNAME}.lnk" "$INSTDIR\\mason.exe"
    CreateShortcut "$DESKTOP\\${APPNAME}.lnk" "$INSTDIR\\mason.exe"
SectionEnd

Section "Uninstall"
    Delete "$DESKTOP\\${APPNAME}.lnk"
    RMDir /r "$SMPROGRAMS\\${APPNAME}"
    RMDir /r "$INSTDIR"
SectionEnd
`;

        const nsisFile = path.join(projectRoot, 'scripts\\installer.nsi');
        fs.writeFileSync(nsisFile, nsisScript);

        try {
            execSync(`"${nsisPath}" "${nsisFile}"`, { stdio: 'inherit' });
            console.log(`\n✓ NSIS installer created!`);
            return;
        } catch (error) {
            console.log('NSIS method failed:', error.message);
        }
    }

    // Use IExpress (built into Windows)
    console.log('Using IExpress to create installer...');

    const psScriptPath = path.join(projectRoot, 'scripts\\create_iexpress.ps1');

    const psScript = `
$ErrorActionPreference = "Stop"
$sourceDir = "${sourceDir}"
$outputExe = "${outputDir}\\${appName}-setup-${version}.exe"
$tempDir = Join-Path $env:TEMP "mason_installer_$(Get-Random)"

New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    Write-Host "Copying files to temp directory..."
    Copy-Item -Path "$sourceDir\\*" -Destination $tempDir -Recurse -Force

    # Create installer script
    $batchContent = @"
@echo off
echo Installing ${appName} ${version}...
set TARGET_DIR=%PROGRAMFILES%\\\\${appName}

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
echo Copying files to %TARGET_DIR%...
xcopy /E /I /Y "%~dp0*" "%TARGET_DIR%"

echo Creating shortcuts...
powershell -Command "\\$ws = New-Object -ComObject WScript.Shell; \\$ws.CreateShortcut('%APPDATA%\\\\Microsoft\\\\Windows\\\\Start Menu\\\\Programs\\\\${appName}.lnk').TargetPath = '%TARGET_DIR%\\\\mason.exe'"

echo.
echo Installation complete!
echo.
pause
start "" "%TARGET_DIR%\\\\mason.exe"
"@
    $batchContent | Out-File -FilePath (Join-Path $tempDir "install.bat") -Encoding ASCII

    # Create SED file for IExpress
    $sedFile = Join-Path $tempDir "setup.sed"
    $sedContent = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=${appName}-setup
FriendlyName=${appName} ${version} Installer
AppLaunched=cmd /c install.bat
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFiles
[Strings]
SourceFilesPath=$tempDir
[SourceFiles]
SourceFiles0=$tempDir
"@

    # Add file entries
    $files = Get-ChildItem -Path $tempDir -File
    $idx = 0
    foreach ($file in $files) {
        $line = "SourceFiles0" + $idx + "=" + $file.Name
        $sedContent += $line + "\`r\`n"
        $idx++
    }

    $sedContent | Out-File -FilePath $sedFile -Encoding ASCII

    # Run IExpress
    $iexpress = Join-Path $env:SystemRoot "System32\\\\iexpress.exe"
    Write-Host "Running IExpress..."
    & $iexpress /N /Q $sedFile

    if (Test-Path $outputExe) {
        $size = (Get-Item $outputExe).Length / 1MB
        Write-Host ""
        Write-Host "✓ Installer created successfully!"
        Write-Host "  Location: $outputExe"
        Write-Host "  Size: $([math]::Round($size, 2)) MB"
    } else {
        Write-Host "IExpress may have failed. Checking for output..."
        $possibleOutput = Get-ChildItem -Path $tempDir -Filter "*.exe"
        if ($possibleOutput) {
            Move-Item -Path $possibleOutput.FullName -Destination $outputExe -Force
            Write-Host "✓ Installer created: $outputExe"
        }
    }
} finally {
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
`;

    fs.writeFileSync(psScriptPath, psScript);

    console.log('Running IExpress via PowerShell...\n');
    execSync(`powershell.exe -ExecutionPolicy Bypass -File "${psScriptPath}"`, {
        stdio: 'inherit'
    });
}

createInstaller().catch(error => {
    console.error('Error:', error.message);
    process.exit(1);
});
