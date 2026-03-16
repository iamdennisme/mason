!include "MUI2.nsh"

!ifndef APP_VERSION
  !define APP_VERSION "0.0.0"
!endif

!ifndef APP_DIR
  !error "APP_DIR is required"
!endif

!ifndef OUT_FILE
  !define OUT_FILE "Mason-setup.exe"
!endif

Name "Mason ${APP_VERSION}"
OutFile "${OUT_FILE}"
InstallDir "$PROGRAMFILES64\\Mason"
RequestExecutionLevel admin

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Install"
  SetOutPath "$INSTDIR"
  File /r "${APP_DIR}\\*.*"

  CreateDirectory "$SMPROGRAMS\\Mason"
  CreateShortCut "$SMPROGRAMS\\Mason\\Mason.lnk" "$INSTDIR\\mason.exe"
  CreateShortCut "$DESKTOP\\Mason.lnk" "$INSTDIR\\mason.exe"

  WriteUninstaller "$INSTDIR\\Uninstall.exe"

  WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Mason" "DisplayName" "Mason"
  WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Mason" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Mason" "UninstallString" "$\"$INSTDIR\\Uninstall.exe$\""
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\\Mason.lnk"
  Delete "$SMPROGRAMS\\Mason\\Mason.lnk"
  RMDir "$SMPROGRAMS\\Mason"

  Delete "$INSTDIR\\Uninstall.exe"
  RMDir /r "$INSTDIR"

  DeleteRegKey HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Mason"
SectionEnd
