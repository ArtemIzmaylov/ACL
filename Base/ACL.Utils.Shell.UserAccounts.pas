{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*               User Accounts               *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Utils.Shell.UserAccounts;

{$I ACL.Config.inc}

interface

uses
  Windows, SysUtils, ShlObj, ACL.Classes.Collections;

type

  { TACLUserAccountInfo }

  TACLUserAccountInfo = class
  strict private
    FDisplayName: string;
    FName: string;
    FPathAppData: string;
    FPathProfile: string;

    function GetDisplayName: string;
  public
    constructor Create(const AName, ADisplayName, AProfilePath, APathAppData: string);
    function Equals(Obj: TObject): Boolean; override;
    //
    property DisplayName: string read GetDisplayName;
    property Name: string read FName;
    property PathAppData: string read FPathAppData;
    property PathProfile: string read FPathProfile;
  end;

  { TACLUserAccountInfoList }

  TACLUserAccountInfoList = class(TACLObjectList<TACLUserAccountInfo>)
  public
    procedure Add(AInfo: TACLUserAccountInfo);
  end;

  { TACLUserAccounts }

  TACLUserAccounts = class
  strict private
    class function OpenUsersFolder(const AProfile: string; out AKey: HKEY): Boolean; static;
  public
    class function Populate: TACLUserAccountInfoList; overload; static;
    class procedure Populate(AList: TACLUserAccountInfoList); overload; static;
  end;

function acComputerName: UnicodeString;
function acUserName: UnicodeString;
implementation

uses
  ACL.Classes.StringList,
  ACL.Utils.Common,
  ACL.Utils.FileSystem,
  ACL.Utils.Registry,
  ACL.Utils.Shell,
  ACL.Utils.Strings;

function ExpandEnvironmentVariablesInPath(const APath: string): string;
var
  ABuffer: TFileLongPath;
begin
  if ExpandEnvironmentStrings(PChar(APath), @ABuffer, Length(ABuffer)) = 0 then
    RaiseLastOSError;
  Result := ABuffer;
end;

function acComputerName: UnicodeString;
var
  ABuffer: array[0..127] of WideChar;
  ASize: Cardinal;
begin
  ASize := Length(ABuffer);
  if GetComputerNameW(@ABuffer[0], ASize) then
    Result := ABuffer
  else
    Result := '';
end;

function acUserName: UnicodeString;
var
  ABuffer: array[0..127] of WideChar;
  ASize: Cardinal;
begin
  ASize := Length(ABuffer);
  if GetUserNameW(@ABuffer[0], ASize) then
    Result := ABuffer
  else
    Result := '';
end;

{ TACLUserAccountInfo }

constructor TACLUserAccountInfo.Create(const AName, ADisplayName, AProfilePath, APathAppData: string);
begin
  inherited Create;
  FName := AName;
  FDisplayName := ADisplayName;
  FPathAppData := IncludeTrailingPathDelimiter(APathAppData);
  FPathProfile := IncludeTrailingPathDelimiter(AProfilePath);
end;

function TACLUserAccountInfo.Equals(Obj: TObject): Boolean;
begin
  Result := (Obj is TACLUserAccountInfo) and (PathProfile = TACLUserAccountInfo(Obj).PathProfile);
end;

function TACLUserAccountInfo.GetDisplayName: string;
begin
  Result := IfThenW(FDisplayName, Name);
end;

{ TACLUserAccountInfoList }

procedure TACLUserAccountInfoList.Add(AInfo: TACLUserAccountInfo);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if List[I].Equals(AInfo) then
    begin
      AInfo.Free;
      Exit;
    end;
  inherited Add(AInfo);
end;

{ TACLUserAccounts }

class function TACLUserAccounts.Populate: TACLUserAccountInfoList;
begin
  Result := TACLUserAccountInfoList.Create;
  Populate(Result);
end;

class procedure TACLUserAccounts.Populate(AList: TACLUserAccountInfoList);
const
  PathProfileList = 'Software\Microsoft\Windows NT\CurrentVersion\ProfileList\';
var
  AKey: HKEY;
  APath: string;
begin
  AList.Add(TACLUserAccountInfo.Create(acUserName, '', ShellGetSystemFolder(CSIDL_PROFILE), ShellGetAppData));

  acRegEnumKeys(HKEY_LOCAL_MACHINE, PathProfileList,
    procedure (const S: string)
    var
      ASubPath: string;
    begin
      if not acIsOurFile('*.bak;', S) then
      begin
        APath := ExpandEnvironmentVariablesInPath(acRegReadStr(HKEY_LOCAL_MACHINE, PathProfileList + S, 'ProfileImagePath'));
        if acDirectoryExists(APath) then
        begin
          if OpenUsersFolder(S, AKey) then
          try
            ASubPath := acStringReplace(acRegReadStr(AKey, 'AppData'), '%USERPROFILE%', APath, True);
            if ASubPath <> '' then
              AList.Add(TACLUserAccountInfo.Create(acExtractDirName(APath), '', APath, ASubPath));
          finally
            acRegClose(AKey);
          end;
        end;
      end;
    end);
end;

class function TACLUserAccounts.OpenUsersFolder(const AProfile: string; out AKey: HKEY): Boolean;
const
  PathUserFolders = 'Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\';
begin
  Result :=
    acRegOpenRead(HKEY_USERS, AProfile + PathDelim + PathUserFolders, AKey) or
    acRegOpenRead(HKEY_USERS, '.DEFAULT' + PathDelim + PathUserFolders, AKey);
end;

end.
