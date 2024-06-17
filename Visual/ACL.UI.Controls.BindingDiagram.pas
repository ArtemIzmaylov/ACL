////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Binding Diagram
//
//  Author:    Artem Izmaylov
//             © 2006-2024
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Controls.BindingDiagram;

{$I ACL.Config.inc}

interface

uses
  {System.}Classes,
  {System.}SysUtils,
  // Vcl
  {Vcl.}Graphics,
  {Vcl.}Controls,
  // ACL
  ACL.Geometry,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.BindingDiagram.SubClass,
  ACL.UI.Controls.BindingDiagram.Types,
  ACL.UI.Controls.CompoundControl,
  ACL.UI.Controls.CompoundControl.SubClass,
  ACL.UI.Forms,
  ACL.UI.Resources,
  ACL.Utils.Common;

type

  { TACLBindingDiagram }

  TACLBindingDiagram = class(TACLCompoundControl)
  strict private
    FBorders: TACLBorders;

    function GetData: TACLBindingDiagramData; inline;
    function GetOnLinkChanged: TACLBindingDiagramLinkNotifyEvent;
    function GetOnLinkChanging: TACLBindingDiagramLinkChangingEvent;
    function GetOnLinkCreated: TACLBindingDiagramLinkNotifyEvent;
    function GetOnLinkCreating: TACLBindingDiagramLinkCreatingEvent;
    function GetOnLinkRemoving: TACLBindingDiagramLinkAcceptEvent;
    function GetOnObjectRemoving: TACLBindingDiagramObjectAcceptEvent;
    function GetOnSelectionChanged: TNotifyEvent;
    function GetOptionsBehavior: TACLBindingDiagramOptionsBehavior; inline;
    function GetOptionsView: TACLBindingDiagramOptionsView; inline;
    function GetSelectedObject: TObject;
    function GetSelectedObjectAsLink: TACLBindingDiagramLink;
    function GetSelectedObjectAsObject: TACLBindingDiagramObject;
    function GetStyle: TACLStyleBindingDiagram; inline;
    function GetSubClass: TACLBindingDiagramSubClass; inline;
    function GetViewInfo: TACLBindingDiagramSubClassViewInfo; inline;
    procedure SetBorders(const Value: TACLBorders);
    procedure SetOnLinkChanged(const Value: TACLBindingDiagramLinkNotifyEvent);
    procedure SetOnLinkChanging(const Value: TACLBindingDiagramLinkChangingEvent);
    procedure SetOnLinkCreated(const Value: TACLBindingDiagramLinkNotifyEvent);
    procedure SetOnLinkCreating(const Value: TACLBindingDiagramLinkCreatingEvent);
    procedure SetOnLinkRemoving(const Value: TACLBindingDiagramLinkAcceptEvent);
    procedure SetOnObjectRemoving(const Value: TACLBindingDiagramObjectAcceptEvent); inline;
    procedure SetOnSelectionChanged(const Value: TNotifyEvent);
    procedure SetOptionsBehavior(const Value: TACLBindingDiagramOptionsBehavior);
    procedure SetOptionsView(const Value: TACLBindingDiagramOptionsView); inline;
    procedure SetSelectedObject(const Value: TObject);
    procedure SetStyle(const Value: TACLStyleBindingDiagram); inline;
  protected
    function CreateSubClass: TACLCompoundControlSubClass; override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure DeleteSelectedObject;
    //# Properties
    property Data: TACLBindingDiagramData read GetData;
    property SelectedObject: TObject read GetSelectedObject write SetSelectedObject;
    property SelectedObjectAsLink: TACLBindingDiagramLink read GetSelectedObjectAsLink;
    property SelectedObjectAsObject: TACLBindingDiagramObject read GetSelectedObjectAsObject;
    property SubClass: TACLBindingDiagramSubClass read GetSubClass;
    property ViewInfo: TACLBindingDiagramSubClassViewInfo read GetViewInfo;
  published
    property Borders: TACLBorders read FBorders write SetBorders default [];
    property DoubleBuffered default True;
    property Font;
    property Padding;
    property OptionsBehavior: TACLBindingDiagramOptionsBehavior read GetOptionsBehavior write SetOptionsBehavior;
    property OptionsView: TACLBindingDiagramOptionsView read GetOptionsView write SetOptionsView;
    property ResourceCollection;
    property Style: TACLStyleBindingDiagram read GetStyle write SetStyle;
    property StyleHint;
    property StyleScrollBox;
    property Transparent;
    //# Events
    property OnClick;
    property OnDblClick;
    property OnLinkChanged: TACLBindingDiagramLinkNotifyEvent read GetOnLinkChanged write SetOnLinkChanged;
    property OnLinkChanging: TACLBindingDiagramLinkChangingEvent read GetOnLinkChanging write SetOnLinkChanging;
    property OnLinkCreated: TACLBindingDiagramLinkNotifyEvent read GetOnLinkCreated write SetOnLinkCreated;
    property OnLinkCreating: TACLBindingDiagramLinkCreatingEvent read GetOnLinkCreating write SetOnLinkCreating;
    property OnLinkRemoving: TACLBindingDiagramLinkAcceptEvent read GetOnLinkRemoving write SetOnLinkRemoving;
    property OnObjectRemoving: TACLBindingDiagramObjectAcceptEvent read GetOnObjectRemoving write SetOnObjectRemoving;
    property OnSelectionChanged: TNotifyEvent read GetOnSelectionChanged write SetOnSelectionChanged;
  end;

implementation

{ TACLBindingDiagram }

constructor TACLBindingDiagram.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FocusOnClick := True;
  DoubleBuffered := True;
  ControlStyle := ControlStyle + [csAcceptsControls];
end;

procedure TACLBindingDiagram.DeleteSelectedObject;
begin
  SubClass.RemoveSelected;
end;

function TACLBindingDiagram.CreateSubClass: TACLCompoundControlSubClass;
begin
  Result := TACLBindingDiagramSubClass.Create(Self);
end;

procedure TACLBindingDiagram.Paint;
begin
  Style.Draw(Canvas, ClientRect, Transparent, Borders);
  inherited;
end;

function TACLBindingDiagram.GetData: TACLBindingDiagramData;
begin
  Result := SubClass.Data;
end;

function TACLBindingDiagram.GetOnLinkChanged: TACLBindingDiagramLinkNotifyEvent;
begin
  Result := SubClass.OnLinkChanged;
end;

function TACLBindingDiagram.GetOnLinkChanging: TACLBindingDiagramLinkChangingEvent;
begin
  Result := SubClass.OnLinkChanging;
end;

function TACLBindingDiagram.GetOnLinkCreated: TACLBindingDiagramLinkNotifyEvent;
begin
  Result := SubClass.OnLinkCreated;
end;

function TACLBindingDiagram.GetOnLinkCreating: TACLBindingDiagramLinkCreatingEvent;
begin
  Result := SubClass.OnLinkCreating;
end;

function TACLBindingDiagram.GetOnLinkRemoving: TACLBindingDiagramLinkAcceptEvent;
begin
  Result := SubClass.OnLinkRemoving;
end;

function TACLBindingDiagram.GetOnObjectRemoving: TACLBindingDiagramObjectAcceptEvent;
begin
  Result := SubClass.OnObjectRemoving;
end;

function TACLBindingDiagram.GetOnSelectionChanged: TNotifyEvent;
begin
  Result := SubClass.OnSelectionChanged;
end;

function TACLBindingDiagram.GetOptionsBehavior: TACLBindingDiagramOptionsBehavior;
begin
  Result := SubClass.OptionsBehavior;
end;

function TACLBindingDiagram.GetOptionsView: TACLBindingDiagramOptionsView;
begin
  Result := SubClass.OptionsView;
end;

function TACLBindingDiagram.GetSelectedObject: TObject;
begin
  Result := SubClass.SelectedObject;
end;

function TACLBindingDiagram.GetSelectedObjectAsLink: TACLBindingDiagramLink;
begin
  if SelectedObject is TACLBindingDiagramLink then
    Result := TACLBindingDiagramLink(SelectedObject)
  else
    Result := nil
end;

function TACLBindingDiagram.GetSelectedObjectAsObject: TACLBindingDiagramObject;
begin
  if SelectedObject is TACLBindingDiagramObject then
    Result := TACLBindingDiagramObject(SelectedObject)
  else
    Result := nil
end;

function TACLBindingDiagram.GetStyle: TACLStyleBindingDiagram;
begin
  Result := TACLBindingDiagramSubClass(SubClass).Style;
end;

function TACLBindingDiagram.GetSubClass: TACLBindingDiagramSubClass;
begin
  Result := TACLBindingDiagramSubClass(inherited SubClass);
end;

function TACLBindingDiagram.GetViewInfo: TACLBindingDiagramSubClassViewInfo;
begin
  Result := TACLBindingDiagramSubClassViewInfo(SubClass.ViewInfo);
end;

procedure TACLBindingDiagram.SetBorders(const Value: TACLBorders);
begin
  if FBorders <> Value then
  begin
    FBorders := Value;
    FullRefresh;
  end;
end;

procedure TACLBindingDiagram.SetOnLinkChanged(const Value: TACLBindingDiagramLinkNotifyEvent);
begin
  SubClass.OnLinkChanged := Value;
end;

procedure TACLBindingDiagram.SetOnLinkChanging(const Value: TACLBindingDiagramLinkChangingEvent);
begin
  SubClass.OnLinkChanging := Value;
end;

procedure TACLBindingDiagram.SetOnLinkCreated(const Value: TACLBindingDiagramLinkNotifyEvent);
begin
  SubClass.OnLinkCreated := Value;
end;

procedure TACLBindingDiagram.SetOnLinkCreating(const Value: TACLBindingDiagramLinkCreatingEvent);
begin
  SubClass.OnLinkCreating := Value;
end;

procedure TACLBindingDiagram.SetOnLinkRemoving(const Value: TACLBindingDiagramLinkAcceptEvent);
begin
  SubClass.OnLinkRemoving := Value;
end;

procedure TACLBindingDiagram.SetOnObjectRemoving(const Value: TACLBindingDiagramObjectAcceptEvent);
begin
  SubClass.OnObjectRemoving := Value;
end;

procedure TACLBindingDiagram.SetOnSelectionChanged(const Value: TNotifyEvent);
begin
  SubClass.OnSelectionChanged := Value;
end;

procedure TACLBindingDiagram.SetOptionsBehavior(const Value: TACLBindingDiagramOptionsBehavior);
begin
  OptionsBehavior.Assign(Value);
end;

procedure TACLBindingDiagram.SetOptionsView(const Value: TACLBindingDiagramOptionsView);
begin
  OptionsView.Assign(Value);
end;

procedure TACLBindingDiagram.SetSelectedObject(const Value: TObject);
begin
  SubClass.SelectedObject := Value;
end;

procedure TACLBindingDiagram.SetStyle(const Value: TACLStyleBindingDiagram);
begin
  Style.Assign(Value);
end;

end.
