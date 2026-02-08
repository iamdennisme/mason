; Mason Inno Setup Installer Script
; Requires Inno Setup 6 or later
; Usage: ISCC.exe /DAPP_VERSION=1.0.0 mason_installer.iss

#define APP_NAME "Mason"
#define APP_PUBLISHER "tech.taicheng.mason"
#define APP_URL "https://github.com/yourusername/mason"

; 从命令行获取版本号，如果未定义则使用默认值
#ifndef APP_VERSION
  #define APP_VERSION "1.0.0"
#endif

[Setup]
AppName={#APP_NAME}
AppVersion={#APP_VERSION}
AppPublisher={#APP_PUBLISHER}
AppPublisherURL={#APP_URL}
AppSupportURL={#APP_URL}
AppUpdatesURL={#APP_URL}
DefaultDirName={autopf}\{#APP_NAME}
DefaultGroupName={#APP_NAME}
AllowNoIcons=yes
OutputDir=..\..\installers
OutputBaseFilename=Mason-setup-{#APP_VERSION}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "chinesesimp"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; 复制整个 Release 目录
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#APP_NAME}"; Filename: "{app}\mason.exe"
Name: "{group}\{cm:UninstallProgram,{#APP_NAME}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#APP_NAME}"; Filename: "{app}\mason.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\mason.exe"; Description: "{cm:LaunchProgram,{#APP_NAME}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Delete: "{app}\*"
