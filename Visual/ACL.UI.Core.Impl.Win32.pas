////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v7.0
//
//  Purpose:   Win32 Adapters and Helpers
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit ACL.UI.Core.Impl.Win32;

{$I ACL.Config.inc}

interface

uses
  Messages,
  Windows,
  // System
  Types,
  // VCL
  Controls,
  Forms;

const
  MSGF_COMMCTRL_BEGINDRAG = $4200;

type

  { TACLStartDragHelper }

  TACLStartDragHelper = class
  public
    class function Check(AControl: TWinControl; X, Y, AThreshold: Integer): Boolean; static;
  end;

  { TACLWSScrollingControl }

  TACLWSScrollingControl = class
  public
    class procedure DispatchNonClientMessage(
      AControl: TWinControl; var AMessage: TMessage); static;
  end;

function IsAlphaComposingSupports: Boolean;
procedure SetWindowStayOnTop(AWnd: HWND; AValue: Boolean);
implementation

function IsAlphaComposingSupports: Boolean;
begin
  Result := True;
end;

class function TACLStartDragHelper.Check(AControl: TWinControl; X, Y, AThreshold: Integer): Boolean;
var
  LMsg: TMsg;
  LTarget: TRect;
  LWnd: HWND;
begin
  Result := False;
  LWnd := AControl.Handle;
  LTarget := Rect(X - AThreshold, Y - AThreshold, X + AThreshold, Y + AThreshold);
  MapWindowPoints(LWnd, HWND_DESKTOP, &LTarget, 2);

  //  SUBTLE!  We use PeekMessage+WaitMessage instead of GetMessage,
  //  because WaitMessage will return when there is an incoming
  //  SendMessage, whereas GetMessage does not.  This is important,
  //  because the incoming message might've been WM_CAPTURECHANGED.
  SetCapture(LWnd);
  repeat
    if PeekMessage(LMsg, 0, 0, 0, PM_REMOVE) then
    begin
      // See if the application wants to process the message...
      if CallMsgFilter(LMsg, MSGF_COMMCTRL_BEGINDRAG) then
        Continue;

      case LMsg.message of
        WM_MOUSEWHEEL, WM_MOUSEHWHEEL,
        WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_LBUTTONUP, WM_RBUTTONUP:
          begin
            ReleaseCapture;
            Exit(False);
          end;

        WM_MOUSEMOVE:
          if IsWindow(LWnd) and not LTarget.Contains(LMsg.pt) then
          begin
            ReleaseCapture;
            Exit(True);
          end;

      else
        TranslateMessage(LMsg);
        DispatchMessage(LMsg);
      end;
    end
    else
      WaitMessage;
  until not (IsWindow(LWnd) and (GetCapture = LWnd));
end;

procedure SetWindowStayOnTop(AWnd: HWND; AValue: Boolean);
const
  StyleMap: array[Boolean] of HWND = (HWND_NOTOPMOST, HWND_TOPMOST);
begin
  if AWnd = 0 then
    Exit;
  if AValue <> (GetWindowLong(AWnd, GWL_EXSTYLE) and WS_EX_TOPMOST <> 0) then
  begin
    SetWindowPos(AWnd, StyleMap[AValue], 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);
  end;
end;

{ TACLWSScrollingControl }

class procedure TACLWSScrollingControl.DispatchNonClientMessage(
  AControl: TWinControl; var AMessage: TMessage);
var
  LDC: HDC;
begin
  case AMessage.Msg of
    WM_NCCALCSIZE:
      TWMNCCalcSize(AMessage).CalcSize_Params.rgrc[0].Inflate(-2, -2);
    WM_NCPAINT:
      begin
        LDC := GetWindowDC(AControl.Handle);
        if LDC <> 0 then
        try
          AMessage.LParam := LDC;
          AControl.Dispatch(AMessage);
        finally
          DeleteDC(LDC);
        end;
      end;
  end;
end;

end.
