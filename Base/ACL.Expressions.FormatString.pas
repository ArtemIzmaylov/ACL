////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Components Library aka ACL
//             v7.0
//
//  Purpose:   Macros-based expressions
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.Expressions.FormatString;

{$I ACL.Config.inc}

interface

uses
  {System.}Math,
  {System.}Classes,
  {System.}StrUtils,
  {System.}SysUtils,
  {System.}Variants,
  // ACL
  ACL.Classes.Collections,
  ACL.Expressions,
  ACL.Parsers,
  ACL.Utils.Common,
  ACL.Utils.Strings;

type
  TACLFormatStringMacroProc = function (AContext: TObject): string of object;
  TACLFormatStringMacroEvalFunction = class;

  TACLFormatStringEnumMacrosProc = reference to procedure (const S: string; AFunc: TACLExpressionFunctionInfo);

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
    class function FunctionStrPart(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionStrPos(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionStrRight(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionStrTransliterate(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionStrTrim(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionStrTrimDiacritic(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionUpperCase(AContext: TObject; AParams: TACLExpressionElements): Variant;
  protected
    MacroDelimiter: Char;
    MacroDelimiterOnBothSides: Boolean;
    ShowCompileErrors: Boolean;

    function CreateCompiler: TACLExpressionCompiler; override;
    function CreateExpression(const AExpression: string; ARoot: TACLExpressionElement): TACLExpression; override;
    function CreateMacroEvalFunction(const AName: string;
      AProc: TACLFormatStringMacroProc; ACategory: Byte): TACLFormatStringMacroEvalFunction; virtual;
    class function TryProcessAsNumber(const AValue: Variant; out ANumber: Integer): Boolean;
    procedure RegisterMacro(const AName: string; AProc: TACLFormatStringMacroProc; ACategory: Byte = 0);
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
    function FetchToken(var P: PChar; var C: Integer; var AToken: TACLParserToken): Boolean; override;
    function ProcessToken: Boolean; override;
  public
    constructor Create(
      const AFactory: TACLCustomExpressionFactory;
      const ADelimiters, AQuotes, ASpaces: string); override;
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
    function Compare(AContext1, AContext2: TObject): Integer; override;
    function Evaluate(AContext: TObject): Variant; override;
    function InvertComparingOrder: Boolean;
    function IsConstant: Boolean; override;
    procedure Optimize; override;
    procedure ToString(ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory); override;
    // Properties
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
    constructor Create(const AName: string; AMacroProc: TACLFormatStringMacroProc; ACategory: Byte);
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
begin
  if FRoot <> nil then
    Result := FRoot.Compare(AContext1, AContext2)
  else
    Result := 0;
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
  LFunction: TACLFormatStringConcatenateFunction;
begin
  Result := False;
  if FRoot = nil then
    Exit;
  if FRoot is TACLFormatStringConcatenateFunction then
    Result := TACLFormatStringConcatenateFunction(FRoot).InvertComparingOrder
  else
  begin
    LFunction := TACLFormatStringConcatenateFunction.Create;
    LFunction.Params.Add(TACLFormatStringReverseMacro.Create);
    LFunction.Params.Add(FRoot);
    FRoot := LFunction;
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

  function FuncToString(AFunc: TACLExpressionFunctionInfo): string;
  begin
    if AFunc.ParamCount = 0 then
      Result := MacroDelimiter + AFunc.ToString + IfThenW(MacroDelimiterOnBothSides, MacroDelimiter)
    else
      Result := MacroDelimiter + AFunc.ToString
  end;

var
  LFunc: TACLExpressionFunctionInfo;
  LTemp: TACLListOf<TACLExpressionFunctionInfo>;
  I: Integer;
begin
  LTemp := TACLListOf<TACLExpressionFunctionInfo>.Create;
  try
    LTemp.Capacity := FRegisteredFunctions.Count;
    for I := 0 to FRegisteredFunctions.Count - 1 do
    begin
      LFunc := FRegisteredFunctions.Items[I];
      if LFunc.Category <> CategoryHidden then
        LTemp.Add(LFunc);
    end;

    LTemp.Sort(
      function (const Item1, Item2: TACLExpressionFunctionInfo): Integer
      begin
        Result := Item1.Category - Item2.Category;
        if Result = 0 then
          Result := acCompareStrings(Item1.Name, Item2.Name, False);
      end);

    for I := 0 to LTemp.Count - 1 do
      AProc(FuncToString(LTemp[I]), LTemp[I]);
  finally
    LTemp.Free;
  end;
end;

function TACLFormatStringFactory.CreateCompiler: TACLExpressionCompiler;
begin
  Result := TACLFormatStringCompiler.Create(Self,
    acParserDefaultIdentDelimiters + MacroDelimiter,
    acParserDefaultQuotes, acParserDefaultSpaceChars);
end;

function TACLFormatStringFactory.CreateExpression(
  const AExpression: string; ARoot: TACLExpressionElement): TACLExpression;
begin
  Result := TACLFormatString.Create(Self, ARoot, AExpression);
end;

function TACLFormatStringFactory.CreateMacroEvalFunction(const AName: string;
  AProc: TACLFormatStringMacroProc; ACategory: Byte): TACLFormatStringMacroEvalFunction;
begin
  Result := TACLFormatStringMacroEvalFunction.Create(AName, AProc, ACategory);
end;

procedure TACLFormatStringFactory.RegisterMacro(
  const AName: string; AProc: TACLFormatStringMacroProc; ACategory: Byte = 0);
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
  RegisterFunction('StrPart', FunctionStrPart, 3, True, CategoryStrings);
  RegisterFunction('StrPos', FunctionStrPos, 2, True, CategoryStrings);
  RegisterFunction('StrRight', FunctionStrRight, 2, True, CategoryStrings);
  RegisterFunction('StrTrim', FunctionStrTrim, 1, True, CategoryStrings);
  RegisterFunction('StrTrimDiacritic', FunctionStrTrimDiacritic, 1, True, CategoryStrings);
  RegisterFunction('Detransliterate', FunctionStrDetransliterate, 1, True, CategoryStrings);
  RegisterFunction('Transliterate', FunctionStrTransliterate, 1, True, CategoryStrings);

  RegisterFunction('Dec', FunctionDec, 2, True, CategoryMath);
  RegisterFunction('Inc', FunctionInc, 2, True, CategoryMath);
end;

class function TACLFormatStringFactory.TryProcessAsNumber(
  const AValue: Variant; out ANumber: Integer): Boolean;
begin
  if VarIsNumeric(AValue) then
  begin
    ANumber := AValue;
    Exit(True);
  end;
  Result := TryStrToInt(acTrim(AValue), ANumber);
end;

class function TACLFormatStringFactory.FunctionCaps(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := acAllWordsWithCaptialLetter(AParams[0].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionCaps2(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := acAllWordsWithCaptialLetter(AParams[0].Evaluate(AContext), True);
end;

class function TACLFormatStringFactory.FunctionCase(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
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

class function TACLFormatStringFactory.FunctionChar(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  AValue: Integer;
begin
  Result := AParams[0].Evaluate(AContext);
  if TryProcessAsNumber(Result, AValue) then
    Result := Char(AValue);
end;

class function TACLFormatStringFactory.FunctionDec(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := FunctionIncCore(AContext, AParams, -1);
end;

class function TACLFormatStringFactory.FunctionFormat(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  try
    Result := FormatFloat(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext));
  except
    Result := AParams[1].Evaluate(AContext);
  end;
end;

class function TACLFormatStringFactory.FunctionIF(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
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

class function TACLFormatStringFactory.FunctionIFEqual(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  if SmartCompare(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext)) = vrEqual then
    Result := AParams[2].Evaluate(AContext)
  else
    Result := AParams[3].Evaluate(AContext);
end;

class function TACLFormatStringFactory.FunctionIFGreater(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  if SmartCompare(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext)) = vrGreaterThan then
    Result := AParams[2].Evaluate(AContext)
  else
    Result := AParams[3].Evaluate(AContext);
end;

class function TACLFormatStringFactory.FunctionIFGreaterOrEqual(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  if SmartCompare(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext)) in [vrEqual, vrGreaterThan] then
    Result := AParams[2].Evaluate(AContext)
  else
    Result := AParams[3].Evaluate(AContext);
end;

class function TACLFormatStringFactory.FunctionInc(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := FunctionIncCore(AContext, AParams, 1);
end;

class function TACLFormatStringFactory.FunctionIncCore(
  AContext: TObject; AParams: TACLExpressionElements; ASign: Integer): Variant;
var
  LNumber1: Integer;
  LNumber2: Integer;
begin
  if not TryProcessAsNumber(AParams[0].Evaluate(AContext), LNumber1) then
    LNumber1 := 0;
  if not TryProcessAsNumber(AParams[1].Evaluate(AContext), LNumber2) then
    LNumber2 := 0;
  Result := LNumber1 + ASign * LNumber2
end;

class function TACLFormatStringFactory.FunctionLength(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Length(AParams[0].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionLowerCase(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := acLowerCase(AParams[0].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionRemove(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  ASource: string;
  I: Integer;
begin
  if AParams.Count = 0 then
    Exit(acEmptyStr);
  if AParams.Count = 1 then
    Exit(AParams[0].Evaluate(AContext));

  ASource := AParams[0].Evaluate(AContext);
  for I := 1 to AParams.Count - 1 do
    ASource := acStringReplace(ASource, AParams[I].Evaluate(AContext), '');
  Result := ASource;
end;

class function TACLFormatStringFactory.FunctionReplace(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := acStringReplace(
    AParams[0].Evaluate(AContext),
    AParams[1].Evaluate(AContext),
    AParams[2].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionReplaceEx(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  AIndex: Integer;
  ACount: Integer;
  ASource: string;
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
    ASource := acStringReplace(ASource,
      AParams[AIndex].Evaluate(AContext),
      AParams[AIndex + 1].Evaluate(AContext));
    Inc(AIndex, 2);
  end;

  Result := ASource;
end;

class function TACLFormatStringFactory.FunctionStrCopy(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  LNumber1: Integer;
  LNumber2: Integer;
begin
  Result := AParams[0].Evaluate(AContext);
  if TryProcessAsNumber(AParams[1].Evaluate(AContext), LNumber1) and
     TryProcessAsNumber(AParams[2].Evaluate(AContext), LNumber2)
  then
    if LNumber2 < 0 then
      Result := Copy(Result, LNumber1)
    else
      Result := Copy(Result, LNumber1, LNumber2);
end;

class function TACLFormatStringFactory.FunctionStrDetransliterate(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := TACLTranslit.Decode(AParams[0].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionStrPart(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  LDelimiter: string;
  LPart: Integer;
  LParts: TArray<string>;
  LString: string;
begin
  Result := AParams[0].Evaluate(AContext);

  LString := VarToStr(Result);
  LDelimiter := VarToStr(AParams[1].Evaluate(AContext));
  if LString.Contains(LDelimiter) then
  begin
    if TryProcessAsNumber(AParams[2].Evaluate(AContext), LPart) then
      LPart := Max(LPart - 1, 0) // 1-based to 0-based
    else
      LPart := 0;

    LParts := LString.Split([LDelimiter]);
    if InRange(LPart, Low(LParts), High(LParts)) then
      Result := LParts[LPart]
    else
      Result := '';
  end;
end;

class function TACLFormatStringFactory.FunctionStrPos(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Pos(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionStrLeft(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
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

class function TACLFormatStringFactory.FunctionStrRight(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
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

class function TACLFormatStringFactory.FunctionStrTransliterate(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := TACLTranslit.Encode(AParams[0].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionStrTrim(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Trim(AParams[0].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionStrTrimDiacritic(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := acRemoveDiacritic(AParams[0].Evaluate(AContext));
end;

class function TACLFormatStringFactory.FunctionUpperCase(
  AContext: TObject; AParams: TACLExpressionElements): Variant;
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

function TACLFormatStringCompiler.FetchToken(var P: PChar; var C: Integer; var AToken: TACLParserToken): Boolean;
var
  AEvalFunction: TACLExpressionFunctionInfo;
  D: Integer;
  K: PChar;
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
        PushConstant(Token.ToString);
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
    Exit(PushConstant(Token.ToString));
  if Token.TokenType = acExprTokenReverse then
    Exit(PushOperand(TACLFormatStringReverseMacro.Create));
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
  Params.AddFromStack(AStack, AStack.Count);
end;

destructor TACLFormatStringConcatenateFunction.Destroy;
begin
  FreeAndNil(FParams);
  inherited Destroy;
end;

function TACLFormatStringConcatenateFunction.Compare(AContext1, AContext2: TObject): Integer;
var
  I: Integer;
  LElement: TACLExpressionElement;
  LReverse: Boolean;
begin
  LReverse := False;
  for I := 0 to FParams.Count - 1 do
  begin
    LElement := FParams[I];
    if LElement is TACLFormatStringReverseMacro then
      LReverse := True;
    if LElement is TACLFormatStringFunction then
    begin
      Result := LElement.Compare(AContext1, AContext2);
      if LReverse then
        Result := -Result;
      if Result <> 0 then
        Exit;
      LReverse := False;
    end;
  end;
  Result := 0;
end;

function TACLFormatStringConcatenateFunction.Evaluate(AContext: TObject): Variant;
var
  LBuffer: TACLStringBuilder;
  I: Integer;
begin
  if FParams.Count = 0 then
    Exit('');
  if FParams.Count = 1 then
    Exit(FParams[0].Evaluate(AContext));

  LBuffer := TACLStringBuilder.Get(256);
  try
    for I := 0 to FParams.Count - 1 do
      LBuffer.Append(VarToStr(Params[I].Evaluate(AContext)));
    Result := LBuffer.ToString;
  finally
    LBuffer.Release;
  end;
end;

function TACLFormatStringConcatenateFunction.InvertComparingOrder: Boolean;
var
  LElement: TACLExpressionElement;
  LIndex: Integer;
  LParams: TACLExpressionElementsAccess;
  LReversed: Boolean;
  LValue: Variant;
begin
  Result := False;
  LIndex := 0;
  LReversed := False;
  LParams := TACLExpressionElementsAccess(Params);
  while LIndex < LParams.Count do
  begin
    LElement := LParams[LIndex];
    if LElement is TACLFormatStringReverseMacro then
    begin
      LElement.Free;
      LParams.FList.Delete(LIndex);
      LReversed := True;
    end
    else

    if LReversed and (LElement is TACLExpressionElementConstant) then
    begin
      LValue := LElement.Evaluate(nil);
      if VarIsStr(LValue) and (acTrim(LValue) = '') then
      begin
        LElement.Free;
        LParams.FList.Delete(LIndex);
      end
      else
        Inc(LIndex);
    end
    else
    begin
      if LElement is TACLFormatStringFunction then
      begin
        if LReversed then
          LReversed := False
        else
        begin
          LParams.FList.Insert(LIndex, TACLFormatStringReverseMacro.Create);
          Inc(LIndex);
        end;
        Result := True;
      end;
      Inc(LIndex);
    end;
  end;
end;

function TACLFormatStringConcatenateFunction.IsConstant: Boolean;
begin
  Result := Params.IsConstant;
end;

procedure TACLFormatStringConcatenateFunction.Optimize;
var
  I, J: Integer;
  LBuffer: TACLStringBuilder;
  LElement: TACLExpressionElement;
  LParams: TACLExpressionElementsAccess;
begin
  I := 0;
  LParams := TACLExpressionElementsAccess(Params);
  LParams.Optimize;
  while I < LParams.Count do
  begin
    if LParams[I].IsConstant then
    begin
      J := I + 1;
      while (J < LParams.Count) and LParams[J].IsConstant do
        Inc(J);
      Dec(J);
      if I < J then
      begin
        LBuffer := TACLStringBuilder.Get(256);
        try
          while I <= J do
          begin
            LElement := LParams.FList.List[I];
            LBuffer.Append(VarToStr(LElement.Evaluate(nil)));
            LParams.FList.Delete(I);
            LElement.Free;
            Dec(J);
          end;
          LParams.FList.Insert(I, TACLExpressionElementConstant.Create(LBuffer.ToString));
        finally
          LBuffer.Release;
        end;
      end;
    end;
    Inc(I);
  end;
end;

procedure TACLFormatStringConcatenateFunction.ToString(
  ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory);
var
  I: Integer;
begin
  for I := 0 to Params.Count - 1 do
    Params[I].ToString(ABuffer, AFactory);
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
  const AName: string; AMacroProc: TACLFormatStringMacroProc; ACategory: Byte);
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
