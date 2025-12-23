////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   TextEdit
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.TextEdit;

{$I ACL.Config.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  {Winapi.}Messages,
  {Winapi.}Windows,
{$ENDIF}
  // Vcl
  {Vcl.}Controls,
  {Vcl.}Graphics,
  {Vcl.}ImgList,
  {Vcl.}Forms,
  // System
  {System.}Classes,
  {System.}Math,
  {System.}Variants,
  {System.}SysUtils,
  {System.}Types,
  System.UITypes,
  // ACL
  ACL.Classes,
  ACL.Geometry,
  ACL.Graphics,
  ACL.MUI,
  ACL.ObjectLinks,
  ACL.UI.Controls.Base,
  ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.Buttons,
  ACL.UI.HintWindow,
  ACL.UI.ImageList,
  ACL.UI.Resources,
  ACL.Utils.Common,
  ACL.Utils.DPIAware,
  ACL.Utils.Strings;

type
  {$SCOPEDENUMS ON}
  TACLEditNumberOption = (Digits, Decimals, Signs, Zeros);
  TACLEditNumberOptions = set of TACLEditNumberOption;
  {$SCOPEDENUMS OFF}

const
  DefaultNumbersOnlyInteger = [
    TACLEditNumberOption.Signs,
    TACLEditNumberOption.Digits,
    TACLEditNumberOption.Zeros];
  DefaultNumbersOnlyFloat = [
    TACLEditNumberOption.Signs,
    TACLEditNumberOption.Digits,
    TACLEditNumberOption.Decimals,
    TACLEditNumberOption.Zeros];

type
  TACLEditButtons = class;
  TACLCustomTextEdit = class;

  { IACLTextEdit }

  IACLTextEdit = interface(IACLEditActions)
  ['{254D369B-2B0F-4D04-AD4F-136F5B93F338}']
    // Get/Set
    function GetSelLength: Integer;
    function GetSelStart: Integer;
    function GetSelText: string;
    function GetText: string;
    procedure SetSelLength(AValue: Integer);
    procedure SetSelStart(AValue: Integer);
    procedure SetSelText(const AValue: string);
    procedure SetText(const AValue: string);
    // Properties
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property SelText: string read GetSelText write SetSelText;
    property Text: string read GetText write SetText;
  end;

  { TACLEditButton }

  TACLEditButton = class(TACLCollectionItem)
  strict private
    FCaption: string;
    FHint: string;
    FSubClass: TACLButtonSubClass;
    FVisible: Boolean;
    FWidth: Integer;

    function GetCollection: TACLEditButtons;
    function GetEnabled: Boolean;
    function GetImageIndex: TImageIndex;
    function GetOnClick: TNotifyEvent;
    procedure SetCaption(const AValue: string);
    procedure SetEnabled(AValue: Boolean);
    procedure SetImageIndex(AValue: TImageIndex);
    procedure SetOnClick(AValue: TNotifyEvent);
    procedure SetVisible(AValue: Boolean);
    procedure SetWidth(AValue: Integer);
    procedure UpdateCaption;
  protected
    procedure AssignTo(Target: TPersistent); override;
    procedure Calculate(var R: TRect);
    procedure SetCollection(Value: TCollection); override;
    //# Properties
    property SubClass: TACLButtonSubClass read FSubClass;
  public
    constructor Create(ACollection: TCollection); override;
    //# Properties
    property Collection: TACLEditButtons read GetCollection;
  published
    property Caption: string read FCaption write SetCaption;
    property Enabled: Boolean read GetEnabled write SetEnabled default True;
    property Hint: string read FHint write FHint;
    property ImageIndex: TImageIndex read GetImageIndex write SetImageIndex default -1;
    property Index stored False;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Width: Integer read FWidth write SetWidth default 0;
    //# Events
    property OnClick: TNotifyEvent read GetOnClick write SetOnClick;
  end;

  { TACLEditButtons }

  TACLEditButtons = class(TCollection)
  strict private
    FEdit: TACLCustomTextEdit;
    function GetItem(AIndex: Integer): TACLEditButton;
  protected
    function GetOwner: TPersistent; override;
    procedure Update(Item: TCollectionItem); override;
    //# Properties
    property Edit: TACLCustomTextEdit read FEdit;
  public
    constructor Create(AEdit: TACLCustomTextEdit);
    function Add(const ACaption: string = ''): TACLEditButton;
    function Find(const P: TPoint; out AButton: TACLEditButton): Boolean;
    //# Properties
    property Items[Index: Integer]: TACLEditButton read GetItem; default;
  end;

  { TACLCustomTextEdit }

  TACLCustomTextEdit = class(TACLCustomEdit,
    IACLInplaceControl,
    IACLTextEdit)
  strict private
    FButtons: TACLEditButtons;
    FButtonsImages: TCustomImageList;
    FButtonsImagesLink: TChangeLink;
    FNumbersOnly: TACLEditNumberOptions;

    function CheckValue(const AText: string; out AValue: Variant): Boolean;
    function GetMaxLength: Integer;
    function GetPasswordChar: Boolean;
    function GetReadOnly: Boolean;
    function GetSelLength: Integer;
    function GetSelStart: Integer;
    function GetSelText: string;
    function GetText: string;
    function GetTextHint: string;
    function GetValue: Variant;
    procedure ReadInputMask(AReader: TReader);
    procedure SetButtons(AValue: TACLEditButtons);
    procedure SetButtonsImages(const AValue: TCustomImageList);
    procedure SetNumbersOnly(AValue: TACLEditNumberOptions);
    procedure SetMaxLength(AValue: Integer);
    procedure SetPasswordChar(AValue: Boolean);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetSelLength(AValue: Integer);
    procedure SetSelStart(AValue: Integer);
    procedure SetSelText(const AValue: string);
    procedure SetText(const AValue: string);
    procedure SetTextHint(const AValue: string);
    procedure SetValue(const AValue: Variant);
    //# Messages
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
  protected
    procedure CalculateButtons(var ARect: TRect; AIndent: Integer); override;
    function GetCursor(const P: TPoint): TCursor; override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure HandlerImageChange(Sender: TObject); virtual;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;

    // Input
    procedure CheckInput(var AText, APart1, APart2: string; var AAccept: Boolean); virtual;
    function TextToValue(const AText: string): Variant; virtual;
    function ValueToText(const AValue: Variant): string; virtual;
    procedure SetTextCore(const AValue: string); virtual;

    // IACLInplaceControl
    function IACLInplaceControl.InplaceIsFocused = Focused;
    function InplaceGetValue: string;
    procedure InplaceSetFocus;
    procedure InplaceSetValue(const AValue: string);

    //# Properties
    property Buttons: TACLEditButtons read FButtons write SetButtons;
    property ButtonsImages: TCustomImageList read FButtonsImages write SetButtonsImages;
    property MaxLength: Integer read GetMaxLength write SetMaxLength default 0;
    property NumbersOnly: TACLEditNumberOptions read FNumbersOnly write SetNumbersOnly default [];
    property PasswordChar: Boolean read GetPasswordChar write SetPasswordChar default False;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property TextHint: string read GetTextHint write SetTextHint;
    property Value: Variant read GetValue write SetValue;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CanExecute(AAction: TACLEditAction): Boolean;
    procedure Execute(AAction: TACLEditAction);
    procedure Localize(const ASection, AName: string); override;
    procedure Select(AStart, ALength: Integer; AGoForward: Boolean = True);
    //# Properties
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property SelText: string read GetSelText write SetSelText;
    property Text: string read GetText write SetText;
  published
    property Color;
    //# Events
    property OnChange;
  end;

  { TACLEdit }

  TACLEditClass = class of TACLEdit;
  TACLEdit = class(TACLCustomTextEdit)
  public
    property Value;
  published
    property AutoSize;
    property Borders;
    property Buttons;
    property ButtonsImages;
    property NumbersOnly;
    property MaxLength;
    property PasswordChar;
    property ReadOnly;
    property ResourceCollection;
    property Style;
    property StyleButton;
    property Text;
    property TextHint;
  end;

implementation

{ TACLEditButton }

constructor TACLEditButton.Create(ACollection: TCollection);
begin
  FVisible := True; // before set collection
  inherited Create(ACollection);
end;

procedure TACLEditButton.AssignTo(Target: TPersistent);
begin
  if Target is TACLEditButton then
  begin
    TACLEditButton(Target).Caption := Caption;
    TACLEditButton(Target).Hint := Hint;
    TACLEditButton(Target).ImageIndex := ImageIndex;
    TACLEditButton(Target).Visible := Visible;
    TACLEditButton(Target).Width := Width;
  end;
end;

procedure TACLEditButton.Calculate(var R: TRect);
var
  LWidth: Integer;
begin
  if SubClass <> nil then
  begin
    if Width > 0 then
      LWidth := dpiApply(Width, SubClass.CurrentDpi)
    else
      LWidth := R.Height;

    SubClass.Calculate(R.Split(srRight, IfThen(Visible, LWidth)));
    R.Right := SubClass.Bounds.Left;
  end;
end;

function TACLEditButton.GetCollection: TACLEditButtons;
begin
  Result := TACLEditButtons(inherited Collection);
end;

function TACLEditButton.GetEnabled: Boolean;
begin
  Result := SubClass.IsEnabled;
end;

function TACLEditButton.GetImageIndex: TImageIndex;
begin
  Result := SubClass.ImageIndex;
end;

function TACLEditButton.GetOnClick: TNotifyEvent;
begin
  Result := SubClass.OnClick;
end;

procedure TACLEditButton.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    UpdateCaption;
    Changed(False);
  end;
end;

procedure TACLEditButton.SetCollection(Value: TCollection);
var
  LEdit: TACLCustomTextEdit;
begin
  if (Value <> nil) and not (Value is TACLEditButtons) then
    raise EInvalidArgument.Create('TACLEditButton cannot be placed on ' + Value.ClassName);

  if SubClass <> nil then
  begin
    LEdit := Collection.Edit;
    if not (csDestroying in LEdit.ComponentState) then
      LEdit.SubClasses.Remove(FSubClass);
    FSubClass := nil;
  end;
  if Value <> nil then // destroying
  begin
    LEdit := TACLEditButtons(Value).Edit;
    LEdit.RegisterSubClass(FSubClass, TACLButtonSubClass.Create(LEdit, LEdit.StyleButton));
  end;
  inherited; // last (for design-time)
end;

procedure TACLEditButton.SetEnabled(AValue: Boolean);
begin
  if AValue <> Enabled then
  begin
    SubClass.IsEnabled := AValue;
    Changed(False);
  end;
end;

procedure TACLEditButton.SetImageIndex(AValue: TImageIndex);
begin
  if ImageIndex <> AValue then
  begin
    SubClass.ImageIndex := AValue;
    UpdateCaption;
    Changed(False);
  end;
end;

procedure TACLEditButton.SetOnClick(AValue: TNotifyEvent);
begin
  SubClass.OnClick := AValue;
end;

procedure TACLEditButton.SetVisible(AValue: Boolean);
begin
  if Visible <> AValue then
  begin
    FVisible := AValue;
    Changed(True);
  end;
end;

procedure TACLEditButton.SetWidth(AValue: Integer);
begin
  if FWidth <> AValue then
  begin
    FWidth := AValue;
    Changed(True);
  end;
end;

procedure TACLEditButton.UpdateCaption;
begin
  SubClass.Caption := IfThenW(SubClass.ImageIndex < 0, Caption);
end;

{ TACLEditButtons }

constructor TACLEditButtons.Create(AEdit: TACLCustomTextEdit);
begin
  FEdit := AEdit;
  inherited Create(TACLEditButton);
end;

function TACLEditButtons.Add(const ACaption: string = ''): TACLEditButton;
begin
  BeginUpdate;
  try
    Result := TACLEditButton(inherited Add);
    Result.Caption := ACaption;
  finally
    EndUpdate;
  end;
end;

function TACLEditButtons.GetItem(AIndex: Integer): TACLEditButton;
begin
  Result := TACLEditButton(inherited Items[AIndex]);
end;

function TACLEditButtons.GetOwner: TPersistent;
begin
  if Edit <> nil then
    Result := Edit
  else
    Result := inherited GetOwner;
end;

function TACLEditButtons.Find(const P: TPoint; out AButton: TACLEditButton): Boolean;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
    if PtInRect(Items[I].SubClass.Bounds, P) then
    begin
      AButton := Items[I];
      Exit(True);
    end;
  Result := False;
end;

procedure TACLEditButtons.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Edit <> nil then
    Edit.HandlerImageChange(nil);
end;

{ TACLCustomTextEdit }

constructor TACLCustomTextEdit.Create(AOwner: TComponent);
begin
  inherited;
  FEditBox.OnInput := CheckInput;
  FButtons := TACLEditButtons.Create(Self);
  FButtonsImagesLink := TChangeLink.Create;
  FButtonsImagesLink.OnChange := HandlerImageChange;
end;

destructor TACLCustomTextEdit.Destroy;
begin
  ButtonsImages := nil;
  FreeAndNil(FButtonsImagesLink);
  FreeAndNil(FButtons);
  inherited;
end;

procedure TACLCustomTextEdit.CalculateButtons(var ARect: TRect; AIndent: Integer);
var
  I: Integer;
  LButton: TACLEditButton;
  LRect: TRect;
begin
  LRect := ARect;
  LRect.Inflate(-AIndent);
  for I := Buttons.Count - 1 downto 0 do
  begin
    LButton := Buttons.Items[I];
    LButton.Calculate(LRect);
    if LButton.Visible then
      Dec(LRect.Right, AIndent);
  end;
  ARect.Right := LRect.Right + AIndent;
end;

function TACLCustomTextEdit.CanExecute(AAction: TACLEditAction): Boolean;
begin
  Result := FEditBox.CanExecute(AAction);
end;

procedure TACLCustomTextEdit.CheckInput(
  var AText, APart1, APart2: string; var AAccept: Boolean);
var
  LString: string;
  LUnused: Variant;
begin
  if NumbersOnly = [] then
    Exit;
  if TACLEditNumberOption.Decimals in NumbersOnly then
  begin
    if FormatSettings.DecimalSeparator <> '.' then
      AText := acReplaceChar(AText, '.', FormatSettings.DecimalSeparator);
  end;

  LString := APart1 + AText + APart2;
  AAccept := CheckValue(LString, LUnused) or
    // If start entering the negative/positive number
    (TACLEditNumberOption.Signs in NumbersOnly) and acContains(LString, ['-', '+']);
end;

function TACLCustomTextEdit.CheckValue(const AText: string; out AValue: Variant): Boolean;
var
  LValue1: Double;
  LValue2: Integer;
begin
  if TACLEditNumberOption.Decimals in NumbersOnly then
  begin
    if TryStrToFloat(AText, LValue1) or
       TryStrToFloat(AText, LValue1, InvariantFormatSettings)
    then
      AValue := LValue1
    else
      Exit(False);
  end
  else
    if TryStrToInt(AText, LValue2) then
      AValue := LValue2
    else
      Exit(False);

  if not (TACLEditNumberOption.Signs in NumbersOnly) then
  begin
    if AValue < 0 then
      Exit(False);
  end;

  if not (TACLEditNumberOption.Zeros in NumbersOnly) then
  begin
    if IsZero(AValue) then
      Exit(False);
  end;

  Result := True;
end;

procedure TACLCustomTextEdit.CMHintShow(var Message: TCMHintShow);
var
  LItem: TACLEditButton;
begin
  if Buttons.Find(Message.HintInfo^.CursorPos, LItem) and (LItem.Hint <> '') then
  begin
    Message.HintInfo^.HintStr := LItem.Hint;
    Message.HintInfo^.HintWindowClass := TACLHintWindow;
  end
  else
    inherited;
end;

procedure TACLCustomTextEdit.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('InputMask', ReadInputMask, nil, False);
end;

procedure TACLCustomTextEdit.Execute(AAction: TACLEditAction);
begin
  FEditBox.Execute(AAction)
end;

function TACLCustomTextEdit.GetCursor(const P: TPoint): TCursor;
var
  LButton: TACLButtonSubClass;
begin
  if Safe.Cast(SubClasses.HitTest(P), TACLButtonSubClass, LButton) and LButton.IsEnabled then
    Result := crHandPoint
  else
    Result := inherited;
end;

function TACLCustomTextEdit.GetMaxLength: Integer;
begin
  Result := FEditBox.MaxLength;
end;

function TACLCustomTextEdit.GetPasswordChar: Boolean;
begin
  Result := FEditBox.PasswordChar <> #0;
end;

function TACLCustomTextEdit.GetReadOnly: Boolean;
begin
  Result := FEditBox.ReadOnly;
end;

function TACLCustomTextEdit.GetSelLength: Integer;
begin
  Result := FEditBox.SelLength;
end;

function TACLCustomTextEdit.GetSelStart: Integer;
begin
  Result := FEditBox.SelStart;
end;

function TACLCustomTextEdit.GetSelText: string;
begin
  Result := FEditBox.SelText;
end;

function TACLCustomTextEdit.GetText: string;
begin
  Result := FEditBox.Text;
end;

function TACLCustomTextEdit.GetTextHint: string;
begin
  Result := FEditBox.TextHint;
end;

function TACLCustomTextEdit.GetValue: Variant;
begin
  Result := TextToValue(Text);
end;

procedure TACLCustomTextEdit.HandlerImageChange(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to Buttons.Count - 1 do
    Buttons[I].SubClass.ImageList := ButtonsImages;
  FullRefresh;
end;

function TACLCustomTextEdit.InplaceGetValue: string;
begin
  Result := Value;
end;

procedure TACLCustomTextEdit.InplaceSetFocus;
begin
  SetFocus;
  Execute(eaSelectAll);
end;

procedure TACLCustomTextEdit.InplaceSetValue(const AValue: string);
begin
  Value := AValue;
end;

procedure TACLCustomTextEdit.Loaded;
begin
  inherited;
  if Text <> '' then
    Changed;
end;

procedure TACLCustomTextEdit.Localize(const ASection, AName: string);
var
  LButton: TACLEditButton;
  LSection: string;
  I: Integer;
begin
  inherited;
  TextHint := LangGet(ASection, 'th', TextHint);
  if Buttons.Count > 0 then
  begin
    LSection := LangSubSection(ASection, AName);
    if LangFile.ExistsSection(LSection) then
    begin
      Buttons.BeginUpdate;
      try
        for I := 0 to Buttons.Count - 1 do
        begin
          LButton := Buttons[I];
          LButton.Caption := LangGet(LSection, 'b[' + IntToStr(I) + ']', LButton.Caption);
        end;
      finally
        Buttons.EndUpdate;
      end;
    end;
  end;
end;

procedure TACLCustomTextEdit.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;
  if AOperation = opRemove then
  begin
    if AComponent = ButtonsImages then
      ButtonsImages := nil;
  end;
end;

procedure TACLCustomTextEdit.ReadInputMask(AReader: TReader);
var
  LIdent: string;
begin
  LIdent := AReader.ReadIdent;
  if LIdent = 'eimInteger' then
    NumbersOnly := DefaultNumbersOnlyInteger
  else if LIdent = 'eimFloat' then
    NumbersOnly := DefaultNumbersOnlyFloat
  else
    NumbersOnly := [];
end;

procedure TACLCustomTextEdit.Select(AStart, ALength: Integer; AGoForward: Boolean);
begin
  FEditBox.Select(AStart, ALength, AGoForward);
end;

procedure TACLCustomTextEdit.SetButtons(AValue: TACLEditButtons);
begin
  Buttons.Assign(AValue);
end;

procedure TACLCustomTextEdit.SetButtonsImages(const AValue: TCustomImageList);
begin
  acSetImageList(AValue, FButtonsImages, FButtonsImagesLink, Self);
end;

procedure TACLCustomTextEdit.SetMaxLength(AValue: Integer);
begin
  FEditBox.MaxLength := AValue;
end;

procedure TACLCustomTextEdit.SetNumbersOnly(AValue: TACLEditNumberOptions);
begin
  if not (TACLEditNumberOption.Digits in AValue) then
    AValue := [];
  if FNumbersOnly <> AValue then
  begin
    FNumbersOnly := AValue;
    SetTextCore(ValueToText(TextToValue(Text)));
  end;
end;

procedure TACLCustomTextEdit.SetPasswordChar(AValue: Boolean);
begin
  if AValue then
    FEditBox.PasswordChar := {$IFDEF UNICODE}#$25CF{$ELSE}'*'{$ENDIF}
  else
    FEditBox.PasswordChar := #0;
end;

procedure TACLCustomTextEdit.SetReadOnly(AValue: Boolean);
begin
  FEditBox.ReadOnly := AValue;
end;

procedure TACLCustomTextEdit.SetSelLength(AValue: Integer);
begin
  FEditBox.SelLength := AValue;
end;

procedure TACLCustomTextEdit.SetSelStart(AValue: Integer);
begin
  FEditBox.SelStart := AValue;
end;

procedure TACLCustomTextEdit.SetSelText(const AValue: string);
begin
  FEditBox.SelText := AValue;
end;

procedure TACLCustomTextEdit.SetText(const AValue: string);
begin
  if AValue <> Text then
    SetTextCore(ValueToText(TextToValue(AValue)));
end;

procedure TACLCustomTextEdit.SetTextCore(const AValue: string);
begin
  FEditBox.Text := AValue;
end;

procedure TACLCustomTextEdit.SetTextHint(const AValue: string);
begin
  FEditBox.TextHint := AValue;
end;

procedure TACLCustomTextEdit.SetValue(const AValue: Variant);
begin
  Text := ValueToText(AValue);
end;

function TACLCustomTextEdit.TextToValue(const AText: string): Variant;
begin
  if NumbersOnly = [] then
    Result := AText
  else
    if not CheckValue(AText, Result) then
    begin
      if TACLEditNumberOption.Zeros in NumbersOnly then
        Result := 0
      else
        Result := 1;
    end;
end;

function TACLCustomTextEdit.ValueToText(const AValue: Variant): string;
begin
  Result := VarToStr(AValue);
end;

end.
