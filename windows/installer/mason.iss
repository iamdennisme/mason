; Mason Application Installer Script
; Requires Inno Setup Compiler to build: https://jrsoftware.org/isdl.php

#define AppName "Mason"
#define AppVersion "1.0.0"
#define AppPublisher "tech.taicheng.mason"
#define AppExeName "mason.exe"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\Mason
DefaultGroupName=Mason
AllowNoIcons=yes
OutputDir=..\..\installers
OutputBaseFilename=mason-setup-{#AppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
WizardImageFile=installer\wizard-image.bmp
WizardSmallImageFile=installer\wizard-small.bmp
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
ChangesAssociations=yes
DisableDirPage=no
DisableProgramGroupPage=yes

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Languages\English.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon
Name: "{userstartup}\{#AppName}"; Filename: "{app}\{#AppExeName}"

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\Mason"

[Code]
function GetUninstallString(): String;
var
  sUnInstPath: String;
  sResult: String;
begin
  sResult := '';
  sUnInstPath := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppName}_is1');
  if RegQueryStringValue(HKLM, sUnInstPath, 'UninstallString', sResult) then
  begin
    Result := sResult;
  end
  else if RegQueryStringValue(HKCU, sUnInstPath, 'UninstallString', sResult) then
  begin
    Result := sResult;
  end
end;

function IsUpgrade(): Boolean;
begin
  Result := (GetUninstallString() <> '');
end;

function UnInstallOldVersion(): Integer;
var
  sUnInstallString: String;
  iResultCode: Integer;
begin
  Result := 0;
  sUnInstallString := GetUninstallString();
  if sUnInstallString <> '' then
  begin
    sUnInstallString := RemoveQuotes(sUnInstallString);
    if Exec(sUnInstallString, '/SILENT /NORESTART /SUPPRESSMSGBOXES','', SW_HIDE, ewWaitUntilTerminated, iResultCode) then
      Result := 3
    else
      Result := 2;
  end
  else
    Result := 1;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  sResult: String;
begin
  if IsUpgrade() then
  begin
    sResult := UnInstallOldVersion();
    if sResult = '2' then
      Result := CustomMessage('UninstallFailed')
    else
      Result := '';
  end
  else
    Result := '';
end;
