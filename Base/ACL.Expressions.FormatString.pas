{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*             Macros Processor              *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2023                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Expressions.FormatString;

{$I ACL.Config.INC}

interface

uses
  System.Math,
  System.SysUtils,
  System.Classes,
  System.Variants,
  System.Generics.Collections,
  // ACL
  ACL.Classes,
  ACL.Classes.StringList,
  ACL.Expressions,
  ACL.Parsers,
  ACL.Utils.Common,
  ACL.Utils.Strings;

type
  TACLFormatStringMacroProc = function (AContext: TObject): string of object;
  TACLFormatStringMacroEvalFunction = class;

  TACLFormatStringEnumMacrosProc = reference to procedure (const S: UnicodeString; AFunc: TACLExpressionFunctionInfo);

  { TACLFormatString }

  TACLFormatString = class(TACLExpression)
  strict private
    FTemplate: string;
  public
    constructor Create(AFactory: TACLCustomExpressionFactory; ARoot: TACLExpressionElement; const ATemplate: string);
    function Compare(AContext1, AContext2: TObject): Integer;
    function Evaluate(AContext: TObject): Variant; override;
    function InvertComparingOrder: Boolean;
    function ToString: string; override;
  end;

  { TACLFormatStringFactory }

  TACLFormatStringFactory = class(TACLCustomExpressionFactory)
  protected const
    ReverseComparingOrderMacro = '!';
  public const
    CategoryChangeCase = 1;
    CategoryConditional = 2;
    CategoryStrings = 3;
    CategoryMath = TACLCustomExpressionFactory.CategoryGeneral;
  strict private
    // Built-in functions
    class function FunctionCaps(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionCaps2(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionCase(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionChar(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionDec(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionFormat(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionIF(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionIFEqual(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionIFGreater(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionIFGreaterOrEqual(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionInc(AContext: TObject; AParams: TACLExpressionElements): Variant; overload;
    class function FunctionIncCore(AContext: TObject; AParams: TACLExpressionElements; ASign: Integer): Variant;
    class function FunctionLength(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionLowerCase(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionRemove(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionReplace(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionReplaceEx(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionStrCopy(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionStrDetransliterate(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionStrLeft(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionStrPos(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionStrRight(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionStrTransliterate(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionStrTrim(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionUpperCase(AContext: TObject; AParams: TACLExpressionElements): Variant;
  protected
    MacroDelimiter: Char;
    MacroDelimiterOnBothSides: Boolean;
    ShowCompileErrors: Boolean;

    function CreateCompiler: TACLExpressionCompiler; override;
    function CreateExpression(const AExpression: string; ARoot: TACLExpressionElement): TACLExpression; override;
    function CreateMacroEvalFunction(const AName: UnicodeString;
      AProc: TACLFormatStringMacroProc; ACategory: Byte): TACLFormatStringMacroEvalFunction; virtual;
    class function TryProcessAsNumber(const AValue: Variant; out ANumber: Integer): Boolean;
    procedure RegisterMacro(const AName: UnicodeString; AProc: TACLFormatStringMacroProc; ACategory: Byte = 0);
    procedure RegisterMacros; virtual;
  public
    constructor Create; override;
    procedure AfterConstruction; override;
    procedure EnumMacros(AProc: TACLFormatStringEnumMacrosProc);
  end;

  { TACLFormatStringCompiler }

  TACLFormatStringCompiler = class(TACLExpressionCompiler)
  strict private const
    acExprTokenReverse = -1;
  strict private
    function GetFactory: TACLFormatStringFactory; inline;
    procedure PopulateOutputBuffer;
  protected
    function CompileCore: TACLExpressionElement; override;
    function FetchToken(var P: PWideChar; var C: Integer; var AToken: TACLParserToken): Boolean; override;
    function ProcessToken: Boolean; override;
  public
    constructor Create(
      const AFactory: TACLCustomExpressionFactory;
      const ADelimiters, AQuotes, ASpaces: UnicodeString); override;
    property Factory: TACLFormatStringFactory read GetFactory;
  end;

  { TACLFormatStringConcatenateFunction }

  TACLFormatStringConcatenateFunction = class(TACLExpressionElement)
  strict private
    FParams: TACLExpressionElements;
  public
    constructor Create; overload;
    constructor Create(AStack: TACLExpressionFastStack<TACLExpressionElement>); overload;
    destructor Destroy; override;
    procedure Optimize; override;
    function Evaluate(AContext: TObject): Variant; override;
    function IsConstant: Boolean; override;
    procedure ToString(ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory); override;
    //# Properties
    property Params: TACLExpressionElements read FParams;
  end;

  { TACLFormatStringFunction }

  TACLFormatStringFunction = class(TACLExpressionElementFunction)
  public
    procedure ToString(ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory); override;
  end;

  { TACLFormatStringMacroEvalFunction }

  TACLFormatStringMacroEvalFunction = class(TACLExpressionFunctionInfo)
  protected
    FMacroProc: TACLFormatStringMacroProc;
    function EvalProc(AContext: TObject; AParams: TACLExpressionElements): Variant; virtual;
  public
    constructor Create(const AName: UnicodeString; AMacroProc: TACLFormatStringMacroProc; ACategory: Byte);
  end;

  { TACLFormatStringReverseMacro }

  TACLFormatStringReverseMacro = class(TACLExpressionElement)
  public
    function Evaluate(AContext: TObject): Variant; override;
    procedure ToString(ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory); override;
  end;

implementation

const
  sErrorClosingTag = 'Syntax Error: macro closing tag is missing';
  sErrorUnknownFunction = 'Syntax Error: Unknown function';

type
  TACLExpressionElementsAccess = class(TACLExpressionElements);

{ TACLFormatString }

constructor TACLFormatString.Create(
  AFactory: TACLCustomExpressionFactory;
  ARoot: TACLExpressionElement; const ATemplate: string);
begin
  inherited Create(AFactory, ARoot);
  FTemplate := ATemplate;
end;

function TACLFormatString.Compare(AContext1, AContext2: TObject): Integer;

  function CompareCore(AElement: TACLExpressionElement): Integer;
  begin
    Result := acLogicalCompare(AElement.Evaluate(AContext1), AElement.Evaluate(AContext2));
  end;

var
  AElement: TACLExpressionElement;
  AReversed: Boolean;
begin
  Result := 0;
  if FRoot = nil then
    Exit;
  if FRoot is TACLFormatStringConcatenateFunction then
  begin
    AReversed := False;
    for var I := 0 to TACLFormatStringConcatenateFunction(FRoot).Params.Count - 1 do
    begin
      AElement := TACLFormatStringConcatenateFunction(FRoot).Params[I];
      if AElement is TACLFormatStringReverseMacro then
        AReversed := True;
      if AElement is TACLFormatStringFunction then
      begin
        Result := CompareCore(AElement);
        if AReversed then
          Result := -Result;
        if Result <> 0 then
          Exit;
        AReversed := False;
      end;
    end;
  end
  else
    Result := CompareCore(FRoot);
end;

function TACLFormatString.Evaluate(AContext: TObject): Variant;
begin
  if FRoot <> nil then
    Result := FRoot.Evaluate(AContext)
  else
    Result := FTemplate;
end;

function TACLFormatString.InvertComparingOrder: Boolean;
var
  AElement: TACLExpressionElement;
  AFunction: TACLFormatStringConcatenateFunction;
  AIndex: Integer;
  AParams: TACLExpressionElementsAccess;
  AReversed: Boolean;
begin
  Result := False;
  if FRoot is TACLFormatStringConcatenateFunction then
  begin
    AIndex := 0;
    AReversed := False;
    AParams := TACLExpressionElementsAccess(TACLFormatStringConcatenateFunction(FRoot).Params);
    while AIndex < AParams.Count do
    begin
      AElement := AParams[AIndex];
      if AElement is TACLFormatStringReverseMacro then
      begin
        AElement.Free;
        AParams.FList.Delete(AIndex);
        AReversed := True;
      end
      else
      begin
        if AElement is TACLFormatStringFunction then
        begin
          if AReversed then
            AReversed := False
          else
          begin
            AParams.FList.Insert(AIndex, TACLFormatStringReverseMacro.Create);
            Inc(AIndex);
          end;
          Result := True;
        end;
        Inc(AIndex);
      end;
    end;
  end
  else
    if FRoot <> nil then
    begin
      AFunction := TACLFormatStringConcatenateFunction.Create;
      TACLExpressionElementsAccess(AFunction.Params).FList.Add(TACLFormatStringReverseMacro.Create);
      TACLExpressionElementsAccess(AFunction.Params).FList.Add(FRoot);
      FRoot := AFunction;
      Result := True;
    end;
end;

function TACLFormatString.ToString: string;
begin
  if FRoot <> nil then
    Result := inherited
  else
    Result := FTemplate;
end;

{ TACLFormatStringFactory }

constructor TACLFormatStringFactory.Create;
begin
  inherited Create;
  ShowCompileErrors := True;
  MacroDelimiter := '%';
end;

procedure TACLFormatStringFactory.AfterConstruction;
begin
  inherited AfterConstruction;
  RegisterMacros;
end;

procedure TACLFormatStringFactory.EnumMacros(AProc: TACLFormatStringEnumMacrosProc);

  function FuncToString(AFunc: TACLExpressionFunctionInfo): UnicodeString;
  begin
    if AFunc.ParamCount = 0 then
      Result := MacroDelimiter + AFunc.ToString + IfThenW(MacroDelimiterOnBothSides, MacroDelimiter)
    else
      Result := MacroDelimiter + AFunc.ToString
  end;

var
  AFunc: TACLExpressionFunctionInfo;
  I: Integer;
  L: TList;
begin
  L := TList.Create;
  try
    for I := 0 to FRegisteredFunctions.Count - 1 do
    begin
      AFunc := FRegisteredFunctions.Items[I];
      if AFunc.Category <> CategoryHidden then
        L.Add(AFunc);
    end;

    L.SortList(
      function (Item1, Item2: Pointer): Integer
      begin
        Result := TACLExpressionFunctionInfo(Item1).Category - TACLExpressionFunctionInfo(Item2).Category;
        if Result = 0 then
          Result := acCompareStrings(TACLExpressionFunctionInfo(Item1).Name, TACLExpressionFunctionInfo(Item2).Name, False);
      end);

    for I := 0 to L.Count - 1 do
      AProc(FuncToString(L[I]), L[I]);
  finally
    L.Free;
  end;
end;

function TACLFormatStringFactory.CreateCompiler: TACLExpressionCompiler;
begin
  Result := TACLFormatStringCompiler.Create(Self,
    acParserDefaultIdentDelimiters + MacroDelimiter,
    acParserDefaultQuotes, acParserDefaultSpaceChars);
end;

function TACLFormatStringFactory.CreateExpression(const AExpression: string; ARoot: TACLExpressionElement): TACLExpression;
begin
  Result := TACLFormatString.Create(Self, ARoot, AExpression);
end;

function TACLFormatStringFactory.CreateMacroEvalFunction(const AName: UnicodeString;
  AProc: TACLFormatStringMacroProc; ACategory: Byte): TACLFormatStringMacroEvalFunction;
begin
  Result := TACLFormatStringMacroEvalFunction.Create(AName, AProc, ACategory);
end;

procedure TACLFormatStringFactory.RegisterMacro(
  const AName: UnicodeString; AProc: TACLFormatStringMacroProc; ACategory: Byte = 0);
begin
  FRegisteredFunctions.Add(CreateMacroEvalFunction(AName, AProc, ACategory));
end;

procedure TACLFormatStringFactory.RegisterMacros;
begin
  RegisterFunction('Caps', FunctionCaps, 1, True, CategoryChangeCase);
  RegisterFunction('Caps2', FunctionCaps2, 1, True, CategoryChangeCase);
  RegisterFunction('Low', FunctionLowerCase, 1, True, CategoryChangeCase);
  RegisterFunction('Up', FunctionUpperCase, 1, True, CategoryChangeCase);

  RegisterFunction('Case', FunctionCase, -1, True, CategoryConditional);
  RegisterFunction('IF', FunctionIF, 3, True, CategoryConditional);
  RegisterFunction('IFEqual', FunctionIFEqual, 4, True, CategoryConditional);
  RegisterFunction('IFGreater', FunctionIFGreater, 4, True, CategoryConditional);
  RegisterFunction('IFGreaterOrEqual', FunctionIFGreaterOrEqual, 4, True, CategoryConditional);

  RegisterFunction('Char', FunctionChar, 1, True, CategoryStrings);
  RegisterFunction('Format', FunctionFormat, 2, True, CategoryStrings);
  RegisterFunction('Length', FunctionLength, 1, True, CategoryStrings);
  RegisterFunction('Remove', FunctionRemove, -1, True, CategoryStrings);
  RegisterFunction('Replace', FunctionReplace, 3, True, CategoryStrings);
  RegisterFunction('ReplaceEx', FunctionReplaceEx, -1, True, CategoryStrings);
  RegisterFunction('StrCopy', FunctionStrCopy, 3, True, CategoryStrings);
  RegisterFunction('StrLeft', FunctionStrLeft, 2, True, CategoryStrings);
  RegisterFunction('StrPos', FunctionStrPos, 2, True, CategoryStrings);
  RegisterFunction('StrRight', FunctionStrRight, 2, True, CategoryStrings);
  RegisterFunction('StrTrim', FunctionStrTrim, 1, True, CategoryStrings);
  RegisterFunction('Detransliterate', FunctionStrDetransliterate, 1, True, CategoryStrings);
  RegisterFunction('Transliterate', FunctionStrTransliterate, 1, True, CategoryStrings);

  RegisterFunction('Dec', FunctionDec, 2, True, CategoryMath);
  RegisterFunction('Inc', FunctionInc, 2, True, CategoryMath);
end;

class function TACLFormatStringFactory.TryProcessAsNumber(const AValue: Variant; out ANumber: Integer): Boolean;
begin
  if VarIsNumeric(AValue) then
  begin
    ANumber := AValue;
    Exit(True);
  end;
  Result := TryStrToInt(acTrim(AValue), ANumber);
end;

class function TACLFormatStringFactory.FunctionCaps(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := acAllWordsWithCaptialLetter(AParams[0].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionCaps2(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := acAllWordsWithCaptialLetter(AParams[0].Evaluate(AContext), True);
end;

class function TACLFormatStringFactory.FunctionCase(AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  ACompareResult: Boolean;
  I: Integer;
begin
  Result := '';
  for I := 0 to AParams.Count - 1 do
  begin
    Result := AParams[I].Evaluate(AContext);
    if VarIsStr(Result) then
      ACompareResult := Result <> ''
    else
      ACompareResult := Result <> 0;

    if ACompareResult then
      Exit;
  end;
end;

class function TACLFormatStringFactory.FunctionChar(AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  AValue: Integer;
begin
  Result := AParams[0].Evaluate(AContext);
  if TryProcessAsNumber(Result, AValue) then
    Result := WideChar(AValue);
end;

class function TACLFormatStringFactory.FunctionDec(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := FunctionIncCore(AContext, AParams, -1);
end;

class function TACLFormatStringFactory.FunctionFormat(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  try
    Result := FormatFloat(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext));
  except
    Result := AParams[1].Evaluate(AContext);
  end;
end;

class function TACLFormatStringFactory.FunctionIF(AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  ACompareResult: Boolean;
begin
  Result := AParams[0].Evaluate(AContext);
  if VarIsStr(Result) then
    ACompareResult := Result <> ''
  else
    ACompareResult := Result <> 0;

  if ACompareResult then
    Result := AParams[1].Evaluate(AContext)
  else
    Result := AParams[2].Evaluate(AContext);
end;

class function TACLFormatStringFactory.FunctionIFEqual(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  if SmartCompare(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext)) = vrEqual then
    Result := AParams[2].Evaluate(AContext)
  else
    Result := AParams[3].Evaluate(AContext);
end;

class function TACLFormatStringFactory.FunctionIFGreater(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  if SmartCompare(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext)) = vrGreaterThan then
    Result := AParams[2].Evaluate(AContext)
  else
    Result := AParams[3].Evaluate(AContext);
end;

class function TACLFormatStringFactory.FunctionIFGreaterOrEqual(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  if SmartCompare(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext)) in [vrEqual, vrGreaterThan] then
    Result := AParams[2].Evaluate(AContext)
  else
    Result := AParams[3].Evaluate(AContext);
end;

class function TACLFormatStringFactory.FunctionInc(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := FunctionIncCore(AContext, AParams, 1);
end;

class function TACLFormatStringFactory.FunctionIncCore(AContext: TObject; AParams: TACLExpressionElements; ASign: Integer): Variant;
var
  ANumber1: Integer;
  ANumber2: Integer;
begin
  if not TryProcessAsNumber(AParams[0].Evaluate(AContext), ANumber1) then
    ANumber1 := 0;
  if not TryProcessAsNumber(AParams[1].Evaluate(AContext), ANumber2) then
    ANumber2 := 0;
  Result := ANumber1 + ASign * ANumber2
end;

class function TACLFormatStringFactory.FunctionLength(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Length(AParams[0].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionLowerCase(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := acLowerCase(AParams[0].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionRemove(AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  ASource: UnicodeString;
begin
  if AParams.Count = 0 then
    Exit(acEmptyStr);
  if AParams.Count = 1 then
    Exit(AParams[0].Evaluate(AContext));

  ASource := AParams[0].Evaluate(AContext);
  for var I := 1 to AParams.Count - 1 do
    ASource := acStringReplace(ASource, AParams[I].Evaluate(AContext), '');
  Result := ASource;
end;

class function TACLFormatStringFactory.FunctionReplace(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := acStringReplace(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext), AParams[2].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionReplaceEx(AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  AIndex: Integer;
  ACount: Integer;
  ASource: UnicodeString;
begin
  ACount := AParams.Count;
  if ACount = 0 then
    Exit(acEmptyStr);
  if ACount = 1 then
    Exit(AParams[0].Evaluate(AContext));
  if ACount = 2 then
    Exit(acStringReplace(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext), acEmptyStr));
  if ACount = 3 then
    Exit(FunctionReplace(AContext, AParams));

  AIndex  := 1;
  ASource := AParams[0].Evaluate(AContext);
  while AIndex + 1 < ACount do
  begin
    ASource := acStringReplace(ASource, AParams[AIndex].Evaluate(AContext), AParams[AIndex + 1].Evaluate(AContext));
    Inc(AIndex, 2);
  end;

  Result := ASource;
end;

class function TACLFormatStringFactory.FunctionStrCopy(AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  ANumber1: Integer;
  ANumber2: Integer;
begin
  Result := AParams[0].Evaluate(AContext);
  if TryProcessAsNumber(AParams[1].Evaluate(AContext), ANumber1) and TryProcessAsNumber(AParams[2].Evaluate(AContext), ANumber2) then
    Result := Copy(Result, ANumber1, ANumber2);
end;

class function TACLFormatStringFactory.FunctionStrDetransliterate(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := TACLTranslit.Decode(AParams[0].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionStrPos(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Pos(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionStrLeft(AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  P: Integer;
  S: string;
  V: Variant;
begin
  S := AParams[0].Evaluate(AContext);
  V := AParams[1].Evaluate(AContext);

  if not TryProcessAsNumber(V, P) then
  begin
    P := Pos(V, S);
    if P = 0 then
      Exit(S);
    Dec(P);
  end;

  Result := Copy(S, 1, P);
end;

class function TACLFormatStringFactory.FunctionStrRight(AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  C: Integer;
  S: string;
  T: string;
  V: Variant;
begin
  S := AParams[0].Evaluate(AContext);
  V := AParams[1].Evaluate(AContext);

  if TryProcessAsNumber(V, C) then
    Result := Copy(S, Length(S) - C + 1, MaxInt)
  else
  begin
    T := V;
    C := Pos(T, S);
    if C = 0 then
      Result := S
    else
      Result := Copy(S, C + Length(T), MaxInt);
  end;
end;

class function TACLFormatStringFactory.FunctionStrTransliterate(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := TACLTranslit.Encode(AParams[0].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionStrTrim(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Trim(AParams[0].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionUpperCase(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := acUpperCase(AParams[0].Evaluate(AContext));
end;

{ TACLFormatStringCompiler }

constructor TACLFormatStringCompiler.Create;
begin
  inherited;
  ClassFunction := TACLFormatStringFunction;
  QuotedTextAsSingleToken := False;
  SkipSpaces := False;
end;

function TACLFormatStringCompiler.CompileCore: TACLExpressionElement;
begin
  PopulateOutputBuffer;
  if OutputBuffer.Count > 1 then
    Result := TACLFormatStringConcatenateFunction.Create(OutputBuffer)
  else
    if OutputBuffer.Count > 0 then
      Result := OutputBuffer.Pop
    else
      Result := nil;
end;

function TACLFormatStringCompiler.FetchToken(var P: PWideChar; var C: Integer; var AToken: TACLParserToken): Boolean;
var
  AEvalFunction: TACLExpressionFunctionInfo;
  D: Integer;
  K: PWideChar;
  T: TACLParserToken;
begin
  Result := (C > 0) and inherited FetchToken(P, C, AToken);
  if Result and (AToken.TokenType = acTokenDelimiter) and (Ord(AToken.Data^) = Ord(Factory.MacroDelimiter)) then
  begin
    K := P;
    D := C;
    T.Reset;
    if inherited FetchToken(K, D, T) then
    begin
      P := K;
      C := D;
      if T.Compare(TACLFormatStringFactory.ReverseComparingOrderMacro, False) then
      begin
        AToken.TokenType := acExprTokenReverse;
        Exit;
      end;

      if RegisteredFunctions.Find(T.Data, T.DataLength, AEvalFunction) then
      begin
        AToken.Context := AEvalFunction;
        AToken.Data := T.Data;
        AToken.DataLength := T.DataLength;
        AToken.TokenType := acExprTokenFunction;
      end
      else
        Error(sErrorUnknownFunction);

      if Factory.MacroDelimiterOnBothSides then
      begin
        if (C = 0) or (P^ <> '(') and (P^ <> Factory.MacroDelimiter) then
          Error(sErrorClosingTag);
        if P^ = Factory.MacroDelimiter then
          MoveToNext(P, C);
      end;
    end;
  end;
end;

procedure TACLFormatStringCompiler.PopulateOutputBuffer;
begin
  try
    PrevSolidToken := ecsttNone;
    while GetToken(Token) do
    begin
      if not ProcessToken then
      begin
        OutputBuffer.Push(TACLExpressionElementConstant.Create(Token.ToString));
        PrevSolidToken := ecsttOperand;
      end;
    end;
    while OperatorStack.Count > 0 do
      OutputOperator(OperatorStack.Pop);
  except
    if Factory.ShowCompileErrors then
      raise;
  end;
end;

function TACLFormatStringCompiler.ProcessToken: Boolean;
begin
  if Token.TokenType = acTokenDelimiter then
    Result := PushConstant(Token.ToString)
  else if Token.TokenType = acExprTokenReverse then
    Result := PushOperand(TACLFormatStringReverseMacro.Create)
  else
    Result := inherited;
end;

function TACLFormatStringCompiler.GetFactory: TACLFormatStringFactory;
begin
  Result := TACLFormatStringFactory(inherited Factory);
end;

{ TACLFormatStringConcatenateFunction }

constructor TACLFormatStringConcatenateFunction.Create;
begin
  inherited Create;
  FParams := TACLExpressionElements.Create;
end;

constructor TACLFormatStringConcatenateFunction.Create(AStack: TACLExpressionFastStack<TACLExpressionElement>);
begin
  Create;
  TACLExpressionElementsAccess(Params).AddFromStack(AStack, AStack.Count);
end;

destructor TACLFormatStringConcatenateFunction.Destroy;
begin
  FreeAndNil(FParams);
  inherited Destroy;
end;

procedure TACLFormatStringConcatenateFunction.Optimize;
var
  ABuffer: TACLStringBuilder;
  AParams: TACLExpressionElementsAccess;
  I, J: Integer;
begin
  AParams := TACLExpressionElementsAccess(Params);
  AParams.Optimize;

  I := 0;
  while (I < Params.Count) do
  begin
    if AParams[I].IsConstant then
    begin
      J := I + 1;
      while (J < AParams.Count) and AParams[J].IsConstant do
        Inc(J);
      Dec(J);
      if I < J then
      begin
        ABuffer := TACLStringBuilder.Get(256);
        try
          while I <= J do
          begin
            ABuffer.Append(UnicodeString(AParams[I].Evaluate(nil)));
            TObject(AParams.FList[I]).Free;
            AParams.FList.Delete(I);
            Dec(J);
          end;
          AParams.FList.Insert(I, TACLExpressionElementConstant.Create(ABuffer.ToString));
        finally
          ABuffer.Release;
        end;
      end;
    end;
    Inc(I);
  end;
end;

function TACLFormatStringConcatenateFunction.Evaluate(AContext: TObject): Variant;
var
  ABuffer: TACLStringBuilder;
begin
  if FParams.Count = 0 then
    Exit('');
  if FParams.Count = 1 then
    Exit(FParams[0].Evaluate(AContext));

  ABuffer := TACLStringBuilder.Get(256);
  try
    for var I := 0 to FParams.Count - 1 do
      ABuffer.Append(UnicodeString(FParams[I].Evaluate(AContext)));
    Result := ABuffer.ToString;
  finally
    ABuffer.Release;
  end;
end;

function TACLFormatStringConcatenateFunction.IsConstant: Boolean;
begin
  Result := Params.IsConstant;
end;

procedure TACLFormatStringConcatenateFunction.ToString(
  ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory);
begin
  FParams.ToString(ABuffer, AFactory, '');
end;

{ TACLFormatStringFunction }

procedure TACLFormatStringFunction.ToString(ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory);
var
  AFormatStringFactory: TACLFormatStringFactory absolute AFactory;
begin
  ABuffer.Append(AFormatStringFactory.MacroDelimiter);
  inherited;
  if AFormatStringFactory.MacroDelimiterOnBothSides and (Params.Count = 0) then
    ABuffer.Append(AFormatStringFactory.MacroDelimiter);
end;

{ TACLFormatStringMacroEvalFunction }

constructor TACLFormatStringMacroEvalFunction.Create(
  const AName: UnicodeString; AMacroProc: TACLFormatStringMacroProc; ACategory: Byte);
begin
  inherited Create(AName, 0, False, EvalProc, ACategory);
  FMacroProc := AMacroProc;
end;

function TACLFormatStringMacroEvalFunction.EvalProc(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := FMacroProc(AContext);
end;

{ TACLFormatStringReverseMacro }

function TACLFormatStringReverseMacro.Evaluate(AContext: TObject): Variant;
begin
  Result := EmptyStr;
end;

procedure TACLFormatStringReverseMacro.ToString(
  ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory);
var
  AFormatStringFactory: TACLFormatStringFactory absolute AFactory;
begin
  ABuffer.Append(AFormatStringFactory.MacroDelimiter);
  ABuffer.Append(AFormatStringFactory.ReverseComparingOrderMacro);
end;

end.
