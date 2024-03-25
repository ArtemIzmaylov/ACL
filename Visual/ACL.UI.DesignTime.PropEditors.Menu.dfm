object ACLMenuEditorDialog: TACLMenuEditorDialog
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  ClientHeight = 523
  ClientWidth = 503
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object lvItems: TACLTreeList
    AlignWithMargins = True
    Left = 6
    Top = 6
    Width = 373
    Height = 511
    Margins.All = 6
    Align = alClient
    PopupMenu = pmMenu
    TabOrder = 0
    Columns = <
      item
      end
      item
        CanResize = False
        TextAlign = taRightJustify
      end>
    OptionsBehavior.DragSorting = True
    OptionsBehavior.DragSortingAllowChangeLevel = True
    OptionsView.Columns.AutoWidth = True
    OptionsView.Columns.Visible = False
    OptionsView.Nodes.GridLines = []
    OnDragSortingNodeDrop = lvItemsDragSortingNodeDrop
    OnFocusedNodeChanged = lvItemsFocusedNodeChanged
    OnGetNodeCellDisplayText = lvItemsGetNodeCellDisplayText
  end
  object pnlRight: TACLPanel
    AlignWithMargins = True
    Left = 385
    Top = 6
    Width = 112
    Height = 511
    Margins.Bottom = 6
    Margins.Left = 0
    Margins.Right = 6
    Margins.Top = 6
    Align = alRight
    TabOrder = 1
    Borders = []
    object btnCreateItem: TACLButton
      AlignWithMargins = True
      Left = 0
      Top = 0
      Width = 112
      Height = 25
      Margins.Bottom = 6
      Margins.Left = 0
      Margins.Right = 0
      Margins.Top = 0
      Align = alTop
      TabOrder = 0
      Action = acCreateItem
    end
    object btnCreateSubItem: TACLButton
      AlignWithMargins = True
      Left = 0
      Top = 31
      Width = 112
      Height = 25
      Margins.Bottom = 6
      Margins.Left = 0
      Margins.Right = 0
      Margins.Top = 0
      Align = alTop
      TabOrder = 1
      Action = acCreateSubItem
    end
    object pnlBottom: TACLPanel
      AlignWithMargins = True
      Left = 0
      Top = 74
      Width = 112
      Height = 437
      Margins.Bottom = 0
      Margins.Left = 0
      Margins.Right = 0
      Margins.Top = 12
      Align = alClient
      TabOrder = 2
      Borders = []
      object btnDelete: TACLButton
        AlignWithMargins = True
        Left = 0
        Top = 74
        Width = 112
        Height = 25
        Margins.Bottom = 0
        Margins.Left = 0
        Margins.Right = 0
        Margins.Top = 12
        Align = alTop
        TabOrder = 2
        Action = acDelete
      end
      object btnMoveDown: TACLButton
        AlignWithMargins = True
        Left = 0
        Top = 31
        Width = 112
        Height = 25
        Margins.Bottom = 6
        Margins.Left = 0
        Margins.Right = 0
        Margins.Top = 0
        Align = alTop
        TabOrder = 0
        Action = acMoveDown
      end
      object btnMoveUp: TACLButton
        AlignWithMargins = True
        Left = 0
        Top = 0
        Width = 112
        Height = 25
        Margins.Bottom = 6
        Margins.Left = 0
        Margins.Right = 0
        Margins.Top = 0
        Align = alTop
        TabOrder = 1
        Action = acMoveUp
      end
    end
  end
  object pmMenu: TACLPopupMenu
    Left = 64
    Top = 40
    object miCreateItem: TMenuItem
      Action = acCreateItem
    end
    object miCreateSubItem: TACLMenuItem
      Action = acCreateSubItem
    end
    object miLine0: TACLMenuItem
      Caption = '-'
    end
    object miMoveUp: TACLMenuItem
      Action = acMoveUp
    end
    object miMoveDown: TACLMenuItem
      Action = acMoveDown
    end
    object miLine1: TMenuItem
      Caption = '-'
    end
    object miDelete: TACLMenuItem
      Action = acDelete
    end
  end
  object Actions: TActionList
    Left = 120
    Top = 40
    object acCreateItem: TAction
      Caption = '&Create Item'
      ShortCut = 45
      OnExecute = acCreateItemExecute
    end
    object acCreateSubItem: TAction
      Tag = 1
      Caption = 'Create &Sub Item'
      ShortCut = 16429
      OnExecute = acCreateItemExecute
    end
    object acDelete: TAction
      Caption = '&Delete'
      OnExecute = acDeleteExecute
      OnUpdate = acDeleteUpdate
    end
    object acMoveDown: TAction
      Tag = 1
      Caption = 'Move &Down'
      ShortCut = 16424
      OnExecute = acMoveExecute
      OnUpdate = acMoveUpdate
    end
    object acMoveUp: TAction
      Tag = -1
      Caption = 'Move &Up'
      ShortCut = 16422
      OnExecute = acMoveExecute
      OnUpdate = acMoveUpdate
    end
  end
end
