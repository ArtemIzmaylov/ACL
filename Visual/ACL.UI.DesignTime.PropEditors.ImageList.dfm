object frmImageListEditor: TfrmImageListEditor
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'ImageList Editor'
  ClientHeight = 408
  ClientWidth = 577
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object gbImages: TGroupBox
    AlignWithMargins = True
    Left = 10
    Top = 10
    Width = 347
    Height = 347
    Margins.Left = 10
    Margins.Top = 10
    Margins.Right = 10
    Margins.Bottom = 10
    Align = alClient
    Caption = ' Images '
    Padding.Left = 5
    Padding.Top = 1
    Padding.Right = 5
    Padding.Bottom = 5
    TabOrder = 0
    object lvImages: TListView
      AlignWithMargins = True
      Left = 10
      Top = 19
      Width = 327
      Height = 290
      Align = alClient
      Columns = <>
      HideSelection = False
      IconOptions.AutoArrange = True
      LargeImages = EditingImageList
      MultiSelect = True
      ReadOnly = True
      PopupMenu = pmImages
      TabOrder = 0
      OnSelectItem = lvImagesSelectItem
    end
    object ToolBar: TToolBar
      AlignWithMargins = True
      Left = 10
      Top = 315
      Width = 327
      Height = 22
      Align = alBottom
      AutoSize = True
      Caption = 'ToolBar'
      Images = ilImages
      TabOrder = 1
      object tbAdd: TToolButton
        Left = 0
        Top = 0
        Action = acAdd
      end
      object tbReplace: TToolButton
        Left = 23
        Top = 0
        Action = acReplace
      end
      object tbDelete: TToolButton
        Left = 46
        Top = 0
        Action = acDelete
      end
      object ToolButton6: TToolButton
        Left = 69
        Top = 0
        Width = 8
        Caption = 'ToolButton6'
        ImageIndex = 5
        Style = tbsSeparator
      end
      object tbDeleteAll: TToolButton
        Left = 77
        Top = 0
        Action = acDeleteAll
      end
      object ToolButton5: TToolButton
        Left = 100
        Top = 0
        Width = 8
        Caption = 'ToolButton5'
        ImageIndex = 5
        Style = tbsSeparator
      end
      object tbExport: TToolButton
        Left = 108
        Top = 0
        Caption = 'acExport'
        DropdownMenu = pmExport
        ImageIndex = 4
      end
    end
  end
  object pnlRight: TPanel
    AlignWithMargins = True
    Left = 367
    Top = 10
    Width = 200
    Height = 347
    Margins.Left = 0
    Margins.Top = 10
    Margins.Right = 10
    Margins.Bottom = 10
    Align = alRight
    BevelOuter = bvNone
    FullRepaint = False
    TabOrder = 1
    object gbPreview: TGroupBox
      Left = 0
      Top = 0
      Width = 200
      Height = 200
      Align = alTop
      Caption = ' Preview '
      TabOrder = 0
      object pbPreview: TPaintBox
        AlignWithMargins = True
        Left = 7
        Top = 17
        Width = 186
        Height = 176
        Margins.Left = 5
        Margins.Top = 2
        Margins.Right = 5
        Margins.Bottom = 5
        Align = alClient
        OnPaint = pbPreviewPaint
        ExplicitLeft = 71
        ExplicitTop = 41
        ExplicitWidth = 374
        ExplicitHeight = 161
      end
    end
  end
  object pnlBottom: TPanel
    AlignWithMargins = True
    Left = 10
    Top = 367
    Width = 557
    Height = 31
    Margins.Left = 10
    Margins.Top = 0
    Margins.Right = 10
    Margins.Bottom = 10
    Align = alBottom
    BevelOuter = bvNone
    FullRepaint = False
    TabOrder = 2
    object btnCancel: TButton
      AlignWithMargins = True
      Left = 479
      Top = 3
      Width = 75
      Height = 25
      Align = alRight
      Cancel = True
      Caption = '&Cancel'
      ModalResult = 2
      TabOrder = 0
    end
    object btnOK: TButton
      AlignWithMargins = True
      Left = 398
      Top = 3
      Width = 75
      Height = 25
      Align = alRight
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 1
    end
  end
  object alActions: TActionList
    Images = ilImages
    Left = 368
    Top = 216
    object acAdd: TAction
      Caption = '&Load from File...'
      ImageIndex = 0
      ShortCut = 45
      OnExecute = acAddExecute
    end
    object acReplace: TAction
      Tag = 1
      Caption = '&Replace from file...'
      ImageIndex = 1
      OnExecute = acReplaceExecute
      OnUpdate = acReplaceUpdate
    end
    object acDelete: TAction
      Caption = '&Delete'
      ImageIndex = 2
      ShortCut = 46
      OnExecute = acDeleteExecute
      OnUpdate = acDeleteUpdate
    end
    object acDeleteAll: TAction
      Caption = 'acDeleteAll'
      ImageIndex = 3
      OnExecute = acDeleteAllExecute
      OnUpdate = acDeleteAllUpdate
    end
    object acExportAsBMP: TAction
      Caption = 'Export as BMP...'
      OnExecute = acExportAsExecute
      OnUpdate = acExportAsUpdate
    end
    object acExportAsPNG: TAction
      Tag = 1
      Caption = 'Export as PNG...'
      OnExecute = acExportAsExecute
      OnUpdate = acExportAsUpdate
    end
  end
  object ilImages: TACLImageList
    Left = 400
    Top = 216
    Bitmap = {
      494C010105000900280010001000FFFFFFFF2110FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000002000000001002000000000000020
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000C5A67B00B26C3400CA8B
      580024242400242424001919190019191900191919000F0F0F000F0F0F000F0F
      0F00BA774300A1551A00B78E5D00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000BA774300EFCA9100EBC5
      880034343400323232002C2C2C002C2C2C0024242400E2B97A00E2B97A001919
      1900E2B97A00DAA65600A1551A00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000C17E4800F2CE9600EFCA
      910045454500414141003C3C3C003737370034343400E5BD7D00E4BA7C002424
      2400E2B97A00DAA65600A1551A00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000C6834E00F4D19D00F2CE
      960059595900535353004E4E4E004848480045454500E7BD8300E5BD7D003737
      3700E2B97A00DAA65600A85E2400000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000CA8B5800F6D5A500F4D1
      9D006B6B6B0066666600616161005C5C5C0057575700535353004D4D4D004848
      4800E5BD7D00DAA65600A85E2400000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000CA8B5800FADAAB00F6D5
      A500F4D19D00EFCA9100EFCA9100EBC58800EBC58800EBC58800E7BD8300E7BD
      8300E7BD8300E1AE5F00A85E2400000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000D1915D00FBDDB100F2CE
      9600F3C88600F3C88600EDC07A00ECBC7200E9B86D00E6B56900E6B56900E3B1
      6400E3B16400E1AE5F00B26C3400000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000D99B6800FFE4BB00E3AF
      7900E3AF7900E3B27500E3B27500E4AF6E00E4AF6E00E2AD6800E2AD6800E2AD
      6800E2AD6800E3B16400B26C3400000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000D99B6800FFE4BB00E3AF
      7900FCFCFC00FCFCFC00FAFAFA00FAFAFA00F8F8F800F8F8F800F6F6F600F6F6
      F600E2AD6800E6B56900B26C3400000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000DFA47100FFE6C200DFA4
      7100FEFEFE00D6D6D600D6D6D600D6D6D600D6D6D600D2D2D200D2D2D200F8F8
      F800E0A96A00E6B56900BA774300000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000DFA47100FFECC900DFA4
      7100FFFFFF00FFFFFF00FEFEFE00FEFEFE00FCFCFC00FCFCFC00FAFAFA00FAFA
      FA00E0A96A00E9B86D00BA774300000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000E4A77500FFEFCF00D99B
      6800FFFFFF00D9D9D900D9D9D900D9D9D900D9D9D900D6D6D600D6D6D600FCFC
      FC00E0A96A00ECBC7200C17E4800000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000E4A77500FFF4D400DFAE
      8500FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FCFC
      FC00E7BD8300EFCA9100C6834E00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000E2CFB000E4A77500E4A7
      7500D9D9D900D9D9D900D9D9D900D9D9D900D9D9D900D9D9D900D9D9D900D9D9
      D900D1915D00CA8B5800CCB59200000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000A559060000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000005B60BD0000000000000000004E4E4E004D4D4D004D4D4D004B4B
      4B004B4B4B004848480047474700474747004545450043434300434343004343
      4300000000000000000000000000000000007A7A7A007A7A7A00777777007777
      7700777777007575750075757500757575007373730070707000707070000000
      0000A5590600A5590600A5590600CCB592004E4E4E004D4D4D004D4D4D004B4B
      4B004B4B4B004848480047474700474747004545450043434300434343004343
      4300000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000099A2D3005B60BD000000000000000000515151006BCE7D006BCE7D0069CF
      7F0068CF800068D0810067D1830067D1840065D2860065D2860064D388004545
      4500000000000000000000000000000000007D7D7D008FDA9D008FDA9D008FDA
      9D008EDBA0008DDCA1008DDCA1008CDDA4008CDDA4008CDDA400737373000000
      000000000000A5590600D3CFC200A5590600515151006BCE7D006BCE7D0069CF
      7F0068CF800068D0810067D1830067D1840065D2860065D2860064D388004545
      450000000000000000000000000000000000C9D5EB0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00004B4FB40099A2D30000000000000000005454540064D388002FC562002EC7
      65002EC765002DC869002DC869002ECA6D002ECA6D0030CB700064D995004747
      4700000000000000000000000000000000007D7D7D008BDEA50062D3890062D3
      890062D58C0062D58C0061D7900061D7900061D790008CE3AF00757575000000
      0000000000000000000000000000A55906005454540064D388002FC562002EC7
      65002EC765002DC869002DC869002ECA6D002ECA6D0030CB700064D995004747
      4700000000000000000000000000000000008991DA0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008A92
      CF004B4FB4000000000000000000000000005757570068D9960041CF7A004CD1
      81005CD68C0072DB9C0085E1A900A1E7BB00BDEDCD00E4F1DB00F2F5E6004B4B
      4B0000000000000000000000000000000000818181008CE3AF0072DB9C0078DC
      A00085E1A90095E4B400A1E7BB00BDEDCD00D1EFD400EDF6E700777777000000
      0000000000000000000000000000000000005757570068D9960041CF7A004CD1
      81005CD68C0072DB9C0085E1A900A1E7BB00BDEDCD00E4F1DB00F2F5E6004B4B
      4B00000000000000000000000000000000007C84D900A4ADE400000000000000
      0000000000000000000000000000000000000000000000000000B5C0E7002C2E
      AF00929BD10000000000000000000000000059595900D1EFD400E4F1DB00F6F1
      DD00F9F2DF00FDF3E100FDF3E100FDF4E200FFF4E600FFF4E600FFF8EE004D4D
      4D000000000000000000000000000000000081818100E4F1DB00EDF6E700F9F5
      E600F9F5E6004E4E4E004D4D4D004D4D4D004B4B4B004B4B4B00484848004747
      47004747470045454500434343004343430059595900D1EFD400E4F1DB00F6F1
      DD00F9F2DF00FDF3E100FDF3E100FDF4E200FFF4E600FFF4E600FFF8EE004D4D
      4D000000000000000000969FD30000000000AEB8E5005D62D600000000000000
      00000000000000000000000000000000000000000000000000005B60BD005B60
      BD00000000000000000000000000000000005C5C5C00FFF6EA00FFF3E300FFF3
      E300FFF3E100FFF2DF00FFF1DE00FFF1DE00FFF1DD00FFF1DD0003531900034F
      1800034F180000000000000000000000000085858500FFF8EE00FFF6EA00FFF6
      EA00FFF6EA00515151006BCE7D006BCE7D0069CF7F0068CF800068D0810067D1
      830067D1840065D2860065D28600454545005C5C5C00FFF6EA00FFF3E300FFF3
      E300FFF3E100FFF2DF00EFE2DC00FFF1DE00FFF1DD00FFF1DD00FFF3E3004E4E
      4E0000000000969FD300929BD10000000000000000006D73DD005D62D6000000
      000000000000000000000000000000000000000000007178CF002C2EAF00AEB8
      E500000000000000000000000000000000005E5E5E00FFF0DA00FFEBCE00FFEA
      CC00FFEACC00FFE9CA00FFE9C800FFE8C700FFE7C400FFE7C40002591B000FCD
      69000353190000000000000000000000000085858500FFF3E300FFF0DA00FFF0
      DA00FFF0DA005454540064D388002FC562002EC765002EC765002DC869002DC8
      69002ECA6D002ECA6D0064D99500484848005E5E5E00FFF0DA00FFEBCE00FFEA
      CC00FFEACC00FFE9CA00B7A8CA00E7D3C600FFE7C400FFE7C400FFEDD3005353
      5300C9D5EB005B60BD00000000000000000000000000000000003F42D200646A
      D800000000000000000000000000000000007C84D9001515BC008991DA000000
      00000000000000000000000000000000000061616100FFE8C700FFDFB300FFDE
      B000FFDEB000FFDDAE00FFDDAD00FFDCAB00FFDBAA00FFDAA600025E1D000FCD
      690002561A0000000000000000000000000089898900FFEDD300FFE7C600FFE7
      C400FFE7C4005757570068D9960041CF7A004CD181005CD68C0072DB9C0085E1
      A900A1E7BB00BDEDCD00EDF6E7004B4B4B0061616100FFE8C700FFDFB300FFDE
      B000FFDEB000FFDDAE00C4ABB6008B78B700FADAAB00FFDAA600FFE4BB005353
      53006469CA00969FD300000000000000000000000000000000009BA4E3001F21
      CD00585CD60000000000000000007C84D9001515BC007177D400000000000000
      00000000000000000000000000000000000064646400FFDEB000FFDDAE00FFDD
      AD00FFDDAD00FFDCAB00FFDBAA0003752800037025000269220002641F0027D8
      7C00025E1D0002591B0002561A00035319008A8A8A00FFE6C200FFE6C200FFE6
      C200FFE6C20059595900D1EFD400E4F1DB00F6F1DD00F9F2DF00FDF3E100FDF3
      E100FDF4E200FFF4E600FFF8EE004E4E4E0064646400FFDEB000FFDDAE00FFDD
      AD00FFDDAD00FFDBAA00FADAAB008B78B7008B78B700FFDAA600FFDAA6002A2A
      94006469CA00000000000000000000000000000000000000000000000000858D
      E1001011CA00383AD600474BD3000B0BC500646AD80000000000000000000000
      0000000000000000000000000000000000006666660066666600646464006363
      6300636363006161610061616100037C2C006FF0B0006FF0B00053E89C003CE0
      8A0027D87C000FCD69000FCD690002561A008D8D8D008A8A8A008A8A8A008A8A
      8A00898989005C5C5C00FFF6EA00FFF3E300FFF3E300FFF3E100FFF2DF00FFF1
      DE00FFF1DE00FFF1DD00FFF4E600515151006666660066666600646464006363
      6300636363006161610061616100595966002A2A94002A2A94002A2A94002A2A
      9400000000000000000000000000000000000000000000000000000000000000
      0000646AD8000A0BCC000505C9002E30CE00A4ADE40000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000387330003873300037C2C000375280053E8
      9C000269220002641F00025E1D0002591B000000000000000000000000000000
      0000000000005E5E5E00FFF0DA00FFEBCE00FFEACC00FFEACC00FFE9CA00FFE9
      C800FFE8C700FFE7C400FFEDD300545454000000000000000000000000000000
      000000000000000000000000000000000000AEB8E5000A0BCC000505C9007C84
      D90000000000000000000000000000000000000000000000000000000000858D
      E1002C2FD7000A0BCC001A1BCD000505C9001A1BCD005D62D6009BA4E3000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000037C2C006FF0
      B00003702500000000000000000000000000C6731B0000000000000000000000
      00000000000061616100FFE8C700FFDFB300FFDEB000FFDEB000FFDDAE00FFDD
      AD00FFDCAB00FFDBAA00FFE4BB00575757000000000000000000000000000000
      00000000000000000000C9D5EB007D84E4002C2FD7006D73DD006D73DD001011
      CA001F21CD005D62D6008991DA00C9D5EB0000000000A4ADE4004E52D9000808
      D5003033D5008B93E200A4ADE4004E52D9000505C9000505C6000505C6002E30
      CE005D62D600838ADB00A4ADE400000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000387330087F6
      C100037C2C00000000000000000000000000C9761D00DAD4C600C6731B000000
      00000000000064646400FFDEB000FFDDAE00FFDDAD00FFDDAD00FFDCAB00FFDB
      AA00FFDBAA00FFDAA600FFDAA600595959000000000000000000000000000000
      000000000000000000007D84E400383AD6009BA4E3000000000000000000AEB8
      E5004E52D9001011CA000505C500474BD3005D63E2000808D5000808D5005E63
      DF00B5C0E700000000000000000000000000858DE100383AD6000505C9000505
      C6000505C5000505C5000505C0007C84D9000000000000000000000000000000
      000000000000000000000000000000000000000000000000000004943A000387
      330003873300000000000000000000000000D8C3A600CB781E00C9761D00C673
      1B00000000006666660066666600646464006363630063636300616161006161
      61005E5E5E005E5E5E005E5E5E005C5C5C000000000000000000000000000000
      00000000000000000000C9D5EB00C9D5EB000000000000000000000000000000
      000000000000B5C0E7007D84E4008B93E2007D84E4005D63E200959EE7000000
      0000000000000000000000000000000000000000000000000000858DE100474B
      D3001011CA000505C6000505C5001F21C7000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CB781E000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000B5C0E700858DE1005D62D6009BA4E300424D3E000000000000003E000000
      2800000040000000200000000100010000000000000100000000000000000000
      000000000000000000000000FFFFFF00FFFF0000000000008001000000000000
      8001000000000000800100000000000080010000000000008001000000000000
      8001000000000000800100000000000080010000000000008001000000000000
      8001000000000000800100000000000080010000000000008001000000000000
      8001000000000000FFFF000000000000FFFFFFFBFFFFFFFB000F0010000FFFF3
      000F0018000F7FF3000F001E000F7FE7000F001F000F3FC7000F0000000D3FCF
      0007000000099F8F000700000003CF1F000700000003C63F000000000007E07F
      00000000000FF07FFE00F800FF0FE01FFFC77800FC008001FFC71800FC600700
      FFC70800FCF81FC0FFFFDFFFFFFFFFF000000000000000000000000000000000
      000000000000}
  end
  object pmImages: TPopupMenu
    Left = 24
    Top = 32
    object miAdd: TMenuItem
      Action = acAdd
    end
    object miReplace: TMenuItem
      Action = acReplace
    end
    object miLine1: TMenuItem
      Caption = '-'
    end
    object miExportasBMP2: TMenuItem
      Action = acExportAsBMP
    end
    object miExportasPNG2: TMenuItem
      Action = acExportAsPNG
    end
    object miLine2: TMenuItem
      Caption = '-'
    end
    object miDelete: TMenuItem
      Action = acDelete
    end
  end
  object pmExport: TPopupMenu
    Left = 136
    Top = 336
    object miExportAsBMP: TMenuItem
      Action = acExportAsBMP
    end
    object miExportAsPNG: TMenuItem
      Action = acExportAsPNG
    end
  end
  object EditingImageList: TACLImageList
    OnChange = EditingImageListChange
    Left = 56
    Top = 32
  end
  object FileDialog: TACLFileDialog
    Options = [ofOverwritePrompt, ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing, ofAutoExtension]
    Left = 88
    Top = 32
  end
end