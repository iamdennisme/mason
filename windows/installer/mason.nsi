; Mason Installer Script for NSIS
; Requires NSIS 3.0 or later

!define APPNAME "Mason"
!define VERSION "1.0.0"
!define PUBLISHER "tech.taicheng.mason"

; General settings
Name "${APPNAME}"
OutFile "..\..\installers\${APPNAME}-setup-${VERSION}.exe"
InstallDir "$PROGRAMFILES64\${APPNAME}"
InstallDirRegKey HKLM "Software\${APPNAME}" "InstallPath"
RequestExecutionLevel admin

; Use modern UI
!include "MUI2.nsh"

; DPI awareness support - fix blur on high DPI screens
!include "FileFunc.nsh"
!include "WinVer.nsh"

; Reserve files for proper resource ordering
!insertmacro MUI_RESERVEFILE_LANGDLL
ReserveFile "${NSISDIR}\Plugins\x86-unicode\Banner.dll"
ReserveFile "${NSISDIR}\Plugins\x86-unicode\AdvSplash.dll"

; Interface settings
!define MUI_ABORTWARNING
!define MUI_ICON "..\runner\resources\app_icon.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Languages
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "SimpChinese"

; Installer sections
Section "Main Application" SecMain
  SectionIn RO

  SetOutPath $INSTDIR

  ; Copy all files from the build directory
  File /r "..\..\build\windows\x64\runner\Release\*.*"

  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Register installation in registry
  WriteRegStr HKLM "Software\${APPNAME}" "InstallPath" "$INSTDIR"
  WriteRegStr HKLM "Software\${APPNAME}" "Version" "${VERSION}"

  ; Add to Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${PUBLISHER}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$INSTDIR\mason.exe"

  ; Create shortcuts
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\mason.exe" "" "$INSTDIR\mason.exe" 0
  CreateShortcut "$SMPROGRAMS\${APPNAME}\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\mason.exe" "" "$INSTDIR\mason.exe" 0

SectionEnd

Section "Start Menu Shortcut" SecShortcut
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\mason.exe"
SectionEnd

Section "Desktop Shortcut" SecDesktop
  CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\mason.exe"
SectionEnd

; Section descriptions
LangString DESC_SecMain ${LANG_ENGLISH} "Install ${APPNAME} main application files."
LangString DESC_SecMain ${LANG_SIMPCHINESE} "Install ${APPNAME} main application files."

LangString DESC_SecShortcut ${LANG_ENGLISH} "Create Start Menu shortcut."
LangString DESC_SecShortcut ${LANG_SIMPCHINESE} "Create Start Menu shortcut."

LangString DESC_SecDesktop ${LANG_ENGLISH} "Create desktop shortcut."
LangString DESC_SecDesktop ${LANG_SIMPCHINESE} "Create desktop shortcut."

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} $(DESC_SecMain)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecShortcut} $(DESC_SecShortcut)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} $(DESC_SecDesktop)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Uninstaller section
Section "Uninstall"
  ; Delete files
  RMDir /r "$INSTDIR"

  ; Delete shortcuts
  Delete "$DESKTOP\${APPNAME}.lnk"
  RMDir /r "$SMPROGRAMS\${APPNAME}"

  ; Remove registry keys
  DeleteRegKey HKLM "Software\${APPNAME}"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
SectionEnd

; Functions
Function .onInit
  ; Set DPI awareness to fix blur on high DPI screens
  System::Call 'user32::SetProcessDPIAware()'

  ; Check if already installed
  ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString"
  StrCmp $R0 "" done

  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \
    "${APPNAME} is already installed. $\n$\nClick OK to remove the previous version or Cancel to cancel this upgrade." \
    IDOK uninst
  Abort

  uninst:
    ClearErrors
    ExecWait '$R0 _?=$INSTDIR'

    IfErrors no_remove_uninstaller done
    no_remove_uninstaller:
  done:
FunctionEnd

Function un.onInit
  ; Set DPI awareness to fix blur on high DPI screens
  System::Call 'user32::SetProcessDPIAware()'

  MessageBox MB_YESNO "Do you really want to uninstall ${APPNAME}?" IDYES No
  Abort
  No:
FunctionEnd
