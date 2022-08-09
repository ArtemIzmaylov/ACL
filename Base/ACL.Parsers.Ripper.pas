{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*       High-level Parsers Routines         *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2021-2022                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Parsers.Ripper;

{$I ACL.Config.inc}

interface

uses
  System.Math,
  System.SysUtils,
  System.Types,
  // ACL
  ACL.Classes.Collections,
  ACL.Expressions,
  ACL.Expressions.FormatString,
  ACL.FileFormats.XML;

type

  { TACLRipperRule }

  TACLRipperRule = class
  strict private
    FSource: TACLRipperRule;
  protected
    procedure ProcessCore(const ATarget: TACLList<string>; const ASource: string); virtual;
  public
    constructor Create(ASource: TACLRipperRule = nil);
    destructor Destroy; override;
    function Extract(const AData: string): string; overload;
    function ExtractEx(const AData: string): TACLList<string>; overload;
    procedure Process(var AData: TACLList<string>);
  end;

  { TACLRipperRuleAimingByTags }

  TACLRipperRuleAimingByTagsOption = (ratMultipleTargets, ratCaseInsensitive, ratConstrictionMode);
  TACLRipperRuleAimingByTagsOptions = set of TACLRipperRuleAimingByTagsOption;
  TACLRipperRuleAimingByTags = class(TACLRipperRule)
  strict private
    FFinishTags: TStringDynArray;
    FOptions: TACLRipperRuleAimingByTagsOptions;
    FStartTags: TStringDynArray;

    function Find(const AStrToFind, AStr: string; AStartPos, AEndPos: Integer; AFromEnd: Boolean): Integer;
  protected
    procedure ProcessCore(const ATarget: TACLList<string>; const ASource: string); override;
  public
    constructor Create(const AStartTags, AFinishTags: string;
      AOptions: TACLRipperRuleAimingByTagsOptions; ASource: TACLRipperRule = nil);
  end;

  { TACLRipperRuleExpression }

  TACLRipperRuleExpression = class(TACLRipperRule)
  strict private
    FExpression: TACLExpression;
  protected
    procedure ProcessCore(const ATarget: TACLList<string>; const ASource: string); override;
  public
    constructor Create(const AExpression: string; ASource: TACLRipperRule = nil);
    destructor Destroy; override;
  end;

  { TACLRipperRuleRemoveHtmlTags }

  TACLRipperRuleRemoveHtmlTags = class(TACLRipperRule)
  protected
    procedure ProcessCore(const ATarget: TACLList<string>; const ASource: string); override;
  end;

implementation

uses
  ACL.Utils.Common,
  ACL.Utils.Strings;

type

  { TACLRipperRuleExpressionContext }

  TACLRipperRuleExpressionContext = class
  public
    Value: string;
  end;

  { TACLRipperRuleExpressions }

  TACLRipperRuleExpressions = class(TACLFormatStringFactory)
  strict private
    class var FInstance: TACLRipperRuleExpressions;
    class function GetValue(AContext: TObject): string;
  protected
    procedure RegisterMacros; override;
  public
    class destructor Destroy;
    class function Instance: TACLRipperRuleExpressions;
  end;

{ TACLRipperRuleExpressions }

class destructor TACLRipperRuleExpressions.Destroy;
begin
  FreeAndNil(FInstance);
end;

class function TACLRipperRuleExpressions.GetValue(AContext: TObject): string;
begin
  Result := TACLRipperRuleExpressionContext(AContext).Value;
end;

class function TACLRipperRuleExpressions.Instance: TACLRipperRuleExpressions;
begin
  if FInstance = nil then
    CreateInstance(FInstance);
  Result := FInstance;
end;

procedure TACLRipperRuleExpressions.RegisterMacros;
begin
  inherited;
  RegisterMacro('Value', GetValue, CategoryHidden);
end;

{ TACLRipperRule }

constructor TACLRipperRule.Create(ASource: TACLRipperRule);
begin
  FSource := ASource;
end;

destructor TACLRipperRule.Destroy;
begin
  FreeAndNil(FSource);
  inherited;
end;

function TACLRipperRule.Extract(const AData: string): string;
var
  AList: TACLList<string>;
begin
  AList := ExtractEx(AData);
  try
    if AList.Count > 0 then
      Result := AList.List[0]
    else
      Result := EmptyStr;
  finally
    AList.Free;
  end;
end;

function TACLRipperRule.ExtractEx(const AData: string): TACLList<string>;
begin
  Result := TACLList<string>.Create;
  Result.Capacity := 1;
  Result.Add(AData);
  Process(Result)
end;

procedure TACLRipperRule.Process(var AData: TACLList<string>);
var
  ATarget: TACLList<string>;
  I: Integer;
begin
  if FSource <> nil then
    FSource.Process(AData);

  ATarget := TACLList<string>.Create;
  try
    ATarget.Capacity := AData.Count;
    for I := 0 to AData.Count - 1 do
      ProcessCore(ATarget, AData.List[I]);
    acExchangePointers(AData, ATarget);
  finally
    ATarget.Free;
  end;
end;

procedure TACLRipperRule.ProcessCore(const ATarget: TACLList<string>; const ASource: string);
begin
  ATarget.Add(ASource);
end;

{ TACLRipperRuleAimingByTags }

constructor TACLRipperRuleAimingByTags.Create(const AStartTags, AFinishTags: string;
  AOptions: TACLRipperRuleAimingByTagsOptions; ASource: TACLRipperRule);

  procedure SplitTags(const S: string; var ATags: TStringDynArray);
  var
    I: Integer;
  begin
    acExplodeString(S, '|', ATags);
    if ratCaseInsensitive in AOptions then
    begin
      for I := Low(ATags) to High(ATags) do
        ATags[I] := acUpperCase(ATags[I]);
    end;
  end;

begin
  inherited Create(ASource);
  FOptions := AOptions;
  SplitTags(AStartTags, FStartTags);
  SplitTags(AFinishTags, FFinishTags);
end;

procedure TACLRipperRuleAimingByTags.ProcessCore(const ATarget: TACLList<string>; const ASource: string);
var
  I0: Integer;
  L1, L2: Integer;
  P1, P2, PE: Integer;
  US: UnicodeString;
begin
  L1 := Length(FStartTags);
  L2 := Length(FFinishTags);
  if (L1 = 0) or (L2 = 0) then
    Exit;

  if ratCaseInsensitive in FOptions then
    US := acUpperCase(ASource)
  else
    US := ASource;

  P1 := 1;
  repeat
    PE := -1;
    P2 := Length(ASource);

    for I0 := 0 to Max(L1, L2) - 1 do
    begin
      if I0 < L1 then
      begin
        P1 := Find(FStartTags[I0], US, P1, P2, False);
        if P1 = 0 then
          Exit;
        P1 := P1 + Length(FStartTags[I0]);
      end;

      if I0 < L2 then
      begin
        P2 := Find(FFinishTags[I0], US, P1, P2, ratConstrictionMode in FOptions);
        if P2 = 0 then
          Exit;
        if PE < 0 then
          PE := P2;
      end;
    end;
    ATarget.Add(Copy(ASource, P1, P2 - P1));
    P1 := PE;
  until (P1 < 0) or not (ratMultipleTargets in FOptions);
end;

function TACLRipperRuleAimingByTags.Find(const AStrToFind, AStr: string; AStartPos, AEndPos: Integer; AFromEnd: Boolean): Integer;
var
  AIterationCount: Integer;
  AStrScan: PWideChar;
  AStrToFindLength: Integer;
  AStrToFindScan: PWideChar;
begin
  if AStartPos <= 0 then
    Exit(0);
  if AStartPos > AEndPos then
    Exit(0);

  AStrToFindLength := Length(AStrToFind);
  AEndPos := Min(AEndPos, Length(AStr));
  AIterationCount := AEndPos - AStartPos - AStrToFindLength + 1;
  if AIterationCount < 0 then
    Exit(0);

  if AFromEnd then
  begin
    AStrToFindScan := PWideChar(AStrToFind);
    AStartPos := AEndPos - AStrToFindLength;
    AStrScan := PWideChar(AStr) + AStartPos;
    while AIterationCount >= 0 do
    begin
      if CompareMem(AStrToFindScan, AStrScan, AStrToFindLength * SizeOf(WideChar)) then
        Exit(AStartPos);
      Dec(AIterationCount);
      Dec(AStartPos);
      Dec(AStrScan);
    end;
  end
  else
  begin
    AStrToFindScan := PWideChar(AStrToFind);
    AStrScan := PWideChar(AStr) + (AStartPos - 1);
    while AIterationCount >= 0 do
    begin
      if CompareMem(AStrToFindScan, AStrScan, AStrToFindLength * SizeOf(WideChar)) then
        Exit(AStartPos);
      Dec(AIterationCount);
      Inc(AStartPos);
      Inc(AStrScan);
    end;
  end;
  Result := 0;
end;

{ TACLRipperRuleExpression }

constructor TACLRipperRuleExpression.Create(const AExpression: string; ASource: TACLRipperRule);
begin
  inherited Create(ASource);
  FExpression := TACLRipperRuleExpressions.Instance.Compile(AExpression, True);
end;

destructor TACLRipperRuleExpression.Destroy;
begin
  FreeAndNil(FExpression);
  inherited Destroy;
end;

procedure TACLRipperRuleExpression.ProcessCore(const ATarget: TACLList<string>; const ASource: string);
var
  AContext: TACLRipperRuleExpressionContext;
begin
  AContext := TACLRipperRuleExpressionContext.Create;
  try
    AContext.Value := ASource;
    ATarget.Add(FExpression.Evaluate(AContext));
  finally
    AContext.Free;
  end;
end;

{ TACLRipperRuleRemoveHtmlTags }

procedure TACLRipperRuleRemoveHtmlTags.ProcessCore(const ATarget: TACLList<string>; const ASource: string);
var
  ABuffer: TStringBuilder;
  ACount: Integer;
  AData: string;
  AScan: PWideChar;
begin
//    Result := acStringReplace(Result, #13, '');
//    Result := acStringReplace(Result, #10, '');
//    Result := acStringReplace(Result, '<br', #13#10'<br', True);
//
//    repeat
//      P1 := acPos('<', Result);
//      P2 := acPos('>', Result, False, P1);
//      if (P1 > 0) and (P2 > 0) then
//        Delete(Result, P1, P2 - P1 + 1);
//    until P1 = 0;

  AData := TACLXMLHelper.DecodeString(ASource);
  ABuffer := TStringBuilder.Create(Length(AData));
  try
    AScan := PWideChar(AData);
    ACount := Length(AData);
    repeat
      case Ord(AScan^) of
        0:
          Break;

        13, 10:
          begin
            Dec(ACount);
            Inc(AScan);
          end;

        92: // '\'
          if (ACount > 1) and ((AScan + 1)^ = 'n') then // \n
          begin
            ABuffer.AppendLine;
            Dec(ACount, 2);
            Inc(AScan, 2);
          end
          else
          begin
            ABuffer.Append('\');
            Dec(ACount);
            Inc(AScan);
          end;

        60: //'<'
          begin
            Inc(AScan);
            Dec(ACount);
            if acCompareStrings(AScan, 'br', Min(ACount, 2), 2, True) = 0 then
              ABuffer.AppendLine;
            while (ACount > 0) and (Ord(AScan^) <> 62{'>'}) do
            begin
              Inc(AScan);
              Dec(ACount);
            end;
            Inc(AScan);
            Dec(ACount);
          end;
      else
        ABuffer.Append(AScan^);
        Inc(AScan);
        Dec(ACount);
      end;
    until ACount = 0;

    ATarget.Add(acTrim(ABuffer.ToString));
  finally
    ABuffer.Free;
  end;
end;

end.
