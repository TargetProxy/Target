Unicode True

Name "Target"
OutFile "..\..\build\windows\installer\TargetSetup.exe"
Icon "..\..\build\windows\installer\TargetAppIcon.ico"
UninstallIcon "..\..\build\windows\installer\TargetAppIcon.ico"
InstallDir "$PROGRAMFILES64\Target"
RequestExecutionLevel admin

Page directory
Page instfiles
UninstPage instfiles

Section "Install"
  SetOutPath "$INSTDIR"
  File /r "..\..\build\windows\x64\runner\Release\*.*"

  CreateDirectory "$SMPROGRAMS\Target"
  CreateShortcut "$SMPROGRAMS\Target\Target.lnk" "$INSTDIR\target.exe"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
  Delete "$SMPROGRAMS\Target\Target.lnk"
  RMDir "$SMPROGRAMS\Target"
  RMDir /r "$INSTDIR"
SectionEnd
