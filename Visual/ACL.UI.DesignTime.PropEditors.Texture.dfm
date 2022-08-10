object ACLTextureEditorDialog: TACLTextureEditorDialog
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Texture Editor'
  ClientHeight = 466
  ClientWidth = 584
  Constraints.MinHeight = 500
  Constraints.MinWidth = 600
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 13
  object pnlPreview: TACLPanel
    AlignWithMargins = True
    Left = 8
    Top = 30
    Width = 365
    Height = 393
    Margins.Bottom = 6
    Margins.Left = 8
    Margins.Top = 7
    Align = alClient
    TabOrder = 1
    object pbDisplay: TPaintBox
      AlignWithMargins = True
      Left = 8
      Top = 38
      Width = 349
      Height = 313
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Align = alClient
      OnMouseDown = pbDisplayMouseDown
      OnMouseMove = pbDisplayMouseMove
      OnMouseUp = pbDisplayMouseUp
      OnPaint = pbDisplayPaint
    end
    object pnlToolbar: TACLPanel
      AlignWithMargins = True
      Left = 5
      Top = 5
      Width = 355
      Height = 27
      Margins.Bottom = 0
      Align = alTop
      TabOrder = 0
      AutoSize = True
      Borders = []
      object cbStretchMode: TACLComboBox
        AlignWithMargins = True
        Left = 202
        Top = 3
        Width = 150
        Height = 21
        Align = alRight
        TabOrder = 0
        Buttons = <>
        Items.Strings = (
          'StretchMode: Stretch'
          'StretchMode: Tile'
          'StretchMode: Center')
        Mode = cbmList
        Text = ''
        OnSelect = cbStretchModeSelect
      end
      object cbSource: TACLComboBox
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 193
        Height = 21
        Align = alClient
        TabOrder = 1
        Buttons = <
          item
            ImageIndex = 0
            OnClick = cbSourceButtons0Click
          end
          item
            ImageIndex = 1
            OnClick = cbSourceButtons1Click
          end>
        ButtonsImages = ilImages
        Items.Strings = (
          'StretchMode: Stretch'
          'StretchMode: Tile'
          'StretchMode: Center')
        Mode = cbmList
        Text = ''
        OnSelect = cbSourceSelect
      end
    end
    object pnlToolbarBottom: TACLPanel
      AlignWithMargins = True
      Left = 5
      Top = 357
      Width = 355
      Height = 31
      Margins.Top = 0
      Align = alBottom
      TabOrder = 1
      Borders = []
      object btnLoad: TACLButton
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 65
        Height = 25
        Cursor = crHandPoint
        Align = alLeft
        TabOrder = 0
        OnClick = btnLoadClick
        Caption = '&Load'
      end
      object btnSave: TACLButton
        AlignWithMargins = True
        Left = 74
        Top = 3
        Width = 65
        Height = 25
        Cursor = crHandPoint
        Align = alLeft
        TabOrder = 1
        OnClick = btnSaveClick
        Caption = '&Save'
      end
      object btnClear: TACLButton
        AlignWithMargins = True
        Left = 287
        Top = 3
        Width = 65
        Height = 25
        Align = alRight
        TabOrder = 2
        OnClick = btnClearClick
        Caption = '&Clear'
      end
    end
  end
  object pnlButtons: TACLPanel
    AlignWithMargins = True
    Left = 8
    Top = 432
    Width = 568
    Height = 31
    Margins.Left = 8
    Margins.Right = 8
    Align = alBottom
    TabOrder = 2
    Borders = []
    object btnOk: TACLButton
      AlignWithMargins = True
      Left = 367
      Top = 3
      Width = 96
      Height = 25
      Cursor = crHandPoint
      Align = alRight
      TabOrder = 1
      Caption = 'OK'
      Default = True
      ModalResult = 1
    end
    object btnCancel: TACLButton
      AlignWithMargins = True
      Left = 469
      Top = 3
      Width = 96
      Height = 25
      Cursor = crHandPoint
      Align = alRight
      TabOrder = 2
      Caption = 'Cancel'
      ModalResult = 2
    end
    object btnExport: TACLButton
      AlignWithMargins = True
      Left = 79
      Top = 3
      Width = 65
      Height = 25
      Cursor = crHandPoint
      Align = alLeft
      TabOrder = 0
      OnClick = btnExportClick
      Caption = '&Export'
    end
    object btnImport: TACLButton
      AlignWithMargins = True
      Left = 8
      Top = 3
      Width = 65
      Height = 25
      Cursor = crHandPoint
      Margins.Left = 8
      Align = alLeft
      TabOrder = 3
      OnClick = btnImportClick
      Caption = '&Import'
    end
  end
  object pnlSettings: TACLPanel
    AlignWithMargins = True
    Left = 376
    Top = 23
    Width = 200
    Height = 400
    Margins.Bottom = 6
    Margins.Left = 0
    Margins.Right = 8
    Margins.Top = 0
    Align = alRight
    TabOrder = 3
    Borders = []
    object gbFrames: TACLGroupBox
      AlignWithMargins = True
      Left = 3
      Top = 0
      Width = 194
      Height = 102
      Margins.Top = 0
      Align = alTop
      TabOrder = 0
      Caption = ' Frames '
      DesignSize = (
        194
        102)
      object Label1: TLabel
        Left = 16
        Top = 21
        Width = 74
        Height = 13
        Caption = 'Display Frame:'
      end
      object Label2: TLabel
        Left = 16
        Top = 44
        Width = 74
        Height = 13
        Caption = 'Frames Count:'
      end
      object seFrame: TACLSpinEdit
        Left = 96
        Top = 21
        Width = 82
        Height = 17
        Anchors = [akTop, akRight]
        TabOrder = 0
        OnChange = seFrameChange
        OptionsValue.MaxValue = 10
        OptionsValue.MinValue = 1
        Value = 1
        DesignSize = (
          82
          17)
      end
      object seMax: TACLSpinEdit
        Left = 96
        Top = 44
        Width = 82
        Height = 17
        Anchors = [akTop, akRight]
        TabOrder = 1
        OnChange = seMaxChange
        OptionsValue.MaxValue = 100
        OptionsValue.MinValue = 1
        Value = 1
        DesignSize = (
          82
          17)
      end
      object cbLayout: TACLComboBox
        Left = 16
        Top = 67
        Width = 162
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 2
        Buttons = <>
        Items.Strings = (
          'Horizontal'
          'Vertical')
        Mode = cbmList
        Text = ''
        OnSelect = cbLayoutSelect
      end
    end
    object gbMargins: TACLGroupBox
      AlignWithMargins = True
      Left = 3
      Top = 213
      Width = 194
      Height = 101
      Align = alTop
      TabOrder = 2
      Caption = ' Sizing Margins '
      object seMarginTop: TACLSpinEdit
        Left = 59
        Top = 25
        Width = 75
        Height = 17
        TabOrder = 0
        OnChange = seMarginLeftChange
        OptionsValue.MinValue = 0
        DesignSize = (
          75
          17)
      end
      object seMarginBottom: TACLSpinEdit
        Left = 59
        Top = 71
        Width = 75
        Height = 17
        TabOrder = 3
        OnChange = seMarginLeftChange
        OptionsValue.MinValue = 0
        DesignSize = (
          75
          17)
      end
      object seMarginLeft: TACLSpinEdit
        Left = 20
        Top = 48
        Width = 75
        Height = 17
        TabOrder = 1
        OnChange = seMarginLeftChange
        OptionsValue.MinValue = 0
        DesignSize = (
          75
          17)
      end
      object seMarginRight: TACLSpinEdit
        Left = 101
        Top = 48
        Width = 75
        Height = 17
        TabOrder = 2
        OnChange = seMarginLeftChange
        OptionsValue.MinValue = 0
        DesignSize = (
          75
          17)
      end
    end
    object gbContentOffsets: TACLGroupBox
      AlignWithMargins = True
      Left = 3
      Top = 108
      Width = 194
      Height = 99
      Align = alTop
      TabOrder = 1
      Caption = ' Content Offsets '
      object seContentOffsetTop: TACLSpinEdit
        Left = 59
        Top = 23
        Width = 75
        Height = 17
        TabOrder = 0
        OnChange = seContentOffsetTopChange
        OptionsValue.MaxValue = 100
        OptionsValue.MinValue = 0
        DesignSize = (
          75
          17)
      end
      object seContentOffsetBottom: TACLSpinEdit
        Left = 59
        Top = 69
        Width = 75
        Height = 17
        TabOrder = 3
        OnChange = seContentOffsetTopChange
        OptionsValue.MaxValue = 100
        OptionsValue.MinValue = 0
        DesignSize = (
          75
          17)
      end
      object seContentOffsetLeft: TACLSpinEdit
        Left = 20
        Top = 46
        Width = 75
        Height = 17
        TabOrder = 1
        OnChange = seContentOffsetTopChange
        OptionsValue.MaxValue = 100
        OptionsValue.MinValue = 0
        DesignSize = (
          75
          17)
      end
      object seContentOffsetRight: TACLSpinEdit
        Left = 101
        Top = 46
        Width = 75
        Height = 17
        TabOrder = 2
        OnChange = seContentOffsetTopChange
        OptionsValue.MaxValue = 100
        OptionsValue.MinValue = 0
        DesignSize = (
          75
          17)
      end
    end
  end
  object cbOverride: TACLCheckBox
    AlignWithMargins = True
    Left = 8
    Top = 8
    Width = 568
    Height = 15
    Cursor = crHandPoint
    Margins.Bottom = 0
    Margins.Left = 8
    Margins.Right = 8
    Margins.Top = 8
    Align = alTop
    TabOrder = 0
    Caption = 'Override StyleSource Value'
    State = cbChecked
  end
  object TextureFileDialog: TACLFileDialog
    Filter = 'PNG Images|*.png;'
    Left = 544
  end
  object ImportExportDialog: TACLFileDialog
    Filter = 'Skinned Image Set (*.acl32) |*.acl32;'
    Left = 512
  end
  object ilImages: TACLImageList
    Left = 480
    Bitmap = {
      4C49435A261100008D000000789CF3F461646462E06060611000C2FF40A028F0
      1F0A9C7CCD182000446B00B103100B0031238302444280611490007634F9FC07
      E18176C7408151FF8FFA7FD4FFA3FE1F6877D01AC0FC492A86E9774EBAF19F1C
      3C907E460623DDFFB8C04849FFB8C0A8FF47FD3FEAFF51FF0FB43B4601ED8093
      AF1D9405A251470D18C1E20D3874FEFF3F58130600FAB0DC25}
  end
end
