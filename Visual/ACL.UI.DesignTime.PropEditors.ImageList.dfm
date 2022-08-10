object frmImageListEditor: TfrmImageListEditor
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'ImageList Editor'
  ClientHeight = 408
  ClientWidth = 577
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
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
      4C49435AA6210000BF060000789CED9A7B4C145714C60F20556B9AB57F988846
      A98D4D8DA16894D4C6905224061A0463B12A2950919582D41625144AA1481015
      04AD564D1AB56A83546B04B55AAD4A82564051D8F2D4E5214F5D5F1414BB41A5
      4EE73BC38CBBCB2EACC5D4B8F1333F2E2ECCDCFB7D73CEDDD9091FCEB1B373A4
      E13484468AFF045113460ABD9AE5F72E49C23849E403913744ECF86BEF7F5EAA
      8F0A73BEA1239FBB51C9FA453471E244C6C9C94941A552299C8CF3A23D1F8FA1
      E31B829FF7B29F99E0A9A36413DD2E5C476E6E6E346DDA34727171619045CBEF
      090CB2C0589BB38033B0159DF9D687EE956DE30C66CF9E4D9E9E9EE4EEEE4E33
      66CCE03CAEE52751DBC944250B5BF35F94EA4FF7CB77720681818114101040FE
      FEFEE4E3E3C379E8F2533903E421FBDF1732F1792FFB99097DAFAFDECB194445
      4551787838858686525050102D5CB890F3F0F3F3E33C90832DFA7F587B40C900
      7D20EF0732A80199E6DC4F6DCA7FF9A6607AD47098EBBFEBFC1AA6BD2081EE9C
      5E49374F2CA7EBC72299D6C36A06FEF17E612BD26E8F20A1ED14B5E67D2D7124
      9669CBFB82693918610432B055FF3D3D3DCCC3870F99EEEE6E46AFD733F08F5A
      B025FF8DD92B48B87E96C7C78F1F534D4D8D111515150C7268DABF8CFDE39EC1
      56C4FEEF5C90464160900330AD07F8C79E604BFEDB7E8E25A14323F581E85DAB
      D51A21D70172807FEC8BB867B215B1FFFB55D4989BA65C7F73C03FDEFFF0DE88
      7B265B518BE61067004CAFBD2978AFC4FDC2A5639B9FF7B25FEA05D5DEC0579E
      EBFC9F2CCE57BEC7E71CDCDB035F5F5F06F7F9DEDEDE0C3EFF78797929982A21
      2181898B8B53888D8D55888989A1E8E86806827719F4D060E77F5AFDF053A591
      FF79F3E65154591213A949A608CD2A8AF833853E2B4F15594D4B2BD630EACA75
      BC1653252525D1C6DA9D0A1BEA765356FD1E26B3215B0139C882F74ACD591E07
      3BFF85EADB4FE5DF77EE51CE40D6FCF9F3F9DC530A97906BF152E69DF3918C6B
      C97266EAC568526BB7F2F530E77FFDD5BDB4A4325DA23A9309BDFC9D42666B1E
      D782A9E07FB0F3A76FAAB5DA7BC6660DFB37143EDF4668B791A72681E694A750
      504D26ADACDB4169CDFB698FEE14E5B79752DBDD3ABAF7F775AE4D53A5A4A4B0
      3F1C135FBF9B8FDBDA765439B6BCA38ADAF53AEE0B731AECFC89ABB5947DB06D
      40EFC70A74E4E29A479BB7971BBD8EE71D5823E6D0DF6DA007F71AE99FAE6689
      FB2DE27DC17589EEBFB847CDF9C7B1F0F8405C23789A9EFEAFF36FDB25D570EE
      896B14BCA46640FFE879C3BE9785671C82FE16095DADBD349320AE41B87BB597
      06C621C0891CE68E660C959696C66BE373F4626D4F23074BF377B4D41BCD8F9F
      2157D9BBE1755C1ED3D06F062BE2357CED9195A942424248E8AC25E1761909B7
      2E49DC2C11394FC28D621274E718FBC0B1A42A8DE41CFAF8C7BA718E5EACE969
      F4336AC2D2FCC7F79590AEB248995F68AFE4E750D8EFCC5D478F5915A45E76A5
      CFEBE88F51A34E5BDC27F09C8B7D36FE4AC2D543120DB9220749A83F4042DD2F
      24D4E6907DC838F66FBFC0F8B9677A7A3AAF4DD03D59AB353D8D7E415F589AFF
      DC81DF687DFC717E2E85F9F1F91CFED591254AED1B6A7B762B394F28A545414F
      EA40F6BE22AECA7C618852ABD5C69E0D7C3BC44E2287E8B7C83EF24DB2573BD3
      DB57123907D40272402D646464F0676743ACEA69B16750CF66E717E7866FF807
      EC5F64F2E42DECDF92D2B29A69E4EB25F4DECC1AF2F6ADA411230ACDD684A1F0
      AC13601D6161610CAE09704874A12F3B0F31013776907B530667803A906B212B
      2B8B3390413D58B5A78819609FE86FFEC0C070F66CC84082DF57475C2247C70B
      E43AB5CCAAF7064B72583B5D42CC01B5800CE45A90EBC09CACDA53C49EC13E31
      90B067C97E50CFFD09D7DF65CA65FEFD31634BF9188CD81BD11F83915C0BE807
      4315C5F4CDC0AA3D45EC67EC1396847D2E69751BFBC1FE0E50DBE871F8C17E26
      DFFBE11AFB7FA4A561C3AA69EAF46A5AFF7D8BF21A3270742C62500F383635A3
      EEA9EB0275B0567F8673305AE757E3A8B6AAC82887FEF614793F05D8272C09DE
      D1C786D70DB5004FC8C1D1B1907B3C38AC857D8390B046BECF31146A02E77992
      43612F0503D693A1866C99A9F483A1AEFC914317E3C7730E7206FDF5347A4306
      FB8425E1DA5ABAB78747E483EB8C11196CFD5167F6770D73405E5276520ECE13
      8AADF63F9090C18B2064872CE43D6196DFFBBD3FC168FC570376D20FECCC9F49
      7A2A267DBFCAEEFF1DE579C5353C02A4A291A412BAC47134A992318E17479D38
      3A93CAA3581C895EF3D0D050711CBE6B238F0E1A67692CF2E0930D6D4AE651D5
      99FC98BA495035390BC5F1D423CE2A148FA69EC54349281E463DDDCE0582D088
      3FB9E8349FCCBFB21ADD99}
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
