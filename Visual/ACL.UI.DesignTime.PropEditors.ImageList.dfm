object frmImageListEditor: TfrmImageListEditor
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'ImageList Editor'
  ClientHeight = 424
  ClientWidth = 618
  Constraints.MinHeight = 480
  Constraints.MinWidth = 640
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 13
  object gbImages: TACLGroupBox
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 406
    Height = 381
    Align = alClient
    TabOrder = 0
    Caption = ' Images '
    Padding.Top = 8
    object lvImages: TListView
      Left = 7
      Top = 15
      Width = 392
      Height = 329
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
    object pnlToolbar: TACLPanel
      AlignWithMargins = True
      Left = 7
      Top = 350
      Width = 392
      Height = 24
      Margins.Bottom = 0
      Margins.Left = 0
      Margins.Right = 0
      Margins.Top = 6
      Align = alBottom
      TabOrder = 1
      Borders = []
      object btnAdd: TACLButton
        AlignWithMargins = True
        Left = 0
        Top = 0
        Width = 24
        Height = 24
        Margins.Bottom = 0
        Margins.Left = 0
        Margins.Top = 0
        Align = alLeft
        TabOrder = 0
        Action = acAdd
        FocusOnClick = False
        ShowCaption = False
        ImageIndex = 0
        Images = ilImages
      end
      object btnReplace: TACLButton
        AlignWithMargins = True
        Left = 27
        Top = 0
        Width = 24
        Height = 24
        Margins.Bottom = 0
        Margins.Left = 0
        Margins.Top = 0
        Align = alLeft
        TabOrder = 1
        Action = acReplace
        FocusOnClick = False
        ShowCaption = False
        ImageIndex = 1
        Images = ilImages
      end
      object btnDelete: TACLButton
        AlignWithMargins = True
        Left = 54
        Top = 0
        Width = 24
        Height = 24
        Margins.Bottom = 0
        Margins.Left = 0
        Margins.Right = 12
        Margins.Top = 0
        Align = alLeft
        TabOrder = 2
        Action = acDelete
        FocusOnClick = False
        ShowCaption = False
        ImageIndex = 2
        Images = ilImages
      end
      object btnDeleteAll: TACLButton
        Left = 368
        Top = 0
        Width = 24
        Height = 24
        Margins.All = 0
        Align = alRight
        TabOrder = 4
        Action = acDeleteAll
        FocusOnClick = False
        ShowCaption = False
        ImageIndex = 3
        Images = ilImages
      end
      object btnSave: TACLButton
        AlignWithMargins = True
        Left = 90
        Top = 0
        Width = 44
        Height = 24
        Margins.Bottom = 0
        Margins.Left = 0
        Margins.Right = 6
        Margins.Top = 0
        Align = alLeft
        TabOrder = 3
        Caption = '&Add from File...'
        FocusOnClick = False
        ShowCaption = False
        ImageIndex = 4
        Images = ilImages
        DropDownMenu = pmExport
        Kind = sbkDropDown
      end
    end
  end
  object pnlRight: TACLPanel
    AlignWithMargins = True
    Left = 415
    Top = 3
    Width = 200
    Height = 381
    Align = alRight
    TabOrder = 1
    Borders = []
    object gbPreview: TACLGroupBox
      Left = 0
      Top = 0
      Width = 200
      Height = 200
      Align = alTop
      TabOrder = 0
      Caption = ' Preview '
      Padding.Top = 8
      object pbPreview: TPaintBox
        Left = 7
        Top = 15
        Width = 186
        Height = 178
        Align = alClient
        OnPaint = pbPreviewPaint
      end
    end
  end
  object pnlBottom: TACLPanel
    AlignWithMargins = True
    Left = 3
    Top = 390
    Width = 612
    Height = 31
    Align = alBottom
    TabOrder = 2
    Borders = []
    object btnOK: TACLButton
      AlignWithMargins = True
      Left = 453
      Top = 3
      Width = 75
      Height = 25
      Align = alRight
      TabOrder = 0
      Caption = 'OK'
      Default = True
      ModalResult = 1
    end
    object btnCancel: TACLButton
      AlignWithMargins = True
      Left = 534
      Top = 3
      Width = 75
      Height = 25
      Align = alRight
      TabOrder = 1
      Caption = '&Cancel'
      Cancel = True
      ModalResult = 2
    end
  end
  object alActions: TActionList
    Images = ilImages
    Left = 512
    Top = 216
    object acAdd: TAction
      Caption = '&Add from File...'
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
    SourceDPI = 0
    Left = 560
    Top = 216
    Bitmap = {
      4C49435AA6210000B2060000789CDD9A7F50545514C779BBB02CB22608C9AF40
      101DA1404769F48FD254340D435C6C10D32815716AA06234D024452505444427
      1BCD199C317F03ABA929A64D2A283FFC31A60583A2A1FCF00751A820B0FBF6DD
      EE59F6C2EEE3BDB70FF691535FE6B0FBDEBEFBCEFD9C7BDEB9F72EBCF32E45D9
      DB38D8D8DA38E11F84E5E7848C9A123ECEA653F01A806D12365F6C94E1B7F180
      4303158EAE199313AFE4A937A3DE1AF71DFF5BCA0EFDE23760C99F934D8289F2
      2237234DF436C416A36778F9972D5BD6969C9C8CC4DAF2E5CB3BA4686BAD0EA9
      B3F452F043BFF47A3D36DAA2310C63E090A2ED8BE6A728CAD6F82AF7F5F5F5CB
      DC1D5F7EA42C03113B5C94466BCAD25141491ACAC7B6FBE7CF515B7B2B0D0C30
      EEDDFC34326D0796B66369B1B3EB404F998C9283D9D9C995B1B18BE3929292E8
      FEE4E713DFF87F5D10868839AA944EEBBF8DFB85301C3CBF863E549C8A8E5FDD
      824E5FDF858E946E42EDED6D34C96521FEB9B153D6C3E76C9F0101015152F35B
      5BFF4C63A0B0B77548C95E786ADF8515E887F2AD74655D116A7A568FDAB5ADA8
      ADED29D2D15A41FE82928D6843EEA2EB5F66C56A9C9C5E7251CA15AAFEAABB52
      F1B36360A7B0556EDDB5EED893D6269A9D473A9D8E937F7F510AFAFE42125AF0
      C9DB995C7DED8F1810FEFAF26A437E5BCAFF0757EF76F561E3D1990633E5368B
      0156F5EDEA6AF67D689A465CFC55F5A5A8BEB10ACD8A98A5D644E620B0FCC86C
      CED81F56673152F2EB753D86893B064C770DE0E326668B5551F17B45DD531DFA
      EE6A33CAAF7A8ADAB434A239C61FEE4B1489C5C72C750E74F1D37A83EFC2C242
      5E2382F9C152FE2B140AFB0307F61FC45C4CECF13A7AE29E1AFACD3DF7E8828A
      BF6986A1192E7EC88B8E8E0E3A3333338BABAFFD99FF845F8C58FC3236BB03D6
      492C63AED3330E37A059050D68C2DE3A94FB6B333ED7B3FE998E3FA802EB2C96
      83DB507FCA8692F577FDB366FC4DD99DB1CE63753FEB3AFAE6C376B4E4E423B4
      BEB8113D794E1BCE59E207E5E46CC981CFD9EC818181D192F3F7E1F987F672B9
      5C09AFB0FEF1F7F71F7E194BCC7DC4F0DFC4C26B2A5FB9514AAC78ACFE58FF88
      AAFFB88F0FAEDD35E3270CBD5DC393EBFBDA566AFEBECEFFD6ACC5A55CC7BF28
      F566DCD863674DDB7F5B6979617AA86F32396527B68D5225739DBCC865EFE2ED
      3EED713B7DD0A26DDE2D6FCC73FEC67DB8FD043816730F47F78FBEEA796EE19A
      DEF45D0A09F1B39FDFA8A8A8D3B6F6942A6AAD67E5921D3E7ADF310E914EEEB6
      8123C63B2E787F8357CDFC74AF5A31FC2A8F25A943C65E4460E41C39C671596D
      7AADFBF0C52996EEE7159090812BB58C1CCF9E3DFB4C424202E2326F6FEF6950
      D3C1F0A594103F7BFFAE56AB23C7840D4A89DBE1C32806C89CC975FEAF0F889E
      9938E42CB08309F90F09095969CAFBF2A8138F5D8334F7D8F100798EFC386DEC
      CC2B68F4F473CD7CECC1A13FD6C2354347ADCE2531003F7AA6E7BCA7C5024E4B
      EB5BAEFDBBA6349D717619E8C1D507C24D8CCF3F08D64D3158D0CE3528FF0FC2
      ED129477D7F49E6EFE3149C0458C2B06849DD82BAF2666137ED0D1F24D66967F
      295D143FD7FE35675FE20D2E56AE78F0F907D39464D093C2423AF98335F74DF3
      A007DFD4C206BE18B0D9474D3BDB28C6FFE87123A6757EEF22E3CD7F2EFECCDC
      F832537EC877C87BD2069E07782EE0F910F21FF9E1E415703DE1861CE0CB7FBE
      1804879EACE36317E22FBB7D1435B73CEACA45D8C78AE187FDFBDA9D1F94137E
      A87350EFA0EE41FD833A08F510EA22D44721FFEA391173559E4BD378EB9F5BCC
      2A4B31106267F31FBF9C8D2EDF39819A5BBBB97BCB0FFBF71B95258FF132D501
      F8619E83F90EE63D38867910E64398172DF97F84158CA5F28C337C07166314BC
      5779C4A6B2598462C0C56EEADF92C2B0C81A1CCF0B53B9F84DD7EFA7B01C1D1D
      55F64AC5809181AF05E12748A11A2CF791DB510EC3FCFC86858787EF17E31F62
      108DB5128B360ACF0BC97CEC067ED6F32E342F58F25FF9A7165DAC7D8E5AB4DD
      7B63BCFDD0F3F193FD3BD8FDFB35B577B060EF3F3EA7A4267855DEB9EDA7AFDD
      227B7F29FC8B61178A8190FF63B75AD0BC630F0DF6E999C6AE3E08F1B325B4F7
      97C2BF103BE4BCD0BC60C97FFC4F8D5DFEC12ED53DEF033FFFDE5F0AFF42EC5D
      9F09C440C87F6A519399FFAA266DAFF9F924865F8C7FD020B7B722C684956A85
      6A9D590CC2CA6867CFE9F32CF96F78A643EB8AFF429FE1DC3B71BBA57B5C38F8
      FBBA7FB7D63F91937BE87B1003BE3ADF1503CC3ED86BC67C31E3CF272EFEBECA
      5AFFE63198A4B6E4CFD963AAD9DF8D84F61F3CC6444444149AF25BB37FB7D6BF
      B59A123ED1F80E5ECDFF6B80EAFC80E26E890742AA4EFCCFF40F0D1804F7}
  end
  object pmImages: TPopupMenu
    Images = ilImages
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
    Left = 101
    Top = 384
    object miExportAsBMP: TMenuItem
      Action = acExportAsBMP
    end
    object miExportAsPNG: TMenuItem
      Action = acExportAsPNG
    end
  end
  object EditingImageList: TACLImageList
    OnChange = EditingImageListChange
    Left = 72
    Top = 32
  end
  object FileDialog: TACLFileDialog
    Options = [ofOverwritePrompt, ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing, ofAutoExtension]
    Left = 120
    Top = 32
  end
end
