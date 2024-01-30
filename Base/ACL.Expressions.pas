{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*       Custom Expressions Processor        *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Expressions;

{$I ACL.Config.inc} //FPC:OK

// Refer to the followed links for more information:
// + http://ru.wikipedia.org/wiki/Обратная_польская_запись
// + http://msdn.microsoft.com/ru-ru/library/ms139741.aspx

interface

uses
  // System
  {System.}Classes,
  {System.}Generics.Collections,
  {System.}Math,
  {System.}SysUtils,
  {System.}Variants,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Parsers,
  ACL.Utils.Strings;

const
  acExprTokenFunction      = acTokenMax + 1;
  acExprTokenOperator      = acExprTokenFunction + 1;
  acExprTokenConstantFloat = acExprTokenOperator + 1;
  acExprTokenConstantInt   = acExprTokenConstantFloat + 1;
  acExprTokenMax           = acExprTokenConstantInt;

const
  sErrorCursorInfo = 'Token: "%s", Scan Cursor: "%s"';

  sErrorFunctionAlreadyRegistered = 'The "%s" function with %d arguments already registered';
  sErrorFunctionNotFound = 'The "%s" function was not found';
  sErrorInvalidExpression = 'Syntax Error: expression is invalid';
  sErrorNotCompiled = 'Expression was not compiled';
  sErrorOperatorArguments = 'Operator must have 1 or 2 arguments';
  sErrorStackIsEmpty = 'Stack is empty';
  sErrorTooManyArguments = 'Syntax Error: function "%s" has too many arguments';
  sErrorTooSmallArguments = 'Syntax Error: function "%s" has too small arguments';
  sErrorUnequalBrackets = 'Syntax Error: unequal brackets';
  sErrorUnexpectedToken = 'Syntax Error: unexpected token';

type
  EACLExpression = class(Exception);
  EACLExpressionCompiler = class(Exception);
  TACLExpressionElements = class;

  TACLCustomExpressionFactory = class;
  TACLExpressionCompiler = class;

  TACLExpressionEvalProc = function (AContext: TObject; AParams: TACLExpressionElements): Variant of object;

  { TACLExpressionFastStack }

  TACLExpressionFastStack<T: class> = class
  strict private
    FBuffer: array of T;
    FCapacity: Integer;
    FCount: Integer;
    FOwnObjects: Boolean;

    procedure SetCapacity(ACapacity: Integer);
  public
    constructor Create(AOwnObjects: Boolean); virtual;
    destructor Destroy; override;
    procedure FreeObjects;
    function Peek: T;
    function Pop: T;
    function Push(AObject: T): Integer;
    //# Properties
    property Count: Integer read FCount;
  end;

  { TACLExpressionFunctionInfo }

  TACLExpressionFunctionInfo = class
  strict private
    FCategory: Byte;
    FDependedFromParametersOnly: Boolean;
    FName: string;
    FParamCount: Integer;
    FProc: TACLExpressionEvalProc;
  public
    constructor Create(const AName: string; AParamCount: Integer;
      ADependedFromParametersOnly: Boolean; AProc: TACLExpressionEvalProc; ACategory: Byte);
    function ToString: string; override;
    //# Properties
    property Category: Byte read FCategory;
    property DependedFromParametersOnly: Boolean read FDependedFromParametersOnly;
    property Name: string read FName;
    property ParamCount: Integer read FParamCount; // -1 = Variable number of parameters
    property Proc: TACLExpressionEvalProc read FProc;
  end;

  { TACLExpressionFunctionInfoList }

  TACLExpressionFunctionInfoList = class(TACLObjectList<TACLExpressionFunctionInfo>)
  strict private
    function Compare(const S: string; B: PChar; L: Integer): Boolean; inline;
  public
    function Find(const AName: PChar; ANameLength, AParamCount: Integer;
      out AFunction: TACLExpressionFunctionInfo): Boolean; overload; virtual;
    function Find(const AName: PChar; ANameLength: Integer;
      out AFunction: TACLExpressionFunctionInfo): Boolean; overload; virtual;
    function Find(const AName: string; AParamCount: Integer;
      out AFunction: TACLExpressionFunctionInfo): Boolean; overload; inline;
    function Find(const AName: string;
      out AFunction: TACLExpressionFunctionInfo): Boolean; overload; inline;
  end;

  { TACLExpressionOperatorInfo }

  TACLExpressionOperatorInfoAssociativity = (eoaLeftToRight, eoaRightToLeft);

  TACLExpressionOperatorInfo = class(TACLExpressionFunctionInfo)
  strict private
    FAssociativity: TACLExpressionOperatorInfoAssociativity;
    FPriority: Integer;
  public
    constructor Create(const AName: string;
      AEvaluateProc: TACLExpressionEvalProc; APriority, AParamCount: Integer;
      AAssociativity: TACLExpressionOperatorInfoAssociativity = eoaLeftToRight);
    function ToString: string; override;
    //# Properties
    property Associativity: TACLExpressionOperatorInfoAssociativity read FAssociativity;
    property Priority: Integer read FPriority;
  end;

  { TACLExpressionElement }

  TACLExpressionElement = class abstract
  public
    procedure Optimize; virtual;
    function Evaluate(AContext: TObject): Variant; virtual; abstract;
    function IsConstant: Boolean; virtual;
    procedure ToString(ABuffer: TACLStringBuilder;
      AFactory: TACLCustomExpressionFactory); reintroduce; virtual; abstract;
  end;

  { TACLExpressionElements }

  TACLExpressionElements = class
  strict private
    function GetCount: Integer; inline;
    function GetItem(Index: Integer): TACLExpressionElement; inline;
  protected
    FList: TList;

    procedure Add(AElement: TACLExpressionElement);
    procedure AddFromStack(AStack: TACLExpressionFastStack<TACLExpressionElement>; ACount: Integer);
    procedure Optimize;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function IsConstant: Boolean;
    procedure ToString(ABuffer: TACLStringBuilder;
      AFactory: TACLCustomExpressionFactory; const ASeparator: string = ','); reintroduce;
    //# Properties
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TACLExpressionElement read GetItem; default;
  end;

  { TACLExpressionElementConstant }

  TACLExpressionElementConstant = class(TACLExpressionElement)
  strict private
    FValue: Variant;
  public
    constructor Create(const AValue: Variant); virtual;
    function Evaluate(AContext: TObject): Variant; override;
    function IsConstant: Boolean; override;
    procedure ToString(ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory); override;
  end;

  { TACLExpressionElementFunction }

  TACLExpressionElementFunctionClass = class of TACLExpressionElementFunction;
  TACLExpressionElementFunction = class(TACLExpressionElement)
  strict private
    FInfo: TACLExpressionFunctionInfo;
    FParams: TACLExpressionElements;

    function GetName: string;
    procedure SetInfo(const Value: TACLExpressionFunctionInfo);
  public
    constructor Create(AInfo: TACLExpressionFunctionInfo); virtual;
    destructor Destroy; override;
    procedure Optimize; override;
    function Evaluate(AContext: TObject): Variant; override;
    function IsConstant: Boolean; override;
    procedure ToString(ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory); override;
    //# Properties
    property Info: TACLExpressionFunctionInfo read FInfo write SetInfo;
    property Name: string read GetName;
    property Params: TACLExpressionElements read FParams;
  end;

  { TACLExpressionElementOperator }

  TACLExpressionElementOperator = class(TACLExpressionElementFunction)
  public
    procedure ToString(ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory); override;
  end;

  { TACLExpression }

  TACLExpression = class
  protected
    FFactory: TACLCustomExpressionFactory;
    FRoot: TACLExpressionElement;
  public
    constructor Create(AFactory: TACLCustomExpressionFactory; ARoot: TACLExpressionElement);
    destructor Destroy; override;
    function Evaluate(AContext: TObject): Variant; virtual;
    function ToString: string; override;
  end;

  { TACLExpressionCache }

  TACLExpressionCache = class(TACLValueCacheManager<string, TACLExpression>)
  strict private
    FFactory: TACLCustomExpressionFactory;
  protected
    procedure DoRemove(const AExpression: TACLExpression); override;
  public
    constructor Create(AFactory: TACLCustomExpressionFactory; ACapacity: Integer);
    function Evaluate(const AExpression: string; AContext: TObject): Variant;
  end;

  { TACLCustomExpressionFactory }

  TACLCustomExpressionFactory = class(TACLUnknownObject)
  public const
    CategoryHidden = Byte(-1);
    CategoryGeneral = 0;
  strict private
    FCache: TACLExpressionCache;

    function GetCacheSize: Integer;
    procedure SetCacheSize(AValue: Integer);
  protected
    FRegisteredFunctions: TACLExpressionFunctionInfoList;
    FRegisteredOperators: TACLExpressionFunctionInfoList;

    function CreateCompiler: TACLExpressionCompiler; virtual;
    function CreateExpression(const AExpression: string; ARoot: TACLExpressionElement): TACLExpression; virtual;
    function CreateFunctionInfoList: TACLExpressionFunctionInfoList; virtual;
    // General Functions
    class procedure CreateInstance(var AInstance);
    class function SmartCompare(const AValue1, AValue2: Variant): TVariantRelationship; static;
    // Factory
    procedure RegisterFunction(const AName: string; AProc: TACLExpressionEvalProc; ACategory: Byte = CategoryGeneral); overload;
    procedure RegisterFunction(const AName: string; AProc: TACLExpressionEvalProc;
      AParamCount: Integer; ADependedFromParametersOnly: Boolean; ACategory: Byte = CategoryGeneral); overload;
    procedure RegisterOperator(const AName: string; AProc: TACLExpressionEvalProc; AParamCount, APriority: Integer);
    procedure RemapFunction(const AOldName, ANewName: string);
    procedure UnregisterFunction(const AName: string);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function Compile(const AExpression: string; AOptimize: Boolean = False): TACLExpression;
    function Evaluate(const AExpression: string; AContext: TObject): Variant;
    function ToString: string; override;
    //# Properties
    property CacheSize: Integer read GetCacheSize write SetCacheSize;
  end;

  { TACLExpressionCompiler }

  TACLExpressionCompilerSolidTokenType = (ecsttNone, ecsttOperand, ecsttOperator);

  TACLExpressionCompiler = class(TACLParser)
  strict private
    FFactory: TACLCustomExpressionFactory;
    FOperatorStack: TACLExpressionFastStack<TACLExpressionOperatorInfo>;
    FOutputBuffer: TACLExpressionFastStack<TACLExpressionElement>;
    FRegisteredFunctions: TACLExpressionFunctionInfoList;
    FRegisteredOperators: TACLExpressionFunctionInfoList;

    procedure ParseParametersList(AFunctionElement: TACLExpressionElementFunction);
  protected
    ClassFunction: TACLExpressionElementFunctionClass;
    ClassOperator: TACLExpressionElementFunctionClass;
    PrevSolidToken: TACLExpressionCompilerSolidTokenType;
    Token: TACLParserToken;

    procedure Error(const AMessage: string); overload;
    procedure Error(const AMessage: string; const AArguments: array of const); overload;
    //# Compiler
    function CompileCore: TACLExpressionElement; virtual;
    function ProcessToken: Boolean; virtual;
    function ProcessTokenAsDelimiter: Boolean; inline;
    function ProcessTokenAsFunction: Boolean; inline;
    function ProcessTokenAsOperator: Boolean; inline;
    function PushConstant(const AValue: Variant): Boolean; inline;
    function PushOperand(AOperand: TACLExpressionElement): Boolean; inline;
    //# Internal
    procedure OutputOperator(AOperator: TACLExpressionOperatorInfo);
    //# Properties
    property Factory: TACLCustomExpressionFactory read FFactory;
    property OperatorStack: TACLExpressionFastStack<TACLExpressionOperatorInfo> read FOperatorStack;
    property OutputBuffer: TACLExpressionFastStack<TACLExpressionElement> read FOutputBuffer;
    property RegisteredFunctions: TACLExpressionFunctionInfoList read FRegisteredFunctions;
    property RegisteredOperators: TACLExpressionFunctionInfoList read FRegisteredOperators;
  public
    constructor Create(
      const AFactory: TACLCustomExpressionFactory;
      const ADelimiters, AQuotes, ASpaces: string); reintroduce; virtual;
    function Compile: TACLExpressionElement; virtual;
  end;

implementation

uses
  ACL.Utils.Common;

procedure OptimizeElement(var AElement: TACLExpressionElement);
var
  APrevElement: TACLExpressionElement;
begin
  if AElement <> nil then
  begin
    AElement.Optimize;
    if AElement.IsConstant and (AElement.ClassType <> TACLExpressionElementConstant) then
    try
      APrevElement := AElement;
      AElement := TACLExpressionElementConstant.Create(APrevElement.Evaluate(nil));
      APrevElement.Free;
    except
      // Evaluate can produce an exception, if fucntion has one of incorrect argumets.
    end;
  end;
end;

{ TACLExpressionFastStack }

constructor TACLExpressionFastStack<T>.Create(AOwnObjects: Boolean);
begin
  inherited Create;
  FOwnObjects := AOwnObjects;
  SetCapacity(16);
end;

destructor TACLExpressionFastStack<T>.Destroy;
begin
  if FOwnObjects then
    FreeObjects;
  inherited Destroy;
end;

procedure TACLExpressionFastStack<T>.FreeObjects;
begin
  while Count > 0 do
    Pop.Free;
end;

function TACLExpressionFastStack<T>.Peek: T;
begin
  if Count = 0 then
    raise Exception.Create(sErrorStackIsEmpty);
  Result := FBuffer[Count - 1];
end;

function TACLExpressionFastStack<T>.Pop: T;
begin
  if Count = 0 then
    raise Exception.Create(sErrorStackIsEmpty);
  Result := FBuffer[Count - 1];
  Dec(FCount);
end;

function TACLExpressionFastStack<T>.Push(AObject: T): Integer;
begin
  Result := Count;
  if Count + 1 > FCapacity then
    SetCapacity(FCapacity * 2);
  FBuffer[Count] := AObject;
  Inc(FCount);
end;

procedure TACLExpressionFastStack<T>.SetCapacity(ACapacity: Integer);
begin
  ACapacity := Max(ACapacity, Count);
  if ACapacity <> FCapacity then
  begin
    FCapacity := ACapacity;
    SetLength(FBuffer, FCapacity);
  end;
end;

{ TACLExpressionFunctionInfo }

constructor TACLExpressionFunctionInfo.Create(const AName: string;
  AParamCount: Integer; ADependedFromParametersOnly: Boolean;
  AProc: TACLExpressionEvalProc; ACategory: Byte);
begin
  inherited Create;
  FName := AName;
  FProc := AProc;
  FCategory := ACategory;
  FParamCount := AParamCount;
  FDependedFromParametersOnly := ADependedFromParametersOnly;
end;

function TACLExpressionFunctionInfo.ToString: string;
var
  B: TACLStringBuilder;
  I: Integer;
begin
  if ParamCount = 0 then
    Exit(Name);

  B := TACLStringBuilder.Get(32);
  try
    B.Append(Name);
    B.Append('(');
    if ParamCount < 0 then
      B.Append('..')
    else
      for I := 0 to ParamCount - 1 do
      begin
        if I > 0 then
          B.Append(',');
        B.Append(Chr(Ord('A') + I));
      end;
    B.Append(')');
    Result := B.ToString;
  finally
    B.Release;
  end;
end;

{ TACLExpressionFunctionInfoList }

function TACLExpressionFunctionInfoList.Find(const AName: PChar;
  ANameLength: Integer; out AFunction: TACLExpressionFunctionInfo): Boolean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Compare(List[I].Name, AName, ANameLength) then
    begin
      AFunction := List[I];
      Exit(True);
    end;

  Result := False;
end;

function TACLExpressionFunctionInfoList.Find(const AName: PChar;
  ANameLength, AParamCount: Integer; out AFunction: TACLExpressionFunctionInfo): Boolean;
var
  AItem: TACLExpressionFunctionInfo;
  I: Integer;
begin
  Result := False;
  for I := 0 to Count - 1 do
  begin
    AItem := List[I];
    if (AItem.ParamCount = AParamCount) and Compare(AItem.Name, AName, ANameLength) then
    begin
      AFunction := AItem;
      Exit(True);
    end;
  end;
end;

function TACLExpressionFunctionInfoList.Find(
  const AName: string; out AFunction: TACLExpressionFunctionInfo): Boolean;
begin
  Result := Find(PChar(AName), Length(AName), AFunction);
end;

function TACLExpressionFunctionInfoList.Find(const AName: string;
  AParamCount: Integer; out AFunction: TACLExpressionFunctionInfo): Boolean;
begin
  Result := Find(PChar(AName), Length(AName), AParamCount, AFunction);
end;

function TACLExpressionFunctionInfoList.Compare(const S: string; B: PChar; L: Integer): Boolean;
begin
  Result := acCompareTokens(PChar(S), B, L, Length(S));
end;

{ TACLExpressionOperatorInfo }

constructor TACLExpressionOperatorInfo.Create(const AName: string;
  AEvaluateProc: TACLExpressionEvalProc; APriority, AParamCount: Integer;
  AAssociativity: TACLExpressionOperatorInfoAssociativity);
begin
  inherited Create(AName, AParamCount, True, AEvaluateProc, 0);
  FAssociativity := AAssociativity;
  FPriority := APriority;
end;

function TACLExpressionOperatorInfo.ToString: string;
begin
  if ParamCount > 1 then
    Result := 'A ' + Name + ' B'
  else
    Result := Name + 'A';
end;

{ TACLExpressionElement }

function TACLExpressionElement.IsConstant: Boolean;
begin
  Result := False;
end;

procedure TACLExpressionElement.Optimize;
begin
  // do nothing
end;

{ TACLExpressionElements }

constructor TACLExpressionElements.Create;
begin
  inherited Create;
  FList := TList.Create;
end;

destructor TACLExpressionElements.Destroy;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    TObject(FList.List[I]).Free;
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TACLExpressionElements.Add(AElement: TACLExpressionElement);
begin
  FList.Add(AElement);
end;

procedure TACLExpressionElements.AddFromStack(
  AStack: TACLExpressionFastStack<TACLExpressionElement>; ACount: Integer);
var
  AIndex: Integer;
begin
  FList.Count := FList.Count + ACount;
  AIndex := Count - 1;
  while ACount > 0 do
  begin
    FList.List[AIndex] := AStack.Pop;
    Dec(AIndex);
    Dec(ACount);
  end;
end;

procedure TACLExpressionElements.ToString(ABuffer: TACLStringBuilder;
  AFactory: TACLCustomExpressionFactory; const ASeparator: string = ',');
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if I > 0 then
      ABuffer.Append(ASeparator);
    Items[I].ToString(ABuffer, AFactory);
  end;
end;

function TACLExpressionElements.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TACLExpressionElements.GetItem(Index: Integer): TACLExpressionElement;
begin
  Result := TACLExpressionElement(FList.List[Index]);
end;

function TACLExpressionElements.IsConstant: Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 0 to Count - 1 do
    Result := Result and Items[I].IsConstant;
end;

procedure TACLExpressionElements.Optimize;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    OptimizeElement(TACLExpressionElement(FList.List[I]));
end;

{ TACLExpressionElementConstant }

constructor TACLExpressionElementConstant.Create(const AValue: Variant);
begin
  FValue := AValue;
end;

function TACLExpressionElementConstant.Evaluate(AContext: TObject): Variant;
begin
  Result := FValue;
end;

function TACLExpressionElementConstant.IsConstant: Boolean;
begin
  Result := True;
end;

procedure TACLExpressionElementConstant.ToString(ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory);
begin
  ABuffer.Append(string(FValue));
end;

{ TACLExpressionElementFunction }

constructor TACLExpressionElementFunction.Create(AInfo: TACLExpressionFunctionInfo);
begin
  FParams := TACLExpressionElements.Create;
  Info := AInfo;
end;

destructor TACLExpressionElementFunction.Destroy;
begin
  FreeAndNil(FParams);
  inherited Destroy;
end;

procedure TACLExpressionElementFunction.Optimize;
begin
  Params.Optimize;
end;

function TACLExpressionElementFunction.Evaluate(AContext: TObject): Variant;
begin
  Result := Info.Proc(AContext, Params);
end;

function TACLExpressionElementFunction.IsConstant: Boolean;
begin
  Result := Info.DependedFromParametersOnly and Params.IsConstant;
end;

procedure TACLExpressionElementFunction.ToString(ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory);
begin
  ABuffer.Append(Name);
  if Params.Count > 0 then
  begin
    ABuffer.Append('(');
    Params.ToString(ABuffer, AFactory);
    ABuffer.Append(')');
  end;
end;

function TACLExpressionElementFunction.GetName: string;
begin
  Result := Info.Name;
end;

procedure TACLExpressionElementFunction.SetInfo(const Value: TACLExpressionFunctionInfo);
begin
  if Value = nil then
    raise EACLExpressionCompiler.Create('Info cannot be nil');
  FInfo := Value;
end;

{ TACLExpressionElementOperator }

procedure TACLExpressionElementOperator.ToString(ABuffer: TACLStringBuilder; AFactory: TACLCustomExpressionFactory);

  procedure ParamToString(AParam: TACLExpressionElement);
  begin
    if AParam is TACLExpressionElementOperator then
    begin
      ABuffer.Append('(');
      AParam.ToString(ABuffer, AFactory);
      ABuffer.Append(')');
    end
    else
      AParam.ToString(ABuffer, AFactory);
  end;

begin
  if Params.Count = 2 then
  begin
    ParamToString(Params[0]);
    ABuffer.Append(' ');
    ABuffer.Append(Name);
    ABuffer.Append(' ');
    ParamToString(Params[1]);
  end
  else
  begin
    ABuffer.Append(Name);
    ABuffer.Append(' ');
    ParamToString(Params[0]);
  end;
end;

{ TACLExpression }

constructor TACLExpression.Create(AFactory: TACLCustomExpressionFactory; ARoot: TACLExpressionElement);
begin
  FFactory := AFactory;
  FRoot := ARoot;
end;

destructor TACLExpression.Destroy;
begin
  FreeAndNil(FRoot);
  inherited;
end;

function TACLExpression.Evaluate(AContext: TObject): Variant;
begin
  if FRoot <> nil then
    Result := FRoot.Evaluate(AContext)
  else
    raise EACLExpression.Create(sErrorNotCompiled);
end;

function TACLExpression.ToString: string;
var
  ABuffer: TACLStringBuilder;
begin
  if FRoot <> nil then
  begin
    ABuffer := TACLStringBuilder.Get(256);
    try
      FRoot.ToString(ABuffer, FFactory);
      Result := ABuffer.ToString;
    finally
      ABuffer.Release;
    end;
  end
  else
    Result := '';
end;

{ TACLExpressionCache }

constructor TACLExpressionCache.Create(AFactory: TACLCustomExpressionFactory; ACapacity: Integer);
begin
  inherited Create(ACapacity);
  FFactory := AFactory;
end;

procedure TACLExpressionCache.DoRemove(const AExpression: TACLExpression);
begin
  AExpression.Free;
end;

function TACLExpressionCache.Evaluate(const AExpression: string; AContext: TObject): Variant;
var
  AExpr: TACLExpression;
begin
  if not Get(AExpression, AExpr) then
  begin
    AExpr := FFactory.Compile(AExpression, True);
    Add(AExpression, AExpr);
  end;
  Result := AExpr.Evaluate(AContext);
end;

{ TACLCustomExpressionFactory }

constructor TACLCustomExpressionFactory.Create;
begin
  inherited Create;
  FRegisteredFunctions := CreateFunctionInfoList;
  FRegisteredOperators := CreateFunctionInfoList;
end;

destructor TACLCustomExpressionFactory.Destroy;
begin
  FreeAndNil(FCache);
  FreeAndNil(FRegisteredOperators);
  FreeAndNil(FRegisteredFunctions);
  inherited Destroy;
end;

function TACLCustomExpressionFactory.Compile(const AExpression: string; AOptimize: Boolean): TACLExpression;
var
  ACompiler: TACLExpressionCompiler;
  AElement: TACLExpressionElement;
begin
  ACompiler := CreateCompiler;
  try
    ACompiler.Initialize(AExpression);
    AElement := ACompiler.Compile;
    if AOptimize then
      OptimizeElement(AElement);
    Result := CreateExpression(AExpression, AElement);
  finally
    ACompiler.Free;
  end;
end;

function TACLCustomExpressionFactory.Evaluate(const AExpression: string; AContext: TObject): Variant;
begin
  if FCache <> nil then
    Result := FCache.Evaluate(AExpression, AContext)
  else
    with Compile(AExpression, False) do
    try
      Result := Evaluate(AContext);
    finally
      Free;
    end;
end;

function TACLCustomExpressionFactory.GetCacheSize: Integer;
begin
  if FCache <> nil then
    Result := FCache.Capacity
  else
    Result := 0;
end;

function TACLCustomExpressionFactory.ToString: string;
begin
{$IFDEF FPC}
  Result := acEmptyStr;
{$ENDIF}
  raise Exception.Create('Unsupported!');
end;

procedure TACLCustomExpressionFactory.RegisterFunction(
  const AName: string; AProc: TACLExpressionEvalProc; ACategory: Byte = 0);
begin
  RegisterFunction(AName, AProc, 0, False, ACategory);
end;

procedure TACLCustomExpressionFactory.RegisterFunction(const AName: string;
  AProc: TACLExpressionEvalProc; AParamCount: Integer; ADependedFromParametersOnly: Boolean;
  ACategory: Byte = CategoryGeneral);
var
  AFunction: TACLExpressionFunctionInfo;
begin
  if FRegisteredFunctions.Find(AName, AParamCount, AFunction) then
    raise EACLExpression.CreateFmt(sErrorFunctionAlreadyRegistered, [AName, AParamCount]);
  FRegisteredFunctions.Add(TACLExpressionFunctionInfo.Create(AName, AParamCount, ADependedFromParametersOnly, AProc, ACategory));
end;

procedure TACLCustomExpressionFactory.RegisterOperator(
  const AName: string; AProc: TACLExpressionEvalProc; AParamCount, APriority: Integer);
const
  Map: array[Boolean] of TACLExpressionOperatorInfoAssociativity = (eoaRightToLeft, eoaLeftToRight);
var
  AFunction: TACLExpressionFunctionInfo;
begin
  if (AParamCount < 1) or (AParamCount > 2) then
    raise EACLExpression.Create(sErrorOperatorArguments);
  if FRegisteredOperators.Find(AName, AParamCount, AFunction) then
    raise EACLExpression.CreateFmt(sErrorFunctionAlreadyRegistered, [AName, AParamCount]);
  FRegisteredOperators.Add(TACLExpressionOperatorInfo.Create(AName, AProc, APriority, AParamCount, Map[AParamCount = 2]));
end;

procedure TACLCustomExpressionFactory.RemapFunction(const AOldName, ANewName: string);
var
  AFunction: TACLExpressionFunctionInfo;
begin
  if FRegisteredFunctions.Find(ANewName, AFunction) then
    RegisterFunction(AOldName, AFunction.Proc, AFunction.ParamCount,
      AFunction.DependedFromParametersOnly, CategoryHidden)
  else
    raise EACLExpression.CreateFmt(sErrorFunctionNotFound, [ANewName]);
end;

procedure TACLCustomExpressionFactory.UnregisterFunction(const AName: string);
var
  AFunction: TACLExpressionFunctionInfo;
begin
  if FRegisteredFunctions.Find(AName, AFunction) then
    FRegisteredFunctions.Remove(AFunction);
end;

function TACLCustomExpressionFactory.CreateCompiler: TACLExpressionCompiler;
begin
  Result := TACLExpressionCompiler.Create(Self,
    acParserDefaultDelimiterChars,
    acParserDefaultQuotes,
    acParserDefaultSpaceChars);
end;

function TACLCustomExpressionFactory.CreateExpression(
  const AExpression: string; ARoot: TACLExpressionElement): TACLExpression;
begin
  Result := TACLExpression.Create(Self, ARoot);
end;

function TACLCustomExpressionFactory.CreateFunctionInfoList: TACLExpressionFunctionInfoList;
begin
  Result := TACLExpressionFunctionInfoList.Create;
end;

class procedure TACLCustomExpressionFactory.CreateInstance(var AInstance);
var
  ATempInstance: TObject;
begin
  ATempInstance := Create;
  if AtomicCmpExchange(Pointer(AInstance), Pointer(ATempInstance), nil) <> nil then
    ATempInstance.Free;
end;

class function TACLCustomExpressionFactory.SmartCompare(const AValue1, AValue2: Variant): TVariantRelationship;
const
  Map: array[-1..1] of TVariantRelationship = (vrLessThan, vrEqual, vrGreaterThan);
begin
  if VarIsStr(AValue1) or VarIsStr(AValue2) then
    Result := Map[acLogicalCompare(AValue1, AValue2, False)]
  else
    try
      Result := VarCompareValue(AValue1, AValue2);
    except
      Result := vrNotEqual;
    end;
end;

procedure TACLCustomExpressionFactory.SetCacheSize(AValue: Integer);
begin
  if CacheSize <> AValue then
  begin
    FreeAndNil(FCache);
    if AValue > 0 then
      FCache := TACLExpressionCache.Create(Self, AValue);
  end;
end;

{ TACLExpressionCompiler }

constructor TACLExpressionCompiler.Create(
  const AFactory: TACLCustomExpressionFactory;
  const ADelimiters, AQuotes, ASpaces: string);
begin
  FFactory := AFactory;
  inherited Create(ADelimiters, AQuotes, ASpaces);
  FRegisteredFunctions := FFactory.FRegisteredFunctions;
  FRegisteredOperators := FFactory.FRegisteredOperators;
  ClassOperator := TACLExpressionElementOperator;
  ClassFunction := TACLExpressionElementFunction;
  QuotedTextAsSingleTokenUnquot := True;
  QuotedTextAsSingleToken := True;
  SkipDelimiters := False;
  SkipSpaces := True;
end;

function TACLExpressionCompiler.Compile: TACLExpressionElement;
begin
  FOutputBuffer := TACLExpressionFastStack<TACLExpressionElement>.Create(True);
  try
    FOperatorStack := TACLExpressionFastStack<TACLExpressionOperatorInfo>.Create(False);
    try
      Result := CompileCore;
    finally
      FreeAndNil(FOperatorStack);
    end;
  finally
    FreeAndNil(FOutputBuffer);
  end;
end;

procedure TACLExpressionCompiler.Error(const AMessage: string);
var
  AScanArea: string;
begin
  if ScanCount > 0 then
  begin
    SetString(AScanArea, Scan, Min(ScanCount, 16));
    raise EACLExpressionCompiler.CreateFmt(AMessage + '(' + sErrorCursorInfo + ')', [Token.ToString, AScanArea]);
  end
  else
    raise EACLExpressionCompiler.Create(AMessage);
end;

procedure TACLExpressionCompiler.Error(const AMessage: string; const AArguments: array of const);
begin
  Error(Format(AMessage, AArguments));
end;

function TACLExpressionCompiler.CompileCore: TACLExpressionElement;
begin
  PrevSolidToken := ecsttNone;
  while GetToken(Token) do
  begin
    if not ProcessToken then
      Error(sErrorUnexpectedToken);
  end;

  while OperatorStack.Count > 0 do
    OutputOperator(OperatorStack.Pop);

  if OutputBuffer.Count <> 1 then
    Error(sErrorInvalidExpression);
  Result := OutputBuffer.Pop;
end;

function TACLExpressionCompiler.ProcessToken: Boolean;
var
  AValueD: Double;
  AValueI: Integer;
begin
  case Token.TokenType of
    acTokenDelimiter:
      Result := ProcessTokenAsDelimiter;
    acExprTokenOperator:
      Result := ProcessTokenAsOperator;
    acExprTokenFunction:
      Result := ProcessTokenAsFunction;
    acTokenQuotedText:
      Result := PushConstant(Token.ToString);
    acExprTokenConstantInt:
      Result := TryStrToInt(Token.ToString, AValueI) and PushConstant(AValueI);
    acExprTokenConstantFloat:
      Result := TryStrToFloat(Token.ToString, AValueD, InvariantFormatSettings) and PushConstant(AValueD);
  else
    Result := False;
  end;
end;

function TACLExpressionCompiler.ProcessTokenAsDelimiter: Boolean;
var
  AOperator: TACLExpressionOperatorInfo;
begin
  Result := False;
  if Token.DataLength = 1 then
    case Token.Data^ of
      '(':
        begin
          OperatorStack.Push(nil);
          Result := True;
        end;
      ')':
        begin
          repeat
            AOperator := OperatorStack.Pop;
            if AOperator = nil then
              Break;
            OutputOperator(AOperator);
          until False;
          Result := True;
        end;
    end;
end;

function TACLExpressionCompiler.ProcessTokenAsFunction: Boolean;
var
  AFunction: TACLExpressionFunctionInfo;
  AFunctionElement: TACLExpressionElementFunction;
begin
  AFunctionElement := ClassFunction.Create(TACLExpressionFunctionInfo(Token.Context));
  try
    if (ScanCount > 0) and (Scan^ = '(') then
      ParseParametersList(AFunctionElement);
    if AFunctionElement.Info.ParamCount >= 0 then
    begin
      if AFunctionElement.Info.ParamCount <> AFunctionElement.Params.Count then
      begin
        // try to find overload version of this function with other number of arguments
        if RegisteredFunctions.Find(AFunctionElement.Name, AFunctionElement.Params.Count, AFunction) then
          AFunctionElement.Info := AFunction;
      end;
      if AFunctionElement.Info.ParamCount > AFunctionElement.Params.Count then
        Error(sErrorTooSmallArguments, [AFunctionElement.Name]);
      if AFunctionElement.Info.ParamCount < AFunctionElement.Params.Count then
        Error(sErrorTooManyArguments, [AFunctionElement.Name]);
    end;
  except
    FreeAndNil(AFunctionElement);
    raise;
  end;
  Result := PushOperand(AFunctionElement);
end;

function TACLExpressionCompiler.ProcessTokenAsOperator: Boolean;
var
  AOperator: TACLExpressionOperatorInfo;
  AOperatorPeek: TACLExpressionOperatorInfo;
begin
  AOperator := TACLExpressionOperatorInfo(Token.Context);
  repeat
    if OperatorStack.Count > 0 then
      AOperatorPeek := OperatorStack.Peek
    else
      AOperatorPeek := nil;

    if AOperatorPeek <> nil then
    begin
      if (AOperator.Associativity = eoaRightToLeft) and (AOperator.Priority <  AOperatorPeek.Priority) or
         (AOperator.Associativity = eoaLeftToRight) and (AOperator.Priority <= AOperatorPeek.Priority)
      then
        OutputOperator(OperatorStack.Pop)
      else
        Break;
    end;
  until AOperatorPeek = nil;
  OperatorStack.Push(AOperator);
  PrevSolidToken := ecsttOperator;
  Result := True;
end;

function TACLExpressionCompiler.PushConstant(const AValue: Variant): Boolean;
begin
  Result := PushOperand(TACLExpressionElementConstant.Create(AValue));
end;

function TACLExpressionCompiler.PushOperand(AOperand: TACLExpressionElement): Boolean;
begin
  OutputBuffer.Push(AOperand);
  PrevSolidToken := ecsttOperand;
  Result := True;
end;

procedure TACLExpressionCompiler.OutputOperator(AOperator: TACLExpressionOperatorInfo);
var
  AFunction: TACLExpressionElementFunction;
begin
  if AOperator = nil then
    Error(sErrorUnequalBrackets);

  AFunction := ClassOperator.Create(AOperator);
  try
    AFunction.Params.AddFromStack(OutputBuffer, AOperator.ParamCount);
    OutputBuffer.Push(AFunction);
  except
    FreeAndNil(AFunction);
    Error(sErrorTooSmallArguments, [AOperator.Name]);
  end;
end;

procedure TACLExpressionCompiler.ParseParametersList(AFunctionElement: TACLExpressionElementFunction);

  function ExtractParameter(AScanStart, AScanFinish: PChar): TACLExpressionElement;
  var
    ACompiler: TACLExpressionCompiler;
    ALength: Integer;
  begin
    ALength := acStringLength(AScanStart, AScanFinish);
    if ALength > 0 then
    begin
      ACompiler := Factory.CreateCompiler;
      try
        ACompiler.Initialize(AScanStart, ALength);
        Result := ACompiler.Compile;
      finally
        ACompiler.Free;
      end;
    end
    else
      Result := nil;

    if Result = nil then
      Result := TACLExpressionElementConstant.Create('');
  end;

var
  ABracketLevel: Integer;
  AParameterCursor: PChar;
  AToken: TACLParserToken;
begin
  ABracketLevel := 0;
  MoveToNextSymbol; // skip Bracket
  AParameterCursor := Scan;
  while GetToken(AToken) do
  begin
    if (AToken.TokenType = acTokenDelimiter) and (AToken.DataLength = 1) then
      case AToken.Data^ of
        '(':
          Inc(ABracketLevel);

        ')':
          if ABracketLevel = 0 then
          begin
            if (AParameterCursor <> Scan - AToken.DataLength) or (AFunctionElement.Params.Count > 0) then
              AFunctionElement.Params.Add(ExtractParameter(AParameterCursor, Scan - AToken.DataLength));
            Break;
          end
          else
            Dec(ABracketLevel);

        ',':
          if ABracketLevel = 0 then
          begin
            AFunctionElement.Params.Add(ExtractParameter(AParameterCursor, Scan - AToken.DataLength));
            AParameterCursor := Scan;
          end;
      end;
  end;

  if ABracketLevel <> 0 then
    Error(sErrorUnequalBrackets);
end;

end.
