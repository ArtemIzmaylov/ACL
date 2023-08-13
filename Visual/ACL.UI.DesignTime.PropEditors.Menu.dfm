object ACLMenuEditorDialog: TACLMenuEditorDialog
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  ClientHeight = 320
  ClientWidth = 240
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnClose = FormClose
  TextHeight = 15
  object lvItems: TACLTreeList
    Left = 0
    Top = 0
    Width = 240
    Height = 320
    Align = alClient
    PopupMenu = pmMenu
    TabOrder = 0
    Columns = <>
    OptionsBehavior.DragSorting = True
    OptionsBehavior.DragSortingAllowChangeLevel = True
    OptionsView.Borders = []
    OptionsView.Columns.Visible = False
    OptionsView.Nodes.GridLines = []
    OnCustomDrawNodeCell = lvItemsCustomDrawNodeCell
    OnDragSortingNodeDrop = lvItemsDragSortingNodeDrop
    OnFocusedNodeChanged = lvItemsFocusedNodeChanged
  end
  object pmMenu: TACLPopupMenu
    Left = 88
    Top = 32
    object miCreateItem: TMenuItem
      Caption = '&Create Item'
      ShortCut = 45
      OnClick = miCreateItemClick
    end
    object miCreateSeparator: TMenuItem
      Caption = 'Create Separator'
      OnClick = miCreateSeparatorClick
    end
    object miCreateLink: TMenuItem
      Caption = 'Create Link'
      OnClick = miCreateLinkClick
    end
    object miCreateList: TMenuItem
      Caption = 'Create List'
      OnClick = miCreateListClick
    end
    object miLine1: TMenuItem
      Caption = '-'
    end
    object miDelete: TACLMenuItem
      Caption = '&Delete'
      ShortCut = 46
      OnClick = miDeleteClick
    end
  end
end
