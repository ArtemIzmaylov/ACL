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
unit ACL.UI.Application.Win;

{$I ACL.Config.inc}

interface

uses
  Messages,
  Windows,
  // VCL
  Controls;

function CheckStartDragImpl(AControl: TWinControl; X, Y, AThreshold: Integer): Boolean;
implementation

end.
