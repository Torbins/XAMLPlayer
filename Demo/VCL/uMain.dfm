object fMain: TfMain
  Left = 0
  Top = 0
  Caption = 'Video Player'
  ClientHeight = 378
  ClientWidth = 628
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object pButtons: TPanel
    Left = 0
    Top = 341
    Width = 628
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'pButtons'
    ShowCaption = False
    TabOrder = 0
    DesignSize = (
      628
      37)
    object lTime: TLabel
      Left = 544
      Top = 0
      Width = 45
      Height = 37
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
    end
    object bOpen: TButton
      Left = 8
      Top = 6
      Width = 65
      Height = 25
      Caption = 'Open'
      TabOrder = 0
      OnClick = bOpenClick
    end
    object bPlay: TButton
      Left = 79
      Top = 6
      Width = 25
      Height = 25
      Caption = #9654
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI Emoji'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = bPlayClick
    end
    object bPause: TButton
      Left = 110
      Top = 6
      Width = 25
      Height = 25
      Caption = #9208
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI Emoji'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = bPauseClick
    end
    object bStop: TButton
      Left = 141
      Top = 6
      Width = 25
      Height = 25
      Caption = #9209
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI Emoji'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = bStopClick
    end
    object bMute: TButton
      Left = 595
      Top = 6
      Width = 25
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #55357#56583
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI Emoji'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = bMuteClick
    end
    object tbPosition: TTrackBar
      Left = 172
      Top = 6
      Width = 366
      Height = 45
      Anchors = [akLeft, akTop, akRight]
      Enabled = False
      Max = 100
      PageSize = 10
      PositionToolTip = ptTop
      TabOrder = 5
      TickMarks = tmBoth
      TickStyle = tsNone
      OnTracking = tbPositionTracking
    end
  end
  object XAMLMediaPlayer: TXAMLMediaPlayer
    Left = 0
    Top = 0
    Width = 628
    Height = 341
    Align = alClient
    OnStateChange = XAMLMediaPlayerStateChange
  end
  object OpenDialog: TOpenDialog
    Left = 64
    Top = 40
  end
  object tTimeUpdate: TTimer
    Enabled = False
    Interval = 100
    OnTimer = tTimeUpdateTimer
    Left = 152
    Top = 40
  end
  object tAction: TTimer
    Interval = 200
    OnTimer = CheckParams
    Left = 224
    Top = 40
  end
end
