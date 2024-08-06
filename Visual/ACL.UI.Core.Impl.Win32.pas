////////////////////////////////////////////////////////////////////////////////
//
//  Project:   Artem's Controls Library aka ACL
//             v6.0
//
//  Purpose:   Win32 Adapters and Helpers
//
//  Author:    Artem Izmaylov
//             © 2006-2024
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
  Controls;

const
  MSGF_COMMCTRL_BEGINDRAG = $4200;

function CheckStartDragImpl(AControl: TWinControl; X, Y, AThreshold: Integer): Boolean;
implementation

function CheckStartDragImpl(AControl: TWinControl; X, Y, AThreshold: Integer): Boolean;
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

end.
