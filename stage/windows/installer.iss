#define AppName "Target"
#define AppPublisher "TargetProxy"
#define AppExeName "target.exe"
#define TargetLibService "TargetLib"

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

#ifndef TargetLibSource
  #define TargetLibSource "..\..\..\TargetLib\build\TargetLib.exe"
#endif

[Setup]
AppId={{8D70C14D-0FC8-4C5D-84B8-D725670B48C8}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir=..\..\build\windows\installer
OutputBaseFilename=TargetSetup
SetupIconFile=..\..\build\windows\installer\TargetAppIcon.ico
UninstallDisplayIcon={app}\{#AppExeName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Excludes: "TargetLib.exe,TargetLib.exe.version"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#TargetLibSource}"; DestDir: "{commonappdata}\TargetLib\bin"; DestName: "TargetLib.exe"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"

[UninstallDelete]
Type: files; Name: "{commonappdata}\TargetLib\bin\TargetLib.exe"
Type: files; Name: "{commonappdata}\TargetLib\bin\TargetLib.exe.version"
Type: dirifempty; Name: "{commonappdata}\TargetLib\bin"

[Code]
const
  ServiceName = '{#TargetLibService}';
  ServiceWaitAttempts = 120;
  ServiceWaitDelay = 250;

function RunServiceControl(const Arguments: String; var ExitCode: Integer): Boolean;
begin
  Result := Exec(ExpandConstant('{sys}\sc.exe'), Arguments, '', SW_HIDE,
    ewWaitUntilTerminated, ExitCode);
end;

function ServiceExists(): Boolean;
var
  ExitCode: Integer;
begin
  Result := RunServiceControl('query "' + ServiceName + '"', ExitCode) and
    (ExitCode = 0);
end;

function ServiceHasState(const StateName: String): Boolean;
var
  ExitCode: Integer;
  Parameters: String;
begin
  Parameters := '/C ""' + ExpandConstant('{sys}\sc.exe') + '" query "' +
    ServiceName + '" | "' + ExpandConstant('{sys}\findstr.exe') +
    '" /C:"' + StateName + '" >nul"';
  Result := Exec(ExpandConstant('{cmd}'), Parameters, '', SW_HIDE,
    ewWaitUntilTerminated, ExitCode) and (ExitCode = 0);
end;

function WaitForServiceState(const StateName: String): Boolean;
var
  Attempt: Integer;
begin
  for Attempt := 1 to ServiceWaitAttempts do
  begin
    if ServiceHasState(StateName) then
    begin
      Result := True;
      Exit;
    end;
    Sleep(ServiceWaitDelay);
  end;
  Result := False;
end;

function WaitForServiceRemoval(): Boolean;
var
  Attempt: Integer;
begin
  for Attempt := 1 to ServiceWaitAttempts do
  begin
    if not ServiceExists() then
    begin
      Result := True;
      Exit;
    end;
    Sleep(ServiceWaitDelay);
  end;
  Result := False;
end;

procedure RemoveTargetLibService();
var
  ExitCode: Integer;
begin
  if not ServiceExists() then
    Exit;

  if not ServiceHasState('STOPPED') then
  begin
    Log('Stopping ' + ServiceName + ' service');
    RunServiceControl('stop "' + ServiceName + '"', ExitCode);
    if not WaitForServiceState('STOPPED') then
      RaiseException(ServiceName + ' did not stop within 30 seconds.');
  end;

  Log('Unregistering ' + ServiceName + ' service');
  if (not RunServiceControl('delete "' + ServiceName + '"', ExitCode)) or
     ((ExitCode <> 0) and (ExitCode <> 1060)) then
    RaiseException(Format('Unable to unregister %s (exit code %d).', [ServiceName, ExitCode]));

  if not WaitForServiceRemoval() then
    RaiseException(ServiceName +
      ' was marked for deletion but is still in use.');
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  try
    RemoveTargetLibService();
  except
    Result := GetExceptionMessage();
  end;
end;

procedure InstallTargetLibService();
var
  ExitCode: Integer;
  ServiceExe: String;
  DataDir: String;
begin
  ServiceExe := ExpandConstant('{commonappdata}\TargetLib\bin\TargetLib.exe');
  DataDir := ExpandConstant('{commonappdata}\TargetLib');

  Log('Registering ' + ServiceName + ' service');
  if (not Exec(ServiceExe, 'install --base-path "' + DataDir + '"', '',
      SW_HIDE, ewWaitUntilTerminated, ExitCode)) or (ExitCode <> 0) then
    RaiseException(Format('Unable to register %s (exit code %d).', [ServiceName, ExitCode]));

  Log('Starting ' + ServiceName + ' service');
  if (not RunServiceControl('start "' + ServiceName + '"', ExitCode)) or
     (ExitCode <> 0) or (not WaitForServiceState('RUNNING')) then
  begin
    try
      RemoveTargetLibService();
    except
      Log('Cleanup after service start failure also failed: ' +
        GetExceptionMessage());
    end;
    DeleteFile(ServiceExe);
    RaiseException(ServiceName + ' did not reach the running state.');
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    InstallTargetLibService();
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    RemoveTargetLibService();
end;
