Unicode True

!include "LogicLib.nsh"
!include "StrFunc.nsh"
${StrStr}
${UnStrStr}

Var TargetLibDataDir

!define TARGETLIB_SERVICE "TargetLib"
!define TARGETLIB_DATA_DIR "$TargetLibDataDir"
!define TARGETLIB_BIN_DIR "${TARGETLIB_DATA_DIR}\bin"
!define TARGETLIB_EXE "${TARGETLIB_BIN_DIR}\TargetLib.exe"

!ifndef TARGETLIB_SOURCE
  !define TARGETLIB_SOURCE "..\..\..\TargetLib\build\TargetLib.exe"
!endif

Name "Target"
OutFile "..\..\build\windows\installer\TargetSetup.exe"
Icon "..\..\build\windows\installer\TargetAppIcon.ico"
UninstallIcon "..\..\build\windows\installer\TargetAppIcon.ico"
InstallDir "$PROGRAMFILES64\Target"
RequestExecutionLevel admin

Page directory
Page instfiles
UninstPage instfiles

Function .onInit
  SetShellVarContext all
  ReadEnvStr $TargetLibDataDir "ProgramData"
  StrCmp $TargetLibDataDir "" 0 +2
  Abort "The ProgramData directory is unavailable."
  StrCpy $TargetLibDataDir "$TargetLibDataDir\TargetLib"
FunctionEnd

Function un.onInit
  SetShellVarContext all
  ReadEnvStr $TargetLibDataDir "ProgramData"
  StrCmp $TargetLibDataDir "" 0 +2
  Abort "The ProgramData directory is unavailable."
  StrCpy $TargetLibDataDir "$TargetLibDataDir\TargetLib"
FunctionEnd

!macro DefineRemoveTargetLibService Prefix
Function ${Prefix}RemoveTargetLibService
  DetailPrint "Checking ${TARGETLIB_SERVICE} service..."
  nsExec::ExecToStack '"$SYSDIR\sc.exe" query "${TARGETLIB_SERVICE}"'
  Pop $0
  Pop $1
  StrCmp $0 "1060" service_done

!if "${Prefix}" == "un."
  ${UnStrStr} $2 $1 "STOPPED"
!else
  ${StrStr} $2 $1 "STOPPED"
!endif
  StrCmp $2 "" 0 service_stopped

  DetailPrint "Stopping ${TARGETLIB_SERVICE} service..."
  nsExec::ExecToLog '"$SYSDIR\sc.exe" stop "${TARGETLIB_SERVICE}"'
  Pop $0

  StrCpy $3 0
service_stop_wait:
  Sleep 250
  nsExec::ExecToStack '"$SYSDIR\sc.exe" query "${TARGETLIB_SERVICE}"'
  Pop $0
  Pop $1
  StrCmp $0 "1060" service_done
!if "${Prefix}" == "un."
  ${UnStrStr} $2 $1 "STOPPED"
!else
  ${StrStr} $2 $1 "STOPPED"
!endif
  StrCmp $2 "" 0 service_stopped
  IntOp $3 $3 + 1
  IntCmp $3 120 service_stop_timeout service_stop_wait service_stop_timeout

service_stop_timeout:
  MessageBox MB_ICONSTOP|MB_OK "${TARGETLIB_SERVICE} did not stop within 30 seconds."
  Abort

service_stopped:
  DetailPrint "Unregistering ${TARGETLIB_SERVICE} service..."
  nsExec::ExecToLog '"$SYSDIR\sc.exe" delete "${TARGETLIB_SERVICE}"'
  Pop $0
  StrCmp $0 "0" service_delete_wait
  StrCmp $0 "1060" service_done
  MessageBox MB_ICONSTOP|MB_OK "Unable to unregister ${TARGETLIB_SERVICE} (exit code $0)."
  Abort

service_delete_wait:
  StrCpy $3 0
service_delete_poll:
  Sleep 250
  nsExec::ExecToStack '"$SYSDIR\sc.exe" query "${TARGETLIB_SERVICE}"'
  Pop $0
  Pop $1
  StrCmp $0 "1060" service_done
  IntOp $3 $3 + 1
  IntCmp $3 120 service_delete_timeout service_delete_poll service_delete_timeout

service_delete_timeout:
  MessageBox MB_ICONSTOP|MB_OK "${TARGETLIB_SERVICE} was marked for deletion but is still in use."
  Abort

service_done:
FunctionEnd
!macroend

!insertmacro DefineRemoveTargetLibService ""
!insertmacro DefineRemoveTargetLibService "un."

Section "Install"
  SetOutPath "$INSTDIR"
  File /r /x TargetLib.exe /x TargetLib.exe.version "..\..\build\windows\x64\runner\Release\*.*"

  Call RemoveTargetLibService

  SetOutPath "${TARGETLIB_BIN_DIR}"
  File /oname=TargetLib.exe "${TARGETLIB_SOURCE}"

  DetailPrint "Registering ${TARGETLIB_SERVICE} service..."
  nsExec::ExecToLog '"${TARGETLIB_EXE}" install --base-path "${TARGETLIB_DATA_DIR}"'
  Pop $0
  StrCmp $0 "0" service_registered
  Delete "${TARGETLIB_EXE}"
  MessageBox MB_ICONSTOP|MB_OK "Unable to register ${TARGETLIB_SERVICE} (exit code $0)."
  Abort

service_registered:
  DetailPrint "Starting ${TARGETLIB_SERVICE} service..."
  nsExec::ExecToLog '"$SYSDIR\sc.exe" start "${TARGETLIB_SERVICE}"'
  Pop $0
  StrCmp $0 "0" service_start_wait
  Goto service_start_failed

service_start_wait:
  StrCpy $3 0
service_start_poll:
  Sleep 250
  nsExec::ExecToStack '"$SYSDIR\sc.exe" query "${TARGETLIB_SERVICE}"'
  Pop $0
  Pop $1
  ${StrStr} $2 $1 "RUNNING"
  StrCmp $2 "" 0 service_started
  IntOp $3 $3 + 1
  IntCmp $3 120 service_start_failed service_start_poll service_start_failed

service_start_failed:
  Call RemoveTargetLibService
  Delete "${TARGETLIB_EXE}"
  MessageBox MB_ICONSTOP|MB_OK "${TARGETLIB_SERVICE} did not reach the running state (last exit code $0)."
  Abort

service_started:
  SetOutPath "$INSTDIR"
  CreateDirectory "$SMPROGRAMS\Target"
  CreateShortcut "$SMPROGRAMS\Target\Target.lnk" "$INSTDIR\target.exe"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
  Call un.RemoveTargetLibService

  Delete "${TARGETLIB_EXE}"
  Delete "${TARGETLIB_EXE}.version"
  RMDir "${TARGETLIB_BIN_DIR}"

  Delete "$SMPROGRAMS\Target\Target.lnk"
  RMDir "$SMPROGRAMS\Target"
  RMDir /r "$INSTDIR"
SectionEnd
