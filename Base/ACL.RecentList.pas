{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*               Recent List                 *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.RecentList;

{$I ACL.Config.inc}

interface

uses
  // System
  System.Classes,
  System.Math,
  System.SysUtils,
  // Vcl
  Vcl.Menus,
  // ACL
  ACL.Classes.StringList,
  ACL.FileFormats.INI,
  ACL.Utils.FileSystem;

type

  { TACLRecentList }

  TACLRecentList = class
  strict private
    FMaxCount: Integer;
    FOnChange: TNotifyEvent;

    function GetLastAdded: string;
  protected
    FItems: TACLStringList;

    procedure Changed;
    function IsValid(const S: UnicodeString): Boolean; virtual;
  public
    constructor Create(AMaxCount: Integer = 10); virtual;
    destructor Destroy; override;
    procedure Add(const S: UnicodeString); virtual;
    procedure BuildMenu(AParentItem: TMenuItem; ATag: Integer; AEvent: TNotifyEvent; const AFormatLine: UnicodeString = '%s');
    procedure ConfigLoad(AConfig: TACLIniFile; const ASection: UnicodeString); virtual;
    procedure ConfigSave(AConfig: TACLIniFile; const ASection: UnicodeString); virtual;
    procedure Validate;
    //
    property Items: TACLStringList read FItems;
    property LastAdded: string read GetLastAdded;
    //
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  { TACLRecentFileList }

  TACLRecentFileList = class(TACLRecentList)
  protected
    function IsValid(const S: string): Boolean; override;
  end;

  { TACLRecentPathList }

  TACLRecentPathList = class(TACLRecentList)
  protected
    function IsValid(const S: string): Boolean; override;
  public
    procedure Add(const S: string); override;
  end;

implementation

uses
  ACL.UI.Menus;

{ TACLRecentList }

constructor TACLRecentList.Create(AMaxCount: Integer = 10);
begin
  inherited Create;
  FItems := TACLStringList.Create;
  FMaxCount := AMaxCount;
end;

destructor TACLRecentList.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TACLRecentList.Add(const S: UnicodeString);
begin
  Items.Remove(S);
  Items.Insert(0, S);
  if Items.Count > FMaxCount then
    Items.Delete(Items.Count - 1);
  Changed;
end;

procedure TACLRecentList.BuildMenu(AParentItem: TMenuItem;
  ATag: Integer; AEvent: TNotifyEvent; const AFormatLine: UnicodeString = '%s');
var
  I: Integer;
begin
  Validate;
  for I := 0 to Items.Count - 1 do
    AParentItem.AddItem(Format(AFormatLine, [Items[I]]), Items[I], ATag, AEvent);
end;

procedure TACLRecentList.ConfigLoad(AConfig: TACLIniFile; const ASection: UnicodeString);
begin
  Items.Text := AConfig.SectionData[ASection];
  Changed;
end;

procedure TACLRecentList.ConfigSave(AConfig: TACLIniFile; const ASection: UnicodeString);
begin
  AConfig.SectionData[ASection] := Items.Text;
end;

procedure TACLRecentList.Validate;
var
  AHasChanges: Boolean;
  I: Integer;
begin
  AHasChanges := False;
  for I := Items.Count - 1 downto 0 do
  begin
    if not IsValid(Items[I]) then
    begin
      AHasChanges := True;
      Items.Delete(I);
    end;
  end;
  if AHasChanges then
    Changed;
end;

procedure TACLRecentList.Changed;
begin
  if Assigned(OnChange) then
    OnChange(Self);
end;

function TACLRecentList.GetLastAdded: string;
begin
  if Items.Count > 0 then
    Result := Items[0]
  else
    Result := '';
end;

function TACLRecentList.IsValid(const S: UnicodeString): Boolean;
begin
  Result := True;
end;

{ TACLRecentPathList }

procedure TACLRecentPathList.Add(const S: string);
begin
  inherited Add(acIncludeTrailingPathDelimiter(S));
end;

function TACLRecentPathList.IsValid(const S: string): Boolean;
begin
  Result := acDirectoryExists(S);
end;

{ TACLRecentFileList }

function TACLRecentFileList.IsValid(const S: string): Boolean;
begin
  Result := acFileExists(S);
end;

end.
