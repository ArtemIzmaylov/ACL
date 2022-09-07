{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*        Math Expressions Processor         *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Expressions.Math;

{$I ACL.Config.INC}

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Variants,
  // ACL
  ACL.Expressions,
  ACL.Parsers,
  ACL.Utils.Strings;

type

  { TACLMathExpressionFactory }

  TACLMathExpressionFactory = class(TACLCustomExpressionFactory)
  strict private
    class var FInstance: TACLMathExpressionFactory;
  strict private
    // Built-in Functions
    class function FunctionAbs(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionCos(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionExp(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionIf(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionLn(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionLog10(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionLogN(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionMax(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionMin(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionPower(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionRandom(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionRound(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionSin(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function FunctionTrunc(AContext: TObject; AParams: TACLExpressionElements): Variant;

    // Built-in Operators
    class function OperatorAnd(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorDivide(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorDivideInt(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorEqual(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorGreater(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorGreaterOrEqual(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorLess(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorLessOrEqual(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorMinus(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorMod(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorMultiply(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorNot(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorNotEqual(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorOr(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorPlus(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorPower(AContext: TObject; AParams: TACLExpressionElements): Variant;
    class function OperatorXor(AContext: TObject; AParams: TACLExpressionElements): Variant;
  protected
    function CreateCompiler: TACLExpressionCompiler; override;
  public
    procedure AfterConstruction; override;
    class destructor Destroy;
    class function Instance: TACLMathExpressionFactory;
  end;

  { TACLMathExpressionCompiler }

  TACLMathExpressionCompiler = class(TACLExpressionCompiler)
  protected
    function FetchNumericToken(var P: PWideChar; var C: Integer; var AToken: TACLParserToken): Boolean;
    function FetchToken(var P: PWideChar; var C: Integer; var AToken: TACLParserToken): Boolean; override;
  end;

implementation

uses
  System.Math;

{ TACLMathExpressionFactory }

class destructor TACLMathExpressionFactory.Destroy;
begin
  FreeAndNil(FInstance);
end;

class function TACLMathExpressionFactory.Instance: TACLMathExpressionFactory;
begin
  if FInstance = nil then
    CreateInstance(FInstance);
  Result := FInstance;
end;

procedure TACLMathExpressionFactory.AfterConstruction;
begin
  inherited;
  // Functiontions
  RegisterFunction('Abs', FunctionAbs, 1, True);
  RegisterFunction('Cos', FunctionCos, 1, True);
  RegisterFunction('Exp', FunctionExp, 1, True);
  RegisterFunction('If', FunctionIf, 3, True);
  RegisterFunction('Ln', FunctionLn, 1, True);
  RegisterFunction('Log10', FunctionLog10, 1, True);
  RegisterFunction('LogN', FunctionLogN, 2, True);
  RegisterFunction('Max', FunctionMax, 2, True);
  RegisterFunction('Min', FunctionMin, 2, True);
  RegisterFunction('Power', FunctionPower, 2, True);
  RegisterFunction('Random', FunctionRandom, 0, False);
  RegisterFunction('Round', FunctionRound, 1, True);
  RegisterFunction('Sin', FunctionSin, 1, True);
  RegisterFunction('Trunc', FunctionTrunc, 1, True);

  // Operators
  RegisterOperator('*', OperatorMultiply, 2, 10);
  RegisterOperator('/', OperatorDivide, 2, 10);
  RegisterOperator('^', OperatorPower, 2, 10);
  RegisterOperator('div', OperatorDivideInt, 2, 10);
  RegisterOperator('mod', OperatorMod, 2, 10);

  RegisterOperator('-', OperatorMinus, 1, 9);
  RegisterOperator('-', OperatorMinus, 2, 9);
  RegisterOperator('+', OperatorPlus, 2, 9);

  RegisterOperator('>', OperatorGreater, 2, 9);
  RegisterOperator('>=', OperatorGreaterOrEqual, 2, 9);
  RegisterOperator('<', OperatorLess, 2, 9);
  RegisterOperator('<=', OperatorLessOrEqual, 2, 9);
  RegisterOperator('<>', OperatorNotEqual, 2, 9);
  RegisterOperator('!=', OperatorNotEqual, 2, 9);
  RegisterOperator('=', OperatorEqual, 2, 9);

  RegisterOperator('not', OperatorNot, 1, 8);
  RegisterOperator('!', OperatorNot, 1, 8);

  RegisterOperator('and', OperatorAnd, 2, 7);
  RegisterOperator('or', OperatorOr, 2, 7);
  RegisterOperator('xor', OperatorXor, 2, 7);
end;

function TACLMathExpressionFactory.CreateCompiler: TACLExpressionCompiler;
begin
  Result := TACLMathExpressionCompiler.Create(Self);
end;

class function TACLMathExpressionFactory.FunctionAbs(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Abs(AParams[0].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.FunctionCos(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Cos(AParams[0].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.FunctionExp(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Exp(AParams[0].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.FunctionIf(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  if AParams[0].Evaluate(AContext) then
    Result := AParams[1].Evaluate(AContext)
  else
    Result := AParams[2].Evaluate(AContext);
end;

class function TACLMathExpressionFactory.FunctionLn(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Ln(AParams[0].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.FunctionLog10(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Log10(AParams[0].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.FunctionLogN(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := LogN(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.FunctionMax(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Max(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.FunctionMin(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Min(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.FunctionPower(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Power(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.FunctionRandom(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Random;
end;

class function TACLMathExpressionFactory.FunctionRound(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Round(AParams[0].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.FunctionSin(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Sin(AParams[0].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.FunctionTrunc(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Trunc(AParams[0].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.OperatorAnd(AContext: TObject; AParams: TACLExpressionElements): Variant;
var
  AValue: Integer;
begin
  AValue := Integer(AParams[0].Evaluate(AContext));
  if AValue <> 0 then
    Result := AValue and Integer(AParams[1].Evaluate(AContext))
  else
    Result := 0;
end;

class function TACLMathExpressionFactory.OperatorDivide(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := AParams[0].Evaluate(AContext) / AParams[1].Evaluate(AContext);
end;

class function TACLMathExpressionFactory.OperatorDivideInt(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := AParams[0].Evaluate(AContext) div AParams[1].Evaluate(AContext);
end;

class function TACLMathExpressionFactory.OperatorEqual(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Ord(SmartCompare(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext)) = vrEqual);
end;

class function TACLMathExpressionFactory.OperatorGreater(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Ord(SmartCompare(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext)) = vrGreaterThan);
end;

class function TACLMathExpressionFactory.OperatorGreaterOrEqual(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Ord(SmartCompare(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext)) in [vrGreaterThan, vrEqual]);
end;

class function TACLMathExpressionFactory.OperatorLess(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Ord(SmartCompare(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext)) = vrLessThan);
end;

class function TACLMathExpressionFactory.OperatorLessOrEqual(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Ord(SmartCompare(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext)) in [vrLessThan, vrEqual]);
end;

class function TACLMathExpressionFactory.OperatorMinus(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  if AParams.Count = 1 then
    Result := -AParams[0].Evaluate(AContext)
  else
    Result := AParams[0].Evaluate(AContext) - AParams[1].Evaluate(AContext);
end;

class function TACLMathExpressionFactory.OperatorMod(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := AParams[0].Evaluate(AContext) mod AParams[1].Evaluate(AContext);
end;

class function TACLMathExpressionFactory.OperatorMultiply(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := AParams[0].Evaluate(AContext) * AParams[1].Evaluate(AContext);
end;

class function TACLMathExpressionFactory.OperatorNot(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := AParams[0].Evaluate(AContext);
  if VarIsStr(Result) then
    Result := Result = ''
  else
    Result := Ord(Integer(Result) = 0);
end;

class function TACLMathExpressionFactory.OperatorNotEqual(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Ord(SmartCompare(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext)) <> vrEqual);
end;

class function TACLMathExpressionFactory.OperatorOr(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
   Result := Integer(AParams[0].Evaluate(AContext)) or Integer(AParams[1].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.OperatorPlus(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := AParams[0].Evaluate(AContext) + AParams[1].Evaluate(AContext);
end;

class function TACLMathExpressionFactory.OperatorPower(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
  Result := Power(AParams[0].Evaluate(AContext), AParams[1].Evaluate(AContext));
end;

class function TACLMathExpressionFactory.OperatorXor(AContext: TObject; AParams: TACLExpressionElements): Variant;
begin
   Result := Integer(AParams[0].Evaluate(AContext)) xor Integer(AParams[1].Evaluate(AContext));
end;

{ TACLMathExpressionCompiler }

function TACLMathExpressionCompiler.FetchNumericToken(var P: PWideChar; var C: Integer; var AToken: TACLParserToken): Boolean;
const
  NumericStateMachine: array[0..3, -1..14] of SmallInt = (
    {    0  1  2  3  4  5  6  7  8  9   +   -   .   E  #0}
    (-2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1,  1,  2, -1),
    (-2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -2,  2, -1),
    (-2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,  3,  3, -2, -2, -1),
    (-2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, -1, -1, -2, -2, -1)
  );

  function GetCharIndex(const C: Char): Integer;
  begin
    if CharInSet(C, ['0'..'9']) then
      Result := Ord(C) - Ord('0')
    else if Ord(C) = Ord('+') then
      Result := 10
    else if Ord(C) = Ord('-') then
      Result := 11
    else if Ord(C) = Ord('.') then
      Result := 12
    else if Ord(C) = Ord('E') then
      Result := 13
    else if Contains(C, FDelimiters, FDelimitersLength) then
      Result := 14
    else
      Result := -1;
  end;

var
  AMachineState: Integer;
  ANextMachineState: Integer;
begin
  AToken.Data := P;

  AMachineState := 0;
  while C > 0 do
  begin
    ANextMachineState := NumericStateMachine[AMachineState, GetCharIndex(P^)];
    if ANextMachineState < 0 then
    begin
      if ANextMachineState = -2 then
      begin
        Error(sErrorUnexpectedToken);
        Exit(False);
      end;
      Break;
    end;
    AMachineState := ANextMachineState;
    Inc(P);
    Dec(C);
  end;

  AToken.DataLength := acStringLength(AToken.Data, P);
  if AMachineState = 0 then
    AToken.TokenType := acExprTokenConstantInt
  else
    AToken.TokenType := acExprTokenConstantFloat;
  Result := True;
end;

function TACLMathExpressionCompiler.FetchToken(var P: PWideChar; var C: Integer; var AToken: TACLParserToken): Boolean;
var
  AEvalFunction: TACLExpressionFunctionInfo;
  ALength: Integer;
begin
  Result := False;
  if C <= 0 then
    Exit;

  // Constants
  if CharInSet(P^, ['0'..'9']) then
    Exit(FetchNumericToken(P, C, AToken));

  // Operators that presented as char separator: >, >=, <>...
  if Contains(P^, FDelimiters, FDelimitersLength) then
  begin
    ALength := 1;
    while RegisteredOperators.Find(P, ALength, 1 + Ord(PrevSolidToken = ecsttOperand), AEvalFunction) do
    begin
      AToken.Context := AEvalFunction;
      AToken.TokenType := acExprTokenOperator;
      Inc(ALength);
      if ALength > C then
        Break;
    end;
    if AToken.TokenType = acExprTokenOperator then
    begin
      AToken.Data := P;
      AToken.DataLength := ALength - 1;
      Inc(P, AToken.DataLength);
      Dec(C, AToken.DataLength);
      Exit(True);
    end;
  end;

  // Other tokens
  Result := inherited FetchToken(P, C, AToken);
  if Result and (AToken.TokenType = acTokenIdent) then
  begin
    if RegisteredFunctions.Find(AToken.Data, AToken.DataLength, AEvalFunction) then
    begin
      AToken.TokenType := acExprTokenFunction;
      AToken.Context := AEvalFunction;
    end
    else

    if RegisteredOperators.Find(AToken.Data, AToken.DataLength, AEvalFunction) then
    begin
      AToken.TokenType := acExprTokenOperator;
      AToken.Context := AEvalFunction;
    end;
  end;
end;

end.
